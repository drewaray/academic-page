#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-${DEPLOY_TARGET:-}}"

if [[ -z "$TARGET" ]]; then
  cat >&2 <<'USAGE'
Usage:
  ./scripts/deploy-site.sh user@host:/remote/site/path/

Or:
  DEPLOY_TARGET=user@host:/remote/site/path/ ./scripts/deploy-site.sh

Optional:
  PHOTO_ASSET_BASE=https://example.edu/~user/pages/Photos/ ./scripts/deploy-site.sh ...
  DEPLOY_INCLUDE_PHOTOS=1 ./scripts/deploy-site.sh ...
  DEPLOY_INCLUDE_COURSE_ARCHIVES=1 ./scripts/deploy-site.sh ...
  DEPLOY_RSYNC_RSH='ssh -i ~/.ssh/key -o IdentitiesOnly=yes' ./scripts/deploy-site.sh ...
  DEPLOY_SKIP_CLEAN=1 ./scripts/deploy-site.sh ...
USAGE
  exit 2
fi

if [[ "$TARGET" == *"://"* ]]; then
  cat >&2 <<'ERROR'
Error: deploy target must be an SSH/rsync path, not an http(s) URL.

Use:
  user@host:/remote/site/path/

For this UCSB site, that is probably:
  ortegaray@web.math.ucsb.edu:/home/grad/ortegaray/public_html/
ERROR
  exit 2
fi

if [[ "$TARGET" != *:* ]]; then
  cat >&2 <<'ERROR'
Error: deploy target is missing the colon before the remote path.

Use:
  user@host:/remote/site/path/

Example:
  ortegaray@web.math.ucsb.edu:/home/grad/ortegaray/public_html/
ERROR
  exit 2
fi

if ! command -v quarto >/dev/null 2>&1; then
  echo "Error: quarto is required to render the site." >&2
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "Error: rsync is required for SSH deployment." >&2
  exit 1
fi

cd "$ROOT_DIR"

RSYNC_RSH="${DEPLOY_RSYNC_RSH:-ssh -o IdentitiesOnly=yes}"

if [[ "${DEPLOY_INCLUDE_PHOTOS:-0}" != "1" && -z "${PHOTO_ASSET_BASE:-}" ]]; then
  export PHOTO_ASSET_BASE="https://web.math.ucsb.edu/~ortegaray/pages/Photos/"
fi

quarto render --to html

photo_excludes=(
  --exclude "/pages/Photos/photography/"
  --exclude "/pages/Photos/photography/**"
  --exclude "/pages/Photos/photography_derived/"
  --exclude "/pages/Photos/photography_derived/**"
)

archive_excludes=(
  --exclude "/pages/Teaching/course_materials/**/*.zip"
)

rsync_excludes=()

if [[ "${DEPLOY_INCLUDE_PHOTOS:-0}" != "1" ]]; then
  rm -rf docs/pages/Photos/photography docs/pages/Photos/photography_derived
  rsync_excludes+=("${photo_excludes[@]}")
fi

if [[ "${DEPLOY_INCLUDE_COURSE_ARCHIVES:-0}" != "1" ]]; then
  rsync_excludes+=("${archive_excludes[@]}")
fi

rsync -az --delete --stats --chmod=u=rwX,go=rX -e "$RSYNC_RSH" "${rsync_excludes[@]}" docs/ "$TARGET"

echo
echo "Deploy preservation summary:"
if [[ "${DEPLOY_INCLUDE_PHOTOS:-0}" != "1" ]]; then
  echo "  remote photos preserved"
else
  echo "  remote photos synced from local checkout"
fi

if [[ "${DEPLOY_INCLUDE_COURSE_ARCHIVES:-0}" != "1" ]]; then
  echo "  remote course archives preserved"
else
  echo "  remote course archives synced from local checkout"
fi

if [[ "${DEPLOY_SKIP_CLEAN:-0}" != "1" ]]; then
  ./scripts/clean-generated.sh --apply
  echo "  generated files cleaned"
else
  echo "  generated files retained"
fi
