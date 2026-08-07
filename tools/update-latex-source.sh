#!/usr/bin/env bash
# 更新 latex-source submodule 到最新 commit，并在主仓库中暂存。
# Update the latex-source submodule to the latest commit and stage it in the parent repo.
set -euo pipefail

cd "$(dirname "$0")/.."

SUBMODULE_PATH="latex-source"

if [ ! -d "$SUBMODULE_PATH" ]; then
  echo "错误: 未找到 submodule '$SUBMODULE_PATH/' — 请先运行 git submodule update --init" >&2
  exit 1
fi

echo ">>> 更新 $SUBMODULE_PATH submodule ..."
OLD=$(git -C "$SUBMODULE_PATH" rev-parse --short HEAD)
git -C "$SUBMODULE_PATH" pull origin main --ff-only
NEW=$(git -C "$SUBMODULE_PATH" rev-parse --short HEAD)

if [ "$OLD" = "$NEW" ]; then
  echo "✓ 已是最新: $OLD"
  exit 0
fi

echo "  $OLD → $NEW"
echo ""
echo ">>> 变更日志:"
git -C "$SUBMODULE_PATH" log --oneline "${OLD}..${NEW}"

echo ""
echo ">>> 在主仓库中暂存 submodule 更新 ..."
git add "$SUBMODULE_PATH"

COMMIT_MSG="chore: update latex-source submodule ($OLD → $NEW)"
echo ""
echo "✓ 已暂存。提交命令:"
echo "  git commit -m \"$COMMIT_MSG\""
echo ""
echo "或一键提交:"
echo "  git commit --no-gpg-sign -m \"$COMMIT_MSG\""