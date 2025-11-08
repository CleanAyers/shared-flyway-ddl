#!/usr/bin/env bash
set -euo pipefail

# Unified Flyway Sync Script - Replaces all three sync scripts
# Handles: publish parent → sync children → nuclear reset if needed
# Usage: ./unified_flyway_sync.sh [OPTIONS]

# Colors for output
RED=$'\033[31m'; GREEN=$'\033[32m'; YEL=$'\033[33m'; CYAN=$'\033[36m'; BOLD=$'\033[1m'; NC=$'\033[0m'

# Configuration
PARENT_SHARED_PATH="read-write-flyway-files"    # Source directory in parent
CHILD_SUBTREE_PATH="read-write-flyway-files"    # Target directory in children (same name!)
DELIVERY_BRANCH="ro-shared-ddl"                 # Parent delivery branch
CHILD_REPOS=("flyway-1-pipeline" "flyway-1-grants" "flyway-2-pipeline" "flyway-2-grants")

# Script options
OPERATION=""
AUTO_COMMIT=0
AUTO_STASH=0
FORCE_NUCLEAR=0
CHILD_BRANCH="main"
PARENT_BRANCH="$DELIVERY_BRANCH"

# Help function
show_help() {
    cat << 'EOF'
Unified Flyway Sync Script

OPERATIONS:
  publish     - Export parent content to delivery branch
  sync        - Sync all children with parent changes  
  nuclear     - Force reset all children (DESTRUCTIVE)
  full        - Complete workflow: publish → sync
  status      - Check sync status (read-only)

OPTIONS:
  --auto-commit      Auto-commit dirty working trees
  --auto-stash       Auto-stash dirty working trees  
  --force-nuclear    Skip confirmation for nuclear option
  --child-branch B   Target branch in children (default: main)
  --help            Show this help

EXAMPLES:
  ./unified_flyway_sync.sh status
  ./unified_flyway_sync.sh publish
  ./unified_flyway_sync.sh sync --auto-commit
  ./unified_flyway_sync.sh full --auto-commit
  ./unified_flyway_sync.sh nuclear --force-nuclear

WORKFLOW:
  1. Make changes in read-write-flyway-files/
  2. Run: ./unified_flyway_sync.sh full --auto-commit
  3. All children will be synchronized automatically
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        publish|sync|nuclear|full|status) 
            if [[ -n "$OPERATION" ]]; then
                echo "${RED}ERROR: Multiple operations specified${NC}"
                exit 1
            fi
            OPERATION="$1"; shift;;
        --auto-commit) AUTO_COMMIT=1; shift;;
        --auto-stash) AUTO_STASH=1; shift;;
        --force-nuclear) FORCE_NUCLEAR=1; shift;;
        --child-branch) CHILD_BRANCH="$2"; shift 2;;
        --help) show_help; exit 0;;
        *) echo "${RED}ERROR: Unknown argument: $1${NC}"; show_help; exit 1;;
    esac
done

# Validate operation
if [[ -z "$OPERATION" ]]; then
    echo "${RED}ERROR: No operation specified${NC}"
    show_help
    exit 1
fi

# Validate conflicting options
if [[ $AUTO_COMMIT -eq 1 && $AUTO_STASH -eq 1 ]]; then
    echo "${RED}ERROR: Cannot use both --auto-commit and --auto-stash${NC}"
    exit 1
fi

# Auto-detect directories
git rev-parse --show-toplevel >/dev/null 2>&1 || { 
    echo "${RED}ERROR: Must run from inside parent repository${NC}"; exit 1; 
}
PARENT_DIR="$(git rev-parse --show-toplevel)"
BASE_DIR="$(dirname "$PARENT_DIR")"
PARENT_URL="$(git remote get-url origin)"

echo "${CYAN}🚀 Unified Flyway Sync${NC}"
echo "${CYAN}Operation:${NC} $OPERATION"
echo "${CYAN}Parent:${NC} $PARENT_DIR"
echo "${CYAN}Children base:${NC} $BASE_DIR"
echo "${CYAN}Source path:${NC} $PARENT_SHARED_PATH"
echo "${CYAN}Target path:${NC} $CHILD_SUBTREE_PATH"
echo

