#!/usr/bin/env bash
# 布局文件同步工具: gbt9704-layout.json → .lua / .def
#
# 自 v0.7.4 起，gbt9704.cls 和 gbt9704-layout.* 改为通过 git submodule (latex-source)
# 以符号链接方式引入，不再需要渲染前自动同步。
#
# 本脚本保留用于在 latex-source submodule 内部修改 layout.json 后，
# 手动重新生成 .lua 和 .def 的场景。
set -euo pipefail

cd "$(dirname "$0")/.."

SRC="${1:-latex-source/gbt9704/gbt9704-layout.json}"

if [ ! -f "$SRC" ]; then
  echo "错误: 未找到 $SRC" >&2
  echo "用法: $0 [layout.json 路径]" >&2
  echo "默认路径: latex-source/gbt9704/gbt9704-layout.json" >&2
  exit 1
fi

DIR=$(dirname "$SRC")
python3 tools/json2def.py "$SRC" --lua > "$DIR/gbt9704-layout.lua"
python3 tools/json2def.py "$SRC"       > "$DIR/gbt9704-layout.def"

echo "✓ 布局已同步: $SRC → .lua / .def"
