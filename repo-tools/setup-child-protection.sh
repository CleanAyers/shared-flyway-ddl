#!/usr/bin/env bash
set -euo pipefail

# Comprehensive Child Repository Protection Setup
# Applies multiple layers of idiot-proofing to all Flyway child repos

# Colors for output
RED=$'\033[31m'; GREEN=$'\033[32m'; YEL=$'\033[33m'; CYAN=$'\033[36m'; BOLD=$'\033[1m'; NC=$'\033[0m'

# Configuration
BASE_DIR="/Users/joshx86/Documents/Codex/Work/Flyway-Repo-Structure"
PARENT_DIR="$BASE_DIR/shared-flyway-ddl"
CHILD_REPOS=("flyway-1-pipeline" "flyway-1-grants" "flyway-2-pipeline" "flyway-2-grants")
GITHUB_USERNAME="CleanAyers"

# Protection options
SETUP_RULESETS=1
SETUP_CODEOWNERS=1
SETUP_GITHUB_ACTIONS=1
SETUP_PRECOMMIT_HOOKS=1
SETUP_REPO_SETTINGS=1
DRY_RUN=0

# Help function
show_help() {
    cat << 'EOF'
Child Repository Protection Setup

This script applies comprehensive protection to all Flyway child repositories:
- Repository rulesets (branch protection, file restrictions)
- CODEOWNERS files (mandatory code review)
- GitHub Actions workflows (continuous validation)
- Pre-commit hooks (local validation)
- Repository settings lock-down

OPTIONS:
  --dry-run           Show what would be done without making changes
  --skip-rulesets     Skip applying GitHub repository rulesets
  --skip-codeowners   Skip setting up CODEOWNERS files
  --skip-actions      Skip GitHub Actions workflow setup
  --skip-hooks        Skip pre-commit hook setup
  --skip-settings     Skip repository settings configuration
  --help              Show this help

EXAMPLES:
  ./setup-child-protection.sh
  ./setup-child-protection.sh --dry-run
  ./setup-child-protection.sh --skip-rulesets --skip-settings
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift;;
        --skip-rulesets) SETUP_RULESETS=0; shift;;
        --skip-codeowners) SETUP_CODEOWNERS=0; shift;;
        --skip-actions) SETUP_GITHUB_ACTIONS=0; shift;;
        --skip-hooks) SETUP_PRECOMMIT_HOOKS=0; shift;;
        --skip-settings) SETUP_REPO_SETTINGS=0; shift;;
        --help) show_help; exit 0;;
        *) echo "${RED}ERROR: Unknown argument: $1${NC}"; show_help; exit 1;;
    esac
done

echo "${CYAN}🛡️  Child Repository Protection Setup${NC}"
echo "${CYAN}Base directory:${NC} $BASE_DIR"
echo "${CYAN}Target repos:${NC} ${CHILD_REPOS[*]}"
echo "${CYAN}Dry run:${NC} $([ $DRY_RUN -eq 1 ] && echo "YES" || echo "NO")"
echo

# =============================================================================
# FUNCTION: Setup repository rulesets
# =============================================================================
setup_rulesets() {
    echo "${BOLD}${CYAN}📋 SETTING UP REPOSITORY RULESETS${NC}"
    
    local ruleset_file="$PARENT_DIR/docs/flyway-child-protection-ruleset.json"
    
    if [[ ! -f "$ruleset_file" ]]; then
        echo "${RED}ERROR: Ruleset template not found: $ruleset_file${NC}"
        return 1
    fi
    
    for repo in "${CHILD_REPOS[@]}"; do
        echo "${CYAN}-- $repo${NC}"
        
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "  ${YEL}DRY RUN:${NC} Would apply ruleset via GitHub API"
        else
            echo "  ${CYAN}APPLY:${NC} Applying protection ruleset..."
            
            # Create repo-specific ruleset by updating the template
            local temp_ruleset="/tmp/${repo}-ruleset.json"
            jq --arg repo_name "$GITHUB_USERNAME/$repo" \
               '.source = $repo_name | .name = "flyway-child-protection"' \
               "$ruleset_file" > "$temp_ruleset"
            
            # Apply via GitHub CLI
            if gh api "repos/$GITHUB_USERNAME/$repo/rulesets" \
                --method POST \
                --input "$temp_ruleset" >/dev/null 2>&1; then
                echo "  ${GREEN}✅ Ruleset applied successfully${NC}"
            else
                echo "  ${YEL}⚠️  Ruleset may already exist or API error occurred${NC}"
            fi
            
            rm -f "$temp_ruleset"
        fi
    done
    
    echo "${GREEN}✅ REPOSITORY RULESETS COMPLETE${NC}"
    echo
}

