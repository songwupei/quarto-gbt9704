#!/usr/bin/env bash
# ============================================================
# md2png.sh — Markdown / Quarto 文档 → PNG 长图
#            Render Markdown / Quarto documents to a tall PNG
#
# 默认 HTML 模式：浏览器原生渲染，emoji/CJK 字体效果好
# 全页截图 + 自动裁边
# ============================================================
set -euo pipefail

# ---- 默认值 ----
WIDTH=900
DPI=150
OUTPUT=""
MODE="html"       # html（默认）或 pdf
INPUT=""
MAX_HEIGHT=24000  # 全页截图最大高度
MARGIN=20         # 四边白边 px
FORMAT=""         # Quarto 格式名（如 gbt9704-html），空则用 --mode

# ---- 帮助 ----
usage() {
  cat << 'EOF'
md2png.sh — Markdown / Quarto 文档 → PNG 长图

用法:
  ./md2png.sh <input.md> [选项]

选项:
  --width N       截图宽度 px（默认 900）
  --dpi N         PDF 渲染 DPI（仅 --mode pdf，默认 150）
  --output FILE   输出文件路径，默认与输入同名 .png
  --mode MODE     html（默认，emoji/CJK 好）| pdf（LaTeX 排版）
  --margin N      四边白边 px（默认 20）
  --format NAME   Quarto 格式名，如 gbt9704-html、gbt9704-pdf
  -h, --help      显示帮助

示例:
  ./md2png.sh xforge.md
  ./md2png.sh xforge.md --width 1200
  ./md2png.sh xforge.md --mode pdf --dpi 300
  ./md2png.sh example.qmd --format gbt9704-html   # 使用扩展 HTML 格式
  ./md2png.sh example.qmd --format gbt9704-pdf    # 使用扩展 PDF 格式

依赖:
  quarto, google-chrome-stable 或 chromium, magick（ImageMagick）
EOF
  exit 0
}

# ---- 参数解析 ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)  usage ;;
    --width)    WIDTH="$2";  shift 2 ;;
    --dpi)      DPI="$2";    shift 2 ;;
    --output)   OUTPUT="$2"; shift 2 ;;
    --mode)     MODE="$2";   shift 2 ;;
    --margin)   MARGIN="$2"; shift 2 ;;
    --format)   FORMAT="$2"; shift 2 ;;
    -*)
      echo "❌ 未知选项: $1"
      usage
      ;;
    *)
      INPUT="$1"
      shift
      ;;
  esac
done

# ---- 校验输入 ----
[[ -z "$INPUT" ]] && { echo "❌ 请指定输入文件"; usage; }
[[ ! -f "$INPUT" ]] && { echo "❌ 文件不存在: $INPUT"; exit 1; }

