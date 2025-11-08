#!/bin/bash
# verify-child-repo-settings.sh
# Comprehensive verification of GitHub Actions settings for all child repositories

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repository list
REPOS=("flyway-1-pipeline" "flyway-1-grants" "flyway-2-pipeline" "flyway-2-grants")
OWNER="CleanAyers"

echo -e "${BLUE}🔍 GitHub Actions Settings Verification${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

# Check GitHub CLI authentication
if ! gh auth status >/dev/null 2>&1; then
    echo -e "${RED}❌ GitHub CLI not authenticated. Run 'gh auth login' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ GitHub CLI authenticated${NC}"
echo ""

# Function to check repository settings
check_repo_settings() {
    local repo=$1
    echo -e "${YELLOW}🔍 Checking $repo...${NC}"
    
    # Check if repo exists and is accessible
    if ! gh repo view "$OWNER/$repo" >/dev/null 2>&1; then
        echo -e "  ${RED}❌ Repository not accessible${NC}"
        return 1
    fi
    
    echo -e "  ${GREEN}✅ Repository accessible${NC}"
    
    # Check Actions permissions
    local actions_data
    if actions_data=$(gh api "repos/$OWNER/$repo/actions/permissions" 2>/dev/null); then
        local enabled=$(echo "$actions_data" | jq -r '.enabled')
        local allowed_actions=$(echo "$actions_data" | jq -r '.allowed_actions')
        
        if [ "$enabled" = "true" ]; then
            echo -e "  ${GREEN}✅ Actions enabled${NC}"
        else
            echo -e "  ${RED}❌ Actions disabled${NC}"
        fi
        
        echo -e "  📋 Allowed actions: $allowed_actions"
    else
        echo -e "  ${RED}❌ Could not access Actions permissions${NC}"
    fi
    
    # Check workflow permissions
    local workflow_data
    if workflow_data=$(gh api "repos/$OWNER/$repo/actions/permissions/workflow" 2>/dev/null); then
        local default_perms=$(echo "$workflow_data" | jq -r '.default_workflow_permissions')
        local can_approve_pr=$(echo "$workflow_data" | jq -r '.can_approve_pull_request_reviews')
        
        echo -e "  📋 Default workflow permissions: $default_perms"
        
        if [ "$default_perms" = "write" ]; then
            echo -e "  ${GREEN}✅ Write permissions enabled${NC}"
        else
            echo -e "  ${YELLOW}⚠️  Default permissions: $default_perms (expected: write)${NC}"
        fi
        
        if [ "$can_approve_pr" = "true" ]; then
            echo -e "  ${GREEN}✅ Can approve pull requests${NC}"
        else
            echo -e "  ${RED}❌ Cannot approve pull requests${NC}"
        fi
    else
        echo -e "  ${RED}❌ Could not access workflow permissions${NC}"
    fi
    
    # Check repository general info
    local repo_data
    if repo_data=$(gh api "repos/$OWNER/$repo" 2>/dev/null); then
        local private=$(echo "$repo_data" | jq -r '.private')
        local default_branch=$(echo "$repo_data" | jq -r '.default_branch')
        
        echo -e "  📋 Private: $private"
        echo -e "  📋 Default branch: $default_branch"
    fi
    
    echo ""
}