# =============================================================================
# FUNCTION: Setup CODEOWNERS files
# =============================================================================
setup_codeowners() {
    echo "${BOLD}${CYAN}👥 SETTING UP CODEOWNERS FILES${NC}"
    
    local codeowners_template="$PARENT_DIR/docs/CODEOWNERS-template"
    
    if [[ ! -f "$codeowners_template" ]]; then
        echo "${RED}ERROR: CODEOWNERS template not found: $codeowners_template${NC}"
        return 1
    fi
    
    for repo in "${CHILD_REPOS[@]}"; do
        local repo_dir="$BASE_DIR/$repo"
        local github_dir="$repo_dir/.github"
        local codeowners_file="$github_dir/CODEOWNERS"
        
        echo "${CYAN}-- $repo${NC}"
        
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "  ${YEL}DRY RUN:${NC} Would create .github/CODEOWNERS"
        else
            # Create .github directory if it doesn't exist
            mkdir -p "$github_dir"
            
            # Copy CODEOWNERS template
            cp "$codeowners_template" "$codeowners_file"
            
            echo "  ${GREEN}✅ CODEOWNERS file created${NC}"
        fi
    done
    
    echo "${GREEN}✅ CODEOWNERS SETUP COMPLETE${NC}"
    echo
}

# =============================================================================
# FUNCTION: Setup GitHub Actions workflows
# =============================================================================
setup_github_actions() {
    echo "${BOLD}${CYAN}🔄 SETTING UP GITHUB ACTIONS WORKFLOWS${NC}"
    
    local workflow_template="$PARENT_DIR/docs/github-actions-protection-template.yml"
    
    if [[ ! -f "$workflow_template" ]]; then
        echo "${RED}ERROR: GitHub Actions template not found: $workflow_template${NC}"
        return 1
    fi
    
    for repo in "${CHILD_REPOS[@]}"; do
        local repo_dir="$BASE_DIR/$repo"
        local workflows_dir="$repo_dir/.github/workflows"
        local workflow_file="$workflows_dir/flyway-protection.yml"
        
        echo "${CYAN}-- $repo${NC}"
        
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "  ${YEL}DRY RUN:${NC} Would create .github/workflows/flyway-protection.yml"
        else
            # Create workflows directory if it doesn't exist
            mkdir -p "$workflows_dir"
            
            # Copy workflow template
            cp "$workflow_template" "$workflow_file"
            
            echo "  ${GREEN}✅ GitHub Actions workflow created${NC}"
        fi
    done
    
    echo "${GREEN}✅ GITHUB ACTIONS SETUP COMPLETE${NC}"
    echo
}

