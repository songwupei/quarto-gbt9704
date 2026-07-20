# quarto-gbt9704

Quarto 扩展：GB/T 9704 党政机关公文格式。
<br><small>Quarto extension: GB/T 9704 Chinese government document format.</small>

支持四种输出格式：**PDF**（XeLaTeX）、**DOCX**、**ConTeXt**、**HTML**。
<br><small>Supports four output formats: PDF (XeLaTeX), DOCX, ConTeXt, HTML.</small>

## 安装 · Install

```bash
quarto add songwupei/quarto-gbt9704
```

## 快速开始 · Quick Start

参考示例文档 [`example.qmd`](example.qmd)，其中展示了标题、正文、多级标题、表格等公文要素。
<br><small>See [`example.qmd`](example.qmd) for a complete reference document with title, body, headings, tables, and more.</small>

```bash
quarto render example.qmd --to gbt9704-pdf     # PDF (XeLaTeX)
quarto render example.qmd --to gbt9704-docx    # DOCX
quarto render example.qmd --to gbt9704-context # ConTeXt
quarto render example.qmd --to gbt9704-html    # HTML (公文 CSS，可截图转 PNG)
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

## 使用 · Usage

在 Quarto 项目的 `_quarto.yml` 中：
<br><small>In your project's `_quarto.yml`:</small>

```yaml
format:
  gbt9704-pdf:
    keep-tex: true
  gbt9704-docx: default
  gbt9704-context:
    keep-tex: true
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

支持四种输出格式：**PDF**、**DOCX**、**ConTeXt**、**HTML**。

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

## Emoji 支持 · Emoji Support

支持在文档中直接使用 emoji 字符（😊🎉✅⚠️📝），四种输出格式均可正确渲染。
<br><small>Use emoji characters directly in documents. All four output formats render them correctly.</small>

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

| 格式 | 渲染引擎 | emoji 效果 |
|------|---------|-----------|
| **PDF** (gbt9704-pdf) | XeLaTeX + Harfbuzz | 彩色 ✅（驱动不支持时自动降级黑白） |
| **DOCX** (gbt9704-docx) | Word OpenXML | 彩色 ✅（Segoe UI Emoji） |
| **ConTeXt** (gbt9704-context) | ConTeXt | 彩色 ✅（Noto Color Emoji） |
| **HTML** (gbt9704-html) | 浏览器 | 彩色 ✅（原生支持） |

### 关闭 emoji

设置 `emoji: false` 或直接省略该字段即可关闭（默认关闭，向后兼容）。

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

## 许可证 · License

MIT
