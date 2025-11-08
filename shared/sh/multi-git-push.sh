#!/usr/bin/env bash
set -euo pipefail

# Batch "git add/commit/push" across multiple repos.
# Usage:
#   ./multi_git_push.sh --msg "chore: sync" [--base /path/to/Flyway-Repo-Structure] [--branch main] [--pull-first] [--include-parent] [--only CHILD1 CHILD2 ...]

BASE_DIR="${HOME}/Documents/Codex/Work/Flyway-Repo-Structure"
BRANCH="main"
MSG=""
PULL_FIRST=0
INCLUDE_PARENT=0
ONLY_REPOS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --msg)         MSG="${2-}"; shift 2;;
    --branch)      BRANCH="${2-}"; shift 2;;
    --base)        BASE_DIR="${2-}"; shift 2;;
    --pull-first)  PULL_FIRST=1; shift;;
    --include-parent) INCLUDE_PARENT=1; shift;;
    --only)        shift; while [[ $# -gt 0 && "$1" != --* ]]; do ONLY_REPOS+=("$1"); shift; done;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

if [[ -z "$MSG" ]]; then
  echo "ERROR: --msg \"commit message\" is required"; exit 1
fi

# Default repo set
REPOS=( "flyway-1-pipeline" "flyway-1-grants" "flyway-2-pipeline" "flyway-2-grants" )
[[ $INCLUDE_PARENT -eq 1 ]] && REPOS=( "shared-flyway-ddl" "${REPOS[@]}" )
[[ ${#ONLY_REPOS[@]} -gt 0 ]] && REPOS=( "${ONLY_REPOS[@]}" )

echo "Base:   $BASE_DIR"
echo "Branch: $BRANCH"
echo "Repos:  ${REPOS[*]}"
echo

fail=0

for repo in "${REPOS[@]}"; do
  DIR="${BASE_DIR}/${repo}"
  echo "----> ${repo}"

  if [[ ! -d "${DIR}/.git" ]]; then
    echo "  SKIP: not a git repo at ${DIR}"
    echo
    continue
  fi

  cd "${DIR}"

  # Ensure branch exists locally; try to switch; create if needed
  if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
    git switch "${BRANCH}" >/dev/null
  else
    # Try tracking remote branch or create new
    if git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}"; then
      git switch -c "${BRANCH}" --track "origin/${BRANCH}" >/dev/null
    else
      git switch -c "${BRANCH}" >/dev/null
    fi
  fi

  if [[ $PULL_FIRST -eq 1 ]]; then
    git fetch --all --tags --prune >/dev/null 2>&1 || true
    git pull --ff-only origin "${BRANCH}" || true
  fi

  if [[ -z "$(git status --porcelain)" ]]; then
    echo "  No changes to commit."
  else
    git add -A
    if git diff --cached --quiet; then
      echo "  Nothing staged after add; skipping commit."
    else
      git commit -m "${MSG}" || true
    fi
  fi

  # Push (set upstream if needed)
  if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
    git push origin "${BRANCH}" || { echo "  PUSH FAILED"; fail=1; }
  else
    git push -u origin "${BRANCH}" || { echo "  PUSH FAILED"; fail=1; }
  fi

  echo
done

[[ $fail -eq 0 ]] && echo "All pushes done." || { echo "Some pushes failed."; exit 1; }