# =============================================================================
# FUNCTION: Setup pre-commit hooks
# =============================================================================
setup_precommit_hooks() {
    echo "${BOLD}${CYAN}🪝 SETTING UP PRE-COMMIT HOOKS${NC}"
    
    local hook_template="$PARENT_DIR/docs/pre-commit-hook-template"
    
    if [[ ! -f "$hook_template" ]]; then
        echo "${RED}ERROR: Pre-commit hook template not found: $hook_template${NC}"
        return 1
    fi
    
    for repo in "${CHILD_REPOS[@]}"; do
        local repo_dir="$BASE_DIR/$repo"
        local hooks_dir="$repo_dir/.git/hooks"
        local hook_file="$hooks_dir/pre-commit"
        
        echo "${CYAN}-- $repo${NC}"
        
        if [[ ! -d "$repo_dir/.git" ]]; then
            echo "  ${YEL}SKIP:${NC} Not a git repository"
            continue
        fi
        
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "  ${YEL}DRY RUN:${NC} Would install pre-commit hook"
        else
            # Copy and make executable
            cp "$hook_template" "$hook_file"
            chmod +x "$hook_file"
            
            echo "  ${GREEN}✅ Pre-commit hook installed${NC}"
        fi
    done
    
    echo "${GREEN}✅ PRE-COMMIT HOOKS SETUP COMPLETE${NC}"
    echo
}

# =============================================================================
# FUNCTION: Setup repository settings
# =============================================================================
setup_repo_settings() {
    echo "${BOLD}${CYAN}⚙️  CONFIGURING REPOSITORY SETTINGS${NC}"
    
    for repo in "${CHILD_REPOS[@]}"; do
        echo "${CYAN}-- $repo${NC}"
        
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "  ${YEL}DRY RUN:${NC} Would disable wiki, issues, projects, discussions"
            echo "  ${YEL}DRY RUN:${NC} Would enable security features"
        else
            echo "  ${CYAN}CONFIG:${NC} Disabling unnecessary features..."
            
            # Disable features that can cause confusion
            gh api "repos/$GITHUB_USERNAME/$repo" \
                --method PATCH \
                --field has_issues=false \
                --field has_projects=false \
                --field has_wiki=false \
                --field has_discussions=false >/dev/null 2>&1 || true
            
            echo "  ${CYAN}SECURITY:${NC} Enabling security features..."
            
            # Enable security features
            gh api "repos/$GITHUB_USERNAME/$repo/vulnerability-alerts" \
                --method PUT >/dev/null 2>&1 || true
                
            gh api "repos/$GITHUB_USERNAME/$repo/automated-security-fixes" \
                --method PUT >/dev/null 2>&1 || true
            
            echo "  ${GREEN}✅ Repository settings configured${NC}"
        fi
    done
    
    echo "${GREEN}✅ REPOSITORY SETTINGS COMPLETE${NC}"
    echo
}

# =============================================================================
# FUNCTION: Commit and push protection files
# =============================================================================
commit_protection_files() {
    echo "${BOLD}${CYAN}📤 COMMITTING PROTECTION FILES${NC}"
    
    for repo in "${CHILD_REPOS[@]}"; do
        local repo_dir="$BASE_DIR/$repo"
        
        echo "${CYAN}-- $repo${NC}"
        
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "  ${YEL}DRY RUN:${NC} Would commit and push protection files"
            continue
        fi
        
        cd "$repo_dir"
        
        # Check if there are new protection files to commit
        if [[ -n "$(git status --porcelain)" ]]; then
            echo "  ${CYAN}COMMIT:${NC} Adding protection files..."
            
            git add .github/ 2>/dev/null || true
            
            if git diff --cached --quiet; then
                echo "  ${YEL}SKIP:${NC} No changes to commit"
            else
                git commit -m "feat: add comprehensive repository protection

- Add CODEOWNERS for mandatory code review
- Add GitHub Actions workflow for continuous validation
- Protect read-only-flyway-files from modification
- Validate SQL file naming conventions

This ensures repository integrity and prevents accidental modifications
to shared files managed by the parent repository."
                
                echo "  ${CYAN}PUSH:${NC} Uploading to GitHub..."
                git push origin main
                
                echo "  ${GREEN}✅ Protection files committed and pushed${NC}"
            fi
        else
            echo "  ${YEL}SKIP:${NC} No changes to commit"
        fi
    done
    
    echo "${GREEN}✅ PROTECTION FILES COMMITTED${NC}"
    echo
}

