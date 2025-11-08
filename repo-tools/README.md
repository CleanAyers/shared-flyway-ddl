# Distributed Flyway Synchronization Scripts

This directory contains three powerful scripts that manage the distributed Flyway architecture, handling synchronization between the parent repository (`shared-flyway-ddl`) and all child repositories (`flyway-X-pipeline`, `flyway-X-grants`).

## 📋 Overview

The distributed Flyway system uses **Git subtrees** to share common content from the parent repository to all child repositories. These scripts automate the complex Git operations required to keep everything synchronized.

### Architecture Summary
```
Parent Repo (shared-flyway-ddl)
├── read-wrte-flyway-files/     ← Edit shared content here
└── ro-shared-ddl               ← Delivery branch (auto-generated)
    
Child Repos (flyway-X-pipeline, flyway-X-grants)  
└── read-only-flyway-files/     ← Synced content (DO NOT EDIT)
```

---

## 🛠️ Scripts Overview

| Script | Purpose | When to Use | Safety Level |
|--------|---------|-------------|--------------|
| `parent_publish_shared.sh` | Export parent content to delivery branch | After editing shared content | Safe |
| `parentPusher.sh` | Sync children with parent changes | Regular sync operations | Safe |
| `justWork.sh` | Nuclear reset all children | When Git gets confused | ⚠️ Destructive |

---

## 1. 📤 `parent_publish_shared.sh`

**Purpose**: Exports the `read-wrte-flyway-files/` folder from the parent repository to the `ro-shared-ddl` delivery branch.

### When to Use
- After making changes to shared content in the parent repository
- Before syncing children (required first step)
- When preparing a new release of shared content

### Usage
```bash
# Run from parent repository root (shared-flyway-ddl)
cd shared-flyway-ddl
./tools/parent_publish_shared.sh
```

### What It Does
1. **Validates** that `read-wrte-flyway-files/` has tracked content
2. **Exports** the folder using `git subtree split`
3. **Creates/updates** the `ro-shared-ddl` branch
4. **Pushes** the delivery branch to GitHub
5. **Fallback**: Uses orphan branch rebuild if subtree split fails

### Example Output
```
== Parent: publish read-wrte-flyway-files/ → ro-shared-ddl from main ==
Already on 'main'
Added dir 'read-wrte-flyway-files'
== Done: pushed ro-shared-ddl ==
```

### Safety Notes
- ✅ **Safe**: Only affects the delivery branch
- ✅ **Non-destructive**: Won't affect your main branch or child repos
- ⚠️ **Force pushes** to `ro-shared-ddl` branch (expected behavior)

---

## 2. 🔄 `parentPusher.sh` (validate_children_ro_shared.sh)

**Purpose**: Synchronizes all child repositories with the latest shared content from the parent's delivery branch.

### When to Use
- After running `parent_publish_shared.sh`
- Regular maintenance to ensure children are up-to-date
- Before making child-specific changes (to start with latest shared content)

### Usage Options
```bash
# Check sync status (read-only)
./tools/parentPusher.sh

# Fix any out-of-sync children
./tools/parentPusher.sh --fix

# Fix and automatically commit any dirty working trees
./tools/parentPusher.sh --fix --auto-commit

# Custom options
./tools/parentPusher.sh --fix --auto-commit \
  --base "/custom/path" \
  --child-branch develop \
  --parent-branch ro-shared-ddl
```

### Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `--fix` | Actually perform sync operations | Check-only mode |
| `--auto-commit` | Auto-commit dirty working trees | Fail on dirty repos |
| `--auto-stash` | Auto-stash dirty working trees | Fail on dirty repos |
| `--base PATH` | Custom children repository location | Parent's parent dir |
| `--child-branch BRANCH` | Target branch in children | `main` |
| `--parent-branch BRANCH` | Source branch in parent | `ro-shared-ddl` |

### What It Does
1. **Discovers** all child repositories (flyway-*-pipeline, flyway-*-grants)
2. **Clones** missing repositories from GitHub
3. **Handles** dirty working trees (commit/stash/fail based on options)
4. **Compares** Git tree hashes between parent and children
5. **Syncs** out-of-date children using `git subtree pull/add`
6. **Pushes** changes to each child's GitHub repository

### Example Output
```
Parent: /Users/joshx86/.../shared-flyway-ddl
Children base: /Users/joshx86/.../Flyway-Repo-Structure
Delivery branch: ro-shared-ddl

-- flyway-1-pipeline
  OK: up to date (tree 72e855a5...)

-- flyway-1-grants  
  OUT-OF-DATE: child=635594f... parent=72e855a5...
  Subtree pull → read-only-flyway-files/
  FIXED: now up to date (tree 72e855a5...)

✅ All children match the parent delivery branch.
```

### Safety Notes
- ✅ **Safe**: Validates before making changes
- ✅ **Atomic**: Either fully succeeds or fails cleanly
- ⚠️ **Requires clean repos**: Use `--auto-commit` or manually commit first
- 🔒 **Uses tree hashes**: Ensures exact synchronization

