#!/usr/bin/env bash
# Purge community-api/ from all git history (destructive).
# Run only after backing up the repo and coordinating with collaborators.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v git-filter-repo >/dev/null 2>&1; then
  echo "Install git-filter-repo first: brew install git-filter-repo"
  exit 1
fi

echo "This rewrites history and invalidates all commit SHAs."
echo "After running, force-push with: git push origin --force --all"
read -r -p "Continue? [y/N] " answer
if [[ "${answer:-}" != "y" && "${answer:-}" != "Y" ]]; then
  echo "Aborted."
  exit 1
fi

git filter-repo --path community-api --invert-paths --force

echo "Done. Review with: git log --oneline -5"
echo "Then: git push origin --force --all && git push origin --force --tags"
echo "Request GitHub support to purge unreachable objects if blobs must be unrecoverable."
