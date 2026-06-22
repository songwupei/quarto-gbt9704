# quarto-gbt9704

Quarto 扩展：GB/T 9704 党政机关公文格式。

支持三种输出格式：**PDF**（XeLaTeX）、**DOCX**、**ConTeXt**。

## 安装

```bash
quarto add songwupei/quarto-gbt9704
```

## 使用

在 Quarto 项目的 `_quarto.yml` 中：

```yaml
format:
  gbt9704-pdf:
    keep-tex: true
  gbt9704-docx: default
```

或在文档 YAML 头中：

```yaml
---
title: 关于印发xxx的通知
format:
  gbt9704-pdf: default
---
```

## 格式特点

- 仿宋正文 16pt，行距 28pt，首行缩进 2 字符
- 大标题 22pt 方正小标宋
- 一级标题黑体，二级标题楷体
- 页边距：上 37mm / 下 35mm / 左 28mm / 右 26mm
- 伪粗体（fakebold）支持中文字体加粗
- 可配置红头、密级、签发人等元数据

## 许可证

MIT
