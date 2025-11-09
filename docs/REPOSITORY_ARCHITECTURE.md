# 🏗️ Flyway Repository Architecture

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
    ║  │ flyway-1-   │◄─╬──────────┼──────────╬─►│ flyway-2-   │  ║
    ║  │ pipeline    │  ║          │          ║  │ pipeline    │  ║
    ║  └─────────────┘  ║          │          ║  └─────────────┘  ║
    ║        │          ║          │          ║        │          ║
    ║        │          ║          │          ║        │          ║
    ║  ┌─────────────┐  ║          │          ║  ┌─────────────┐  ║
    ║  │ flyway-1-   │◄─╬──────────┼──────────╬─►│ flyway-2-   │  ║
    ║  │ grants      │  ║          │          ║  │ grants      │  ║
    ║  └─────────────┘  ║          │          ║  └─────────────┘  ║
    ╚═══════════════════╝          │          ╚═══════════════════╝
                                   │
                                   ▼
                          ┌────────────────┐
                          │ Sync Status    │
                          │ Monitoring     │
                          │ (Every 6hrs)   │
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
│                     Child Repositories                                   │
│                                                                           │
│  flyway-1-pipeline/          flyway-1-grants/                           │
│  ├─ config/ (local)          ├─ conf/ (local)                           │
│  └─ read-only-flyway-files/  └─ read-only-flyway-files/                 │
│     ├─ sql/ ◄────────────────────┬─ sql/ ◄─────────────┐                │
│     ├─ callbacks/               ├─ callbacks/          │                │
│     ├─ global_config/           ├─ global_config/      │                │
│     ├─ scripts/                 ├─ scripts/            │                │
│     └─ yaml/                    └─ yaml/               │                │
│                                                        │                │
│  flyway-2-pipeline/          flyway-2-grants/         │                │
│  ├─ config/ (local)          ├─ config/ (local)       │                │
│  └─ read-only-flyway-files/  └─ read-only-flyway-files/│                │
│     ├─ sql/ ◄────────────────────┬─ sql/ ◄─────────────┘                │
│     ├─ callbacks/               ├─ callbacks/                           │
│     ├─ global_config/           ├─ global_config/                       │
│     ├─ scripts/                 ├─ scripts/                             │
│     └─ yaml/                    └─ yaml/                                │
└───────────────────────────────────────────────────────────────────────────┘
```

## ⚡ Sync Trigger Flow

```
Developer Action               GitHub Actions Response
─────────────────             ─────────────────────────

1️⃣  git push origin main     ┌─► 🤖 auto-sync.yml triggers
   (changes in read-write-    │
    flyway-files/)            │
                              │
2️⃣  Pull Request created     ├─► 🔍 PR validation runs
   to main branch            │   ├─ SQL syntax check
                              │   ├─ Naming conventions  
                              │   └─ Sync script test
                              │
3️⃣  PR approved & merged     ├─► 🚀 production-release.yml
                              │   ├─ Manual approval gate
                              │   ├─ Sync to all 4 repos
                              │   └─ Generate release report
                              │
4️⃣  Every 6 hours           └─► 📊 sync-status.yml
   (automated)                   ├─ Check repo sync health
                                 ├─ Create issues if drift
                                 └─ Auto-close when fixed
```

## 🎯 Repository Purposes

| Repository | Purpose | Database Role |
|------------|---------|---------------|
| `shared-flyway-ddl` | **Master Control** | Schema definitions, shared migrations |
| `flyway-1-pipeline` | **Cluster-1 Core** | Main database changes for cluster 1 |
| `flyway-1-grants` | **Cluster-1 Security** | Permissions, roles, grants for cluster 1 |
| `flyway-2-pipeline` | **Cluster-2 Core** | Main database changes for cluster 2 |
| `flyway-2-grants` | **Cluster-2 Security** | Permissions, roles, grants for cluster 2 |

## 🔧 Sync Technology Stack

```
┌─ Git Subtree Technology ─────────────────────────┐
│  ├─ Maintains independent git history            │
│  ├─ Allows bidirectional sync if needed          │
│  └─ Clean separation of shared vs local content  │
└───────────────────────────────────────────────────┘
           │
           ▼
┌─ GitHub Actions Automation ──────────────────────┐
│  ├─ Webhook-triggered on file changes            │
│  ├─ Pull Request validation workflow             │
│  ├─ Production deployment with approvals         │
│  └─ Health monitoring & drift detection          │
└───────────────────────────────────────────────────┘
           │
           ▼
┌─ Script Orchestration ───────────────────────────┐
│  ├─ unified_flyway_sync.sh                       │
│  ├─ Status checking & reporting                  │
│  ├─ Emergency nuclear reset capability           │
│  └─ Detailed logging & error handling            │
└───────────────────────────────────────────────────┘
```

## 🚀 Quick Reference

**Add new migration**: Edit `shared-flyway-ddl/read-write-flyway-files/sql/`  
**Check sync status**: `./repo-tools/unified_flyway_sync.sh status`  
**Manual sync**: `./repo-tools/unified_flyway_sync.sh sync --auto-commit`  
**Emergency reset**: `./repo-tools/unified_flyway_sync.sh nuclear --force-nuclear`

---
*This architecture ensures consistent database schema management across multiple clusters while maintaining separation of concerns between pipeline changes and security grants.*