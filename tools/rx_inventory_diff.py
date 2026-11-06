#!/usr/bin/env python3
"""对比两份 RXSend 资源清单，回答「什么变了 / 文件去哪了」。

用法：
    python3 rx_inventory_diff.py inventory/server-2026-11-06.tsv inventory/server-2026-11-20.tsv

输出分五类：
    ADDED     新增路径
    REMOVED   消失路径
    MODIFIED  同路径但内容变了（sha256 不同）
    TOUCHED   同路径同内容，但权限/属主/大小变了
    MOVED     同一个 sha256 出现在两个不同路径（改名 / 挪位置）

常用选项：
    --quiet-moved   不打印 MOVED 明细
    --json          输出机器可读 JSON
"""

import argparse
import json
import sys
from collections import defaultdict


def load(path):
    """返回 {relpath: (sha256, size, mtime, mode, owner)}"""
    data = {}
    with open(path, "r", encoding="utf-8") as fh:
        for lineno, line in enumerate(fh, 1):
            line = line.rstrip("\n")
            if not line:
                continue
            parts = line.split("\t")
            if len(parts) != 6:
                print(f"警告: {path}:{lineno} 字段数 {len(parts)} != 6，已跳过",
                      file=sys.stderr)
                continue
            digest, size, mtime, mode, owner, rel = parts
            data[rel] = (digest, int(size), int(mtime), mode, owner)
    return data


def human(n):
    for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
        if abs(n) < 1024:
            return f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} PiB"


def main():
    ap = argparse.ArgumentParser(description="对比两份资源清单")
    ap.add_argument("old")
    ap.add_argument("new")
    ap.add_argument("--quiet-moved", action="store_true")
    ap.add_argument("--json", action="store_true", dest="as_json")
    args = ap.parse_args()

    old = load(args.old)
    new = load(args.new)

    old_paths, new_paths = set(old), set(new)
    added = sorted(new_paths - old_paths)
    removed = sorted(old_paths - new_paths)

    modified, touched = [], []
    for rel in sorted(old_paths & new_paths):
        oh, osz, _om, omode, oown = old[rel]
        nh, nsz, _nm, nmode, nown = new[rel]
        if oh != nh:
            modified.append((rel, oh, nh))
        elif (osz, omode, oown) != (nsz, nmode, nown):
            touched.append((rel, (osz, omode, oown), (nsz, nmode, nown)))

    # MOVED：消失的路径与新增的路径里，sha256 相同的配对
    removed_by_hash = defaultdict(list)
    for rel in removed:
        removed_by_hash[old[rel][0]].append(rel)
    added_by_hash = defaultdict(list)
    for rel in added:
        added_by_hash[new[rel][0]].append(rel)

    moved = []
    for digest in set(removed_by_hash) & set(added_by_hash):
        srcs = sorted(removed_by_hash[digest])
        dsts = sorted(added_by_hash[digest])
        for i in range(min(len(srcs), len(dsts))):
            moved.append((srcs[i], dsts[i], digest))

    moved_src = {m[0] for m in moved}
    moved_dst = {m[1] for m in moved}

    result = {
        "old": args.old,
        "new": args.new,
        "old_files": len(old),
        "new_files": len(new),
        "added": [p for p in added if p not in moved_dst],
        "removed": [p for p in removed if p not in moved_src],
        "modified": [{"path": p, "old_sha256": a, "new_sha256": b}
                     for p, a, b in modified],
        "touched": [{"path": p, "old": list(a), "new": list(b)}
                    for p, a, b in touched],
        "moved": [{"from": s, "to": d, "sha256": h} for s, d, h in moved],
    }

    if args.as_json:
        json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
        print()
        return

    real_added = result["added"]
    real_removed = result["removed"]

    print(f"旧清单: {args.old}  ({len(old)} 个文件)")
    print(f"新清单: {args.new}  ({len(new)} 个文件)")
    print()
    print(f"  ADDED    {len(real_added)}")
    print(f"  REMOVED  {len(real_removed)}")
    print(f"  MODIFIED {len(modified)}")
    print(f"  MOVED    {len(moved)}")
    print(f"  TOUCHED  {len(touched)}")

    def section(title, items):
        if not items:
            return
        print(f"\n--- {title} ---")
        for item in items:
            print(f"  {item}")

    section("ADDED", real_added)
    section("REMOVED", real_removed)
    section("MODIFIED", [f"{p}  ({a[:8]} -> {b[:8]})" for p, a, b in modified])
    if not args.quiet_moved:
        section("MOVED", [f"{s}  ->  {d}" for s, d, _ in moved])
    section("TOUCHED", [f"{p}  {a} -> {b}" for p, a, b in touched])

    # 给个总体积变化的提示，方便判断是不是整包被替换了
    old_bytes = sum(v[1] for v in old.values())
    new_bytes = sum(v[1] for v in new.values())
    delta = new_bytes - old_bytes
    print(f"\n总体积: {human(old_bytes)} -> {human(new_bytes)}  ({delta:+,})".replace(
        f"{delta:+,}", f"{human(abs(delta))} {'增加' if delta >= 0 else '减少'}"))


if __name__ == "__main__":
    main()
