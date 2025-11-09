# 🛡️ Classic Branch Protection Configuration (Free GitHub Plan)

## 📋 Settings for Child Repositories

**Apply these settings to each child repository:**
- `flyway-1-pipeline`
- `flyway-1-grants`
- `flyway-2-pipeline`
- `flyway-2-grants`

---

## 🔧 Branch Protection Rule Configuration

### **Navigate to:**
```
https://github.com/CleanAyers/{REPO_NAME}/settings/branches
```

### **Add Rule → Branch name pattern:**
```
main
```

---

## ✅ Protection Settings

### **1. Protect matching branches**
☑️ **Require a pull request before merging**
- **Required number of approvals before merging:** `1`
- ☑️ **Dismiss stale PR approvals when new commits are pushed**
- ☑️ **Require review from code owners**

### **2. Require status checks to pass before merging**
☑️ **Require status checks to pass before merging**
- ☑️ **Require branches to be up to date before merging**
- **Status checks that are required:**
  - `protect-readonly-files`
  - `flyway-validate`

### **3. Additional restrictions**
☑️ **Require conversation resolution before merging**
☐ **Require signed commits** *(optional)*
☐ **Include administrators** ⚠️ **IMPORTANT: LEAVE UNCHECKED**
☑️ **Restrict pushes that create matching branches**
☐ **Allow force pushes**
☐ **Allow deletions**

---

## 🎯 Why These Settings Work

### **Protection for Normal Users:**
- ✅ Requires PR approval before merging
- ✅ Requires GitHub Actions to pass (protect-readonly-files + flyway-validate)
- ✅ Prevents force pushes and branch deletion
- ✅ Enforces code owner review

### **Automation Bypass:**
- ✅ Admin bypass enabled (Include administrators = unchecked)
- ✅ Your sync automation can push directly
- ✅ No more "Changes must be made through a pull request" errors

---

## 📋 Quick Setup Checklist

For each child repository:

### **flyway-1-pipeline**
- [ ] Navigate to Settings → Branches
- [ ] Add rule for `main` branch
- [ ] Configure settings as above
- [ ] Verify status checks: `protect-readonly-files`, `flyway-validate`
- [ ] **ENSURE "Include administrators" is UNCHECKED**

### **flyway-1-grants**
- [ ] Same configuration as above

### **flyway-2-pipeline**  
- [ ] Same configuration as above

### **flyway-2-grants**
- [ ] Same configuration as above

---

## 🚀 Test Your Protection

After setting up all 4 repositories:

1. **Add test migration** in `shared-flyway-ddl/read-write-flyway-files/sql/`
2. **Create PR** from `dev` → `main` in parent repo
3. **Merge PR** via GitHub GUI
4. **Watch automation** - Should successfully sync to all child repos

---

## 🔍 Status Check Names

Make sure these exact names are used in the "Required status checks" field:
```
protect-readonly-files
flyway-validate
```

These match the job names in your `.github/workflows/flyway-protection.yml` files.

---

## ⚠️ Critical Setting

**The most important setting is:**
```
☐ Include administrators (UNCHECKED)
```

This allows your automation (running under your admin account) to bypass the PR requirement during automated sync operations while still protecting against manual edits by others.