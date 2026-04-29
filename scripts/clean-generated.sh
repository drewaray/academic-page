#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

DRY_RUN=true
if [[ "${1:-}" == "--apply" ]]; then
  DRY_RUN=false
elif [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'USAGE'
Usage:
  ./scripts/clean-generated.sh          # preview generated files to remove
  ./scripts/clean-generated.sh --apply  # remove generated files

Removes disposable Quarto output, local render caches, macOS metadata, and
duplicate listing/feed artifacts. It does not remove source files, course
materials, photos, or Git history.
USAGE
  exit 0
elif [[ $# -gt 0 ]]; then
  echo "Error: unknown option: $1" >&2
  echo "Run ./scripts/clean-generated.sh --help for usage." >&2
  exit 2
fi

paths=()

add_if_exists() {
  local path="$1"
  [[ -e "$path" ]] && paths+=("$path")
}

add_matches() {
  while IFS= read -r -d '' path; do
    paths+=("$path")
  done < <(
    find . \
      -path ./.git -prune -o \
      -path ./.quarto -prune -o \
      -path ./docs -prune -o \
      \( "$@" \) \
      -print0
  )
}

add_if_exists ".quarto"
add_if_exists "docs"

add_matches \
  -name ".DS_Store" -o \
  -name "._*" -o \
  -name "*-listing*.json" -o \
  -name "*.feed-full-staged" -o \
  -name "*.quarto_ipynb"

if [[ ${#paths[@]} -eq 0 ]]; then
  echo "No generated files found."
  exit 0
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Generated files/directories that would be removed:"
  printf '  %s\n' "${paths[@]}"
  echo
  echo "Run ./scripts/clean-generated.sh --apply to remove them."
  exit 0
fi

echo "Removing generated files/directories:"
printf '  %s\n' "${paths[@]}"
rm -rf -- "${paths[@]}"
echo "Cleanup complete."
