#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "Repository size summary"
echo "======================="
du -sh . .git pages files _extensions 2>/dev/null || true

echo
echo "Git object database"
echo "==================="
git count-objects -vH

echo
echo "Largest working-tree files"
echo "=========================="
find . \
  -path ./.git -prune -o \
  -type f -print0 |
  xargs -0 du -h |
  sort -hr |
  sed -n '1,25p'

echo
echo "Largest reachable Git blobs"
echo "==========================="
git rev-list --objects --all |
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
  awk '$1 == "blob" {print $3, $4}' |
  sort -nr |
  sed -n '1,25p'
