#!/usr/bin/env bash
set -euo pipefail

REMOTE=origin
SRC_BRANCH=main
SRC_PATH=shared          # your shared files now live directly under shared/
DELIVERY=ro-shared-ddl   # delivery branch

echo "== Parent: publish ${SRC_PATH}/ → ${DELIVERY} from ${SRC_BRANCH} =="

git switch "${SRC_BRANCH}"
git pull --ff-only "${REMOTE}" "${SRC_BRANCH}"

# sanity checks
git ls-files -- "${SRC_PATH}" >/dev/null || { echo "No tracked files in ${SRC_PATH}/"; exit 1; }
git log -1 -- "${SRC_PATH}" >/dev/null || { echo "No commits touch ${SRC_PATH}/"; exit 1; }

# try subtree split (explicit range helps with caches)
set +e
git subtree split --prefix="${SRC_PATH}" --branch "${DELIVERY}" "${SRC_BRANCH}~999999..${SRC_BRANCH}"
RC=$?
set -e

# fallback: orphan rebuild if subtree split is stubborn
if [[ $RC -ne 0 ]]; then
  echo "subtree split balked — rebuilding delivery branch (orphan)…"
  git checkout --orphan "${DELIVERY}"
  git rm -rf . 2>/dev/null || true
  git checkout "${SRC_BRANCH}" -- "${SRC_PATH}"
  rsync -a "${SRC_PATH}/" ./
  git rm -r "${SRC_PATH}" 2>/dev/null || true
  git add -A
  git commit -m "build: export ${SRC_PATH}/ for delivery"
fi

git push -u "${REMOTE}" "${DELIVERY}" --force
git switch "${SRC_BRANCH}"
echo "== Done: pushed ${DELIVERY} =="