# Shared Flyway DDL - Distributed Architecture

## 🔄 Repository Sync Status

[![Auto Sync Pipeline](https://github.com/CleanAyers/shared-flyway-ddl/actions/workflows/auto-sync.yml/badge.svg)](https://github.com/CleanAyers/shared-flyway-ddl/actions/workflows/auto-sync.yml)

| Repository | Status | Last Sync | Branch | Notes |
|------------|--------|-----------|---------|-------|
| **flyway-1-pipeline** | ![Sync Status](https://img.shields.io/github/workflow/status/CleanAyers/shared-flyway-ddl/Check%20Sync%20Status?label=synced&style=flat-square) | ![Last Commit](https://img.shields.io/github/last-commit/CleanAyers/flyway-1-pipeline/main?label=&style=flat-square) | `main` | Pipeline Database |
| **flyway-1-grants** | ![Sync Status](https://img.shields.io/github/workflow/status/CleanAyers/shared-flyway-ddl/Check%20Sync%20Status?label=synced&style=flat-square) | ![Last Commit](https://img.shields.io/github/last-commit/CleanAyers/flyway-1-grants/main?label=&style=flat-square) | `main` | Grants & Permissions |
| **flyway-2-pipeline** | ![Sync Status](https://img.shields.io/github/workflow/status/CleanAyers/shared-flyway-ddl/Check%20Sync%20Status?label=synced&style=flat-square) | ![Last Commit](https://img.shields.io/github/last-commit/CleanAyers/flyway-2-pipeline/main?label=&style=flat-square) | `main` | Pipeline Database |
| **flyway-2-grants** | ![Sync Status](https://img.shields.io/github/workflow/status/CleanAyers/shared-flyway-ddl/Check%20Sync%20Status?label=synced&style=flat-square) | ![Last Commit](https://img.shields.io/github/last-commit/CleanAyers/flyway-2-grants/main?label=&style=flat-square) | `main` | Grants & Permissions |

### 🎯 Quick Actions
- **📊 [Check Detailed Status](../../actions/workflows/sync-status.yml)** - View complete synchronization report
- **🔄 [Manual Sync](../../actions/workflows/auto-sync.yml)** - Trigger synchronization manually
- **📋 [View Logs](../../actions)** - See recent sync operations

### 🚀 Automation Status
- **✅ Auto-sync on push to `main`** - Automatically syncs all child repositories
- **✅ Status monitoring** - Real-time sync status tracking
- **✅ Conflict detection** - Alerts on sync issues
- **🔔 Notifications** - Slack/email alerts on failures (optional)

---

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
4. Real testing - You get to test your sync mechanism across actual different databases# Test commit
# Test permissions fix - Sat Nov  8 11:03:00 CST 2025
