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
   1. `./validate_children_ro_shared.sh --fix --autocommit` from parent repo
   2. then `shared/sh/multi-git-push.sh --msg "chore: sync shared + children" --pull-first --include-parent` to push all
  