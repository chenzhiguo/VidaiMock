# VidaiMock Documentation (MkDocs)

Local, Markdown-only documentation for VidaiMock. Lives in the repo so docs
stay in sync with the code — a feature PR should update its doc page in the
same commit.

This is **separate from** the marketing site (`Vidai_Website/MainSite`, which
uses Astro + Starlight). This MkDocs site is the engineering source of truth;
the marketing site can mirror or link to it later if desired.

## Quick start

```bash
# one-time (already installed on the maintainer's machine):
python3 -m pip install -r requirements.txt

# live preview at http://127.0.0.1:8001 (auto-reloads on edit):
./serve.sh

# one-shot static build into ./site (gitignored):
./serve.sh build
```

`./serve.sh build` runs with `--strict`, so broken links or nav references
fail the build. Keep it green.

## Structure

```
mkdocs/
├── mkdocs.yml          # site config + nav (Material theme)
├── requirements.txt    # pinned mkdocs + material versions
├── serve.sh            # local preview / build helper (port 8001)
└── docs/               # all content (plain Markdown, no MDX/JSX)
    ├── index.md
    ├── getting-started/
    ├── providers/
    ├── configuration/
    ├── recipes/
    ├── reference/
    └── assets/
```

## Conventions

- Plain CommonMark + PyMdown extensions only. No framework components.
- Source of truth is the repo `README.md`, `CHANGELOG.md`, and the actual
  `config/` providers/templates — not the older Starlight pages.
- Use the correct repo path everywhere: `github.com/vidaiUK/VidaiMock`,
  release artifacts named `vidaimock-<os>-<arch>.tar.gz`.
- When a feature changes, update its page in the same PR and bump the
  changelog page.

## Publishing (optional, not enabled yet)

`mkdocs gh-deploy` would publish to GitHub Pages. Intentionally not wired
into CI — this is a local-refresh workflow by design. Flip it on later if
hosted docs are wanted.
