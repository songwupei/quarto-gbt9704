# quarto-gbt9704

Quarto 扩展：GB/T 9704 党政机关公文格式。
<br><small>Quarto extension: GB/T 9704 Chinese government document format.</small>

支持三种输出格式：**PDF**（XeLaTeX）、**DOCX**、**ConTeXt**。
<br><small>Supports three output formats: PDF (XeLaTeX), DOCX, ConTeXt.</small>

## 安装 · Install

```bash
quarto add songwupei/quarto-gbt9704
```

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

| 特性 Feature | 说明 Description |
|---|---|
| 正文字体 Body font | 仿宋 16pt，行距 28pt，首行缩进 2 字符 |
| 大标题 Main title | 22pt 方正小标宋 |
| 一级标题 Heading 1 | 黑体 |
| 二级标题 Heading 2 | 楷体 |
| 页边距 Margins | 上 37mm / 下 35mm / 左 28mm / 右 26mm |
| 伪粗体 Fakebold | 支持中文字体加粗 · Bold for CJK fonts |
| 元数据 Metadata | 红头、密级、签发人 · Red-header, security level, signatory |

## 许可证 · License

MIT
