#!/usr/bin/env python3
"""RXSend 资源清单生成器（只读）。

输出按路径排序的 TSV，每行一个文件：

    sha256 <TAB> size <TAB> mtime <TAB> mode <TAB> uid:gid <TAB> path

用途：记录服务器上每个文件的身份与位置，之后用 `rx_inventory_diff.py`
回答三个问题：
    1. 哪些文件被改了 / 新增了 / 删了？
    2. 某个文件被挪到哪去了？（按 sha256 匹配）
    3. 权限 / 属主有没有被搞乱？

它**不是备份**：无法还原文件内容，只负责发现变化。

用法：
    sudo python3 rx_inventory.py --root /srv/rxsend/server --out /tmp/inventory.tsv
    sudo python3 rx_inventory.py --out inventory/server.tsv --summary
"""

import argparse
import fnmatch
import hashlib
import os
import stat
import sys
import time

SKIP_DIRS = {".git", "__pycache__", "lost+found"}

# 默认排除：这些目录的内容天然高频变动，会对 diff 造成噪音。
DEFAULT_EXCLUDE = [
    "garrysmod/logs/*",
    "garrysmod/*.log",
    "garrysmod/sv.db-wal",
    "garrysmod/sv.db-shm",
]


def sha256_of(path, bufsize=1 << 20):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        while True:
            chunk = fh.read(bufsize)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def excluded(rel, patterns):
    for pat in patterns:
        if fnmatch.fnmatch(rel, pat):
            return True
    return False


def main():
    ap = argparse.ArgumentParser(description="生成 RXSend 资源清单 TSV")
    ap.add_argument("--root", default="/srv/rxsend/server", help="扫描根目录")
    ap.add_argument("--out", default="-", help="输出文件，- 表示 stdout")
    ap.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                    help="额外排除规则（可重复）")
    ap.add_argument("--no-default-excludes", action="store_true")
    ap.add_argument("--summary", action="store_true", help="结束时向 stderr 打印统计")
    args = ap.parse_args()

    root = os.path.abspath(args.root)
    if not os.path.isdir(root):
        sys.exit(f"根目录不存在: {root}")

    patterns = list(args.exclude)
    if not args.no_default_excludes:
        patterns += DEFAULT_EXCLUDE

    started = time.time()
    rows = []
    unreadable = []
    total_files = 0
    total_bytes = 0

    for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
        dirnames[:] = sorted(d for d in dirnames if d not in SKIP_DIRS)
        for name in filenames:
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, root).replace(os.sep, "/")
            if excluded(rel, patterns):
                continue
            try:
                st = os.lstat(full)
            except OSError:
                continue
            # 只记录普通文件：符号链接/设备/管道单独统计，不混进清单
            if not stat.S_ISREG(st.st_mode):
                continue
            try:
                digest = sha256_of(full)
            except OSError:
                digest = "!unreadable"
                unreadable.append(rel)
            rows.append((
                rel,
                digest,
                st.st_size,
                int(st.st_mtime),
                stat.S_IMODE(st.st_mode),
                f"{st.st_uid}:{st.st_gid}",
            ))
            total_files += 1
            total_bytes += st.st_size
            if total_files % 5000 == 0:
                print(f"  ... {total_files} 个文件 / {total_bytes/2**30:.2f} GiB",
                      file=sys.stderr)

    rows.sort(key=lambda r: r[0])

    out = sys.stdout if args.out == "-" else open(args.out, "w", encoding="utf-8", newline="\n")
    try:
        for rel, digest, size, mtime, mode, owner in rows:
            out.write(f"{digest}\t{size}\t{mtime}\t{mode:04o}\t{owner}\t{rel}\n")
    finally:
        if out is not sys.stdout:
            out.close()

    elapsed = time.time() - started
    if args.summary:
        print(f"根目录 : {root}", file=sys.stderr)
        print(f"文件数 : {total_files}", file=sys.stderr)
        print(f"总字节 : {total_bytes} ({total_bytes/2**30:.2f} GiB)", file=sys.stderr)
        print(f"耗时   : {elapsed:.1f}s ({total_bytes/max(elapsed,1e-9)/2**20:.0f} MiB/s)",
              file=sys.stderr)
        if unreadable:
            print(f"无法读取: {len(unreadable)} 个文件", file=sys.stderr)
            for p in unreadable[:20]:
                print(f"    {p}", file=sys.stderr)


if __name__ == "__main__":
    main()