# ---- 推导路径 ----
INPUT_DIR=$(dirname "$(realpath "$INPUT")")
INPUT_NAME="$(basename "$INPUT" | sed 's/\.[^.]*$//')"
[[ -z "$OUTPUT" ]] && OUTPUT="${INPUT_DIR}/${INPUT_NAME}.png"
[[ "$OUTPUT" != /* ]] && OUTPUT="$(pwd)/$OUTPUT"
OUTPUT_DIR=$(dirname "$OUTPUT")
OUTPUT_NAME="$(basename "$OUTPUT" | sed 's/\.[^.]*$//')"

# ---- 依赖检查 ----
check_cmd() { command -v "$1" &>/dev/null || { echo "❌ 缺少依赖: $1  —  $2"; exit 1; }; }
check_cmd quarto "https://quarto.org/docs/get-started/"

# ---- 裁白边 + 加边距 ----
process_margin() {
  local img="$1"
  local m="$2"
  local cmd=""
  command -v magick &>/dev/null && cmd="magick" || { command -v convert &>/dev/null && cmd="convert"; }
  [[ -z "$cmd" ]] && return 0

  # 先裁掉多余白边，再加统一边距
  "$cmd" "$img" -trim +repage -bordercolor white -border "${m}x${m}" "$img"
}

# ---- HTML 模式（默认）：Quarto → HTML → 浏览器全页截图 ----
render_html() {
  # 自动检测浏览器：优先 google-chrome-stable，其次 chromium
  local browser=""
  if command -v google-chrome-stable &>/dev/null; then
    browser="google-chrome-stable"
  elif command -v chromium &>/dev/null; then
    browser="chromium"
  else
    echo "❌ 缺少浏览器依赖"
    echo "   请安装 google-chrome-stable 或 chromium"
    echo "   Arch: sudo pacman -S google-chrome  或  sudo pacman -S chromium"
    exit 1
  fi

  local qformat="${FORMAT:-html}"

  echo "📄 Step 1/2: Quarto → HTML..."
  echo "   输入: $INPUT  (格式: $qformat)"

  HTML_OUT="${INPUT_DIR}/${INPUT_NAME}.html"
  quarto render "$INPUT" --to "$qformat" --output-dir "$INPUT_DIR" 2>&1 | grep -v '^$' | sed 's/^/   /'

  [[ ! -f "$HTML_OUT" ]] && [[ -f "${INPUT_NAME}.html" ]] && HTML_OUT="$(pwd)/${INPUT_NAME}.html"
  [[ ! -f "$HTML_OUT" ]] && { echo "❌ HTML 生成失败"; exit 1; }
  echo "   ✅ $HTML_OUT"

  echo "🖼️  Step 2/2: Chrome 全页截图 → PNG..."
  echo "   宽度: ${WIDTH}px"

  "$browser" \
    --headless --disable-gpu --no-sandbox \
    --screenshot="$OUTPUT" \
    --window-size="${WIDTH},${MAX_HEIGHT}" \
    --default-background-color=ffffff \
    --hide-scrollbars \
    --virtual-time-budget=10000 \
    "file://${HTML_OUT}" 2>&1 | grep -vE '(^$|vaapi|ERROR:gpu)' | sed 's/^/   /' || true

  if [[ -f "$OUTPUT" ]]; then
    process_margin "$OUTPUT" "$MARGIN"
    echo ""
    echo "✅ 完成！"
    echo "   📁 HTML: $HTML_OUT"
    echo "   🖼️  PNG:  $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"
  else
    echo "❌ PNG 生成失败"
    exit 1
  fi
}

# ---- PDF 模式：Quarto → PDF → pdftoppm → 合并长图 ----
render_pdf() {
  check_cmd pdftoppm "sudo pacman -S poppler"

  local qformat="${FORMAT:-pdf}"

  echo "📄 Step 1/2: Quarto → PDF..."
  echo "   输入: $INPUT  (格式: $qformat, DPI: ${DPI})"

  PDF_OUT="${INPUT_DIR}/${INPUT_NAME}.pdf"
  quarto render "$INPUT" --to "$qformat" --output-dir "$INPUT_DIR" 2>&1 | grep -v '^$' | sed 's/^/   /'
  [[ ! -f "$PDF_OUT" ]] && { echo "❌ PDF 生成失败"; exit 1; }
  echo "   ✅ $PDF_OUT"

  echo "🖼️  Step 2/2: PDF → PNG..."
  mkdir -p "$OUTPUT_DIR"
  pdftoppm -png -r "$DPI" "$PDF_OUT" "${OUTPUT_DIR}/${OUTPUT_NAME}"

  local pages=("${OUTPUT_DIR}/${OUTPUT_NAME}-"*.png)
  local n=${#pages[@]}
  (( n == 0 )) && { echo "❌ PNG 生成失败"; exit 1; }

  if (( n > 1 )); then
    check_cmd convert "sudo pacman -S imagemagick"
    local merged="${OUTPUT_DIR}/${OUTPUT_NAME}.png"
    echo "   🔗 合并 $n 页 → $(basename "$merged")"
    if command -v magick &>/dev/null; then
      magick -append "${pages[@]}" "$merged"
    else
      convert -append "${pages[@]}" "$merged"
    fi
    echo "   🖼️  $(basename "$merged")  ($(du -h "$merged" | cut -f1))"
  else
    mv "${pages[1]}" "${OUTPUT_DIR}/${OUTPUT_NAME}.png"
    echo "   🖼️  ${OUTPUT_NAME}.png  ($(du -h "${OUTPUT_DIR}/${OUTPUT_NAME}.png" | cut -f1))"
  fi
  echo ""
  echo "✅ 完成！共 $n 页"
}

# ---- 执行 ----
echo ""
if [[ -n "$FORMAT" ]]; then
  # 根据格式名自动选择管线：含 html → 截图，含 pdf → pdftoppm
  if [[ "$FORMAT" == *html* ]]; then
    render_html
  elif [[ "$FORMAT" == *pdf* ]]; then
    render_pdf
  else
    echo "❌ 无法判断 $FORMAT 格式的渲染管线（格式名需含 html 或 pdf）"
    exit 1
  fi
else
  case "$MODE" in
    html) render_html ;;
    pdf)  render_pdf ;;
    *)    echo "❌ 无效模式: $MODE (可选: html, pdf)"; exit 1 ;;
  esac
fi
