# Andrew Ortegaray's Personal Website

This repository contains the Quarto source for Andrew Ortegaray's academic website:

```text
https://web.math.ucsb.edu/~ortegaray/
```

The normal workflow is source-first: edit `.qmd`, `.yml`, `.bib`, CSS, or script files locally, render the site into `docs/`, then deploy the rendered bundle to the UCSB web server over SSH with `rsync`.

## Quick Start

Render the site locally:

```bash
quarto render --to html
```

Run the site checks:

```bash
./scripts/check-site.sh
```

Deploy routine text/layout updates to the UCSB server:

```bash
./scripts/deploy-site.sh \
  ortegaray@web.math.ucsb.edu:/home/grad/ortegaray/public_html/
```

Deploy after adding or changing photos:

```bash
./scripts/optimize-photos.sh
DEPLOY_INCLUDE_PHOTOS=1 ./scripts/deploy-site.sh \
  ortegaray@web.math.ucsb.edu:/home/grad/ortegaray/public_html/
```

Do not use an `http://` URL as the deploy target. `rsync` needs an SSH path in this form:

```text
user@host:/absolute/server/path/
```

## Project Layout

- `_quarto.yml`: site-wide Quarto configuration, navigation, metadata, themes, and output directory.
- `index.qmd`: homepage.
- `404.qmd`: custom not-found page.
- `styles.css`: shared site styling.
- `pages/About/`: about page and about-page media.
- `pages/Math/papers/`: publications page and bibliography.
- `pages/Math/blog/`: blog listing and blog post directories.
- `pages/Teaching/`: teaching pages, course materials, and structured teaching data.
- `pages/Resources/`: resources page and resources data.
- `pages/Photos/`: photo gallery page, photo manifest, and optional local photo assets.
- `files/`: shared PDFs, images, JavaScript, and reusable includes.
- `_extensions/`: Quarto extensions used by the site.
- `scripts/`: local maintenance, checking, photo optimization, and deploy scripts.
- `docs/`: rendered site output. This is generated and ignored by Git.

## Editing Content

Most pages are plain Quarto files:

```text
*.qmd
```

Edit them directly, then run:

```bash
quarto render --to html
```

For a faster local preview while editing:

```bash
quarto preview
```

### Blog Posts

Blog posts live under:

```text
pages/Math/blog/posts/
```

To add a post:

1. Duplicate `pages/Math/blog/posts/futureDate-postName/`.
2. Rename the copy to `YYYY-MM-DD-post-slug`.
3. Edit the copied `index.qmd` front matter.
4. Add any post-local images or files inside the post folder.
5. Render and check that the post appears on the homepage and blog page.

Common front matter fields:

- `title`
- `description`
- `date`
- `categories`
- `image`
- `draft`

### Publications

The publications page is:

```text
pages/Math/papers/publications.qmd
```

Bibliography entries live in:

```text
pages/Math/papers/publications.bib
```

### Teaching

Teaching data is stored in YAML:

```text
pages/Teaching/data/courses.yml
pages/Teaching/data/mentoring.yml
```

`courses.yml` entries commonly use:

- `term`
- `institution`
- `course_code`
- `title`
- `status`
- `links`
- `course_url`

`mentoring.yml` entries commonly use:

- `year`
- `program`
- `program_url`
- `topics`
- `topics_url`
- `mentees`
- `poster_url`

### Resources

Resources are stored in:

```text
pages/Resources/resources.yml
```

Common fields include:

- `title`
- `url`
- `apply_url`
- `audience`
- `type`
- `notes`
- `deadline`
- `location`
- `last_updated`

## Photos

The photo gallery is designed so routine website edits do not require keeping or transferring the full photo collection.

The gallery page is:

```text
pages/Photos/photos.qmd
```

The gallery list is:

```text
pages/Photos/photos.json
```

Large local photo folders are intentionally ignored:

```text
pages/Photos/photography/
pages/Photos/photography_derived/
```

`photos.qmd` reads `photos.json`, so the original photo folder does not need to be present just to render the page. On routine deploys, `scripts/deploy-site.sh` sets:

