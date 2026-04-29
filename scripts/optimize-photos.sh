#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$ROOT_DIR/pages/Photos/photography"
WEB_DIR="$ROOT_DIR/pages/Photos/photography_derived/web"
THUMB_DIR="$ROOT_DIR/pages/Photos/photography_derived/thumbs"

mkdir -p "$WEB_DIR" "$THUMB_DIR"

if python3 - <<'PY' >/dev/null 2>&1
import PIL
PY
then
  optimizer="pillow"
elif command -v sips >/dev/null 2>&1; then
  optimizer="sips"
else
  echo "Error: image optimization requires either Python Pillow or 'sips'." >&2
  exit 1
fi

processed=0
shopt -s nullglob
for image in "$SRC_DIR"/*.{jpg,jpeg,png,JPG,JPEG,PNG}; do
  filename="$(basename "$image")"
  if [[ "$optimizer" == "pillow" ]]; then
    IMAGE_IN="$image" WEB_OUT="$WEB_DIR/$filename" THUMB_OUT="$THUMB_DIR/$filename" python3 - <<'PY'
import os
from pathlib import Path

from PIL import Image, ImageOps, ImageStat


def save_resized(src, dest, max_size, quality):
    with Image.open(src) as image:
        image = ImageOps.exif_transpose(image)
        image.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)

        suffix = Path(dest).suffix.lower()
        if suffix in {".jpg", ".jpeg"}:
            if image.mode not in {"RGB", "L"}:
                background = Image.new("RGB", image.size, (255, 255, 255))
                if image.mode in {"RGBA", "LA"}:
                    background.paste(image, mask=image.getchannel("A"))
                else:
                    background.paste(image.convert("RGB"))
                image = background
            elif image.mode != "RGB":
                image = image.convert("RGB")
            image.save(dest, "JPEG", quality=quality, optimize=True, progressive=True)
        else:
            image.save(dest, optimize=True)

    with Image.open(dest) as output:
        stat = ImageStat.Stat(output.convert("L"))
        if stat.extrema[0] == (0, 0):
            raise RuntimeError(f"Generated all-black image: {dest}")


save_resized(os.environ["IMAGE_IN"], os.environ["WEB_OUT"], 2200, 85)
save_resized(os.environ["IMAGE_IN"], os.environ["THUMB_OUT"], 480, 80)
PY
  else
    sips -s formatOptions 85 -Z 2200 "$image" --out "$WEB_DIR/$filename" >/dev/null
    sips -s formatOptions 80 -Z 480 "$image" --out "$THUMB_DIR/$filename" >/dev/null
  fi
  processed=$((processed + 1))
done

chmod -R u=rwX,go=rX "$WEB_DIR" "$THUMB_DIR"

echo "Optimized $processed image(s)."
echo "Optimizer: $optimizer"
echo "Web images: $WEB_DIR"
echo "Thumbnails: $THUMB_DIR"