# Function to generate summary report
generate_summary() {
    echo -e "${BLUE}📊 SUMMARY REPORT${NC}"
    echo -e "${BLUE}=================${NC}"
    echo ""
    
    local all_good=true
    
    for repo in "${REPOS[@]}"; do
        echo -e "${YELLOW}$repo:${NC}"
        
        # Quick check of critical settings
        if actions_data=$(gh api "repos/$OWNER/$repo/actions/permissions" 2>/dev/null); then
            local enabled=$(echo "$actions_data" | jq -r '.enabled')
            if [ "$enabled" = "true" ]; then
                echo -e "  Actions: ${GREEN}✅ Enabled${NC}"
            else
                echo -e "  Actions: ${RED}❌ Disabled${NC}"
                all_good=false
            fi
        else
            echo -e "  Actions: ${RED}❌ Cannot access${NC}"
            all_good=false
        fi
        
        if workflow_data=$(gh api "repos/$OWNER/$repo/actions/permissions/workflow" 2>/dev/null); then
            local default_perms=$(echo "$workflow_data" | jq -r '.default_workflow_permissions')
            local can_approve_pr=$(echo "$workflow_data" | jq -r '.can_approve_pull_request_reviews')
            
            if [ "$default_perms" = "write" ]; then
                echo -e "  Permissions: ${GREEN}✅ Write${NC}"
            else
                echo -e "  Permissions: ${YELLOW}⚠️  $default_perms${NC}"
                all_good=false
            fi
            
            if [ "$can_approve_pr" = "true" ]; then
                echo -e "  PR Approval: ${GREEN}✅ Enabled${NC}"
            else
                echo -e "  PR Approval: ${RED}❌ Disabled${NC}"
                all_good=false
            fi
        fi
        echo ""
    done
    
    if [ "$all_good" = "true" ]; then
        echo -e "${GREEN}🎉 All repositories are correctly configured!${NC}"
    else
        echo -e "${YELLOW}⚠️  Some repositories need attention. Check the detailed output above.${NC}"
    fi
}

# Function to show quick status
quick_status() {
    echo -e "${BLUE}🚀 QUICK STATUS CHECK${NC}"
    echo -e "${BLUE}===================${NC}"
    echo ""
    
    for repo in "${REPOS[@]}"; do
        printf "%-20s " "$repo:"
        
        if ! gh repo view "$OWNER/$repo" >/dev/null 2>&1; then
            echo -e "${RED}❌ Not accessible${NC}"
            continue
        fi
        
        local status_icons=""
        
        # Check Actions enabled
        if actions_data=$(gh api "repos/$OWNER/$repo/actions/permissions" 2>/dev/null); then
            local enabled=$(echo "$actions_data" | jq -r '.enabled')
            if [ "$enabled" = "true" ]; then
                status_icons+="${GREEN}🔧${NC}"
            else
                status_icons+="${RED}❌${NC}"
            fi
        else
            status_icons+="${RED}❌${NC}"
        fi
        
        # Check write permissions
        if workflow_data=$(gh api "repos/$OWNER/$repo/actions/permissions/workflow" 2>/dev/null); then
            local default_perms=$(echo "$workflow_data" | jq -r '.default_workflow_permissions')
            if [ "$default_perms" = "write" ]; then
                status_icons+="${GREEN}✏️${NC} "
            else
                status_icons+="${YELLOW}⚠️${NC} "
            fi
        else
            status_icons+="${RED}❌${NC}"
        fi
        
        echo -e "$status_icons"
    done
    
    echo ""
    echo -e "Legend: ${GREEN}🔧${NC}=Actions ${GREEN}✏️${NC}=Write ${YELLOW}⚠️${NC}=Warning ${RED}❌${NC}=Error"
}

# Main execution
case "${1:-detailed}" in
    "quick"|"q")
        quick_status
        ;;
    "summary"|"s")
        generate_summary
        ;;
    "detailed"|"d"|"")
        echo "Performing detailed verification of all child repositories..."
        echo ""
        
        for repo in "${REPOS[@]}"; do
            check_repo_settings "$repo"
        done
        
        generate_summary
        ;;
    "help"|"h"|"--help")
        echo "Usage: $0 [MODE]"
        echo ""
        echo "Modes:"
        echo "  detailed (default) - Full detailed check of all settings"
        echo "  quick             - Quick status overview with icons"
        echo "  summary           - Summary report only"
        echo "  help              - Show this help"
        echo ""
        echo "Examples:"
        echo "  $0                 # Detailed check"
        echo "  $0 quick           # Quick status"
        echo "  $0 summary         # Summary only"
        ;;
    *)
        echo -e "${RED}❌ Invalid mode: $1${NC}"
        echo "Use '$0 help' for usage information."
        exit 1
        ;;
esac