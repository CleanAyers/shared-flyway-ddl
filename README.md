# 🛠️ shared-flyway-ddl

## Overview
This repository serves as the **centralized source of truth** for all Flyway-managed  
database schema and access-control migrations across clusters.  

It provides shared DDL templates, baseline schemas, and orchestration scripts  
that ensure consistency and governance across all cluster-specific Flyway repositories.

**Purpose:**  
- Maintain a **unified Flyway DDL architecture**  
- Provide **shared templates** for schema and grant scripts  
- Support **distributed pipelines** across clusters (Aurora, ECS, etc.)  
- Enforce **standard naming conventions and deployment order**

---

## 🧩 Architecture Overview
```
Flyway-Repo-Structure/
├── shared-flyway-ddl/                    # 🏗️ Parent repository (this repo)
│   ├── shared/                           # Source files for distribution
│   │   ├── sql/
│   │   │   └── V1__test.sql
│   │   └── sh/
│   │       └── child_pull_shared.sh
│   ├── parent_publish_shared.sh          # Push shared/ → ro-shared-ddl branch
│   ├── validate_children_ro_shared.sh    # Validate children are in sync
│   └── README.md
│
├── flyway-1-pipeline/                    # 🏗️ Cluster 1 schema migrations
│   ├── ro-shared-ddl/                    # Synced from parent
│   │   ├── sql/
│   │   │   └── V1__test.sql
│   │   └── sh/
│   │       └── child_pull_shared.sh
│   └── README.md
│
├── flyway-1-grants/                      # 🔐 Cluster 1 access control
│   ├── ro-shared-ddl/                    # Synced from parent
│   │   ├── sql/
│   │   │   └── V1__test.sql
│   │   └── sh/
│   │       └── child_pull_shared.sh
│   └── README.md
│
├── flyway-2-pipeline/                    # 🏗️ Cluster 2 schema migrations
│   ├── ro-shared-ddl/                    # Synced from parent
│   │   ├── sql/
│   │   │   └── V1__test.sql
│   │   └── sh/
│   │       └── child_pull_shared.sh
│   └── README.md
│
├── flyway-2-grants/                      # 🔐 Cluster 2 access control
│   ├── ro-shared-ddl/                    # Synced from parent
│   │   ├── sql/
│   │   │   └── V1__test.sql
│   │   └── sh/
│   │       └── child_pull_shared.sh
│   └── README.md
│
├── sync_all_children.sh                  # Bulk sync all children
└── parent-to-child.md                    # Quick workflow guide
```

### Repository Roles
| Type | Description |
|------|--------------|
| **Pipeline** | Handles schema-level DDL (versioned `V__` scripts) |
| **Grants** | Handles roles and permissions (repeatable `R__` scripts) |
| **Shared DDL** | Provides templates and baselines reused by all clusters |

---

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
   1. or run ./validate_children_ro_shared.sh --fix from parent
  