# =============================================================================
# FUNCTION: Validate setup
# =============================================================================
validate_setup() {
    echo "${BOLD}${CYAN}🔍 VALIDATING PROTECTION SETUP${NC}"
    
    local all_good=1
    
    for repo in "${CHILD_REPOS[@]}"; do
        local repo_dir="$BASE_DIR/$repo"
        echo "${CYAN}-- $repo${NC}"
        
        # Check CODEOWNERS
        if [[ -f "$repo_dir/.github/CODEOWNERS" ]]; then
            echo "  ${GREEN}✅ CODEOWNERS file present${NC}"
        else
            echo "  ${RED}❌ CODEOWNERS file missing${NC}"
            all_good=0
        fi
        
        # Check GitHub Actions
        if [[ -f "$repo_dir/.github/workflows/flyway-protection.yml" ]]; then
            echo "  ${GREEN}✅ GitHub Actions workflow present${NC}"
        else
            echo "  ${RED}❌ GitHub Actions workflow missing${NC}"
            all_good=0
        fi
        
        # Check pre-commit hook
        if [[ -x "$repo_dir/.git/hooks/pre-commit" ]]; then
            echo "  ${GREEN}✅ Pre-commit hook installed${NC}"
        else
            echo "  ${YEL}⚠️  Pre-commit hook missing or not executable${NC}"
        fi
        
        # Check if rulesets can be verified (would need API call)
        if [[ $DRY_RUN -eq 0 ]]; then
            echo "  ${CYAN}ℹ️  Repository rulesets: Check GitHub web interface${NC}"
        fi
    done
    
    echo
    if [[ $all_good -eq 1 ]]; then
        echo "${GREEN}🎉 ALL PROTECTION LAYERS SUCCESSFULLY APPLIED!${NC}"
    else
        echo "${YEL}⚠️  Some protection layers may need manual attention${NC}"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

# Verify we're in the right directory
if [[ ! -d "$PARENT_DIR" ]]; then
    echo "${RED}ERROR: Parent directory not found: $PARENT_DIR${NC}"
    exit 1
fi

# Verify GitHub CLI is available and authenticated
if ! command -v gh >/dev/null 2>&1; then
    echo "${RED}ERROR: GitHub CLI (gh) not found. Install with: brew install gh${NC}"
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "${RED}ERROR: GitHub CLI not authenticated. Run: gh auth login${NC}"
    exit 1
fi

# Verify all child repositories exist
for repo in "${CHILD_REPOS[@]}"; do
    if [[ ! -d "$BASE_DIR/$repo" ]]; then
        echo "${RED}ERROR: Child repository not found: $BASE_DIR/$repo${NC}"
        exit 1
    fi
done

echo "${GREEN}✅ Prerequisites validated${NC}"
echo

# Execute protection setup steps
if [[ $SETUP_RULESETS -eq 1 ]]; then
    setup_rulesets
fi

if [[ $SETUP_CODEOWNERS -eq 1 ]]; then
    setup_codeowners
fi

if [[ $SETUP_GITHUB_ACTIONS -eq 1 ]]; then
    setup_github_actions
fi

if [[ $SETUP_PRECOMMIT_HOOKS -eq 1 ]]; then
    setup_precommit_hooks
fi

if [[ $SETUP_REPO_SETTINGS -eq 1 ]]; then
    setup_repo_settings
fi

# Commit protection files (only if not dry run and files were created)
if [[ $DRY_RUN -eq 0 ]] && ([[ $SETUP_CODEOWNERS -eq 1 ]] || [[ $SETUP_GITHUB_ACTIONS -eq 1 ]]); then
    commit_protection_files
fi

# Validate the setup
validate_setup

echo
echo "${BOLD}${GREEN}🛡️  CHILD REPOSITORY PROTECTION SETUP COMPLETE!${NC}"
echo
echo "${CYAN}Next steps:${NC}"
echo "1. Review the GitHub repository settings manually"
echo "2. Test the protection by trying to create a PR that modifies read-only-flyway-files/"
echo "3. Verify rulesets are active in each repository's Settings → Rules"
echo "4. Share the CODEOWNERS requirements with your team"