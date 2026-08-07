# TODO · quarto-gbt9704

## 红线负间距不生效

**现象**: 修改 `gbt9704-layout.json` 中 redline 的 `space_before` / `space_after` 为负值（如 `-2cm`），
渲染 PDF 后红线前后间距没有变化。

**根因**:

1. ~~**JSON→Lua 不同步**~~ ✅ **已修复 (v0.7.4)**。`gbt9704-layout.*` 和 `gbt9704.cls` 改为 git submodule
   (`latex-source`) 符号链接，JSON/Lua/Def 三者始终一致。详见 [#开发](#开发) 章节。

2. **安装目录副本陈旧**。`quarto add` 安装的扩展（如 `~/.yazi-quarto/_extensions/songwupei/gbt9704/`）
   有一个冻结的 `.lua` 副本，不会随源仓库更新。用户项目渲染时加载的是安装目录的副本，
   而非源仓库中最新的 `.lua`。

3. **LaTeX 层面**（待验证）。`\vspace` 在 `{center}` 环境内对负值的处理可能被吞掉。
   需测试：
   - 负值 `\vspace` 是否在 `center` 内实际收缩间距
   - 是否需要改用 `\vspace*` 或 `\\[负值]` 
   - 是否需要调整 `center` 环境的 `\topsep` 等参数

**修复方向**:

- [x] ~~短期：跑 `sync-layout.sh` 同步 `.lua` →~~ v0.7.4 已通过 submodule 符号链接解决。
- [ ] 短期：重新 `quarto add` 更新安装目录（或 `quarto remove songwupei/quarto-gbt9704 && quarto add songwupei/quarto-gbt9704`）
- [ ] 中期：在 `quarto-render.sh` (yazi-quarto) 的 `_init_workdir()` 中增加 submodule update 或 `.lua` 刷新逻辑
  - 或在 gbt9704 扩展发布流程中通过 CI/CD 确保 `quarto add` 拉取最新 release
- [ ] 验证：测试负值 `\vspace` 在 `center` 环境中的实际效果
  - 如果不生效，修改 `gbt9704.cls` 中的间距实现方式
- [ ] 长期：考虑让 `layout-loader.lua` 直接读取 JSON（而非预生成的 `.lua`），
  消除 JSON→Lua 同步步骤（submodule 已解决源仓库同步，此项针对安装目录场景）

**相关文件**:

- `latex-source/gbt9704/gbt9704-layout.json` — 布局参数定义（规范源，git submodule）
- `latex-source/gbt9704/gbt9704-layout.lua` — 由 JSON 生成
- `latex-source/gbt9704/gbt9704-layout.def` — 由 JSON 生成
- `_extensions/gbt9704/gbt9704-layout.*` → `../../latex-source/gbt9704/` 符号链接
- `tools/sync-layout.sh` — JSON → .lua/.def 同步工具（用于 submodule 内修改后重新生成）
- `tools/update-latex-source.sh` — 拉取 submodule 最新 commit 并暂存
- `tools/json2def.py` — 生成器
- `_extensions/gbt9704/assets/filters/layout-loader.lua` — 渲染时读入 .lua 并注入 \def
- `latex-source/gbt9704/gbt9704.cls` L390-408 — 红头命令实现（\vspace + \rule）
