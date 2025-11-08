# 🧩 Using Python Scripts with Flyway

This guide explains how to integrate **Python-based data ingestion** scripts into a Flyway-powered database pipeline.

---

## 🧠 Concept Overview

Flyway and Python serve two different purposes, but they complement each other perfectly:

| Tool | Role | Typical Actions |
|------|------|------------------|
| **Flyway** | Schema migration (DDL) | Create tables, views, indexes, constraints |
| **Python** | Data ingestion / ETL (DML) | Insert, update, or transform data via APIs or CSVs |

---

## ⚙️ 1. Flyway – Set Up Your Database Structure

Flyway runs all versioned (`V__`) and repeatable (`R__`) migration scripts to create and maintain your schema.

Example:

```bash
flyway -configFiles=conf/flyway.conf migrate
```

This ensures your Postgres instance is at the correct version — with all necessary schemas, tables, and views in place.

---

## 🐍 2. Python – Load Data After Migration

Once Flyway has created the schema, you can use a Python script to load real data into those tables.

Example script (`scripts/fetch_odds.py`):

```python
import requests, psycopg2

conn = psycopg2.connect("dbname=sports_data user=postgres password=secret")
cur = conn.cursor()

data = requests.get("https://api.theoddsapi.com/v4/sports/soccer/odds").json()

for match in data:
    cur.execute(
        "INSERT INTO sports.match_odds (match_id, home_team, away_team, home_odds, away_odds) VALUES (%s, %s, %s, %s, %s) ON CONFLICT DO NOTHING",
        (match["id"], match["home_team"], match["away_team"],
         match["bookmakers"][0]["markets"][0]["outcomes"][0]["price"],
         match["bookmakers"][0]["markets"][0]["outcomes"][1]["price"])
    )

conn.commit()
cur.close()
conn.close()
```

This script pulls odds from an API and inserts them into the tables Flyway created.

---

## 🔄 3. Orchestrating with a Makefile

You can automate the whole sequence using a `Makefile`:

```makefile
migrate:
	flyway -configFiles=conf/flyway.conf migrate

load:
	python scripts/fetch_odds.py

views:
	psql sports_data -c "SELECT * FROM sports.vw_upcoming_with_form;"

all: migrate load views
```

Now you can just run:

```bash
make all
```

This will:
1. Run Flyway migrations
2. Load new data via Python
3. Query or refresh analytics views

---

## ⚙️ 4. Integrating into CI/CD (Optional)

In a GitHub Actions workflow (`.github/workflows/migrate.yml`), you could automate this on every push:

1. Start a Postgres service.
2. Run `flyway migrate`.
3. Execute the Python ingestion script.

That way, your schema and data always stay synchronized.

---

## 🧩 Summary

| Step | Command | Purpose |
|------|----------|----------|
| 1️⃣ | `flyway migrate` | Apply schema migrations |
| 2️⃣ | `python scripts/fetch_odds.py` | Load data into tables |
| 3️⃣ | `psql` or dashboards | Query and analyze data |

Flyway defines **structure**.  
Python provides **data**.  
Make or CI ties it **all together**.

---

**Next:** Consider adding logging or exception handling to your Python ingestion script so failed API calls never break the pipeline.
