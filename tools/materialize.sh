#!/usr/bin/env bash
# 将 _extensions/gbt9704/ 中的符号链接替换为真实文件内容，使扩展自包含。
# 用于 CI 发布：quarto add 安装时不需要 git submodule。
#
# Resolve symlinks in _extensions/gbt9704/ by copying real files from latex-source
# submodule. Produces a self-contained extension ready for quarto add / release.
set -euo pipefail

cd "$(dirname "$0")/.."

EXT_DIR="_extensions/gbt9704"
SUBMODULE_DIR="latex-source"

# 确保 submodule 已初始化
if [ ! -f "$SUBMODULE_DIR/gbt9704/gbt9704.cls" ]; then
  echo ">>> 初始化 submodule ..."
  git submodule update --init --recursive
fi

echo ">>> 展开符号链接 ..."
resolved=0
for symlink in "$EXT_DIR"/*; do
  if [ -L "$symlink" ]; then
    target=$(readlink -f "$symlink")
    basename=$(basename "$symlink")
    if [ -f "$target" ]; then
      rm "$symlink"
      cp "$target" "$symlink"
      echo "  ✓ $basename ← $target"
      resolved=$((resolved + 1))
    else
      echo "  ✗ $basename: 目标不存在 ($target)" >&2
      exit 1
    fi
  fi
done

if [ "$resolved" -eq 0 ]; then
  echo "  (无符号链接，已是最新)"
else
  echo "  ✓ 已展开 $resolved 个文件"
fi