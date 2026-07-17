# scripts/

Utility scripts for `quarto-gbt9704`.

## `md2png.sh` — Markdown → PNG 长图

Converts Markdown / Quarto documents to a single tall PNG image.

### Why HTML mode (default)

HTML mode uses the **browser's native rendering engine**:

- ✅ **Emoji** — rendered natively by the browser
- ✅ **CJK fonts** — uses system fonts, no LaTeX font setup needed
- ✅ **Tables, code blocks, images** — full web rendering

### Usage

```bash
# HTML mode (default) — fast, good emoji/CJK
./md2png.sh document.md

# Wider output
./md2png.sh document.md --width 1200

# More/less margin
./md2png.sh document.md --margin 40

# PDF mode — LaTeX typesetting, crisp text
./md2png.sh document.md --mode pdf --dpi 300

# Extension formats — GB/T 9704 styled output
./md2png.sh example.qmd --format gbt9704-html   # HTML with official document CSS → PNG
./md2png.sh example.qmd --format gbt9704-pdf    # PDF with gbt9704.cls → PNG
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `--width N` | `900` | Screenshot width px |
| `--margin N` | `20` | White border px on all sides |
| `--dpi N` | `150` | PDF render DPI (pdf mode only) |
| `--output FILE` | same as input `.png` | Output path |
| `--mode MODE` | `html` | `html` (browser) or `pdf` (LaTeX) |
| `--format NAME` | (none) | Quarto format name, e.g. `gbt9704-html` |
| `-h, --help` | | Show help |

### Dependencies

| Tool | Package | Used by |
|------|---------|---------|
| `quarto` | [quarto.org](https://quarto.org) | both modes |
| `google-chrome-stable` or `chromium` | `google-chrome` / `chromium` | html mode (auto-detected) |
| `magick` / `convert` | `imagemagick` | trim + margin |
| `pdftoppm` | `poppler` | pdf mode |

### How It Works

```
html mode (default):
  Markdown  ──quarto──▶  HTML  ──Chrome headless (24000px tall)──▶
  raw.png  ──trim + margin──▶  final.png

pdf mode:
  Markdown  ──quarto──▶  PDF  ──pdftoppm──▶
  page-*.png  ──magick -append──▶  merged.png
```
