#!/usr/bin/env python3
"""
extract-pdf-headings.py — 提取 PDF 各级标题的字体、字号等信息，输出 JSON

用法:
  python3 extract-pdf-headings.py <pdf_file> [--json] [--all]

依赖: mutool (mupdf)
"""

import subprocess
import xml.etree.ElementTree as ET
import json
import re
import sys
import os
import html
from collections import defaultdict

# ─── 标题分类规则 ───
PATTERNS = [
    ("chapter",    r"^第[一二三四五六七八九十百千\d]+章"),      # 第X章
    ("section",    r"^第[一二三四五六七八九十百千\d]+节"),      # 第X节
    ("article",    r"^第[一二三四五六七八九十百千\d]+条"),      # 第X条
    ("subitem_cn", r"^（[一二三四五六七八九十百千]+）"),        # （一）（二）
    ("subitem_num", r"^\d+\."),                                 # 1. 2.
    ("page_number", r"^—\s*\d+\s*—$"),                          # — N —
]


def classify(text):
    """根据文本内容分类"""
    text = text.strip()
    if not text:
        return "empty"
    for label, pattern in PATTERNS:
        if re.match(pattern, text):
            return label
    return "body"


def run_mutool(pdf_path):
    """运行 mutool 提取结构化文本 XML"""
    result = subprocess.run(
        ["mutool", "draw", "-F", "stext", pdf_path],
        capture_output=True, text=True, timeout=60
    )
    if result.returncode != 0:
        print(f"mutool error: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    return result.stdout


def parse_stext_xml(xml_str):
    """解析 mutool stext XML，提取每行的字体信息"""
    root = ET.fromstring(xml_str)
    results = []
    ns = {}  # no namespace

    for page in root.findall(".//page"):
        page_num = page.get("id", "?")

        for block in page.findall(".//block"):
            block_bbox = block.get("bbox", "")

            for line in block.findall(".//line"):
                fonts = line.findall("font")
                if not fonts:
                    continue

                # text 在 <line> 元素上, font name/size 在 <font> 子元素上
                full_text = line.get("text", "")
                if not full_text:
                    continue
                # XML 实体解码 (&#xXXXX; → Unicode)
                full_text = html.unescape(full_text)

                # 一行可能有多个 font 切换，取第一个为主字体
                main_font = fonts[0]
                font_name = main_font.get("name", "unknown")
                font_size = float(main_font.get("size", 0))

                # 同时计算行 bbox
                line_bbox = line.get("bbox", "")

                results.append({
                    "page": page_num,
                    "text": full_text,
                    "font": font_name,
                    "size": round(font_size, 2),
                    "bbox": line_bbox,
                    "block_bbox": block_bbox,
                })

    return results


def extract_size_range(items):
    """计算字号范围"""
    if not items:
        return None
    sizes = [i["size"] for i in items]
    return {"min": round(min(sizes), 2), "max": round(max(sizes), 2), "avg": round(sum(sizes)/len(sizes), 2)}


def analyze(pdf_path, all_text=False):
    """主分析函数"""
    xml_str = run_mutool(pdf_path)
    lines = parse_stext_xml(xml_str)

    # 按标题类型分组
    groups = defaultdict(list)
    summary = {}

    for item in lines:
        label = classify(item["text"])
        groups[label].append(item)

    # 生成摘要
    for label in ["chapter", "section", "article", "subitem_cn", "subitem_num", "body"]:
        items = groups.get(label, [])
        if not items:
            continue

        fonts = list(set(i["font"] for i in items))
        sizes = extract_size_range(items)
        pages = list(set(i["page"] for i in items))

        entry = {
            "count": len(items),
            "fonts": fonts,
            "size_range": sizes,
            "pages": sorted(pages, key=lambda x: int(x) if x.isdigit() else 0),
        }

        if label == "body":
            # 正文：额外统计每页代表性的字体/字号
            entry["samples"] = []
            seen_pages = set()
            for i in items:
                if i["page"] not in seen_pages:
                    entry["samples"].append({
                        "page": i["page"],
                        "text": i["text"][:30],
                        "font": i["font"],
                        "size": i["size"],
                    })
                    seen_pages.add(i["page"])
                    if len(seen_pages) >= 3:
                        break

        summary[label] = entry

    # 页面总数
    summary["_meta"] = {
        "file": os.path.basename(pdf_path),
        "total_pages": len(set(i["page"] for i in lines)),
        "total_text_lines": len(lines),
    }

    return summary, lines if all_text else None


def main():
    import argparse
    parser = argparse.ArgumentParser(description="提取 PDF 各级标题字体信息")
    parser.add_argument("pdf", help="PDF 文件路径")
    parser.add_argument("--json-only", action="store_true", help="仅输出 JSON（禁止其他输出）")
    parser.add_argument("--all", action="store_true", help="输出所有行的详细信息")
    args = parser.parse_args()

    summary, all_lines = analyze(args.pdf, all_text=args.all)

    output = summary.copy()
    if all_lines:
        output["_all_lines"] = all_lines

    if args.json_only:
        print(json.dumps(output, ensure_ascii=False, indent=2))
    else:
        print(json.dumps(output, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