# =============================================================================
# FUNCTION: Publish parent content to delivery branch
# =============================================================================
publish_shared() {
    echo "${BOLD}${CYAN}📤 PUBLISHING PARENT CONTENT${NC}"
    
    cd "$PARENT_DIR"
    
    # Ensure we're on main and up to date
    git switch main
    git pull --ff-only origin main || true
    
    # Validate source path exists and has content
    if [[ ! -d "$PARENT_SHARED_PATH" ]]; then
        echo "${RED}ERROR: Source path '$PARENT_SHARED_PATH' not found${NC}"
        exit 1
    fi
    
    if ! git ls-files -- "$PARENT_SHARED_PATH" | grep -q .; then
        echo "${RED}ERROR: No tracked files in '$PARENT_SHARED_PATH'${NC}"
        exit 1
    fi
    
    echo "✓ Source validation passed"
    
    # Use subtree split to preserve directory structure
    echo "🔄 Creating subtree split for $PARENT_SHARED_PATH..."
    
    # Clean up existing branch
    git branch -D "$DELIVERY_BRANCH" 2>/dev/null || true
    
    # Create subtree split (this preserves the directory structure)
    if git subtree split --prefix="$PARENT_SHARED_PATH" --branch "$DELIVERY_BRANCH"; then
        echo "✅ Subtree split successful"
    else
        echo "${RED}ERROR: Subtree split failed${NC}"
        exit 1
    fi
    
    # Push delivery branch
    echo "🚀 Pushing delivery branch..."
    git push -u origin "$DELIVERY_BRANCH" --force
    
    # Return to main
    git switch main
    
    echo "${GREEN}✅ PUBLISH COMPLETE${NC}"
    echo
}

# =============================================================================
# FUNCTION: Sync all children with parent
# =============================================================================
sync_children() {
    echo "${BOLD}${CYAN}🔄 SYNCING CHILDREN${NC}"
    
    cd "$PARENT_DIR"
    
    # Get parent tree hash
    git fetch --all --tags --prune >/dev/null 2>&1 || true
    if ! git show-ref --verify --quiet "refs/heads/$DELIVERY_BRANCH"; then
        if git show-ref --verify --quiet "refs/remotes/origin/$DELIVERY_BRANCH"; then
            git branch --track "$DELIVERY_BRANCH" "origin/$DELIVERY_BRANCH" >/dev/null 2>&1 || true
        else
            echo "${RED}ERROR: Delivery branch '$DELIVERY_BRANCH' not found. Run 'publish' first.${NC}"
            exit 1
        fi
    fi
    
    PARENT_TREE="$(git rev-parse "$DELIVERY_BRANCH^{tree}")"
    echo "Parent tree: $PARENT_TREE"
    echo
    
    FAIL_COUNT=0
    
    for repo in "${CHILD_REPOS[@]}"; do
        CHILD_DIR="$BASE_DIR/$repo"
        echo "${CYAN}-- $repo${NC}"
        
        # Clone if missing
        if [[ ! -d "$CHILD_DIR/.git" ]]; then
            echo "  ${YEL}CLONE:${NC} Repository not found, cloning..."
            gh repo clone "CleanAyers/$repo" "$CHILD_DIR" || {
                echo "  ${RED}ERROR:${NC} Failed to clone repository"
                ((FAIL_COUNT++))
                continue
            }
        fi
        
        cd "$CHILD_DIR"
        
        # Handle dirty working tree
        if [[ -n "$(git status --porcelain)" ]]; then
            if [[ $AUTO_COMMIT -eq 1 ]]; then
                echo "  ${YEL}AUTO-COMMIT:${NC} Committing changes..."
                git add -A
                git commit -m "chore: auto-commit before sync ($(date +%Y-%m-%d))"
            elif [[ $AUTO_STASH -eq 1 ]]; then
                echo "  ${YEL}AUTO-STASH:${NC} Stashing changes..."
                git stash push -m "auto-stash before sync $(date +%Y%m%d-%H%M%S)"
            else
                echo "  ${RED}ERROR:${NC} Working tree dirty. Use --auto-commit or --auto-stash"
                ((FAIL_COUNT++))
                continue
            fi
        fi
        
        # Switch to target branch and update
        git fetch --all --tags --prune >/dev/null 2>&1 || true
        git switch "$CHILD_BRANCH" || {
            echo "  ${RED}ERROR:${NC} Cannot switch to branch '$CHILD_BRANCH'"
            ((FAIL_COUNT++))
            continue
        }
        git pull --ff-only origin "$CHILD_BRANCH" || true
        
        # Setup parent remote
        if ! git remote | grep -qx "parent-shared"; then
            echo "  ${CYAN}REMOTE:${NC} Adding parent remote"
            git remote add "parent-shared" "$PARENT_URL"
        fi
        git fetch parent-shared "$DELIVERY_BRANCH"
        
        # Check current subtree state
        if git cat-file -e "HEAD:$CHILD_SUBTREE_PATH" 2>/dev/null; then
            CHILD_TREE="$(git rev-parse "HEAD:$CHILD_SUBTREE_PATH")"
        else
            CHILD_TREE=""
        fi
        
        # Sync if needed
        if [[ "$CHILD_TREE" == "$PARENT_TREE" && -n "$CHILD_TREE" ]]; then
            echo "  ${GREEN}OK:${NC} up to date (tree ${CHILD_TREE:0:12}...)"
        else
            echo "  ${YEL}SYNC:${NC} child=${CHILD_TREE:0:12} parent=${PARENT_TREE:0:12}"
            
            if [[ -z "$CHILD_TREE" ]]; then
                echo "  ${CYAN}ADD:${NC} First-time subtree add"
                git subtree add --prefix="$CHILD_SUBTREE_PATH" "parent-shared" "$DELIVERY_BRANCH" --squash
            else
                echo "  ${CYAN}PULL:${NC} Updating existing subtree"
                git subtree pull --prefix="$CHILD_SUBTREE_PATH" "parent-shared" "$DELIVERY_BRANCH" --squash
            fi
            
            # Commit if changes made
            if ! git diff --quiet; then
                git add -A
                git commit -m "chore(shared): sync $CHILD_SUBTREE_PATH from $DELIVERY_BRANCH"
            fi
            
            # Push changes
            echo "  ${CYAN}PUSH:${NC} Uploading to GitHub..."
            git push origin "$CHILD_BRANCH"
            
            # Verify sync
            CHILD_TREE_AFTER="$(git rev-parse "HEAD:$CHILD_SUBTREE_PATH")"
            if [[ "$CHILD_TREE_AFTER" == "$PARENT_TREE" ]]; then
                echo "  ${GREEN}✓ SYNCED:${NC} now up to date (tree ${CHILD_TREE_AFTER:0:12}...)"
            else
                echo "  ${RED}✗ FAILED:${NC} sync verification failed"
                ((FAIL_COUNT++))
            fi
        fi
        
        echo
    done
    
    if [[ $FAIL_COUNT -eq 0 ]]; then
        echo "${GREEN}✅ ALL CHILDREN SYNCHRONIZED${NC}"
    else
        echo "${RED}⚠️  $FAIL_COUNT repositories had sync issues${NC}"
        return 1
    fi
    echo
}

