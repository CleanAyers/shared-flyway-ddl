## Running Postgres DB related Notes
- Quick Start on Mac

1) Create DB (Postgres.app or psql)
createdb sports_data

2) Put files in place
  project/
    conf/flyway.conf
        sql/V1__init.sql

3) Run migration
flyway -configFiles=conf/flyway.conf migrate

4) Smoke test
psql sports_data -c "\dt sports.*"
psql sports_data -c "SELECT * FROM sports.fixtures LIMIT 5;"


## 🎯 Recommended Approach for Your Hobby Project

#### Phase 1: Local Development
```
# Start with local PostgreSQL
brew install postgresql
createdb cluster1_dev
createdb cluster2_dev
```

#### Phase 2: Cloud Testing
- Neon for Cluster 1 (great branching features)
- Supabase for Cluster 2 (nice dashboard)

#### Phase 3: "Production" Simulation

- Keep using free tiers but treat them as prod
- Your Flyway architecture will work identically
- All your CI/CD pipelines will function the same
  
### 💡 Bonus: Perfect for Your Architecture
Your distributed Flyway setup is actually ideal for free tiers because:

1. Small databases - You're not storing massive amounts of data
2. Clear separation - Each cluster can use different providers
3. Easy migration - If you outgrow free tiers, just change connection strings
4. Real testing - You get to test your sync mechanism across actual different databases