# Shared Database DDL - Distributed Architecture

### 🔄 Repository Sync Status: 
[![PR Validation](https://github.com/CleanAyers/shared-flyway-ddl/actions/workflows/pr-validation.yml/badge.svg)](https://github.com/CleanAyers/shared-flyway-ddl/actions/workflows/pr-validation.yml) [![Production Release](https://github.com/CleanAyers/shared-flyway-ddl/actions/workflows/production-release.yml/badge.svg?branch=main)](https://github.com/CleanAyers/shared-flyway-ddl/actions/workflows/production-release.yml)


| Repository | Status | Last Sync | Branch | Notes |
|------------|--------|-----------|---------|-------|
| **flyway-1-pipeline** | [![Downstream Sync Status](https://github.com/CleanAyers/flyway-1-pipeline/actions/workflows/flyway-protection.yml/badge.svg)](https://github.com/CleanAyers/flyway-1-pipeline/actions/workflows/flyway-protection.yml) | ![Last Commit](https://img.shields.io/github/last-commit/CleanAyers/flyway-1-pipeline/main?label=&style=flat-square) | `main` | Pipeline Database |
| **flyway-1-grants** | [![Downstream Sync Status](https://github.com/CleanAyers/flyway-1-grants/actions/workflows/flyway-protection.yml/badge.svg)](https://github.com/CleanAyers/flyway-1-grants/actions/workflows/flyway-protection.yml) | ![Last Commit](https://img.shields.io/github/last-commit/CleanAyers/flyway-1-grants/main?label=&style=flat-square) | `main` | Grants & Permissions |
| **flyway-2-pipeline** | [![Downstream Sync Status](https://github.com/CleanAyers/flyway-2-pipeline/actions/workflows/flyway-protection.yml/badge.svg)](https://github.com/CleanAyers/flyway-2-pipeline/actions/workflows/flyway-protection.yml) | ![Last Commit](https://img.shields.io/github/last-commit/CleanAyers/flyway-2-pipeline/main?label=&style=flat-square) | `main` | Pipeline Database |
| **flyway-2-grants** | [![Downstream Sync Status](https://github.com/CleanAyers/flyway-2-grants/actions/workflows/flyway-protection.yml/badge.svg)](https://github.com/CleanAyers/flyway-2-grants/actions/workflows/flyway-protection.yml) | ![Last Commit](https://img.shields.io/github/last-commit/CleanAyers/flyway-2-grants/main?label=&style=flat-square) | `main` | Grants & Permissions |

### 🎯 The Simple Workflow

1. **Add your files to the parent repository** (`shared-flyway-ddl/read-write-flyway-files`) 
2. **Merge to `main` branch** 
3. **Pipeline automatically syncs to all child repositories**
4. **Child repositories get all new files within the shared folder added**

### 🚀 Quick Reference

## 📊 Repository Flow Diagram

```
                           🏛️ PARENT REPOSITORY
                        shared-flyway-ddl (main)
                                   │
                          ┌────────┴────────┐
                          │ Git Subtree     │
                          │ Auto-Sync       │
                          │ GitHub Actions  │
                          └────────┬────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
              ▼                    │                    ▼
    ╔═══════════════════╗          │          ╔═══════════════════╗
    ║    CLUSTER-1      ║          │          ║    CLUSTER-2      ║
    ║                   ║          │          ║                   ║
    ║  ┌─────────────┐  ║          │          ║  ┌─────────────┐  ║
    ║  │ flyway-1-   │◄─╬          │          ╬─►│ flyway-2-   │  ║
    ║  │ pipeline    │  ║          │          ║  │ pipeline    │  ║
    ║  └─────────────┘  ║          │          ║  └─────────────┘  ║
    ║        │          ║          │          ║        │          ║
    ║        │          ║          │          ║        │          ║
    ║  ┌─────────────┐  ║          │          ║  ┌─────────────┐  ║
    ║  │ flyway-1-   │◄─╬          │          ╬─►│ flyway-2-   │  ║
    ║  │ grants      │  ║          │          ║  │ grants      │  ║
    ║  └─────────────┘  ║          │          ║  └─────────────┘  ║
    ╚═══════════════════╝          │          ╚═══════════════════╝
                                   │
                                   ▼
                          ┌────────────────┐
                          │   Sync Status  │
                          │   Monitoring   │
                          │   (Optional)   │
                          └────────────────┘
```

## 🔄 Data Flow Architecture

```
Parent Repo Structure:
┌─ shared-flyway-ddl/
│  ├─ read-write-flyway-files/  ← ✏️  EDIT HERE
│  │  ├─ sql/
│  │  ├─ callbacks/
│  │  ├─ global_config/
│  │  ├─ scripts/
│  │  └─ yaml/
│  └─ .github/workflows/
│     ├─ auto-sync.yml         ← 🤖 Auto triggers
│     └─ production-release.yml ← 🚀 Production deploy
│
│
└─ SYNCS TO ────────────────────────────┐
                                        │
┌───────────────────────────────────────▼─────────────────────────────────┐
│                     Child Repositories                                  │
│                                                                         │
│  flyway-1-pipeline/          flyway-1-grants/                           │
│  ├─ config/ (local)          ├─ conf/ (local)                           │
│  └─ read-only-flyway-files/  └─ read-only-flyway-files/                 │
│     ├─ sql/ ◄────────────────────┬─ sql/ ◄─────────────┐                │
│     ├─ callbacks/               ├─ callbacks/          │                │
│     ├─ global_config/           ├─ global_config/      │                │
│     ├─ scripts/                 ├─ scripts/            │                │
│     └─ yaml/                    └─ yaml/               │                │
│                                                        │                │
│  flyway-2-pipeline/          flyway-2-grants/          │                │
│  ├─ config/ (local)          ├─ config/ (local)        │                │
│  └─ read-only-flyway-files/  └─ read-only-flyway-files/│                │
│     ├─ sql/ ◄────────────────────┬─ sql/ ◄─────────────┘                │
│     ├─ callbacks/               ├─ callbacks/                           │
│     ├─ global_config/           ├─ global_config/                       │
│     ├─ scripts/                 ├─ scripts/                             │
│     └─ yaml/                    └─ yaml/                                │
└─────────────────────────────────────────────────────────────────────────┘
```