# =============================================================================
# FUNCTION: Nuclear reset all children (destructive)
# =============================================================================
nuclear_reset() {
    echo "${BOLD}${RED}☢️  NUCLEAR RESET${NC}"
    echo "${RED}This will DESTROY any local changes in $CHILD_SUBTREE_PATH folders!${NC}"
    
    if [[ $FORCE_NUCLEAR -ne 1 ]]; then
        echo
        read -p "Type 'NUKE' to confirm destructive operation: " confirmation
        if [[ "$confirmation" != "NUKE" ]]; then
            echo "${YEL}Operation cancelled${NC}"
            return 0
        fi
    fi
    
    echo
    echo "${CYAN}Starting nuclear reset...${NC}"
    
    FAIL_COUNT=0
    
    for repo in "${CHILD_REPOS[@]}"; do
        CHILD_DIR="$BASE_DIR/$repo"
        echo "${CYAN}-- $repo${NC}"
        
        if [[ ! -d "$CHILD_DIR/.git" ]]; then
            echo "  ${YEL}SKIP:${NC} Not a git repository"
            continue
        fi
        
        cd "$CHILD_DIR"
        
        # Stash any changes
        if [[ -n "$(git status --porcelain)" ]]; then
            echo "  ${YEL}STASH:${NC} Preserving uncommitted changes"
            git stash push -m "nuclear-reset-stash-$(date +%Y%m%d-%H%M%S)"
        fi
        
        # Ensure clean state
        git fetch --all --prune >/dev/null 2>&1 || true
        git switch "$CHILD_BRANCH" >/dev/null 2>&1 || {
            echo "  ${RED}ERROR:${NC} Cannot switch to branch '$CHILD_BRANCH'"
            ((FAIL_COUNT++))
            continue
        }
        git pull --ff-only origin "$CHILD_BRANCH" || true
        
        # Setup parent remote if needed
        if ! git remote | grep -qx "parent-shared"; then
            git remote add "parent-shared" "$PARENT_URL"
        fi
        git fetch parent-shared "$DELIVERY_BRANCH"
        
        # Nuclear removal of subtree
        if [[ -d "$CHILD_SUBTREE_PATH" ]]; then
            echo "  ${RED}NUKE:${NC} Removing $CHILD_SUBTREE_PATH"
            git rm -rf "$CHILD_SUBTREE_PATH" >/dev/null 2>&1 || rm -rf "$CHILD_SUBTREE_PATH"
            if [[ -n "$(git status --porcelain)" ]]; then
                git add -A
                git commit --no-verify -m "nuclear: remove $CHILD_SUBTREE_PATH before reset"
            fi
        fi
        
        # Clean any subtree config
        git config --unset-all "subtree.$CHILD_SUBTREE_PATH.url" >/dev/null 2>&1 || true
        git config --unset-all "subtree.$CHILD_SUBTREE_PATH.branch" >/dev/null 2>&1 || true
        
        # Add fresh subtree
        echo "  ${GREEN}ADD:${NC} Fresh subtree from parent"
        if git subtree add --prefix="$CHILD_SUBTREE_PATH" "parent-shared" "$DELIVERY_BRANCH" --squash; then
            echo "  ${GREEN}✓ Nuclear reset successful${NC}"
            
            # Push changes
            git push origin "$CHILD_BRANCH"
        else
            echo "  ${RED}✗ Nuclear reset failed${NC}"
            ((FAIL_COUNT++))
        fi
        
        echo
    done
    
    if [[ $FAIL_COUNT -eq 0 ]]; then
        echo "${GREEN}☢️  NUCLEAR RESET COMPLETE - All repositories reset${NC}"
    else
        echo "${RED}⚠️  $FAIL_COUNT repositories failed nuclear reset${NC}"
        return 1
    fi
}

