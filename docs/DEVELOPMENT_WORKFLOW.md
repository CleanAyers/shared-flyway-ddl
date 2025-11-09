# Development Workflow & Branch Protection Guide

## 🛡️ Branch Protection Setup

### **Step 1: Configure Branch Protection Rules**

Go to your repository settings and configure these protection rules:

#### **Main Branch Protection (Production)**
- Repository: `https://github.com/CleanAyers/shared-flyway-ddl/settings/branches`
- Branch name pattern: `main`
- Settings to enable:
  - ✅ **Require a pull request before merging**
  - ✅ **Require status checks to pass before merging**
  - ✅ **Require conversation resolution before merging** 
  - ✅ **Restrict pushes that create files larger than 100 MB**
  - ✅ **Allow force pushes: Everyone** (disabled)
  - ✅ **Allow deletions** (disabled)

#### **Develop Branch Protection**
- Branch name pattern: `develop`
- Settings to enable:
  - ✅ **Require a pull request before merging**
  - ✅ **Require status checks to pass before merging**

### **Step 2: Required Status Checks**
Add these required status checks for main branch:
- `Auto Sync Child Repositories` (from auto-sync.yml)
- `Production Sync to All Child Repositories` (from production-release.yml)

## 🔄 Development Workflow

### **Daily Development Workflow**

```bash
# 1. Start new feature from develop
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name

# 2. Make changes to shared Flyway files
# Edit files in read-write-flyway-files/

# 3. Test locally
./repo-tools/unified_flyway_sync.sh status
./repo-tools/unified_flyway_sync.sh publish
./repo-tools/unified_flyway_sync.sh sync --auto-commit

# 4. Commit and push feature branch
git add .
git commit -m "feat: description of your changes"
git push origin feature/your-feature-name

# 5. Create Pull Request to develop branch
# GitHub Actions will run automatic sync tests

# 6. After approval, merge to develop
# This triggers development environment sync

# 7. When ready for production, create PR from develop to main
# This requires additional approvals and runs production sync
```

### **Branch Strategy**

```
main (production)     ←── Pull Request ←── develop (integration)
  ↑                                           ↑
  │                                           │
Production Release                     Feature branches
(Manual approval)                    (feature/*, bugfix/*)
```

## 🚀 Deployment Environments

### **Development Environment**
- **Trigger**: Push to `develop` branch
- **Purpose**: Integration testing and development validation
- **Auto-sync**: Runs automatically on shared file changes
- **Child repo branches**: Can sync to `develop` branches in child repos

### **Production Environment**  
- **Trigger**: Push to `main` branch (via PR only)
- **Purpose**: Production releases
- **Approval**: Requires manual approval via GitHub Environments
- **Auto-sync**: Runs automatically but with stricter validation
- **Child repo branches**: Syncs to `main` branches in child repos

## 🔐 Security Features

### **Branch Protection Benefits**
- ❌ **No direct pushes to main** - All changes via Pull Requests
- ✅ **Code review required** - At least one approval needed
- ✅ **Status checks** - All tests must pass before merge
- ✅ **Conversation resolution** - All review comments resolved
- ✅ **Production approval** - Manual gate for production releases

### **PAT Token Security**
- ✅ **Scoped permissions** - Only repo and workflow access
- ✅ **Repository secrets** - Token stored securely
- ✅ **Automatic rotation** - Set expiration dates on PATs
- ✅ **Audit trail** - All sync operations logged

## 📊 Monitoring & Alerts

### **Workflow Notifications**
- **Develop sync failures** → Create issues automatically
- **Production sync failures** → Immediate notification + rollback
- **Drift detection** → Monitor child repo status every 6 hours
- **Release reports** → Detailed artifacts for each deployment

### **Status Badges**
Add these to your README for real-time status:

```markdown
![Dev Sync Status](https://github.com/CleanAyers/shared-flyway-ddl/workflows/Auto%20Sync%20Child%20Repositories/badge.svg?branch=develop)
![Production Status](https://github.com/CleanAyers/shared-flyway-ddl/workflows/Production%20Release%20to%20Main/badge.svg?branch=main)
```

## 🛠️ Emergency Procedures

### **Emergency Hotfix**
```bash
# 1. Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-fix

# 2. Make minimal changes
# 3. Test thoroughly
# 4. Create PR directly to main
# 5. Use emergency_release workflow option
```

### **Rollback Procedure**
```bash
# 1. Identify last known good commit
# 2. Create rollback branch
git checkout -b rollback/to-commit-abc123 abc123

# 3. Create PR to main with rollback
# 4. Use nuclear reset if needed
./repo-tools/unified_flyway_sync.sh nuclear --force-nuclear
```

## 📋 Next Steps

1. **Configure branch protection rules** (above settings)
2. **Set up GitHub Environment** for production approvals
3. **Add team members** as required reviewers
4. **Test the workflow** with a small change
5. **Train team** on new development process

This workflow ensures that:
- ✅ All production changes are reviewed
- ✅ Development changes are automatically tested
- ✅ Emergency procedures exist for critical fixes
- ✅ Complete audit trail for all database changes