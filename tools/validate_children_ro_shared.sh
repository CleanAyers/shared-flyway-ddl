#!/usr/bin/env bash
set -euo pipefail

# Run from the PARENT repo root (shared-flyway-ddl)
# Usage:
#   ./validate_children_ro_shared.sh
#   ./validate_children_ro_shared.sh --fix
#   ./validate_children_ro_shared.sh --fix --auto-commit
#   ./validate_children_ro_shared.sh --fix --auto-stash
#   ./validate_children_ro_shared.sh --fix --base "/path/to/children" --child-branch main --parent-branch ro-shared-ddl

FIX=0
BASE_OVERRIDE=""
CHILD_BRANCH="main"
PARENT_DELIVERY_BRANCH="ro-shared-ddl"
AUTO_COMMIT=0
AUTO_STASH=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fix) FIX=1; shift;;
    --auto-commit) AUTO_COMMIT=1; shift;;
    --auto-stash) AUTO_STASH=1; shift;;
    --base) 
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --base requires a value"; exit 2
      fi
      BASE_OVERRIDE="$2"; shift 2;;
    --child-branch) 
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --child-branch requires a value"; exit 2
      fi
      CHILD_BRANCH="$2"; shift 2;;
    --parent-branch)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --parent-branch requires a value"; exit 2
      fi
      PARENT_DELIVERY_BRANCH="$2"; shift 2;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

# Validate conflicting options
if [[ $AUTO_COMMIT -eq 1 && $AUTO_STASH -eq 1 ]]; then
  echo "ERROR: Cannot use both --auto-commit and --auto-stash"
  exit 2
fi

# Colors
RED=$'\033[31m'; GREEN=$'\033[32m'; YEL=$'\033[33m'; CYAN=$'\033[36m'; NC=$'\033[0m'

# Auto-detect parent dir (must run inside parent)
git rev-parse --show-toplevel >/dev/null 2>&1 || { echo "ERROR: run from parent repo root"; exit 2; }
PARENT_DIR="$(git rev-parse --show-toplevel)"
cd "$PARENT_DIR"

# Where the children repos live (default: parent’s parent directory)
if [[ -n "$BASE_OVERRIDE" ]]; then
  BASE_DIR="$BASE_OVERRIDE"
else
  BASE_DIR="$(dirname "$PARENT_DIR")"
fi

# Config
CHILD_REPOS=("flyway-1-pipeline" "flyway-1-grants" "flyway-2-pipeline" "flyway-2-grants")
DELIVERY_BRANCH="$PARENT_DELIVERY_BRANCH"    # parent delivery branch (now configurable)
PREFIX_DIR="ro-shared-ddl"                   # subtree folder inside each child
PARENT_REMOTE_NAME="parent-shared"           # name to use inside each child for the parent remote
PARENT_URL="$(git remote get-url origin)"

echo "${CYAN}Parent:${NC} $PARENT_DIR"
echo "${CYAN}Children base:${NC} $BASE_DIR"
echo "${CYAN}Delivery branch:${NC} $DELIVERY_BRANCH"
echo "${CYAN}Child branch:${NC} $CHILD_BRANCH"
echo

# Ensure parent delivery branch exists locally (or track it) and get its TREE
git fetch --all --tags --prune >/dev/null 2>&1 || true
if ! git show-ref --verify --quiet "refs/heads/${DELIVERY_BRANCH}"; then
  if git show-ref --verify --quiet "refs/remotes/origin/${DELIVERY_BRANCH}"; then
    git branch --track "${DELIVERY_BRANCH}" "origin/${DELIVERY_BRANCH}" >/dev/null 2>&1 || true
  else
    echo "${RED}ERROR:${NC} Parent delivery branch '${DELIVERY_BRANCH}' not found. Publish it first."
    exit 2
  fi
fi
PARENT_TREE="$(git rev-parse "${DELIVERY_BRANCH}^{tree}")"
echo "Parent delivery branch tree: ${PARENT_TREE}"
echo

FAIL=0

