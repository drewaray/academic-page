#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

SKIP_RENDER=false
if [[ "${1:-}" == "--skip-render" ]]; then
  SKIP_RENDER=true
fi

if [[ "$SKIP_RENDER" == "true" ]]; then
  echo "[1/4] Skipping render (--skip-render)"
else
  echo "[1/4] Rendering site"
  quarto render --to html
fi

echo "[2/4] Checking tracked generated artifacts"
tracked_generated="$(
  git ls-files | rg '(_files/|\\.quarto_ipynb$|index_files/)' | while IFS= read -r file; do
    if [[ -e "$file" ]]; then
      printf '%s\n' "$file"
    fi
  done || true
)"
if [[ -n "$tracked_generated" ]]; then
  echo "Tracked generated artifacts found:" >&2
  echo "$tracked_generated" >&2
  exit 1
fi

echo "[3/4] Checking placeholder links"
placeholder_links="$(rg -n '\]\(#\)' pages index.qmd || true)"
if [[ -n "$placeholder_links" ]]; then
  echo "Warning: placeholder links found:" >&2
  echo "$placeholder_links" >&2
fi

echo "[4/4] Checking missing local assets"
python3 - <<'PY'
import re
from pathlib import Path

ROOT = Path.cwd()
missing = []

md_link_re = re.compile(r'!?\[[^\]]*\]\(([^)]+)\)')
yaml_re = re.compile(r'^\s*(?:href|image|poster_url):\s*["\']?([^"\'\n#]+)', re.IGNORECASE)

ignore_prefixes = (
    "http://",
    "https://",
    "mailto:",
    "tel:",
    "javascript:",
    "data:",
)

skip_dirs = {".git", ".quarto", "docs", "node_modules", "people_test"}
allowed_generated = {"posts.xml", "sitemap.xml", "search.json", "listings.json"}


def should_check(target: str) -> bool:
    target = target.strip()
    if not target or target.startswith("#"):
        return False
    if target.startswith(ignore_prefixes):
        return False
    if target in allowed_generated:
        return False
    if "{" in target or "}" in target:
        return False
    return True


def normalize_target(target: str) -> str:
    target = target.strip().strip("<>").split("#", 1)[0].split("?", 1)[0]
    return target.strip()


def candidate_paths(path: Path, target: str):
    candidates = []
    if target.startswith("/"):
        candidates.append(ROOT / target.lstrip("/"))
    else:
        candidates.append(path.parent / target)
        if path.parts[:3] == ("pages", "Teaching", "data"):
            candidates.append(ROOT / "pages/Teaching" / target)

    if " " in target:
        trimmed = target.split(" ", 1)[0].strip()
        if trimmed and trimmed != target:
            if trimmed.startswith("/"):
                candidates.append(ROOT / trimmed.lstrip("/"))
            else:
                candidates.append(path.parent / trimmed)
                if path.parts[:3] == ("pages", "Teaching", "data"):
                    candidates.append(ROOT / "pages/Teaching" / trimmed)

    return candidates


for path in ROOT.rglob("*"):
    if path.suffix.lower() not in {".qmd", ".md", ".yml"}:
        continue

    rel_path = path.relative_to(ROOT)
    if any(part in skip_dirs for part in rel_path.parts):
        continue

    text = path.read_text(encoding="utf-8", errors="ignore")
    in_code_block = False
    for line_no, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()
        if path.suffix.lower() in {".qmd", ".md"} and stripped.startswith("```"):
            in_code_block = not in_code_block
            continue
        if in_code_block:
            continue
        if stripped.startswith("<!--") or stripped.startswith("-->"):
            continue

        targets = []
        for match in md_link_re.finditer(line):
            targets.append(match.group(1))

        yaml_match = yaml_re.search(line)
        if yaml_match:
            targets.append(yaml_match.group(1))

        for raw_target in targets:
            if not should_check(raw_target):
                continue
            target = normalize_target(raw_target)
            if not target:
                continue
            if target.startswith(ignore_prefixes) or target.startswith("#"):
                continue

            if not any(candidate.exists() for candidate in candidate_paths(rel_path, target)):
                missing.append((str(rel_path), line_no, target))

if missing:
    print("Missing local assets:")
    for file_path, line_no, target in missing:
        print(f"  {file_path}:{line_no} -> {target}")
    raise SystemExit(1)

print("No missing local asset references detected.")
PY

echo "Site checks completed."
