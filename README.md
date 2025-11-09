## Overview
This folder serves as the **centralized source of shared truth** 

It provides shared DDL templates, baseline schemas, and orchestration scripts  
that ensure consistency and governance across all cluster-specific Flyway repositories.

**Purpose:**  
- Maintain a **unified Flyway DDL architecture**  
- Provide **shared templates** for schema and grant scripts  
- Support **distributed pipelines** across clusters (Aurora, ECS, etc.)  
- Enforce **standard naming conventions and deployment order**

## 🔄 How Automated Parent-to-Child Synchronization Works

### The Architecture
```
Parent Repo (shared-flyway-ddl)
├── read-write-flyway-files/       ← Source of truth (you edit here)
│   ├── sql/V1__test.sql
│   └── sh/sync_scripts.sh
│
└── ro-shared-ddl branch           ← Auto-generated delivery branch
    ├── sql/V1__test.sql           ← Identical to read-write-flyway-files/sql/
    └── sh/sync_scripts.sh         ← Identical to read-write-flyway-files/sh/

Child Repos (flyway-1-pipeline, flyway-1-grants, etc.)
└── read-only-flyway-files/        ← Auto-synced from parent's ro-shared-ddl branch
    ├── sql/V1__test.sql           ← Pulled from parent
    └── sh/sync_scripts.sh         ← Pulled from parent
```

### ✨ Automated Workflow (New!)

The synchronization is now **fully automated** via GitHub Actions:

#### Step 1: Edit Files in Parent's `read-write-flyway-files/` Directory
**What happens:** You make changes to files in `shared-flyway-ddl/read-write-flyway-files/`
**Files affected:** Any files you create/modify in the `read-write-flyway-files/` folder
**Why:** This is the single source of truth for all shared code

#### Step 2: Commit and Push Changes
```bash
git add -A && git commit -m "feat: add new callback" && git push
```
**What happens:** Normal Git push to the `main` branch
**Automation trigger:** GitHub Actions auto-sync pipeline activates
**Files affected:** Only files in `read-write-flyway-files/` directory

#### Step 3: Automatic Synchronization (No Manual Action Required!)
**GitHub Actions automatically:**
1. **Publishes** parent content to `ro-shared-ddl` delivery branch
2. **Syncs all 4 child repositories** with the new content
3. **Commits and pushes** changes to each child repo
4. **Verifies** sync completion across all repos
5. **Reports status** in the main README dashboard

### 🎯 What Files Get Synchronized

**Source (Parent):** `shared-flyway-ddl/read-write-flyway-files/`
```
read-write-flyway-files/
├── callbacks/
│   ├── afterMigrate.sql          ← Auto-synced to all children
│   ├── beforeClean.sql           ← Auto-synced to all children
│   └── ...
├── sql/
│   ├── V1__init.sql             ← Auto-synced to all children
│   ├── V2__users.sql            ← Auto-synced to all children
│   └── baseline/
│       └── V001__init.sql       ← Auto-synced to all children
├── global_config/               ← Auto-synced to all children
├── hooks/                       ← Auto-synced to all children
└── sh/                         ← Auto-synced to all children
```

**Destination (Each Child):** `flyway-X-Y/read-only-flyway-files/`
```
read-only-flyway-files/          ← Auto-created by GitHub Actions
├── callbacks/                   ← Identical copies from parent
├── sql/                        ← Identical copies from parent
├── global_config/              ← Identical copies from parent
├── hooks/                      ← Identical copies from parent
└── sh/                         ← Identical copies from parent
```

### 🚀 Automation Features

#### ✅ Automatic Triggers
- **Push to `main`** - Sync runs automatically on every push
- **File changes in `read-write-flyway-files/`** - Only triggers when shared content changes
- **Manual trigger** - Can be manually run from GitHub Actions

#### ✅ Smart Conflict Handling
- **Auto-commit dirty repos** - Handles uncommitted changes gracefully
- **Nuclear reset option** - Available for corrupted Git states
- **Status verification** - Ensures perfect sync after operations

#### ✅ Monitoring & Reporting
- **Real-time status dashboard** - See sync status in main README
- **Automated issue creation** - Creates GitHub issues on sync drift
- **Detailed reports** - Complete sync logs available as artifacts
- **Failure notifications** - Clear error messages and recovery steps

### 🎯 New Simplified Workflow

#### Daily Development (Automated!)
```bash
# 1. Make changes to shared content
# Edit files in read-write-flyway-files/

# 2. Commit and push (triggers automation)
git add -A 
git commit -m "feat: add new migration"
git push

# 3. GitHub Actions automatically:
#    - Publishes to delivery branch
#    - Syncs all 4 child repositories  
#    - Updates status dashboard
#    - Reports completion
```

#### Manual Operations (When Needed)
```bash
# Check current status
./repo-tools/unified_flyway_sync.sh status

# Manual full sync (if automation fails)
./repo-tools/unified_flyway_sync.sh full --auto-commit

# Emergency reset (last resort)
./repo-tools/unified_flyway_sync.sh nuclear
```

### 🔍 Monitoring Your Sync Status

Check the **Repository Sync Status** section in the main README to see:
- ✅ Real-time sync status for all 4 repositories
- 📊 Last commit timestamps
- 🔄 Pipeline execution status
- 📋 Links to detailed logs and reports

### 🚨 Legacy Manual Commands (Still Available)

The old Git aliases are still configured but **no longer needed** for daily use:

#### Legacy Parent Commands
```bash
# Old way (manual)
git pubshared  # Still works, but automated now

# New way (automatic) 
git push       # Triggers GitHub Actions auto-sync
```

#### Legacy Child Commands  
```bash
# Old way (manual, per child)
git syncshared  # Still works in each child repo

# New way (automatic)
# GitHub Actions syncs ALL children automatically
```

## 🎉 Benefits of Automation

- **🚀 Zero manual steps** - Just push to main branch
- **🔒 Guaranteed consistency** - All repos stay perfectly in sync
- **📊 Complete visibility** - Real-time status dashboard
- **🛡️ Error handling** - Automatic issue creation and resolution
- **⏰ Time savings** - No more manual sync commands
- **🔄 Reliable delivery** - GitHub Actions ensures sync completion

---

**💡 Quick Start**: For daily development, simply:
```bash
# Edit files in read-write-flyway-files/
git add -A && git commit -m "your changes" && git push
# GitHub Actions handles everything else automatically! 🎉
```
