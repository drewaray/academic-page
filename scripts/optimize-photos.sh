#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$ROOT_DIR/pages/Photos/photography"
WEB_DIR="$ROOT_DIR/pages/Photos/photography_derived/web"
THUMB_DIR="$ROOT_DIR/pages/Photos/photography_derived/thumbs"

if ! command -v sips >/dev/null 2>&1; then
  echo "Error: 'sips' is required for image optimization on macOS." >&2
  exit 1
fi

mkdir -p "$WEB_DIR" "$THUMB_DIR"

processed=0
shopt -s nullglob
for image in "$SRC_DIR"/*.{jpg,jpeg,png,JPG,JPEG,PNG}; do
  filename="$(basename "$image")"
  sips -s formatOptions 85 -Z 2200 "$image" --out "$WEB_DIR/$filename" >/dev/null
  sips -s formatOptions 80 -Z 480 "$image" --out "$THUMB_DIR/$filename" >/dev/null
  processed=$((processed + 1))
done

echo "Optimized $processed image(s)."
echo "Web images: $WEB_DIR"
echo "Thumbnails: $THUMB_DIR"
