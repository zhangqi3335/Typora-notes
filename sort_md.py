#!/usr/bin/env python3
# sort_md.py
# 按“出现的 '#' 级别顺序”生成编号（1 / 1.1 / 1.1.1 ...），保留缩进、不生成 TOC。

import re
import sys
import os

def renumber_markdown(input_file, output_file):
    # seen_levels: 按出现顺序记录不同的 '#' 数量，例如 [1,3,4]
    seen_levels = []
    # counters: 与 seen_levels 对应的计数器
    counters = []

    # 匹配可能的前导空格、连续的 #（1~6）、及标题内容
    pattern = re.compile(r'^(\s*)(#{1,6})\s*(.*\S)?\s*$')

    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    out_lines = []

    for line in lines:
        m = pattern.match(line)
        if not m:
            out_lines.append(line)
            continue

        leading, hashes, title = m.groups()
        title = (title or '').strip()
        hash_count = len(hashes)

        # 如果 hash_count 尚未出现在 seen_levels 中，插入到合适的位置：
        if hash_count in seen_levels:
            idx = seen_levels.index(hash_count)
            depth = idx + 1
            # 增加该深度计数，清零更深计数
            counters[idx] += 1
            for j in range(idx+1, len(counters)):
                counters[j] = 0
        else:
            # 找到插入位置：在最后一个小于 hash_count 的索引后插入
            insert_pos = None
            for i in range(len(seen_levels)-1, -1, -1):
                if seen_levels[i] < hash_count:
                    insert_pos = i + 1
                    break
            if insert_pos is None:
                insert_pos = 0
            # 插入新层级，并初始化计数器为 1
            seen_levels.insert(insert_pos, hash_count)
            counters.insert(insert_pos, 1)
            # 清零之后的 deeper 计数（保持树形）
            for j in range(insert_pos+1, len(counters)):
                counters[j] = 0
            depth = insert_pos + 1

        # 生成编号：只保留到当前 depth（父级到当前级）的计数
        numbering = '.'.join(str(counters[i]) for i in range(depth))

        # 生成新标题，保留 leading 空格 和 原来的 # 数
        new_title_line = f"{leading}{hashes} {numbering} {title}\n"
        out_lines.append(new_title_line)

    with open(output_file, 'w', encoding='utf-8') as f:
        f.writelines(out_lines)

    print(f"✔ 输出: {output_file}")
    print(f"  发现的 header levels (by # count): {seen_levels}")
    print(f"  对应计数器状态: {counters}")

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

if __name__ == '__main__':
    main()
