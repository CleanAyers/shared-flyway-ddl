# 📚 Repository Rulesets (GitHub Team Plan Required)

**⚠️ IMPORTANT:** These rulesets require **GitHub Team plan** and are **NOT available on free GitHub accounts**. They are maintained here for:
- Documentation of best practices
- Future reference when upgrading to paid plan
- Demonstration of security knowledge

**Current Status:** Using alternative protection methods (GitHub Actions + CODEOWNERS + Classic Branch Protection)

---

**Created:** November 9, 2025  
**Purpose:** Individual, tailored rulesets for each Flyway child repository  
**Availability:** GitHub Team/Enterprise plans only

## 🎯 Repository-Specific Configurations (Reference Only)

### **flyway-1-pipeline-protection.json**
- **Purpose:** Production pipeline database management
- **Review Requirements:** 2 approvals (moderate security)
- **Protected Branches:** `main`, `master`, `production`
- **Special Features:**
  - Pipeline-specific status check: `pipeline-config-check`
  - Protects production configuration files
  - Allows pipeline development branches: `pipeline-dev/*`

### **flyway-1-grants-protection.json** 
- **Purpose:** Security and permissions management (highest security)
- **Review Requirements:** 3 approvals + last push approval
- **Protected Branches:** `main`, `master`, `production`
- **Special Features:**
  - Enhanced security auditing: `security-audit`, `grants-validation`
  - Protects security configuration files
  - Most restrictive ruleset due to security implications

### **flyway-2-pipeline-protection.json**
- **Purpose:** Version 2 pipeline database with staging support
- **Review Requirements:** 2 approvals
- **Protected Branches:** `main`, `master`, `production`, `staging`
- **Special Features:**
  - V2 compatibility checks: `v2-compatibility-check`
  - Staging environment support
  - V2-specific development branches: `v2-dev/*`

### **flyway-2-grants-protection.json**
- **Purpose:** Version 2 grants and security (enhanced for v2)
- **Review Requirements:** 3 approvals + last push approval
- **Protected Branches:** `main`, `master`, `production`, `staging`
- **Special Features:**
  - V2 grants compatibility: `v2-grants-compatibility`
  - Enhanced security for version 2 architecture
  - Most comprehensive protection set

## 🔒 Security Levels Summary

| Repository | Approvals | Last Push Required | Security Level | Use Case |
|------------|-----------|-------------------|----------------|----------|
| flyway-1-pipeline | 2 | ❌ | Medium | Pipeline Operations |
| flyway-1-grants | 3 | ✅ | **Maximum** | Security & Permissions |
| flyway-2-pipeline | 2 | ❌ | Medium | V2 Pipeline Operations |
| flyway-2-grants | 3 | ✅ | **Maximum** | V2 Security & Permissions |

## ✅ Current Protection (Free Plan Alternative)

Since rulesets aren't available on free GitHub accounts, equivalent protection is provided by:

**1. GitHub Actions Workflows** (`.github/workflows/flyway-protection.yml`)
- ✅ Blocks modifications to `read-only-flyway-files/`
- ✅ Validates SQL file naming conventions
- ✅ Runs on every PR and push

**2. CODEOWNERS Files** (`.github/CODEOWNERS`)
- ✅ Requires approval from repository owner
- ✅ Mandatory code review for all changes

**3. Classic Branch Protection** (Manual setup via GitHub web interface)
- ✅ Requires pull request reviews
- ✅ Requires status checks to pass
- ✅ Prevents force pushes and deletions

## 🎯 Equivalent Protection Mapping

**Rulesets Feature → Free Plan Alternative:**
- File path restrictions → GitHub Actions validation
- Required reviews → CODEOWNERS + Classic branch protection
- Status checks → GitHub Actions + Classic branch protection
- Branch deletion protection → Classic branch protection
- Force push prevention → Classic branch protection

## 🚀 Future Use (When Upgrading to GitHub Team)

If upgrading to GitHub Team plan in the future:
1. Apply these rulesets using the archived JSON files
2. Remove manual classic branch protection rules
3. Keep GitHub Actions as additional validation layer
4. Maintain CODEOWNERS for code review workflow

## 📝 Historical Context

These rulesets were designed on November 9, 2025, as part of the comprehensive repository protection system implementation. They demonstrate knowledge of advanced GitHub security features and represent the ideal protection configuration that would be applied if the account had access to GitHub Team plan features.

**Design Principles:**
1. **Grants repositories** = Maximum security (3 approvals + last push)
2. **Pipeline repositories** = Operational security (2 approvals)  
3. **V2 repositories** = Enhanced compatibility checking
4. **All repositories** = Core protection against accidents

The current implementation using free GitHub features provides equivalent protection through alternative methods.