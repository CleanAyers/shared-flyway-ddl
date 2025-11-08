#!/bin/bash
# Setup script to install Git hooks in child repositories

# Colors
RED=$'\033[31m'; GREEN=$'\033[32m'; YEL=$'\033[33m'; CYAN=$'\033[36m'; NC=$'\033[0m'

echo "${CYAN}Installing Git hooks in all child repositories...${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="$(dirname "$SCRIPT_DIR")"
PARENT_DIR="$(dirname "$SHARED_DIR")"
BASE_DIR="$(dirname "$PARENT_DIR")"

# Child repositories
CHILD_REPOS=("flyway-1-pipeline" "flyway-1-grants" "flyway-2-pipeline" "flyway-2-grants")

for repo in "${CHILD_REPOS[@]}"; do
    CHILD_DIR="${BASE_DIR}/${repo}"
    
    echo "${CYAN}-- ${repo}${NC}"
    
    if [[ ! -d "${CHILD_DIR}/.git" ]]; then
        echo "  ${RED}SKIP:${NC} Repository not found at ${CHILD_DIR}"
        continue
    fi
    
    # Create hooks directory if it doesn't exist
    HOOKS_DIR="${CHILD_DIR}/.git/hooks"
    mkdir -p "$HOOKS_DIR"
    
    # Copy pre-commit hook
    if [[ -f "${SHARED_DIR}/hooks/pre-commit" ]]; then
        cp "${SHARED_DIR}/hooks/pre-commit" "${HOOKS_DIR}/pre-commit"
        chmod +x "${HOOKS_DIR}/pre-commit"
        echo "  ${GREEN}OK:${NC} Installed pre-commit hook"
    else
        echo "  ${RED}ERROR:${NC} Source hook file not found at ${SHARED_DIR}/hooks/pre-commit"
    fi
done

echo "${GREEN}Git hook installation complete!${NC}"