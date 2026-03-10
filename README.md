# Andrew Ortegaray's Personal Website

This repository contains the source for a Quarto-based personal academic website.

## Project Layout
- `_quarto.yml`: site-wide Quarto configuration and navigation.
- `index.qmd`: homepage.
- `pages/About/`: about page.
- `pages/Math/`: papers page and blog.
- `pages/Math/blog/posts/`: blog post directories, one post per folder.
- `pages/Teaching/`: teaching pages and course materials.
- `pages/Teaching/data/`: structured teaching data files.
- `pages/Resources/`: resources page and `resources.yml` data.
- `pages/Photos/`: photo gallery page and source images.
- `files/includes/`: reusable HTML/QMD includes.
- `files/js/`: shared front-end hooks loaded site-wide.
- `scripts/`: maintenance/check utility scripts.

## Build and Check Commands
- Render site:
  - `quarto render --to html`
- Run full checks:
  - `./scripts/check-site.sh`
- Optimize photo derivatives (web + thumbnails):
  - `./scripts/optimize-photos.sh`

## Add a New Blog Post
1. Duplicate `pages/Math/blog/posts/futureDate-postName/`.
2. Rename folder to `YYYY-MM-DD-post-slug`.
3. Edit `index.qmd` front matter:
   - `title`
   - `description`
   - `date`
   - `categories`
   - `image` (optional)
   - `draft` (optional)
4. Add post-local media files (if needed) into that post folder.
5. Run `quarto render --to html` and verify the post appears on:
   - home page recent posts
   - `pages/Math/blog/blog.qmd`

## Data Schemas
### `pages/Teaching/data/courses.yml`
Each entry supports:
- `term`: display term string.
- `institution`: school/group name.
- `course_code`: short code (e.g., `MA4B`).
- `title`: course title.
- `status`: `current` or `archive`.
- `links`: list of `{ label, href }`.
- `course_url` (optional): direct course page link.

### `pages/Teaching/data/mentoring.yml`
Each entry supports:
- `year`: year range label.
- `program`: project/program name.
- `program_url`: optional link target for `program`.
- `topics`: summary text.
- `topics_url`: optional link target for `topics`.
- `mentees`: list of mentee names.
- `poster_url`: optional local/remote poster link.

### `pages/Resources/resources.yml`
Entries are schema-flexible. Common fields:
- `title`, `url`, `apply_url`, `audience`, `type`, `notes`, `deadline`, `location`, `last_updated`.

## Source-Only Repository Policy
Generated artifacts should not be committed:
- `*.quarto_ipynb`
- `*_files/`
- `index_files/`
- rendered `docs/`

Use the scripts above to regenerate outputs locally as needed.
