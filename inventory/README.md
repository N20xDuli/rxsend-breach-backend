# 资源清单（inventory）

## 这是什么

服务器上每个文件的「身份 + 位置」快照，**不是备份**。

每行一个文件，制表符分隔：

```
sha256　size　mtime　mode　uid:gid　path
```

它只回答三个问题：

1. 从上次快照到现在，**哪些文件被改了 / 新增了 / 删了？**
2. 某个文件**被挪到哪去了？**（同一个 sha256 出现在两个路径 → MOVED）
3. 权限 / 属主有没有被搞乱？（root 写了本该属于 `rxsend` 的文件之类）

它**不能**还原文件内容。地图和模型由团队另行保存，这里只负责"发现变化"。

## 怎么生成

脚本在 `tools/rx_inventory.py`，只读，不修改任何文件。

```bash
# 在服务器上
sudo python3 rx_inventory.py --root /srv/rxsend/server \
     --out inventory/server-$(date +%F).tsv --summary
```

实测：36,081 个文件 / 16.6 GiB / **20 秒**（844 MiB/s）。

把产出拉回本地，提交到本仓库即可。文件名的日期是本仓库区分快照版本的唯一依据。

## 怎么看变化

```bash
python3 tools/rx_inventory_diff.py \
    inventory/server-2026-11-06.tsv \
    inventory/server-2026-11-20.tsv
```

输出五类：

| 类别 | 含义 |
|---|---|
| `ADDED` | 新增路径 |
| `REMOVED` | 消失路径 |
| `MODIFIED` | 同路径，内容变了（sha256 不同） |
| `MOVED` | 同 sha256 换了路径 —— **"文件去哪了"** |
| `TOUCHED` | 内容没变，但权限 / 属主 / 大小变了 |

也可以直接看 git：

```bash
git log --oneline -- inventory/
git diff HEAD~1 -- inventory/          # 上一次提交以来的变化
```

## 默认排除（避免噪音）

`tools/rx_inventory.py` 的 `DEFAULT_EXCLUDE`：

- `garrysmod/logs/*`、`garrysmod/*.log` —— 日志天然一直在变
- `garrysmod/sv.db-wal`、`garrysmod/sv.db-shm` —— sqlite 运行时文件

如果要连这些一起记录，加 `--no-default-excludes`。

## 已知噪声源

即使不做任何改动，这些文件也会在运行中变化，出现 TOUCHED 是正常的：

- `garrysmod/sv.db` —— sqlite 主库
- `garrysmod/data/**` —— ULX / 玩家存档
- `garrysmod/settings/**` —— ULX 配置回写
- `.deployment-private/instance.lock` —— 服务进程锁

## 当前基线

| 快照 | 文件数 | 体积 | 服务端 | 备注 |
|---|---:|---:|---|---|
| `server-2026-11-06.tsv` | 36,081 | 16.62 GiB | PRIVATE 仓库 `rxsend-breach-backend` | 首次建库；连续两次快照 diff 为 0，噪声基线干净 |
