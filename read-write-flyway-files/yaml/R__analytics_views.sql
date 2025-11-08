-- Repeatable analytics views for sports schema
-- Re-run any time with: flyway migrate

SET search_path = sports, public;

-- 1) Latest odds per fixture (by captured_at)
CREATE OR REPLACE VIEW sports.vw_odds_latest AS
WITH ranked AS (
  SELECT
    o.*,
    ROW_NUMBER() OVER (PARTITION BY o.fixture_id ORDER BY o.captured_at DESC, o.odds_id DESC) AS rn
  FROM sports.odds o
)
SELECT *
FROM ranked
WHERE rn = 1;


-- 2) Next 7 days fixtures (friendly names + latest odds)
CREATE OR REPLACE VIEW sports.vw_next_7_days_fixtures AS
SELECT
  f.fixture_id,
  c.code          AS competition_code,
  c.name          AS competition_name,
  f.match_date,
  ht.name         AS home_team,
  at.name         AS away_team,
  f.venue,
  f.status,
  ol.ml_home,
  ol.ml_draw,
  ol.ml_away,
  ol.btts_yes,
  ol.btts_no,
  ol.ou_2_5_over,
  ol.ou_2_5_under,
  ol.source       AS odds_source,
  ol.captured_at  AS odds_captured_at
FROM sports.fixtures f
JOIN sports.competitions c ON c.competition_id = f.competition_id
JOIN sports.teams ht ON ht.team_id = f.home_team_id
JOIN sports.teams at ON at.team_id = f.away_team_id
LEFT JOIN sports.vw_odds_latest ol ON ol.fixture_id = f.fixture_id
WHERE f.match_date >= now()
  AND f.match_date <  now() + interval '7 days'
ORDER BY f.match_date ASC;


-- 3) Recent form (last 5 results per team, 3-1-0 points)
CREATE OR REPLACE VIEW sports.vw_recent_form AS
WITH exploded AS (
  SELECT
    f.fixture_id,
    f.match_date,
    f.status,
    f.home_team_id AS team_id,
    CASE
      WHEN f.home_score IS NOT NULL AND f.away_score IS NOT NULL THEN
        CASE WHEN f.home_score > f.away_score THEN 3
             WHEN f.home_score = f.away_score THEN 1
             ELSE 0 END
      ELSE NULL
    END AS points
  FROM sports.fixtures f
  UNION ALL
  SELECT
    f.fixture_id,
    f.match_date,
    f.status,
    f.away_team_id AS team_id,
    CASE
      WHEN f.home_score IS NOT NULL AND f.away_score IS NOT NULL THEN
        CASE WHEN f.away_score > f.home_score THEN 3
             WHEN f.away_score = f.home_score THEN 1
             ELSE 0 END
      ELSE NULL
    END AS points
  FROM sports.fixtures f
),
ranked AS (
  SELECT
    e.*,
    ROW_NUMBER() OVER (PARTITION BY e.team_id ORDER BY e.match_date DESC, e.fixture_id DESC) AS rn
  FROM exploded e
  WHERE e.points IS NOT NULL
)
SELECT
  r.team_id,
  SUM(CASE WHEN r.rn <= 5 THEN r.points ELSE 0 END) AS points_last_5,
  AVG(CASE WHEN r.rn <= 5 THEN r.points::numeric ELSE NULL END) AS avg_points_last_5
FROM ranked r
GROUP BY r.team_id;


-- 4) xG summary per fixture with team names
CREATE OR REPLACE VIEW sports.vw_xg_summary AS
SELECT
  f.fixture_id,
  c.code AS competition_code,
  f.match_date,
  ht.name AS home_team,
  at.name AS away_team,
  x.home_xg, x.away_xg,
  x.home_xgot, x.away_xgot,
  x.home_xa,   x.away_xa
FROM sports.fixtures f
JOIN sports.competitions c ON c.competition_id = f.competition_id
JOIN sports.teams ht ON ht.team_id = f.home_team_id
JOIN sports.teams at ON at.team_id = f.away_team_id
LEFT JOIN sports.match_xg x ON x.fixture_id = f.fixture_id;


-- 5) Convenience: upcoming fixtures with recent form snippet
CREATE OR REPLACE VIEW sports.vw_upcoming_with_form AS
SELECT
  n.fixture_id,
  n.competition_code,
  n.competition_name,
  n.match_date,
  n.home_team,
  n.away_team,
  ht_form.points_last_5 AS home_points_last_5,
  at_form.points_last_5 AS away_points_last_5,
  n.ml_home, n.ml_draw, n.ml_away,
  n.btts_yes, n.btts_no,
  n.ou_2_5_over, n.ou_2_5_under,
  n.odds_source, n.odds_captured_at
FROM sports.vw_next_7_days_fixtures n
LEFT JOIN sports.vw_recent_form ht_form ON ht_form.team_id = (
  SELECT team_id FROM sports.teams WHERE name = n.home_team LIMIT 1
)
LEFT JOIN sports.vw_recent_form at_form ON at_form.team_id = (
  SELECT team_id FROM sports.teams WHERE name = n.away_team LIMIT 1
)
ORDER BY n.match_date;
