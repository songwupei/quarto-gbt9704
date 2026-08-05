#!/usr/bin/env bash
# 渲染前自动同步布局文件: gbt9704-layout.json → .lua / .def
# 由 _quarto.yml 的 project.pre-render 钩子在每次 quarto render 时调用。
set -euo pipefail

cd "$(dirname "$0")/.."

python3 tools/json2def.py _extensions/gbt9704/gbt9704-layout.json --lua \
  > _extensions/gbt9704/gbt9704-layout.lua
python3 tools/json2def.py _extensions/gbt9704/gbt9704-layout.json \
  > _extensions/gbt9704/gbt9704-layout.def

echo "✓ 布局已同步: gbt9704-layout.json → .lua / .def"
