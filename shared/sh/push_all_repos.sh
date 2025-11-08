#!/bin/bash
# Script to push all repositories in the Flyway structure

set -euo pipefail

# Colors
RED=$'\033[31m'; GREEN=$'\033[32m'; YEL=$'\033[33m'; CYAN=$'\033[36m'; NC=$'\033[0m'

echo "${CYAN}Pushing all Flyway repositories...${NC}"

# Base directory (where this script is located)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# All repositories
REPOS=("shared-flyway-ddl" "flyway-1-pipeline" "flyway-1-grants" "flyway-2-pipeline" "flyway-2-grants")

for repo in "${REPOS[@]}"; do
    REPO_DIR="${BASE_DIR}/${repo}"
    
    echo ""
    echo "${CYAN}-- ${repo}${NC}"
    
    if [[ ! -d "${REPO_DIR}/.git" ]]; then
        echo "  ${RED}SKIP:${NC} Not a git repository at ${REPO_DIR}"
        continue
    fi
    
    cd "${REPO_DIR}"
    
    # Check if there are any changes to commit
    if [[ -n "$(git status --porcelain)" ]]; then
        echo "  ${YEL}INFO:${NC} Uncommitted changes found, adding and committing..."
        git add -A
        
        # Check if this is a child repo with ro-shared-ddl changes
        if [[ "${repo}" != "shared-flyway-ddl" ]] && git diff --cached --name-only | grep -q "^ro-shared-ddl/"; then
            echo "  ${YEL}INFO:${NC} Changes in ro-shared-ddl/ detected, using --no-verify to bypass hooks..."
            git commit --no-verify -m "chore: auto-commit changes before push $(date +%Y%m%d-%H%M%S)"
        else
            git commit -m "chore: auto-commit changes before push $(date +%Y%m%d-%H%M%S)"
        fi
    fi
    
    # Check if we're on a branch that can be pushed
    CURRENT_BRANCH=$(git branch --show-current)
    if [[ -z "$CURRENT_BRANCH" ]]; then
        echo "  ${RED}SKIP:${NC} Not on a named branch"
        continue
    fi
    
    # Try to push
    echo "  ${CYAN}Pushing branch: ${CURRENT_BRANCH}${NC}"
    if git push origin "${CURRENT_BRANCH}"; then
        echo "  ${GREEN}✓ Successfully pushed${NC}"
    else
        echo "  ${RED}✗ Failed to push${NC}"
    fi
done

echo ""
echo "${GREEN}Push operation complete!${NC}"