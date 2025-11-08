#!/bin/bash
# Nuclear subtree sync script - Forces all child repos to sync with parent
# WARNING: This will overwrite any local changes in read-only-flyway-files folders

set -euo pipefail

# Colors
RED=$'\033[31m'; GREEN=$'\033[32m'; YEL=$'\033[33m'; CYAN=$'\033[36m'; BOLD=$'\033[1m'; NC=$'\033[0m'

echo "${BOLD}${RED}🚨 NUCLEAR SUBTREE SYNC${NC}"
echo "${RED}This will FORCE sync all read-only-flyway-files folders from the parent repository.${NC}"
echo "${RED}Any local changes in read-only-flyway-files will be OVERWRITTEN!${NC}"
echo ""

# Ask for confirmation
read -p "Are you absolutely sure you want to proceed? (type 'NN' to confirm): " confirmation
if [[ "$confirmation" != "NN" ]]; then
    echo "${YEL}Operation cancelled.${NC}"
    exit 0
fi

echo ""
echo "${CYAN}Starting nuclear subtree sync...${NC}"

# Base directory - get parent of the shared-flyway-ddl directory
PARENT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BASE_DIR="$(dirname "$PARENT_DIR")"

echo "${CYAN}Parent directory:${NC} $PARENT_DIR"cd /Users/joshx86/Documents/Codex/Work/Flyway-Repo-Structure/shared-flyway-ddl
./tools/parent_publish_shared.sh
echo "${CYAN}Base directory:${NC} $BASE_DIR"

# Child repositories that have read-only-flyway-files subtrees
CHILD_REPOS=("flyway-1-pipeline" "flyway-1-grants" "flyway-2-pipeline" "flyway-2-grants")

# Parent repository details
PARENT_REPO_URL="https://github.com/CleanAyers/shared-flyway-ddl.git"
PARENT_REMOTE_NAME="parent-shared"
PARENT_BRANCH="ro-shared-ddl"
SUBTREE_PREFIX="read-only-flyway-files"

FAIL_COUNT=0

for repo in "${CHILD_REPOS[@]}"; do
    CHILD_DIR="${BASE_DIR}/${repo}"
    
    echo ""
    echo "${CYAN}-- ${BOLD}${repo}${NC}"
    
    if [[ ! -d "${CHILD_DIR}/.git" ]]; then
        echo "  ${RED}SKIP:${NC} Not a git repository at ${CHILD_DIR}"
        ((FAIL_COUNT++))
        continue
    fi
    
    cd "${CHILD_DIR}"
    
    # Stash any uncommitted changes
    if [[ -n "$(git status --porcelain)" ]]; then
        echo "  ${YEL}STASH:${NC} Stashing uncommitted changes..."
        git stash push -m "nuclear-sync-stash-$(date +%Y%m%d-%H%M%S)"
    fi
    
    # Ensure we're on main branch
    git fetch --all --tags --prune >/dev/null 2>&1 || true
    git switch main >/dev/null 2>&1 || git switch master >/dev/null 2>&1 || {
        echo "  ${RED}ERROR:${NC} Cannot switch to main/master branch"
        ((FAIL_COUNT++))
        continue
    }
    
    # Pull latest main
    git pull --ff-only origin HEAD || {
        echo "  ${RED}ERROR:${NC} Cannot pull latest changes"
        ((FAIL_COUNT++))
        continue
    }
    
    # Add or update parent remote
    if ! git remote | grep -qx "${PARENT_REMOTE_NAME}"; then
        echo "  ${CYAN}REMOTE:${NC} Adding parent remote '${PARENT_REMOTE_NAME}'"
        git remote add "${PARENT_REMOTE_NAME}" "${PARENT_REPO_URL}"
    else
        git remote set-url "${PARENT_REMOTE_NAME}" "${PARENT_REPO_URL}"
    fi
    
    # Fetch parent
    echo "  ${CYAN}FETCH:${NC} Fetching parent ${PARENT_BRANCH} branch..."
    git fetch "${PARENT_REMOTE_NAME}" "${PARENT_BRANCH}" || {
        echo "  ${RED}ERROR:${NC} Cannot fetch parent branch"
        ((FAIL_COUNT++))
        continue
    }
    
    # Nuclear option: Remove existing subtree and re-add it
    if [[ -d "${SUBTREE_PREFIX}" ]]; then
        echo "  ${RED}NUKE:${NC} Removing existing ${SUBTREE_PREFIX} folder..."
        git rm -rf "${SUBTREE_PREFIX}" >/dev/null 2>&1 || rm -rf "${SUBTREE_PREFIX}"
        git add . >/dev/null 2>&1 || true
        if [[ -n "$(git diff --cached)" ]] || [[ -n "$(git status --porcelain)" ]]; then
            git add -A >/dev/null 2>&1 || true
            git commit --no-verify -m "nuclear: remove old ${SUBTREE_PREFIX} before re-sync" >/dev/null 2>&1 || true
        fi
    fi
    
    # Ensure working tree is absolutely clean before subtree add
    git clean -fd >/dev/null 2>&1 || true
    git reset --hard HEAD >/dev/null 2>&1 || true
    
    # Extra cleanup: remove any Git subtree history that might interfere
    git config --unset-all subtree.${SUBTREE_PREFIX}.url >/dev/null 2>&1 || true
    git config --unset-all subtree.${SUBTREE_PREFIX}.branch >/dev/null 2>&1 || true
    
    # Add fresh subtree
    echo "  ${GREEN}ADD:${NC} Adding fresh ${SUBTREE_PREFIX} subtree..."
    if git subtree add --prefix="${SUBTREE_PREFIX}" "${PARENT_REMOTE_NAME}" "${PARENT_BRANCH}" --squash; then
        echo "  ${GREEN}✓ Successfully synced subtree${NC}"
    else
        echo "  ${RED}✗ Failed to add subtree${NC}"
        ((FAIL_COUNT++))
        continue
    fi
    
    # Commit if needed
    if [[ -n "$(git status --porcelain)" ]]; then
        git add -A
        git commit --no-verify -m "nuclear: force sync ${SUBTREE_PREFIX} from parent $(date +%Y-%m-%d)"
    fi
    
    # Push changes
    echo "  ${CYAN}PUSH:${NC} Pushing changes to origin..."
    if git push origin HEAD; then
        echo "  ${GREEN}✓ Successfully pushed${NC}"
    else
        echo "  ${RED}✗ Failed to push${NC}"
        ((FAIL_COUNT++))
    fi
    
    echo "  ${GREEN}DONE${NC}"
