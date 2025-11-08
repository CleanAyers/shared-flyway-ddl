#!/usr/bin/env python3
"""
Load odds into sports.odds.

Priority:
1) If ODDS_API_KEY is set, fetch EPL soccer odds from The Odds API (upcoming).
2) Else, use a small built-in mock payload so you can test the pipeline.

Env:
  PGHOST=localhost
  PGPORT=5432
  PGDATABASE=sports_data
  PGUSER=postgres
  PGPASSWORD=...           # optional if you have trust auth locally
  ODDS_API_KEY=...         # optional; if missing we use mock data

Usage:
  python scripts/fetch_odds.py
"""

import os
import sys
import json
import time
import datetime as dt
from typing import List, Dict, Any, Optional

import psycopg2
import psycopg2.extras
import requests


def pg_connect():
    conn = psycopg2.connect(
        host=os.getenv("PGHOST", "localhost"),
        port=int(os.getenv("PGPORT", "5432")),
        dbname=os.getenv("PGDATABASE", "sports_data"),
        user=os.getenv("PGUSER", "postgres"),
        password=os.getenv("PGPASSWORD", ""),
    )
    conn.autocommit = True
    return conn


def fetch_real_odds() -> List[Dict[str, Any]]:
    """
    Minimal Odds API call for EPL soccer (bookmaker-agnostic).
    See: https://the-odds-api.com/ (requires API key)
    """
    api_key = os.getenv("ODDS_API_KEY")
    if not api_key:
        return []

    url = "https://api.the-odds-api.com/v4/sports/soccer_epl/odds"
    params = {
        "apiKey": api_key,
        "regions": "uk,eu,us",
        "markets": "h2h,btts,totals",
        "oddsFormat": "decimal",
        "dateFormat": "iso",
    }
    try:
        resp = requests.get(url, params=params, timeout=20)
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        print(f"[WARN] Odds API failed: {e}", file=sys.stderr)
        return []


def mock_odds_payload() -> List[Dict[str, Any]]:
    # Minimal mock shaped similarly: one match with H2H + BTTS + Totals
    now = dt.datetime.utcnow()
    start = (now + dt.timedelta(days=3)).replace(microsecond=0).isoformat() + "Z"
    return [
        {
            "id": "mock-001",
            "commence_time": start,
            "home_team": "Newcastle United",
            "away_team": "Arsenal",
            "bookmakers": [
                {
                    "key": "mockbook",
                    "title": "Mock Book",
                    "last_update": now.isoformat() + "Z",
                    "markets": [
                        {
                            "key": "h2h",
                            "outcomes": [
                                {"name": "Newcastle United", "price": 2.20},
                                {"name": "Arsenal", "price": 3.10},
                                {"name": "Draw", "price": 3.45},
                            ],
                        },
                        {
                            "key": "btts",
                            "outcomes": [
                                {"name": "Yes", "price": 1.70},
                                {"name": "No", "price": 2.10},
                            ],
                        },
                        {
                            "key": "totals",
                            "outcomes": [
                                {"name": "Over 2.5", "price": 1.95},
                                {"name": "Under 2.5", "price": 1.85},
                            ],
                        },
                    ],
                }
            ],
        }
    ]


def parse_decimal(outs: List[Dict[str, Any]], name: str) -> Optional[float]:
    for o in outs:
        if o.get("name", "").lower() == name.lower():
            try:
                return float(o.get("price"))
            except Exception:
                return None
    return None


def resolve_fixture_id(cur, home: str, away: str, kickoff_iso: str) -> Optional[int]:
    """
    Try to resolve a fixture by team names within +/- 2 days of commence_time.
    This is heuristic for demo purposes.
    """
    try:
        kickoff = dt.datetime.fromisoformat(kickoff_iso.replace("Z", "+00:00"))
    except Exception:
        kickoff = None

    params = {"home": home, "away": away}
    time_clause = ""
    if kickoff:
        params["start"] = kickoff - dt.timedelta(days=2)
        params["end"] = kickoff + dt.timedelta(days=2)
        time_clause = "AND f.match_date BETWEEN %(start)s AND %(end)s"

    sql = f"""
        SELECT f.fixture_id
        FROM sports.fixtures f
        JOIN sports.teams ht ON ht.team_id = f.home_team_id
        JOIN sports.teams at ON at.team_id = f.away_team_id
        WHERE LOWER(ht.name) = LOWER(%(home)s)
          AND LOWER(at.name) = LOWER(%(away)s)
          {time_clause}
        ORDER BY ABS(EXTRACT(EPOCH FROM (f.match_date - COALESCE(%(start)s, f.match_date))))
        LIMIT 1
    """
    cur.execute(sql, params)
    row = cur.fetchone()
    return row[0] if row else None


def upsert_odds(cur, fixture_id: int, source: str, payload: Dict[str, Any]):
    ml_home = ml_draw = ml_away = btts_yes = btts_no = ou_over = ou_under = None

    # Extract markets (format differs by provider; we standardize)
    for m in payload.get("markets", []):
        key = m.get("key")
        outs = m.get("outcomes", [])
        if key == "h2h":
            ml_home = parse_decimal(outs, "home") or parse_decimal(outs, payload.get("home_team", ""))
            ml_away = parse_decimal(outs, "away") or parse_decimal(outs, payload.get("away_team", ""))
            ml_draw = parse_decimal(outs, "draw")
        elif key == "btts":
            btts_yes = parse_decimal(outs, "yes")
            btts_no = parse_decimal(outs, "no")
        elif key == "totals":
            ou_over  = parse_decimal(outs, "over 2.5")
            ou_under = parse_decimal(outs, "under 2.5")

    cur.execute(
        """
        INSERT INTO sports.odds
          (fixture_id, source, captured_at, ml_home, ml_draw, ml_away,
           btts_yes, btts_no, ou_2_5_over, ou_2_5_under, meta)
        VALUES
          (%s, %s, now(), %s, %s, %s, %s, %s, %s, %s, %s::jsonb)
        """,
        (
            fixture_id,
            source,
            ml_home,
            ml_draw,
            ml_away,
            btts_yes,
            btts_no,
            ou_over,
            ou_under,
            json.dumps(payload),
        ),
    )


def main():
    conn = pg_connect()
    cur = conn.cursor()

    data = fetch_real_odds()
    used_real = True
    if not data:
        data = mock_odds_payload()
        used_real = False

    inserted = 0
    for event in data:
        home = event.get("home_team")
        away = event.get("away_team")
        commence_time = event.get("commence_time")
        bookmakers = event.get("bookmakers", [])
        if not home or not away or not bookmakers:
            continue

        # Resolve fixture
        fixture_id = resolve_fixture_id(cur, home, away, commence_time or "")
        if not fixture_id:
            print(f"[INFO] No fixture match for {home} vs {away} @ {commence_time}, skipping odds insert.")
            continue

        # Insert one row per bookmaker
        for bk in bookmakers:
            payload = {
                "key": bk.get("key"),
                "title": bk.get("title"),
                "last_update": bk.get("last_update"),
                "markets": bk.get("markets", []),
                "home_team": home,
                "away_team": away,
            }
            source = bk.get("title") or bk.get("key") or ("real_api" if used_real else "mockbook")
            upsert_odds(cur, fixture_id, source, payload)
            inserted += 1

    print(f"Inserted {inserted} odds rows.")
    cur.close()
    conn.close()


if __name__ == "__main__":
    main()