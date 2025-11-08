#!/usr/bin/env bash
set -euo pipefail

# CONFIG
PARENT_REMOTE="parent-shared"  # the remote pointing to the parent repo
PARENT_URL="git@github.com:CleanAyers/shared-flyway-ddl.git"
DELIVERY_BRANCH="shared-ddl-branch"
PREFIX_DIR="shared"            # where shared files live in this child
PUSH_REMOTE="origin"
TARGET_BRANCH="main"

echo "== Child: syncing ${PREFIX_DIR}/ from ${PARENT_REMOTE}/${DELIVERY_BRANCH} =="

# Ensure repo state
git fetch --all --tags
git switch "${TARGET_BRANCH}"
git pull --ff-only "${PUSH_REMOTE}" "${TARGET_BRANCH}"

# Add parent remote if missing
if ! git remote | grep -qx "${PARENT_REMOTE}"; then
  echo "Adding remote ${PARENT_REMOTE} -> ${PARENT_URL}"
  git remote add "${PARENT_REMOTE}" "${PARENT_URL}"
fi

# Fetch delivery branch
git fetch "${PARENT_REMOTE}" "${DELIVERY_BRANCH}"

# Initial add if folder empty, else pull update
if [[ ! -d "${PREFIX_DIR}" ]] || [[ -z "$(ls -A "${PREFIX_DIR}" 2>/dev/null || true)" ]]; then
  echo "Subtree add → ${PREFIX_DIR}/"
  git subtree add --prefix="${PREFIX_DIR}" "${PARENT_REMOTE}" "${DELIVERY_BRANCH}" --squash
else
  echo "Subtree pull → ${PREFIX_DIR}/"
  git subtree pull --prefix="${PREFIX_DIR}" "${PARENT_REMOTE}" "${DELIVERY_BRANCH}" --squash
fi

# Commit/push if changed
if ! git diff --quiet; then
  git add -A
  git commit -m "chore(shared): sync from parent ${DELIVERY_BRANCH}"
  git push "${PUSH_REMOTE}" "${TARGET_BRANCH}"
  echo "== Changes pushed to ${PUSH_REMOTE}/${TARGET_BRANCH} =="
else
  echo "== No changes to commit. =="
fi