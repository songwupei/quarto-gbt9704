# quarto-gbt9704

Quarto 扩展集合：GB/T 9704 党政机关公文格式 + 教科书排版。
<br><small>Quarto extension bundle: GB/T 9704 Chinese government document format + textbook layout.</small>

| 格式 | 安装 | 用途 |
|------|------|------|
| `gbt9704-pdf` / `gbt9704-docx` / `gbt9704-html` | 本仓库 | 党政机关公文 |
| `gbt9704-pptx` / `gbt9704-beamer` | 本仓库 | 幻灯片（蓝色商务 PPTX · 青山绿水 Beamer） |
| `textbook-pdf` | [`quarto-textbook`](https://codeberg.org/songwupei/quarto-textbook) | 繁体中文教科书 |

## 安装 · Install

```bash
# 公文格式
quarto add songwupei/quarto-gbt9704

# 教科书格式
quarto add songwupei/quarto-textbook
```

## 快速开始 · Quick Start

参考示例文档 [`example.qmd`](example.qmd)，其中展示了标题、正文、多级标题、表格等公文要素。
<br><small>See [`example.qmd`](example.qmd) for a complete reference document with title, body, headings, tables, and more.</small>

```bash
quarto render example.qmd --to gbt9704-pdf     # PDF (LuaLaTeX)
quarto render example.qmd --to gbt9704-docx    # DOCX
quarto render example.qmd --to gbt9704-html    # HTML (公文 CSS，可截图转 PNG)
quarto render example.qmd --to gbt9704-pptx    # PPTX (蓝色商务)
quarto render example.qmd --to gbt9704-beamer  # Beamer PDF (青山绿水)
```

预渲染的输出文件：`example.pdf`、`example.docx`。

## 标题自动提取 · Title Fallback

当文档 YAML 头未指定 `title` 时，自动提取正文第一个一级标题（`# 标题`）作为公文大标题。
<br><small>When no `title` is specified in YAML frontmatter, the first H1 heading is automatically used as the document title.</small>

```markdown
# 关于加强xxx工作的通知

正文内容...
```

等价于显式指定：

```yaml
---
title: 关于加强xxx工作的通知
---
# 关于加强xxx工作的通知

正文内容...
```

> 注意：YAML `title` 优先级更高，显式指定时会覆盖 H1 提取。

## 标题编号自动识别 · Auto Numbering Detection

内置双模式标题引擎，自动识别文档的编号体系，无需手动标注层级：

| 模式 | 编号风格 | 示例 | 适用文档 |
|------|---------|------|---------|
| **通知模式** | 中文编号 `一、` `（一）` `1.` | 通知、报告、请示 | `一、总体进展` → H1 → 黑体 |
| **标准模式** | 数字编号 `1` `2.1` `3.1.2` | 标准、规范、指南 | `2.1 目标` → H2 → 楷体 |

### 通知模式

典型公文写法——标题用 `一、` `（一）` `1.`，支持**纯文本**和 **Markdown `#` 标题**混用：

```markdown
一、总体建设进展情况          ← 纯文本，自动提升为 H1 → 黑体

（一）各类模型进展情况        ← 纯文本，自动提升为 H2 → 楷体

1. 资金与财务类模型          ← 纯文本，自动提升为 H3 → 仿宋加粗

# 二、目前存在的主要问题      ← Markdown H1 → 黑体

## （一）组织机构主数据       ← Markdown H2 → 楷体
```

### 标准模式

标准/规范文件写法——数字编号 `1` `2.1` `2.2.1`，纯文本自动转换：

```markdown
1 范围                       ← 自动提升为 H1 → 黑体

2 目标与原则                  ← 自动提升为 H1 → 黑体

2.1 目标                     ← 自动提升为 H2 → 楷体

2.2.1 问题导向原则            ← 自动提升为 H3 → 仿宋加粗
```

> 检测逻辑：扫描全文 Header 编号模式。命中文编号 `一、`/`（一）` → 通知模式；命中数字编号 `1`/`2.1` → 标准模式。两种模式下均可混合使用纯文本和 Markdown 标题。

### 显式指定模式

不想依赖默认行为？在 YAML 头中设置 `title-type`，支持 `+` 组合：

```yaml
---
title-type: none              # 什么都不做
title-type: tongzhi           # 仅中文编号
title-type: biaozhun          # 仅数字编号
title-type: tongzhi+biaozhun  # 中文 + 数字
title-type: zhidu             # 制度文档（第X章/第X条）
---
```

同一个 Markdown，不同模式的渲染结果：

```markdown
一、总体进展          ← 中文编号
（一）子项            ← 中文子编号
1 范围               ← 数字编号
2.1 目标             ← 数字子编号
**1. 问题：** 答案     ← 混合格式
```

| 模式 | `一、` | `（一）` | `1 xxx` | `2.1 xxx` | `**1. 问题：**` | 适用场景 |
|------|:---:|:---:|:---:|:---:|:---:|------|
| `none` | 正文 | 正文 | 正文 | 正文 | 粗体+正文 | 考试试卷、普通文档 |
| `tongzhi` | **H1** | **H2** | 正文 | 正文 | 粗体+正文 | 通知、报告、请示 |
| `biaozhun` | 正文 | 正文 | **H1** | **H2** | 粗体+正文 | 标准、规范、指南 |
| `tongzhi+biaozhun` | **H1** | **H2** | **H1** | **H2** | 粗体+正文 | 混合编号文档 |
| `zhidu` | 正文 | 正文 | 正文 | 正文 | 粗体+正文 | 制度、法规、办法 |

> **设计原则**：四个独立规则，通过 `+` 自由组合。
> - `tongzhi` = 中文编号规则（`一、`→H1 `（一）`→H2）
> - `biaozhun` = 数字编号规则（`1`→H1 `2.1`→H2 `3.1.2`→H3）
> - `zhidu` = 制度文档规则（删除 H2/H3 标记，第X章居中黑体，第X条黑体前缀）
> - 默认（不设 `title-type`）= `tongzhi`，向后兼容

### 制度模式

专门为制度/法规/办法类文档设计。使用 `##` 标记章标题、`###` 标记条标题，渲染时自动：

- **删除 H2/H3 标题标记**：章和条不渲染为 HTML/DOCX/PDF 标题样式
- **第X章**：整行居中、不缩进、**黑体加粗**，章号后自动插入两个全角空格
- **第X条**：条号 **黑体加粗**，正文保持仿宋字体，条号后自动插入两个全角空格

```yaml
---
title-type: zhidu
---
```

```markdown
# 制度名称（H1 → 文档大标题）

## 第一章 总则

### 第一条 制定目的

正文内容……

### 第二条 适用范围

正文内容……

## 第二章 组织与职责

### 第三条 职责分工

正文内容……
```

> 支持 PDF（LuaLaTeX）、DOCX、HTML 三种输出格式。

## 使用 · Usage

在 Quarto 项目的 `_quarto.yml` 中：
<br><small>In your project's `_quarto.yml`:</small>

```yaml
format:
  gbt9704-pdf:
    keep-tex: true
  gbt9704-docx: default
```

或在文档 YAML 头中：
<br><small>Or in a document's YAML header:</small>

```yaml
---
title: 关于印发xxx的通知
format:
  gbt9704-pdf: default
---
```

## 格式特点 · Features

支持五种输出格式：**PDF**、**DOCX**、**HTML**、**PPTX**、**Beamer**。

| 特性 Feature | 说明 Description |
|---|---|
| 正文字体 Body font | 仿宋 16pt，行距 28pt，首行缩进 2 字符 |
| 大标题 Main title | 22pt 方正小标宋 |
| 一级标题 Heading 1 | 黑体 |
| 二级标题 Heading 2 | 楷体 |
| 页边距 Margins | 上 37mm / 下 35mm / 左 28mm / 右 26mm |
| 伪粗体 Fakebold | 支持中文字体加粗 · Bold for CJK fonts |
| 元数据 Metadata | 红头、密级、签发人 · Red-header, security level, signatory |
| 财务表格 Financial tables | fcolumn v1.5+：千分位分隔、小数点对齐、\sumline 合计线 |

## 财务表格 · Financial Tables

基于 **fcolumn** 宏包 (v1.5+)，提供财务表格的自动排版：

- **千分位分隔**：数字自动显示逗号千分位（如 `1,234.56`）
- **小数点对齐**：财务列自动按小数点对齐
- **合计线**：`\sumline` 自动绘制合计线并计算列合计
- **自动检测**：表格中含 `\sumline` 标记时自动启用，无需额外配置

### 在 Markdown 中使用

```markdown
| 项目       | 预算金额（元） | 实际支出（元） |
|------------|---------------|---------------|
| 办公设备    | 150000.00     | 148235.50     |
| 信息化建设  | 350000.00     | 328900.00     |
| \sumline   |               |               |
| 合计       |               |               |
```

### 使用 LaTeX 环境

```latex
\begin{financialtable}{l C C l}
\toprule
项目 & 预算金额（元） & 实际支出（元） & 备注 \\
\midrule
办公设备 & 150000.00 & 148235.50 & 已完成 \\
信息化建设 & 350000.00 & 328900.00 & 持续进行 \\
\sumline
合计 & & & \\
\bottomrule
\end{financialtable}
```

可用列类型：`l`（文本左对齐）、`f`（欧式财务列）、`C`（中式财务列，逗号千分位）、`N`（无千分位数字列）

## 表格修复 · Table Fixes

`fix-table.lua` 自动修复 Pipe Table 的三个常见问题：

| 问题 | 修复方式 |
|------|---------|
| `<br>` 不换行 | `RawInline html` → `LineBreak` |
| `tbl-colwidths` 列宽不生效 | 将 Div 属性传播到 Table `colspecs` |
| `□` (U+25A1) 字体缺失 | LaTeX 输出时回退到 Sarasa Mono SC |

> 所有格式（HTML/DOCX/PDF）均自动启用，无需额外配置。

## Emoji 支持 · Emoji Support

支持在文档中直接使用 emoji 字符（😊🎉✅⚠️📝），三种输出格式均可正确渲染。
<br><small>Use emoji characters directly in documents. All three output formats render them correctly.</small>

### 启用方法

在文档 YAML 头中设置 `emoji: true`:

```yaml
---
title: 关于加强xxx工作的通知
emoji: true
format:
  gbt9704-pdf: default
---

各位同仁 📞：

项目推进顺利 👍🏽，已达成以下里程碑 🏆：
- 软件开发 ✅ 已完成
- 硬件采购 ⏳ 进行中
```

### 使用 Pandoc 短码（可选）

如果你习惯使用 `:smile:` 风格的短码，可在项目配置中启用 Pandoc 的 `+emoji` 扩展：

`_quarto.yml`:
```yaml
format:
  gbt9704-pdf:
    from: markdown+emoji
```

或文档 YAML:
```yaml
---
title: 通知
emoji: true
from: markdown+emoji
---
:white_check_mark: 已完成
:warning: 请留意
```

> 注意：直接输入 Unicode emoji（😊）无需任何额外配置，`emoji: true` 即可。
> 短码方式需 Pandoc 3.0+ 支持（当前环境 Pandoc 3.6.1 ✅）。

### 各格式渲染效果

| 格式 | 渲染引擎 | emoji 效果 | 字体策略 |
|------|---------|-----------|---------|
| **PDF** (gbt9704-pdf) | LuaLaTeX | 彩色矢量 ✅ | bxcoloremoji → twemojis（PDF 彩色矢量图形） |
| **PDF** (gbt9704-pdf) | XeLaTeX | 黑白 ✅ | Segoe UI Emoji (COLRv0) → NotoEmoji-Regular |
| **DOCX** (gbt9704-docx) | Word / WPS | 黑白 ✅ | Segoe UI Symbol (纯 glyf，无 COLR 依赖) |
| **HTML** (gbt9704-html) | 浏览器 | 彩色 ✅ | 原生支持 |

> **技术说明**：
>
> **LuaLaTeX（推荐）**：bxcoloremoji → twemojis 渲染管线，emoji 以 PDF 彩色矢量图形输出，无需系统 emoji 字体。安装方式：`tlmgr install bxcoloremoji twemojis`。
>
> **XeLaTeX**：CID 字体嵌入会剥离 COLR 颜色表。选择 COLRv0 字体（Segoe UI Emoji）——其基础轮廓有实体 glyph，剥离颜色后仍可黑白渲染。
>
> **DOCX**：选择 Segoe UI Symbol（纯 glyf 轮廓字体），WPS / Office 均内置。
>

### 关闭 emoji

设置 `emoji: false` 或直接省略该字段即可关闭（默认关闭，向后兼容）。

## 幻灯片 · Slides

`gbt9704-pptx` 和 `gbt9704-beamer` 提供两种幻灯片格式，从 quarto-zhanshi 合并而来。

### PPTX

蓝色商务风格，基于 `reference-gbt9704.pptx` 模板。`slide-level: 2` 表示二级标题 (`##`) 开启新幻灯片。

> **布局选择机制**：Quarto/Pandoc 不支持手动指定 slide layout（如 `::: {.layout-name}`）。Pandoc 根据内容结构**自动匹配**布局：文字+表格 → Content with Caption，纯文字 → Title and Content，两栏 → Two Content。控制布局的唯一方式是**修改 reference pptx 中对应 layout 的占位符位置和大小**。

```yaml
---
title: "演示标题"
author: "汇报人"
format:
  gbt9704-pptx: default
---
```

### Beamer

青山绿水中文模板——楷体 · 山水配色 · 手绘波纹装饰。

```yaml
---
title: "演示标题"
author: "汇报人"
format:
  gbt9704-beamer: default
---
```

**特性**：
- 中文字体：STKaiti（华文楷体）+ Times New Roman + unicode-math
- 青山绿水配色：MountainGreen / BambooGreen / MistyTeal / StreamBlue
- 自定义 beamer 主题：手绘波纹标题线、进度条、山坡背景
- 章节转场页：每节开始自动插入水墨风格过渡页
- 定理盒子：定义/定理/引理/推论/命题/例（tcolorbox）
- 列表行间距：多行列表项自动增加间距

## 工具脚本 · Scripts

[`scripts/md2png.sh`](scripts/md2png.sh) — 将 Markdown / Quarto 文档渲染为 PNG 长图，支持 emoji 和 CJK 字体。

```bash
./scripts/md2png.sh document.md                      # HTML 模式（默认，emoji/CJK 好）
./scripts/md2png.sh document.md --width 1200          # 指定宽度
./scripts/md2png.sh document.md --margin 40           # 白边大小（默认 20px）
./scripts/md2png.sh document.md --mode pdf            # LaTeX PDF 模式
./scripts/md2png.sh example.qmd --format gbt9704-html # 扩展 HTML（公文 CSS）→ PNG
./scripts/md2png.sh example.qmd --format gbt9704-pdf  # 扩展 PDF（公文 LaTeX）→ PNG
```

详见 [`scripts/README.md`](scripts/README.md)。

## 开发 · Development

本仓库通过 git submodule 引用 [gbt9704-latex](https://github.com/songwupei/gbt9704-latex) 作为 LaTeX 源头。

```bash
# 克隆时初始化 submodule
git clone --recurse-submodules git@github.com:songwupei/quarto-gbt9704.git

# 或克隆后手动拉取
git submodule update --init --recursive
```

`_extensions/gbt9704/` 下的以下文件为指向 `latex-source/gbt9704/` 的符号链接：

| 文件 | 说明 |
|------|------|
| `gbt9704.cls` | LaTeX 文档类 |
| `gbt9704-layout.json` | 布局参数定义 |
| `gbt9704-layout.lua` | 布局参数（Lua 常量，Quarto 渲染时生效） |
| `gbt9704-layout.def` | 布局参数（LaTeX 宏定义，直接编译时兜底） |

### 更新 LaTeX 源头

```bash
./tools/update-latex-source.sh      # 拉取最新并暂存，打印变更日志
git commit -m "chore: update latex-source submodule"
```

### 本地修改布局参数

如需本地调试布局参数，可直接修改 `latex-source/gbt9704/gbt9704-layout.json`，然后运行：

```bash
./tools/sync-layout.sh
```

> 注意：`.lua` / `.def` 均由 JSON 自动生成，请勿手改。渲染 PDF 时实际生效的是 `.lua`（由 `assets/filters/layout-loader.lua` 在渲染时读取并注入 LaTeX 覆盖）；`.def` 仅在直接使用 gbt9704.cls 编译（不走 Quarto）时被读取。`tools/json2def.py` 同步自 [gbt9704-latex](https://github.com/songwupei/gbt9704-latex)。

可定制参数包括红头字号/颜色/紧缩比例、红头与发文号间距、红线粗细、大标题字号、主送人字号、落款字号等。详见 JSON 文件内注释。

## 破坏性变更 · Breaking Changes

- **v0.7.4** — `gbt9704.cls` 和 `gbt9704-layout.*` 改为 git submodule (`latex-source`) 符号链接，不再手动复制。克隆时需 `--recurse-submodules`。
- **v0.7.0** — 合并 quarto-zhanshi：新增 `gbt9704-pptx`（蓝色商务）和 `gbt9704-beamer`（青山绿水）幻灯片格式。
- **v0.6.13** — 新增 `tools/json2def.py` 布局生成器与渲染前自动同步：修改 `gbt9704-layout.json` 后，`quarto render` 会自动重新生成 `.lua` / `.def`（通过项目 `_quarto.yml` 的 pre-render 钩子调用）。
- **v0.6.10** — 引入 `gbt9704-layout.json` 布局参数系统。`gbt9704.cls` 中的可变参数（红头字号/颜色/间距等）改为从 JSON 生成的 `.def` / `.lua` 常量读取（Quarto 渲染时以 `.lua` 生效），支持 JSON 驱动定制，无需编辑 `.cls`。
- **v0.6.2** — 同步 gbt9704.cls v0.1.4：标题样式改用 ctex `\ctexset` 接口（修复 `heading=true` 时黑体不生效），中文序号排版（一、（一）、1.），附件间距修复。
- **v0.6.0** — 重构 `title-type`：删除 `auto`/`shijuan`，改为 `none`/`tongzhi`/`biaozhun` 三个独立规则，支持 `+` 组合（如 `tongzhi+biaozhun`）。
- **v0.5.1** — 重构标题引擎。新增 `numbering-to-headings.lua`（数字编号自动转换）+ 重构 `heading-demotion.lua`（双模式自动识别）。标准/规范类文档（`1`/`2.1` 编号）开箱即用，通知类文档向后兼容。
- **v0.5.0** — 放弃 ConTeXt 支持。移除 `gbt9704-context` 格式、`context-template.tex` 模板以及 `context-support.lua` / `fakebold.lua` / `natural-table.lua` 三个 ConTeXt 专用 filter。如果仍需要 ConTeXt 输出，请使用 v0.4.x 版本。

## 许可证 · License

MIT
