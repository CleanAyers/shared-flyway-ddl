# 🏗️ Project: Sports Stats Warehouse (Flyway + Postgres)

**Objective:**  
Design and implement a modular Flyway migration pipeline that manages a Postgres database for ingesting, transforming, and versioning sports data (EPL, MLB, MLS, NBA, etc.).  
This project simulates real-world data warehousing and schema version control in a DevOps-like setup.

---

## 🎯 Learning Goals
- **Flyway Fundamentals**
  - Create and version SQL migrations (`V1__init.sql`, `V2__add_xg_tables.sql`, `R__refresh_views.sql`)
  - Practice repeatable vs. versioned migrations
  - Test rollback and re-run behaviors

- **Postgres Skills**
  - Design normalized schemas for sports data (`teams`, `fixtures`, `stats`, `odds`)
  - Write joins, aggregates, and materialized views
  - Explore partitioning and indexing strategies for historical data

- **Pipeline Orchestration**
  - Automate schema migrations via scripts or CI
  - Synchronize shared DDL (parent → child cluster) using Git subtrees
  - Integrate data ingestion via API (Football-Data.org or The Odds API)

- **Analytics Layer**
  - Build read-optimized views (e.g., xG summaries, team performance)
  - Use SQL or Python (Pandas) to visualize data trends

---

## 🧩 Deliverables
1. **Flyway Migration Repo**
   - `V1__init.sql` – schema and seed tables
   - `V2__fixtures_table.sql` – add match details
   - `R__refresh_views.sql` – repeatable analytics views

2. **Sample Data Pipeline**
   - Python script (`fetch_data.py`) to load external API data into Postgres
   - Dockerized Postgres setup (optional)
   - Scheduled Flyway `migrate` runs

3. **Documentation**
   - `README.md` with setup and migration commands
   - Entity Relationship Diagram (ERD)
   - Example queries

---

## 🧠 Stretch Goals
- Integrate a **Grafana dashboard** or **Metabase** instance
- Add **test data validation** before Flyway runs
- Deploy schema updates automatically through GitHub Actions

---

**Next Steps:**  
1. Initialize local Postgres (`sports_data` DB).  
2. Create Flyway configuration (`flyway.conf`).  
3. Write first migration file (`V1__init.sql`).  
4. Test migration + rollback locally.  
5. Add small API ingestion job to populate match data.  