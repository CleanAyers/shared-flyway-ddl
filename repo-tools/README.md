# Unified Flyway Sync Script

A single, powerful script that manages the entire distributed Flyway architecture by handling synchronization between the parent repository (`shared-flyway-ddl`) and all child repositories (`flyway-X-pipeline`, `flyway-X-grants`).

## 🎯 What This Script Does

This unified script **replaces three separate tools** and provides a single interface for:
- **Publishing** shared content from parent to delivery branch
- **Syncing** all child repositories with latest parent changes
- **Nuclear reset** when Git subtrees get corrupted
- **Status checking** to verify synchronization state

## 📋 Script Location & Setup

```bash
# Location
/Users/joshx86/Documents/Codex/Work/Flyway-Repo-Structure/shared-flyway-ddl/repo-tools/unified_flyway_sync.sh

# Make executable (if needed)
chmod +x repo-tools/unified_flyway_sync.sh

# Always run from parent repository root
cd shared-flyway-ddl
```

---

## 🛠️ Operations

The script supports five main operations:

| Operation | Purpose | Safety Level | Use Case |
|-----------|---------|--------------|----------|
| `status` | Check sync status (read-only) | ✅ Safe | Daily monitoring |
| `publish` | Export parent content to delivery branch | ✅ Safe | After making shared changes |
| `sync` | Sync all children with parent | ✅ Safe | Regular maintenance |
| `full` | Complete workflow: publish → sync | ✅ Safe | **Most common usage** |
| `nuclear` | Force reset all children | ⚠️ **Destructive** | Emergency recovery |

---

## 🚀 Command Reference

### Basic Usage Pattern
```bash
./repo-tools/unified_flyway_sync.sh [OPERATION] [OPTIONS]
```

### 1. 📊 Status Check (Read-Only)
**Check if all repositories are synchronized:**
```bash
./repo-tools/unified_flyway_sync.sh status
```

**Example output:**
```
📊 STATUS CHECK
Parent tree: 72e855a5d45a...

-- flyway-1-pipeline
  ✓ SYNCED (tree 72e855a5d45a...)
-- flyway-1-grants
  ✗ OUT-OF-DATE (child: a1b2c3... parent: 72e855a5...)

⚠️  SYNC REQUIRED
Run: ./unified_flyway_sync.sh sync --auto-commit
```

### 2. 📤 Publish Parent Content
**Export shared content to delivery branch:**
```bash
./repo-tools/unified_flyway_sync.sh publish
```

**What it does:**
- Validates `read-write-flyway-files/` has content
- Exports folder to `ro-shared-ddl` delivery branch
- Pushes to GitHub for children to consume

### 3. 🔄 Sync All Children
**Synchronize all child repositories:**
```bash
# Basic sync (fails on dirty repos)
./repo-tools/unified_flyway_sync.sh sync

# Auto-commit dirty repos before syncing
./repo-tools/unified_flyway_sync.sh sync --auto-commit

# Auto-stash dirty repos before syncing  
./repo-tools/unified_flyway_sync.sh sync --auto-stash
```

### 4. 🎯 Full Workflow (Most Common)
**Complete publish + sync in one command:**
```bash
# Most common usage - handles everything
./repo-tools/unified_flyway_sync.sh full --auto-commit
```

**What it does:**
1. Publishes parent `read-write-flyway-files/` → `ro-shared-ddl` branch
2. Syncs all 4 child repositories with the published content
3. Auto-commits any dirty working trees in children
4. Pushes all changes to GitHub

### 5. ☢️ Nuclear Reset (Emergency Only)
**Force reset when Git subtrees are corrupted:**
```bash
# Interactive confirmation required
./repo-tools/unified_flyway_sync.sh nuclear

# Skip confirmation (dangerous!)
./repo-tools/unified_flyway_sync.sh nuclear --force-nuclear
```

⚠️ **WARNING**: This operation is **DESTRUCTIVE** and will:
- Remove all existing `read-only-flyway-files/` folders
- Stash any uncommitted changes
- Add fresh subtrees from parent
- **Overwrite any local modifications** in shared folders

---

## ⚙️ Command Line Options

### General Options
| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `--help` | Show help and usage | - | `./script.sh --help` |
| `--child-branch BRANCH` | Target branch in children | `main` | `--child-branch develop` |

### Dirty Working Tree Handling
| Option | Description | Use When |
|--------|-------------|----------|
| `--auto-commit` | Auto-commit dirty repos before sync | **Recommended** for routine operations |
| `--auto-stash` | Auto-stash dirty repos before sync | When you want to preserve uncommitted work |
| _(none)_ | Fail if repos are dirty | When you want explicit control |

