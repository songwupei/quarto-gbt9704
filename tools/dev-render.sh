#!/usr/bin/env bash
# dev-render.sh — 改 gbt9704.cls / 模板时的快速回路。
#
#   bash tools/dev-render.sh            # 渲染 tests/ci-minimal.qmd（1 页，只出 PDF）
#   bash tools/dev-render.sh 我的稿子.md   # 换成任意 .md/.qmd
#
# 为什么快：只渲染 PDF 一种输出，且默认用 1 页自检样例（fandol 模式，不依赖系统字体）。
# 对比：yazi 里按 R 是"全量"（PDF+DOCX+HTML+PNG 长图），16 页的稿子约 2 分钟；
#      本脚本针对 1 页样例，通常 20 秒上下。
set -euo pipefail

cd "$(dirname "$0")/.."
TARGET="${1:-tests/ci-minimal.qmd}"

if [ ! -f "$TARGET" ]; then
  echo "❌ 找不到 $TARGET" >&2
  exit 1
fi

echo "▶ 渲染 $TARGET（只出 PDF）..."
start=$(date +%s)
quarto render "$TARGET" --to gbt9704-pdf
echo "✅ 完成，用时 $(( $(date +%s) - start ))s → ${TARGET%.*}.pdf"