done

echo ""
echo "${CYAN}Nuclear subtree sync complete!${NC}"

if [[ $FAIL_COUNT -eq 0 ]]; then
    echo "${GREEN}🎉 All repositories successfully synced!${NC}"
    
    # Perform verification diff between parent and first child
    echo ""
    echo "${CYAN}🔍 Verification: Comparing parent read-wrte-flyway-files/ with child read-only-flyway-files/${NC}"
    
    PARENT_SHARED_DIR="${BASE_DIR}/shared-flyway-ddl/read-wrte-flyway-files"
    FIRST_CHILD_DIR="${BASE_DIR}/${CHILD_REPOS[0]}/read-only-flyway-files"
    
    if [[ -d "$PARENT_SHARED_DIR" && -d "$FIRST_CHILD_DIR" ]]; then
        echo "${CYAN}Comparing:${NC}"
        echo "  Parent:  ${PARENT_SHARED_DIR}"
        echo "  Child:   ${FIRST_CHILD_DIR}"
        echo ""
        
        # Use diff to compare the directories
        if diff -r --brief "$PARENT_SHARED_DIR" "$FIRST_CHILD_DIR" >/dev/null 2>&1; then
            echo "${GREEN}✓ PERFECT SYNC: Directories are identical${NC}"
        else
            echo "${YEL}⚠️  DIFFERENCES FOUND:${NC}"
            echo ""
            diff -r --brief "$PARENT_SHARED_DIR" "$FIRST_CHILD_DIR" || true
            echo ""
            echo "${CYAN}Detailed diff (first 20 lines):${NC}"
            diff -r "$PARENT_SHARED_DIR" "$FIRST_CHILD_DIR" | head -20 || true
            echo ""
            echo "${YEL}Note: Some differences may be expected (e.g., .gitkeep files, permissions)${NC}"
        fi
    else
        echo "${RED}ERROR: Cannot find directories for comparison${NC}"
        echo "  Parent: $PARENT_SHARED_DIR (exists: $(test -d "$PARENT_SHARED_DIR" && echo "yes" || echo "no"))"
        echo "  Child:  $FIRST_CHILD_DIR (exists: $(test -d "$FIRST_CHILD_DIR" && echo "yes" || echo "no"))"
    fi
    
    # Reinstall Git hooks in all child repositories
    echo ""
    echo "${CYAN}🪝 Reinstalling Git hooks in all child repositories...${NC}"
    
    for repo in "${CHILD_REPOS[@]}"; do
        CHILD_DIR="${BASE_DIR}/${repo}"
        
        if [[ -d "${CHILD_DIR}/.git" && -f "${CHILD_DIR}/read-only-flyway-files/sh/setup_git_hooks.sh" ]]; then
            echo "${CYAN}-- ${repo}${NC}"
            cd "${CHILD_DIR}"
            
            # Run the setup script to install Git hooks
            if ./read-only-flyway-files/sh/setup_git_hooks.sh; then
                echo "  ${GREEN}✓ Git hooks installed${NC}"
            else
                echo "  ${RED}✗ Failed to install Git hooks${NC}"
            fi
        else
            echo "${CYAN}-- ${repo}${NC}"
            echo "  ${YEL}SKIP: Missing setup script or not a git repository${NC}"
        fi
    done
    
    echo ""
    echo "${GREEN}🎊 Nuclear sync and Git hooks installation complete!${NC}"
    
    exit 0
else
    echo "${RED}⚠️  ${FAIL_COUNT} repositories had issues. Check output above.${NC}"
    exit 1
fi