for repo in "${CHILD_REPOS[@]}"; do
  CHILD_DIR="${BASE_DIR}/${repo}"
  echo "${CYAN}-- ${repo}${NC}"

  if [[ ! -d "${CHILD_DIR}/.git" ]]; then
    echo "  ${YEL}WARN:${NC} not found at ${CHILD_DIR}; cloning..."
    gh repo clone "CleanAyers/${repo}" "${CHILD_DIR}"
  fi

  cd "${CHILD_DIR}"

  # Safety: ensure clean tree or handle automatically
  if [[ -n "$(git status --porcelain)" ]]; then
    if [[ $AUTO_COMMIT -eq 1 ]]; then
      echo "  ${YEL}WARN:${NC} working tree dirty, auto-committing changes..."
      git add -A
      git commit -m "chore: auto-commit changes before shared sync"
    elif [[ $AUTO_STASH -eq 1 ]]; then
      echo "  ${YEL}WARN:${NC} working tree dirty, stashing changes..."
      git stash push -m "auto-stash before shared sync $(date +%Y%m%d-%H%M%S)"
    else
      echo "  ${RED}ERROR:${NC} working tree not clean. Options:"
      echo "    1. Commit changes: git add -A && git commit -m 'your message'"
      echo "    2. Stash changes: git stash"
      echo "    3. Use --auto-commit to auto-commit"
      echo "    4. Use --auto-stash to auto-stash"
      FAIL=1; echo; continue
    fi
  fi

  git fetch --all --tags --prune >/dev/null 2>&1 || true
  git switch "${CHILD_BRANCH}"
  git pull --ff-only origin "${CHILD_BRANCH}" || true

  # Ensure parent remote exists in child
  if ! git remote | grep -qx "${PARENT_REMOTE_NAME}"; then
    echo "  Adding remote '${PARENT_REMOTE_NAME}' -> ${PARENT_URL}"
    git remote add "${PARENT_REMOTE_NAME}" "${PARENT_URL}"
  fi

  git fetch "${PARENT_REMOTE_NAME}" "${DELIVERY_BRANCH}"

  # Determine child subtree tree (if present)
  if git cat-file -e "HEAD:${PREFIX_DIR}" 2>/dev/null; then
    CHILD_TREE="$(git rev-parse "HEAD:${PREFIX_DIR}")"
  else
    CHILD_TREE=""
  fi

  if [[ "${CHILD_TREE}" == "${PARENT_TREE}" && -n "${CHILD_TREE}" ]]; then
    echo "  ${GREEN}OK:${NC} up to date (tree ${CHILD_TREE})"
  else
    echo "  ${RED}OUT-OF-DATE:${NC} child=${CHILD_TREE:-<missing>}  parent=${PARENT_TREE}"
    if [[ $FIX -eq 1 ]]; then
      # Add or pull
      if [[ -z "${CHILD_TREE}" ]]; then
        echo "  Subtree add → ${PREFIX_DIR}/"
        git subtree add --prefix="${PREFIX_DIR}" "${PARENT_REMOTE_NAME}" "${DELIVERY_BRANCH}" --squash
      else
        echo "  Subtree pull → ${PREFIX_DIR}/"
        git subtree pull --prefix="${PREFIX_DIR}" "${PARENT_REMOTE_NAME}" "${DELIVERY_BRANCH}" --squash
      fi

      # Commit and push if anything changed
      if ! git diff --quiet; then
        git add -A
        git commit -m "chore(shared): sync ${PREFIX_DIR} from ${DELIVERY_BRANCH}"
      fi
      git push origin "${CHILD_BRANCH}"

      # Re-check tree to confirm
      CHILD_TREE_AFTER="$(git rev-parse "HEAD:${PREFIX_DIR}")"
      if [[ "${CHILD_TREE_AFTER}" == "${PARENT_TREE}" ]]; then
        echo "  ${GREEN}FIXED:${NC} now up to date (tree ${CHILD_TREE_AFTER})"
      else
        echo "  ${RED}STILL OUT-OF-DATE:${NC} child=${CHILD_TREE_AFTER} parent=${PARENT_TREE}"
        FAIL=1
      fi
    else
      FAIL=1
      echo "  Hint: rerun with --fix to update this repo automatically."
    fi
  fi

  echo
done

if [[ $FAIL -ne 0 ]]; then
  echo "${RED}Some children are missing or out of date.${NC}"
  [[ $FIX -eq 1 ]] || echo "Run with ${CYAN}--fix${NC} to auto-update."
  exit 1
fi

echo "${GREEN}All children match the parent delivery branch.${NC}"