**⚠️ Note**: `--auto-commit` and `--auto-stash` are mutually exclusive.

### Nuclear Options
| Option | Description | Use Case |
|--------|-------------|----------|
| `--force-nuclear` | Skip interactive confirmation | Automation scripts |

---

## 🔄 Daily Workflows

### Standard Development Workflow
```bash
# 1. Make changes to shared content
cd shared-flyway-ddl
# Edit files in read-write-flyway-files/

# 2. Publish and sync everything (one command)
./repo-tools/unified_flyway_sync.sh full --auto-commit

# 3. Verify sync completed
./repo-tools/unified_flyway_sync.sh status
```

### Quick Status Check Workflow
```bash
# Check if everything is in sync
./repo-tools/unified_flyway_sync.sh status

# If out of sync, fix it
./repo-tools/unified_flyway_sync.sh sync --auto-commit
```

### Emergency Recovery Workflow
```bash
# When Git subtrees are corrupted
./repo-tools/unified_flyway_sync.sh nuclear
# Type 'NUKE' to confirm

# Verify nuclear reset worked
./repo-tools/unified_flyway_sync.sh status
```

### New Team Member Setup
```bash
# Clone parent repository
git clone https://github.com/CleanAyers/shared-flyway-ddl.git
cd shared-flyway-ddl

# Auto-clone and sync all children
./repo-tools/unified_flyway_sync.sh sync --auto-commit
```

---

## 📁 Architecture Overview

The script manages this folder structure:

```
Parent Repository (shared-flyway-ddl):
├── read-write-flyway-files/        # ✅ EDIT HERE
│   ├── callbacks/                  # Flyway lifecycle callbacks
│   ├── global_config/             # Shared configuration templates  
│   ├── hooks/                     # Git protection hooks
│   ├── scripts/                   # Shared automation scripts
│   ├── sh/                        # Shell utilities
│   └── sql/                       # Shared SQL migrations
└── ro-shared-ddl                  # 🤖 AUTO-GENERATED delivery branch

Child Repositories (flyway-X-pipeline, flyway-X-grants):
└── read-only-flyway-files/        # 🚫 DO NOT EDIT - Synced content
    ├── callbacks/                  # (Same structure as parent)
    ├── global_config/             
    ├── hooks/                     
    ├── scripts/                   
    ├── sh/                        
    └── sql/                       
```

---

## 🔍 Understanding Script Output

### Status Check Output
```bash
📊 STATUS CHECK
Parent tree: 72e855a5d45a3bcd0cf490e0e2dc32c729fdbf6b

-- flyway-1-pipeline
  ✓ SYNCED (tree 72e855a5d45a...)     # In sync
-- flyway-1-grants  
  ✗ OUT-OF-DATE (child: a1b2c3... parent: 72e855a5...)  # Needs sync
-- flyway-2-pipeline
  ⚠️  NO SUBTREE (read-only-flyway-files missing)        # Needs initial setup
-- flyway-2-grants
  📁 MISSING (Repository not cloned)                      # Needs cloning
```

### Sync Operation Output
```bash
🔄 SYNCING CHILDREN
Parent tree: 72e855a5d45a...

-- flyway-1-pipeline
  🔄 AUTO-COMMIT: Committing changes...
  🔄 PULL: Updating existing subtree
  ✓ SYNCED: now up to date (tree 72e855a5...)
```

### Nuclear Reset Output
```bash
☢️ NUCLEAR RESET

-- flyway-1-pipeline
  📦 STASH: Preserving uncommitted changes
  💥 NUKE: Removing read-only-flyway-files
  ✅ ADD: Fresh subtree from parent
  ✓ Nuclear reset successful
```

---

## 🔧 Child Repository Settings

All child repositories must have specific GitHub Actions settings configured to work with the automated sync system. Each child repo should have these settings at:

- `https://github.com/CleanAyers/flyway-1-pipeline/settings/actions`
- `https://github.com/CleanAyers/flyway-1-grants/settings/actions`
- `https://github.com/CleanAyers/flyway-2-pipeline/settings/actions`
- `https://github.com/CleanAyers/flyway-2-grants/settings/actions`

### Required Settings

#### Fork Pull Request Workflows
- ✅ **Run workflows from fork pull requests** - Enabled
- ✅ **Send write tokens to workflows from fork pull requests** - Enabled
- ⬜ **Send secrets and variables to workflows from fork pull requests** - Disabled
- ⬜ **Require approval for fork pull request workflows** - Disabled