# =============================================================================
# FUNCTION: Status check (read-only)
# =============================================================================
status_check() {
    echo "${BOLD}${CYAN}📊 STATUS CHECK${NC}"
    
    cd "$PARENT_DIR"
    
    # Check if delivery branch exists
    git fetch --all --prune >/dev/null 2>&1 || true
    if ! git show-ref --verify --quiet "refs/heads/$DELIVERY_BRANCH" && 
       ! git show-ref --verify --quiet "refs/remotes/origin/$DELIVERY_BRANCH"; then
        echo "${YEL}⚠️  Delivery branch '$DELIVERY_BRANCH' not found${NC}"
        echo "Run: ./unified_flyway_sync.sh publish"
        return 1
    fi
    
    # Get parent tree hash
    if ! git show-ref --verify --quiet "refs/heads/$DELIVERY_BRANCH"; then
        git branch --track "$DELIVERY_BRANCH" "origin/$DELIVERY_BRANCH" >/dev/null 2>&1 || true
    fi
    PARENT_TREE="$(git rev-parse "$DELIVERY_BRANCH^{tree}")"
    echo "Parent tree: $PARENT_TREE"
    echo
    
    # Check each child
    ALL_SYNCED=1
    for repo in "${CHILD_REPOS[@]}"; do
        CHILD_DIR="$BASE_DIR/$repo"
        echo "${CYAN}-- $repo${NC}"
        
        if [[ ! -d "$CHILD_DIR/.git" ]]; then
            echo "  ${YEL}MISSING:${NC} Repository not cloned"
            ALL_SYNCED=0
            continue
        fi
        
        cd "$CHILD_DIR"
        
        if git cat-file -e "HEAD:$CHILD_SUBTREE_PATH" 2>/dev/null; then
            CHILD_TREE="$(git rev-parse "HEAD:$CHILD_SUBTREE_PATH")"
            if [[ "$CHILD_TREE" == "$PARENT_TREE" ]]; then
                echo "  ${GREEN}✓ SYNCED${NC} (tree ${CHILD_TREE:0:12}...)"
            else
                echo "  ${RED}✗ OUT-OF-DATE${NC} (child: ${CHILD_TREE:0:12} parent: ${PARENT_TREE:0:12})"
                ALL_SYNCED=0
            fi
        else
            echo "  ${YEL}⚠️  NO SUBTREE${NC} ($CHILD_SUBTREE_PATH missing)"
            ALL_SYNCED=0
        fi
    done
    
    echo
    if [[ $ALL_SYNCED -eq 1 ]]; then
        echo "${GREEN}✅ ALL REPOSITORIES IN SYNC${NC}"
    else
        echo "${YEL}⚠️  SYNC REQUIRED${NC}"
        echo "Run: ./unified_flyway_sync.sh sync --auto-commit"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

case "$OPERATION" in
    "publish")
        publish_shared
        ;;
    "sync")
        sync_children
        ;;
    "nuclear")
        nuclear_reset
        ;;
    "full")
        publish_shared
        sync_children
        ;;
    "status")
        status_check
        ;;
    *)
        echo "${RED}ERROR: Unknown operation: $OPERATION${NC}"
        exit 1
        ;;
esac

echo "${GREEN}🎉 Operation '$OPERATION' completed successfully${NC}"