---

## 3. ☢️ `justWork.sh` (Nuclear Option)

**Purpose**: Forces a complete reset and resynchronization of all child repositories when normal sync operations fail.

### ⚠️ **DANGER: DESTRUCTIVE OPERATION**

This script will **OVERWRITE** any local changes in `read-only-flyway-files/` folders across all children.

### When to Use (Last Resort Only)
- Git subtree operations are failing repeatedly
- Child repositories have corrupted subtree history
- Folder structure changes (like the recent name change)
- After major refactoring of shared content

### Usage
```bash
# Interactive confirmation required
cd shared-flyway-ddl
./tools/justWork.sh

# Confirmation prompt
🚨 NUCLEAR SUBTREE SYNC
This will FORCE sync all read-only-flyway-files folders from the parent repository.
Any local changes in read-only-flyway-files will be OVERWRITTEN!

Are you absolutely sure you want to proceed? (type 'NN' to confirm): NN
```

### What It Does
1. **Confirms** destructive operation with user
2. **Stashes** any uncommitted changes in children
3. **Removes** existing `read-only-flyway-files/` folders completely
4. **Cleans** Git subtree configuration and history
5. **Adds** fresh subtrees from parent delivery branch
6. **Pushes** all changes to GitHub
7. **Verifies** sync by comparing directories
8. **Reinstalls** Git hooks in all children

### Example Output
```
-- flyway-1-pipeline
  NUKE: Removing existing read-only-flyway-files folder...
  ADD: Adding fresh read-only-flyway-files subtree...
  ✓ Successfully synced subtree
  ✓ Successfully pushed

🎉 All repositories successfully synced!
✓ PERFECT SYNC: Directories are identical
🪝 Git hooks installed
```

### Safety Notes
- ⚠️ **DESTRUCTIVE**: Removes all local changes in shared folders
- 🔒 **Stashes changes**: Uncommitted work is preserved in Git stash
- ✅ **Verification**: Compares final state with parent
- 🪝 **Reinstalls hooks**: Restores Git protection hooks

---

## 🚀 Common Workflows

### Daily Development Workflow
```bash
# 1. Make changes to shared content in parent
cd shared-flyway-ddl
# Edit files in read-wrte-flyway-files/

# 2. Publish changes
./tools/parent_publish_shared.sh

# 3. Sync all children
./tools/parentPusher.sh --fix --auto-commit
```

### Emergency Recovery Workflow
```bash
# When normal sync fails
cd shared-flyway-ddl

# Try nuclear option
./tools/justWork.sh
# Type 'NN' to confirm

# Verify everything is working
./tools/parentPusher.sh
```

### New Team Member Setup
```bash
# Clone parent repository
git clone https://github.com/CleanAyers/shared-flyway-ddl.git
cd shared-flyway-ddl

# Auto-clone and sync all children
./tools/parentPusher.sh --fix --auto-commit
```

---

## 🎯 Best Practices

### Do's ✅
- **Always run `parent_publish_shared.sh` first** before syncing children
- **Use `--auto-commit`** for routine operations to handle dirty repos
- **Verify sync status** by running without `--fix` first
- **Check for errors** in script output before proceeding
- **Make shared changes in parent only** (`read-wrte-flyway-files/`)

### Don'ts ❌
- **Never edit `read-only-flyway-files/`** directly in children
- **Don't force push** to child repository main branches manually  
- **Don't run scripts from wrong directory** (must be in parent root)
- **Don't ignore dirty working tree warnings** without understanding them
- **Avoid nuclear option** unless normal sync consistently fails

### Troubleshooting

| Problem | Solution |
|---------|----------|
| "Working tree dirty" errors | Use `--auto-commit` or manually commit |
| "Subtree split failed" | Normal, script uses fallback method |
| "Cannot find child repo" | Check repository names and GitHub access |
| Git subtree consistently failing | Use nuclear option (`justWork.sh`) |
| Permission denied | Run `chmod +x tools/*.sh` |

---

## 📊 File Structure Context

```
shared-flyway-ddl/
├── read-wrte-flyway-files/         # ✅ EDIT HERE
│   ├── callbacks/                  # Flyway lifecycle callbacks
│   ├── global_config/             # Shared configuration templates
│   ├── hooks/                     # Git protection hooks
│   ├── sh/                        # Shared shell scripts
│   └── sql/                       # Shared SQL migrations
└── tools/                         # 🛠️ SYNC SCRIPTS
    ├── parent_publish_shared.sh    # Export to delivery branch
    ├── parentPusher.sh            # Sync all children
    └── justWork.sh               # Nuclear reset option
```

The scripts maintain this distributed architecture automatically, ensuring that all child repositories stay in perfect sync with the parent's shared content while preserving their individual configurations and customizations.

---

**Remember**: These scripts handle complex Git subtree operations automatically. When in doubt, start with the read-only check (`./tools/parentPusher.sh`) to understand the current state before making changes.