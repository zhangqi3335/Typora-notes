#!/usr/bin/env python3
# sort_md.py
# 按 Markdown 真实层级编号（支持 ## 起始 / 忽略代码块 / 剥离旧编号）

import re
import sys
import os

HEADER_RE = re.compile(r'^(\s*)(#{1,6})\s+(.*)$')
OLD_NUM_RE = re.compile(r'^\d+(\.\d+)*\s*\.?\s*')

def renumber_markdown(input_file, output_file):
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # ---------- 1. 找到第一个标题级作为基准 ----------
    base_level = None
    for line in lines:
        m = HEADER_RE.match(line)
        if m:
            base_level = len(m.group(2))
            break

    if base_level is None:
        print("未发现任何 Markdown 标题")
        return

    counters = [0] * 6
    in_code_block = False
    out_lines = []

    for line in lines:
        stripped = line.strip()

        # ---------- 代码块 ----------
        if stripped.startswith("```"):
            in_code_block = not in_code_block
            out_lines.append(line)
            continue

        if in_code_block:
            out_lines.append(line)
            continue

        # ---------- 标题 ----------
        m = HEADER_RE.match(line)
        if not m:
            out_lines.append(line)
            continue

        leading, hashes, title = m.groups()
        raw_level = len(hashes)

        # 计算逻辑层级（从 1 开始）
        level = raw_level - base_level + 1
        if level < 1:
            level = 1

        # 清理原标题里的旧编号
        title = OLD_NUM_RE.sub('', title).strip()

        # 计数
        counters[level - 1] += 1
        for i in range(level, 6):
            counters[i] = 0

        numbering = ".".join(str(counters[i]) for i in range(level))
        new_line = f"{leading}{hashes} {numbering} {title}\n"
        out_lines.append(new_line)

    with open(output_file, 'w', encoding='utf-8') as f:
        f.writelines(out_lines)

    print("✔ 处理完成")
    print("基准标题级别:", "#" * base_level)
    print("输出文件:", output_file)

def main():
    if len(sys.argv) < 2:
        print("用法: python sort_md.py input.md [output.md]")
        return

    input_file = sys.argv[1]
    if not os.path.exists(input_file):
        print("找不到文件:", input_file)
        return

    if len(sys.argv) >= 3:
        output_file = sys.argv[2]
    else:
        name, ext = os.path.splitext(input_file)
        output_file = f"{name}_sorted{ext}"

    renumber_markdown(input_file, output_file)

if __name__ == "__main__":
    main()
