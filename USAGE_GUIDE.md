# 🚀 Distributed Flyway Sync System - Usage Guide (PR-Based Workflow)

## Overview
This system automatically synchronizes shared Flyway files across multiple child repositories using Git subtree technology and a **pull request-based workflow** for safe, reviewed deployments.

## 📁 Repository Structure

### Parent Repository: `shared-flyway-ddl`
```
shared-flyway-ddl/
├── read-write-flyway-files/    ← Add your shared files here
│   ├── sql/                    ← Migration scripts (V1__.sql, V2__.sql, etc.)
│   ├── callbacks/              ← Flyway callback scripts 
│   ├── global_config/          ← Global configuration files
│   ├── scripts/                ← Custom utility scripts
│   └── yaml/                   ← YAML configuration files
└── repo-tools/
    └── unified_flyway_sync.sh  ← Main sync script
```

### Child Repositories: `flyway-[1-2]-[pipeline|grants]`
```
flyway-1-pipeline/
├── config/                     ← Local Flyway configuration
├── read-write-flyway-files/    ← Synced content (DO NOT EDIT MANUALLY)
│   ├── sql/                    ← Your shared migration scripts
│   ├── callbacks/              ← Your shared callback scripts
│   ├── global_config/          ← Your shared global config
│   ├── scripts/                ← Your shared utility scripts
│   └── yaml/                   ← Your shared YAML config
└── README.md                   ← Local documentation
```

## 🔄 **NEW: Pull Request Workflow**

### **For Adding New Files (Recommended Process):**

1. **Create a Feature Branch**:
   ```bash
   cd shared-flyway-ddl
   git checkout -b feature/add-v4-products-table
   ```

2. **Clean & Sync First** (Ensure clean starting point):
   ```bash
   ./repo-tools/unified_flyway_sync.sh sync --auto-commit
   ```

3. **Add Your Files** to the appropriate directory:
   ```bash
   # Example: Add a new migration
   nano read-write-flyway-files/sql/V4__create_products_table.sql
   
   # Example: Add a callback script
   nano read-write-flyway-files/callbacks/afterMigrate_log.sql
   ```

4. **Commit Your Changes**:
   ```bash
   git add read-write-flyway-files/
   git commit -m "feat: add V4 products table migration"
   git push origin feature/add-v4-products-table
   ```

5. **Create Pull Request**:
   ```bash
   # Via GitHub CLI (recommended)
   gh pr create --title "Add V4 products table migration" --body "Adds new products table with indexes and sample data"
   
   # Or via GitHub web interface
   ```

6. **Automated Validation Runs**:
   - ✅ SQL syntax validation
   - ✅ Migration naming convention checks  
   - ✅ Sync script dry-run testing
   - ✅ PR comment with validation report

7. **Code Review & Approval**:
   - Team reviews the SQL changes
   - At least 2 approvals required (when branch protection is enabled)
   - Merge conflicts resolved if needed

8. **Merge PR**:
   - Merge the pull request via GitHub interface
   - **Automatic sync triggers** upon merge
   - Production workflow distributes to all 4 child repositories

## 🛠️ Available Commands (Manual Operations)

### 1. Check Sync Status
```bash
cd shared-flyway-ddl
./repo-tools/unified_flyway_sync.sh status
```
**Use this to**: Verify which repositories are synchronized and which need updates.

### 2. Manual Sync (When Needed)
```bash
cd shared-flyway-ddl
./repo-tools/unified_flyway_sync.sh sync --auto-commit
```
**Use this to**: Manually sync repositories if automated workflow fails.

### 3. Manual Full Workflow (Emergency)
```bash
cd shared-flyway-ddl
./repo-tools/unified_flyway_sync.sh full --auto-commit
```
**Use this to**: Emergency manual distribution (bypasses PR workflow).

### 4. Emergency Reset (Advanced)
```bash
cd shared-flyway-ddl
./repo-tools/unified_flyway_sync.sh nuclear --force-nuclear
```
**Use this to**: Completely reset all child repositories (destructive operation).

## 🤖 **Automated Workflows**

### **1. PR Validation** (`.github/workflows/pr-validation.yml`)
**Triggers**: Every pull request to main
**Purpose**: 
- Validates SQL syntax and naming conventions
- Tests sync script functionality  
- Posts validation report as PR comment
- **Required to pass before merge**

### **2. Production Release** (`.github/workflows/production-release.yml`)
**Triggers**: When PR is merged to main
**Purpose**:
- Automatically syncs changes to all 4 child repositories
- Requires production environment approval
- Generates detailed release report

### **3. Sync Status Monitor** (`.github/workflows/sync-status.yml`)
**Triggers**: Every 6 hours + manual dispatch
**Purpose**:
- Monitors repository synchronization health
- Creates GitHub issues if drift detected
- Automatically closes issues when sync restored

## ⚠️ Important Rules

### ✅ DO:
- **Always use pull requests** for shared file changes
- Wait for PR validation to pass before requesting review
- Address any validation warnings or errors  
- Use descriptive commit messages and PR descriptions
- Run `sync --auto-commit` locally before creating PRs

### ❌ DON'T:
- Never push directly to main branch (will be blocked)
- Don't edit files in child repository `read-write-flyway-files/` directories
- Don't skip the PR workflow unless it's an emergency
- Don't ignore PR validation failures
- Don't delete the `read-write-flyway-files/` directories in child repos

## 🚨 Branch Protection (Coming Soon)

When branch protection is enabled:
- **No direct pushes to main** - All changes via PRs
- **Required reviews** - Minimum 2 approvals needed
- **Status checks** - PR validation must pass
- **Up-to-date branches** - Must be current with main before merge

## 🔍 Troubleshooting

### PR Validation Failures
**Problem**: PR validation workflow fails
**Solution**: 
- Check workflow logs for specific errors
- Fix SQL syntax or naming convention issues  
- Push fixes to the same PR branch

### Merge Conflicts in PR
**Problem**: Branch conflicts with main
**Solution**:
```bash
git checkout feature/your-branch
git merge main  # or git rebase main
# Resolve conflicts
git push origin feature/your-branch
```

### Production Sync Fails After Merge
**Problem**: Automatic sync fails after PR merge
**Solution**:
```bash
# Manual emergency sync
./repo-tools/unified_flyway_sync.sh sync --auto-commit
```

### Repository Drift Detected
**Problem**: Status monitor creates drift issues
**Solution**: Check the issue details and run manual sync if needed

## 🎯 Success Verification

After a PR is merged and production workflow completes:
```
✅ ALL REPOSITORIES IN SYNC
✓ SYNCED (tree abc123...)  ← Same hash for all repos
```

## 📞 Emergency Procedures

### Emergency Direct Push (Bypass PR)
**Only for production emergencies:**
```bash
# 1. Disable branch protection temporarily
# 2. Push critical fix directly 
git push origin main
# 3. Run manual sync
./repo-tools/unified_flyway_sync.sh full --auto-commit  
# 4. Re-enable branch protection
```

### Manual Workflow Trigger
**If automated workflow fails:**
```bash
# Via GitHub CLI
gh workflow run production-release.yml

# Or via GitHub web interface: Actions → Production Release → Run workflow
```

---

**Your distributed Flyway sync system now uses a safe, reviewable PR-based workflow!** 🚀