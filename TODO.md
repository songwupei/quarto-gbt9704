# TODO · quarto-gbt9704

## 红线负间距不生效

**现象**: 修改 `gbt9704-layout.json` 中 redline 的 `space_before` / `space_after` 为负值（如 `-2cm`），
渲染 PDF 后红线前后间距没有变化。

**根因**:

1. **JSON→Lua 不同步**。修改 JSON 后必须运行 `tools/sync-layout.sh` 重新生成 `.lua` 和 `.def`，
   否则 `layout-loader.lua` 读到的仍是旧值。当前 `.lua` 和 `.def` 均为 `0cm`（JSON 已是 `-2cm`）。

2. **安装目录副本陈旧**。`quarto add` 安装的扩展（如 `~/.yazi-quarto/_extensions/songwupei/gbt9704/`）
   有一个冻结的 `.lua` 副本，不会随源仓库更新。用户项目渲染时加载的是安装目录的副本，
   而非源仓库中最新的 `.lua`。

3. **LaTeX 层面**（待验证）。`\vspace` 在 `{center}` 环境内对负值的处理可能被吞掉。
   需测试：
   - 负值 `\vspace` 是否在 `center` 内实际收缩间距
   - 是否需要改用 `\vspace*` 或 `\\[负值]` 
   - 是否需要调整 `center` 环境的 `\topsep` 等参数

**修复方向**:

- [ ] 短期：跑 `sync-layout.sh` 同步 `.lua` + 重新 `quarto add` 更新安装目录
- [ ] 中期：在 `quarto-render.sh` (yazi-quarto) 的 `_init_workdir()` 中增加 `.lua` 更新逻辑
  - 或在 gbt9704 扩展发布流程中确保 `.lua` 与 JSON 一致
- [ ] 验证：在更新 `.lua` 后测试负值 `\vspace` 在 `center` 环境中的实际效果
  - 如果不生效，修改 `gbt9704.cls` 中的间距实现方式
- [ ] 长期：考虑让 `layout-loader.lua` 直接读取 JSON（而非预生成的 `.lua`），
  消除 JSON→Lua 同步步骤

**相关文件**:

- `_extensions/gbt9704/gbt9704-layout.json` — 用户修改的布局参数
- `_extensions/gbt9704/gbt9704-layout.lua` — 由 JSON 生成（当前过期）
- `_extensions/gbt9704/gbt9704-layout.def` — 由 JSON 生成（当前过期）
- `tools/sync-layout.sh` — JSON → .lua/.def 同步脚本
- `tools/json2def.py` — 同步脚本调用的生成器
- `_extensions/gbt9704/assets/filters/layout-loader.lua` — 渲染时读入 .lua 并注入 \def
- `_extensions/gbt9704/gbt9704.cls` L390-408 — 红头命令实现（\vspace + \rule）