```text
PHOTO_ASSET_BASE=https://web.math.ucsb.edu/~ortegaray/pages/Photos/
```

That makes the rendered gallery point at the existing photo assets on the live server while the deploy skips local photo folders.

### Add Or Change Photos

1. Put original images in `pages/Photos/photography/`.
2. Add each image filename and title to `pages/Photos/photos.json`.
3. Generate web-sized and thumbnail derivatives:

```bash
./scripts/optimize-photos.sh
```

4. Deploy with photos included:

```bash
DEPLOY_INCLUDE_PHOTOS=1 ./scripts/deploy-site.sh \
  ortegaray@web.math.ucsb.edu:/home/grad/ortegaray/public_html/
```

After the remote photo folders are uploaded, local originals can live outside this working checkout if you want to keep the repo lightweight.

## Deployment

The deploy script renders the site and then syncs `docs/` to the server:

```bash
./scripts/deploy-site.sh \
  ortegaray@web.math.ucsb.edu:/home/grad/ortegaray/public_html/
```

By default, it:

- runs `quarto render --to html`
- removes generated photo folders from `docs/`
- preserves remote photo asset folders
- transfers only the rendered site bundle with `rsync`

To override the photo asset base URL:

```bash
PHOTO_ASSET_BASE=https://example.edu/~user/pages/Photos/ \
  ./scripts/deploy-site.sh user@host:/remote/site/path/
```

To use a specific SSH identity:

```bash
DEPLOY_RSYNC_RSH='ssh -i ~/.ssh/YOUR_KEY -o IdentitiesOnly=yes' \
  ./scripts/deploy-site.sh \
  ortegaray@web.math.ucsb.edu:/home/grad/ortegaray/public_html/
```

If SSH reports `Too many authentication failures`, keep `IdentitiesOnly=yes` or specify the exact key as above.

## Checks And Maintenance

Run all checks:

```bash
./scripts/check-site.sh
```

Skip rendering and only run repository checks:

```bash
./scripts/check-site.sh --skip-render
```

The check script looks for:

- tracked generated artifacts
- placeholder links like `](#)`
- missing local asset references

The `.quarto/` directory is a disposable cache. It can be removed to reclaim space:

```bash
rm -rf .quarto
```

`docs/` is also generated output and can be removed or regenerated at any time:

```bash
rm -rf docs
quarto render --to html
```

## Generated Files Policy

Do not commit generated render outputs or local caches:

- `.quarto/`
- `docs/`
- `README.html`
- `*.quarto_ipynb`
- `*_files/`
- `index_files/`
- `node_modules/`

Large photo source and derivative folders are also ignored:

- `pages/Photos/photography/`
- `pages/Photos/photography_derived/`

Keep the source files, manifests, scripts, and data files in Git; regenerate outputs locally as needed.

## Troubleshooting

### Quarto/Jupyter Prints `quarto_kernel_setup`

During pages with Python chunks, Quarto may print:

```text
[IPKernelApp] ERROR | No such comm target registered: quarto_kernel_setup
```

If the render still finishes and `quarto check jupyter` reports `OK`, this is a harmless Jupyter startup warning. It is not a deploy failure.

### Deploy Target Looks Like A URL

This is wrong:

```text
ortegaray@http://web.math.ucsb.edu/home/grad/ortegaray/public_html
```

Use this instead:

```text
ortegaray@web.math.ucsb.edu:/home/grad/ortegaray/public_html/
```

### SSH Authentication Fails

First confirm you can SSH manually:

```bash
ssh -o IdentitiesOnly=yes ortegaray@web.math.ucsb.edu
```

Then rerun deploy from your terminal so you can respond to any password or two-factor prompts.

### Checks Report Tracked Generated Artifacts

If `./scripts/check-site.sh` reports files under `pages/Photos/photos_files/`, those are generated Quarto support files that were historically committed. They are ignored by current policy, but Git will keep tracking already-tracked files until they are removed from the index.

When you are ready to clean that up:

```bash
git rm -r --cached pages/Photos/photos_files
```

Then commit the cleanup. The files can be regenerated by Quarto if needed.
