#!/usr/bin/env bash
set -euo pipefail

# CONFIG
SPLIT_PATH="shared/shared-ddl"
SPLIT_BRANCH="shared-ddl-branch"
REMOTE="origin"
BASE_BRANCH="main"

echo "== Parent: publishing ${SPLIT_PATH} as ${SPLIT_BRANCH} from ${BASE_BRANCH} =="

# Ensure we’re on main with latest
git switch "${BASE_BRANCH}"
git pull --ff-only "${REMOTE}" "${BASE_BRANCH}"

# Sanity checks
if ! git ls-files -- "${SPLIT_PATH}" | grep -q .; then
  echo "ERROR: No tracked files under ${SPLIT_PATH}. Commit something first."
  exit 1
fi

if ! git log --oneline -- "${SPLIT_PATH}" | head -n1 >/dev/null; then
  echo "ERROR: No commits touch ${SPLIT_PATH}. Commit something first."
  exit 1
fi

# Produce/refresh split branch (robust form)
git subtree split --prefix="${SPLIT_PATH}" --branch "${SPLIT_BRANCH}" "${BASE_BRANCH}" || {
  echo "subtree split had trouble; trying force re-point"
  SHA="$(git subtree split -P "${SPLIT_PATH}")"
  git branch -f "${SPLIT_BRANCH}" "${SHA}"
}

# Push delivery branch
git push -u "${REMOTE}" "${SPLIT_BRANCH}" --force

echo "== Done. Pushed ${SPLIT_BRANCH} to ${REMOTE}. =="
echo "Next: run a child sync script to pull into each child repo."