#### Workflow Permissions
- 🔘 **Read and write permissions** - Selected
- ⬜ **Read repository contents and packages permissions** - Not selected
- ✅ **Allow GitHub Actions to create and approve pull requests** - Enabled

#### Access
- 🔘 **Accessible from repositories owned by the user 'CleanAyers'** - Selected

### Verifying Settings via GitHub CLI

You can verify these settings using the GitHub CLI:

```bash
# Check workflow permissions for all child repos
for repo in flyway-1-pipeline flyway-1-grants flyway-2-pipeline flyway-2-grants; do
    echo "=== $repo ==="
    gh api repos/CleanAyers/$repo --jq '.permissions.actions'
    gh api repos/CleanAyers/$repo/actions/permissions --jq '.'
    echo
done

# Check specific workflow permissions
gh api repos/CleanAyers/flyway-1-pipeline/actions/permissions

# List all repository settings (requires admin access)
gh api repos/CleanAyers/flyway-1-pipeline --jq '{
    name: .name,
    private: .private,
    permissions: .permissions,
    default_branch: .default_branch
}'
```

### Batch Verification Script

Create a quick verification script:

```bash
#!/bin/bash
# verify-child-repo-settings.sh

REPOS=("flyway-1-pipeline" "flyway-1-grants" "flyway-2-pipeline" "flyway-2-grants")

for repo in "${REPOS[@]}"; do
    echo "🔍 Checking $repo..."
    
    # Check if repo exists and is accessible
    if gh repo view CleanAyers/$repo >/dev/null 2>&1; then
        echo "  ✅ Repository accessible"
        
        # Check workflow permissions
        PERMISSIONS=$(gh api repos/CleanAyers/$repo/actions/permissions --jq '.enabled')
        if [ "$PERMISSIONS" = "true" ]; then
            echo "  ✅ Actions enabled"
        else
            echo "  ❌ Actions disabled"
        fi
        
        # Check default workflow permissions
        DEFAULT_PERMS=$(gh api repos/CleanAyers/$repo/actions/permissions/selected-actions --jq '.default_workflow_permissions' 2>/dev/null || echo "read")
        echo "  📋 Default permissions: $DEFAULT_PERMS"
        
    else
        echo "  ❌ Repository not accessible"
    fi
    echo
done
```

---

## 🚨 Troubleshooting Settings

---

## ❌ Troubleshooting

### Common Issues & Solutions

| Problem | Cause | Solution |
|---------|-------|----------|
| `"Working tree dirty"` | Uncommitted changes | Use `--auto-commit` or `--auto-stash` |
| `"Delivery branch not found"` | Parent content not published | Run `./script.sh publish` first |
| `"Cannot switch to branch"` | Branch doesn't exist | Check `--child-branch` option |
| `"Failed to clone repository"` | GitHub access issues | Check GitHub CLI (`gh auth status`) |
| `"Subtree split failed"` | Normal fallback behavior | Script automatically uses orphan rebuild |
| Git subtrees consistently failing | Corrupted subtree history | Use `./script.sh nuclear` |

### Error Exit Codes
- `0` - Success
- `1` - Validation errors, sync failures
- `2` - Invalid command line arguments

### Debug Tips
1. **Always start with status check**: `./script.sh status`
2. **Check Git remotes**: Ensure GitHub access is working
3. **Verify parent content**: Ensure `read-write-flyway-files/` has content
4. **Use `--auto-commit`**: Handles most common dirty tree issues
5. **Nuclear option**: Last resort for corrupted Git state

---

## 🎯 Best Practices

### Do's ✅
- **Use `full --auto-commit`** for routine development workflows
- **Run `status`** before making changes to understand current state
- **Always edit in parent** (`read-write-flyway-files/`) never in children
- **Test in non-production repos first** when learning the tool
- **Keep the script in `repo-tools/`** for consistency

### Don'ts ❌
- **Never edit `read-only-flyway-files/`** directly in child repositories
- **Don't ignore dirty working tree warnings** without understanding impact
- **Don't use nuclear option** unless normal sync consistently fails
- **Don't run from wrong directory** - must be in parent repository root
- **Don't mix `--auto-commit` and `--auto-stash`** in same command

---

## 🔐 Security Notes

- The script uses **GitHub CLI** for repository access
- **Force pushes** to `ro-shared-ddl` branch (expected behavior)  
- **Nuclear option stashes** uncommitted work (doesn't delete)
- **No credentials** are stored in the script
- All operations are **logged** and **reversible** through Git history

---

**💡 Quick Start**: For most use cases, simply run:
```bash
./repo-tools/unified_flyway_sync.sh full --auto-commit
```

This single command handles the complete workflow of publishing your shared changes and syncing all child repositories automatically.