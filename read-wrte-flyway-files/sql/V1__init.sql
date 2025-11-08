-- Schema: sports_data
-- Purpose: base structures for leagues/teams/fixtures + odds/xG

-- Idempotent guards for schema creation (safe on first-run)
CREATE SCHEMA IF NOT EXISTS sports;

-- --- Reference tables -------------------------------------------------------

CREATE TABLE IF NOT EXISTS sports.competitions (
    competition_id   SERIAL PRIMARY KEY,
    code             TEXT UNIQUE NOT NULL,          -- e.g., EPL, UCL, MLS
    name             TEXT NOT NULL,                 -- e.g., Premier League
    country          TEXT,
    season           TEXT,                          -- e.g., 2025/26
    created_at       TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sports.teams (
    team_id          SERIAL PRIMARY KEY,
    ext_ref          TEXT,                          -- external provider id
    name             TEXT NOT NULL,
    short_name       TEXT,
    country          TEXT,
    created_at       TIMESTAMPTZ DEFAULT now(),
    UNIQUE (name, country)
);

-- --- Fixtures (matches) -----------------------------------------------------

CREATE TABLE IF NOT EXISTS sports.fixtures (
    fixture_id       BIGSERIAL PRIMARY KEY,
    competition_id   INT NOT NULL REFERENCES sports.competitions(competition_id),
    match_date       TIMESTAMPTZ NOT NULL,
    status           TEXT NOT NULL DEFAULT 'scheduled',  -- scheduled|live|finished|postponed
    home_team_id     INT NOT NULL REFERENCES sports.teams(team_id),
    away_team_id     INT NOT NULL REFERENCES sports.teams(team_id),
    home_score       INT,
    away_score       INT,
    venue            TEXT,
    ext_ref          TEXT,                                -- external provider id
    created_at       TIMESTAMPTZ DEFAULT now(),
    UNIQUE (competition_id, match_date, home_team_id, away_team_id)
);

-- --- Advanced stats (expected goals etc.) -----------------------------------

CREATE TABLE IF NOT EXISTS sports.match_xg (
    fixture_id       BIGINT PRIMARY KEY REFERENCES sports.fixtures(fixture_id) ON DELETE CASCADE,
    home_xg          NUMERIC(6,3),
    away_xg          NUMERIC(6,3),
    home_xgot        NUMERIC(6,3),     -- xG on target
    away_xgot        NUMERIC(6,3),
    home_xa          NUMERIC(6,3),
    away_xa          NUMERIC(6,3),
    updated_at       TIMESTAMPTZ DEFAULT now()
);

-- --- Odds snapshot table ----------------------------------------------------

CREATE TABLE IF NOT EXISTS sports.odds (
    odds_id          BIGSERIAL PRIMARY KEY,
    fixture_id       BIGINT NOT NULL REFERENCES sports.fixtures(fixture_id) ON DELETE CASCADE,
    source           TEXT NOT NULL,                    -- e.g., pinnacle, exchange, oddsapi
    captured_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    ml_home          NUMERIC(10,4),                    -- moneyline home decimal odds
    ml_draw          NUMERIC(10,4),
    ml_away          NUMERIC(10,4),
    btts_yes         NUMERIC(10,4),                    -- both teams to score YES
    btts_no          NUMERIC(10,4),
    ou_2_5_over      NUMERIC(10,4),
    ou_2_5_under     NUMERIC(10,4),
    meta             JSONB DEFAULT '{}'::jsonb
);

-- --- Helpful indexes --------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_competitions_code        ON sports.competitions(code);
CREATE INDEX IF NOT EXISTS idx_teams_name_country       ON sports.teams(name, country);
CREATE INDEX IF NOT EXISTS idx_fixtures_comp_date       ON sports.fixtures(competition_id, match_date);
CREATE INDEX IF NOT EXISTS idx_fixtures_teams_date      ON sports.fixtures(home_team_id, away_team_id, match_date);
CREATE INDEX IF NOT EXISTS idx_odds_fixture_captured    ON sports.odds(fixture_id, captured_at DESC);

-- --- Seed minimal reference data (safe-upsert style) -----------------------

INSERT INTO sports.competitions(code, name, country, season)
VALUES
  ('EPL', 'Premier League', 'England', '2025/26'),
  ('LLA', 'La Liga',        'Spain',   '2025/26'),
  ('SA',  'Serie A',        'Italy',   '2025/26')
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    country = EXCLUDED.country,
    season = EXCLUDED.season;

-- Example teams (add as needed)
INSERT INTO sports.teams(name, short_name, country)
VALUES
  ('Newcastle United','NEW','England'),
  ('Arsenal','ARS','England'),
  ('Liverpool','LIV','England')
ON CONFLICT (name, country) DO NOTHING;

-- Example fixture (to verify joins work)
INSERT INTO sports.fixtures(competition_id, match_date, home_team_id, away_team_id, venue, status)
SELECT c.competition_id, now() + interval '3 days', t1.team_id, t2.team_id, 'St James'' Park', 'scheduled'
FROM sports.competitions c
JOIN sports.teams t1 ON t1.name = 'Newcastle United'
JOIN sports.teams t2 ON t2.name = 'Arsenal'
WHERE c.code = 'EPL'
ON CONFLICT DO NOTHING;