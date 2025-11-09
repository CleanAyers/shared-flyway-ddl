# Shared Flyway DDL - Distributed Architecture

## 🔄 Repository Sync Status

[![PR Validation](https://github.com/CleanAyers/shared-flyway-ddl/actions/workflows/pr-validation.yml/badge.svg)](https://github.com/CleanAyers/shared-flyway-ddl/actions/workflows/pr-validation.yml)
[![Production Release](https://github.com/CleanAyers/shared-flyway-ddl/actions/workflows/production-release.yml/badge.svg?branch=main)](https://github.com/CleanAyers/shared-flyway-ddl/actions/workflows/production-release.yml)


| Repository | Status | Last Sync | Branch | Notes |
|------------|--------|-----------|---------|-------|
| **flyway-1-pipeline** | ![Downstream Sync Status](https://img.shields.io/github/workflow/status/CleanAyers/flyway-1-pipeline/Flyway%20Landing%20Confirmation?label=synced&style=flat-square) | ![Last Commit](https://img.shields.io/github/last-commit/CleanAyers/flyway-1-pipeline/main?label=&style=flat-square) | `main` | Pipeline Database |
| **flyway-1-grants** | ![Sync Status](https://img.shields.io/github/workflow/status/CleanAyers/flyway-1-grants/Flyway%20Landing%20Confirmation?label=synced&style=flat-square) | ![Last Commit](https://img.shields.io/github/last-commit/CleanAyers/flyway-1-grants/main?label=&style=flat-square) | `main` | Grants & Permissions |
| **flyway-2-pipeline** | ![Sync Status](https://img.shields.io/github/workflow/status/CleanAyers/flyway-2-pipeline/Flyway%20Landing%20Confirmation?label=synced&style=flat-square) | ![Last Commit](https://img.shields.io/github/last-commit/CleanAyers/flyway-2-pipeline/main?label=&style=flat-square) | `main` | Pipeline Database |
| **flyway-2-grants** | ![Sync Status](https://img.shields.io/github/workflow/status/CleanAyers/shared-flyway-ddl/Flyway%20Landing%20Confirmation?label=synced&style=flat-square) | ![Last Commit](https://img.shields.io/github/last-commit/CleanAyers/flyway-2-grants/main?label=&style=flat-square) | `main` | Grants & Permissions |

### 🎯 Quick Actions
- **📊 [Check Detailed Status](../../actions/workflows/sync-status.yml)** - View complete synchronization report
- **🔄 [Manual Sync](../../actions/workflows/auto-sync.yml)** - Trigger synchronization manually
- **📋 [View Logs](../../actions)** - See recent sync operations

### 🚀 Automation Status
- **✅ Auto-sync on push to `main`** - Automatically syncs all child repositories
- **✅ Status monitoring** - Real-time sync status tracking
- **✅ Conflict detection** - Alerts on sync issues
- **🔔 Notifications** - Slack/email alerts on failures (optional)
