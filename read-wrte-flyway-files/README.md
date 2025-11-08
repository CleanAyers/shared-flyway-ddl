# shared/ folder
- Do *not* edit unless you are on the parent directory (shared-flyway-ddl)

## Overview
This folder serves as the **centralized source of shared truth** 

It provides shared DDL templates, baseline schemas, and orchestration scripts  
that ensure consistency and governance across all cluster-specific Flyway repositories.

**Purpose:**  
- Maintain a **unified Flyway DDL architecture**  
- Provide **shared templates** for schema and grant scripts  
- Support **distributed pipelines** across clusters (Aurora, ECS, etc.)  
- Enforce **standard naming conventions and deployment order**

## 🔄 How Parent-to-Child Synchronization Works

### The Architecture
```
Parent Repo (shared-flyway-ddl)
├── shared/                    ← Source of truth (you edit here)
│   ├── sql/V1__test.sql
│   └── sh/child_pull_shared.sh
│
└── ro-shared-ddl branch       ← Generated from shared/ folder
    ├── sql/V1__test.sql       ← Identical to shared/sql/
    └── sh/child_pull_shared.sh ← Identical to shared/sh/

Child Repos (flyway-1-pipeline, flyway-1-grants, etc.)
└── ro-shared-ddl/             ← Synced from parent's ro-shared-ddl branch
    ├── sql/V1__test.sql       ← Pulled from parent
    └── sh/child_pull_shared.sh ← Pulled from parent
```

### Step-by-Step Breakdown

#### Step 1: Edit Files in Parent's `shared/` Directory
**What happens:** You make changes to files in `shared-flyway-ddl/shared/`
**Files affected:** Any files you create/modify in the `shared/` folder
**Why:** This is the single source of truth for all shared code

#### Step 2: Commit Changes in Parent
```bash
git add -A && git commit -m "..." && git push
```
**What happens:** Normal Git commit to the `main` branch of parent repo
**Files affected:** Only files in `shared/` directory are committed to main branch
**Why:** We need the changes saved before we can export them

#### Step 3: Parent Export - `git pubshared`
```bash
git config alias.pubshared '!f(){ git switch main && git pull --ff-only && \
  (git subtree split --prefix=shared --branch ro-shared-ddl main || \
   (git checkout --orphan ro-shared-ddl && git rm -rf . && git checkout main -- shared && rsync -a shared/ ./ && git rm -r shared && git add -A && git commit -m "build: export shared/ for delivery" && git switch -)); \
  git push -u origin ro-shared-ddl --force; }; f'
```

**What this does in detail:**
1. **`git switch main && git pull --ff-only`** - Ensure we're on latest main
2. **`git subtree split --prefix=shared --branch ro-shared-ddl main`** - Creates a new branch `ro-shared-ddl` containing ONLY the contents of the `shared/` folder
   - This transforms: `shared/sql/V1__test.sql` → becomes root-level: `sql/V1__test.sql` 
   - The `shared/` prefix is removed in the new branch
3. **Fallback logic** (if subtree split fails) - Creates orphan branch and manually copies files
4. **`git push -u origin ro-shared-ddl --force`** - Pushes the ro-shared-ddl branch to remote

**Result:** The parent repo now has a `ro-shared-ddl` branch where the root contains exactly what was in `shared/`

#### Step 4: Child Sync - `git syncshared` (Manual Method)
```bash
git config alias.syncshared '!git fetch parent-shared ro-shared-ddl && git subtree pull --prefix=ro-shared-ddl parent-shared ro-shared-ddl --squash && git add -A && git commit -m "chore(shared): sync ro-shared-ddl" || true && git push'
```

**What this does:**
1. **`git fetch parent-shared ro-shared-ddl`** - Fetches the latest ro-shared-ddl branch from parent
2. **`git subtree pull --prefix=ro-shared-ddl parent-shared ro-shared-ddl --squash`** - Pulls the parent's ro-shared-ddl branch into the child's `ro-shared-ddl/` folder
   - Maps: parent's root `sql/V1__test.sql` → child's `ro-shared-ddl/sql/V1__test.sql`
3. **Commits and pushes** the changes

#### Step 4 (Alternative): Automated Method
```bash
./validate_children_ro_shared.sh --fix --auto-commit
```
**What this does:** Automatically performs step 4 for ALL child repositories at once

### 🎯 What Files Get Synchronized

**Source (Parent):** `shared-flyway-ddl/shared/`
```
shared/
├── sql/
│   ├── V1__test.sql           ← This file gets synced
│   ├── V2__users.sql          ← This file gets synced
│   └── baseline/
│       └── V001__init.sql     ← This file gets synced
└── sh/
    └── child_pull_shared.sh   ← This file gets synced
```

**Destination (Each Child):** `flyway-X-Y/ro-shared-ddl/`
```
ro-shared-ddl/                 ← Folder created by git subtree
├── sql/
│   ├── V1__test.sql          ← Identical copy from parent
│   ├── V2__users.sql         ← Identical copy from parent
│   └── baseline/
│       └── V001__init.sql    ← Identical copy from parent
└── sh/
    └── child_pull_shared.sh  ← Identical copy from parent
```

### 🔧 Why This Works

1. **Git Subtree** creates a true copy of files, not just references
2. **Squash merges** keep child history clean
3. **Branch isolation** keeps shared code separate from child-specific code
4. **Atomic updates** ensure all files sync together
5. **Version tracking** via Git tree hashes ensures exact synchronization

### 🚨 Critical Rules

1. **NEVER** edit files in any `ro-shared-ddl/` folder directly
2. **ALWAYS** make changes in the parent's `shared/` folder first
3. **ALWAYS** run parent export before child sync
4. **NEVER** commit directly to the `ro-shared-ddl` branch

This system ensures that all shared Flyway migrations, scripts, and templates remain perfectly synchronized across all cluster repositories while maintaining clear ownership and change management.

### Using Git Aliases

I applied this to the parent repo
```bash
git config alias.pubshared '!f(){ git switch main && git pull --ff-only && \
  (git subtree split --prefix=shared --branch ro-shared-ddl main || \
   (git checkout --orphan ro-shared-ddl && git rm -rf . && git checkout main -- shared && rsync -a shared/ ./ && git rm -r shared && git add -A && git commit -m "build: export shared/ for delivery" && git switch -)); \
  git push -u origin ro-shared-ddl --force; }; f'
```

I applied this in every child repo
```bash
git config alias.syncshared '!git fetch parent-shared ro-shared-ddl && git subtree pull --prefix=ro-shared-ddl parent-shared ro-shared-ddl --squash && git add -A && git commit -m "chore(shared): sync ro-shared-ddl" || true && git push'

```

### Usage 
- Parent Update = `git pubshared`
- Child Update = `git syncshared`

## Repository Cadence:
1. Changes are made in the `shared/` directory to be applied downward
2. `git add -A && git commit -m "..." && git push`
3. In parent: `git pubshared`
4. In each child: `git syncshared`
   1. `./validate_children_ro_shared.sh --fix --auto-commit` from parent repo
   2. then `shared/sh/multi-git-push.sh --msg "chore: sync shared + children" --pull-first --include-parent` to push all
