# RXSend Breach — 后端源码仓库

Garry's Mod `rxsend_breach` 游戏模式的服务端 / 共享 / 客户端源码备份仓库。

- **基线来源**：现网服务器 `orisland`，路径 `/srv/rxsend/server/garrysmod/gamemodes/rxsend_breach`
- **抓取时间**：2026-11-06 08:43 (+08:00)
- **校验方式**：544 个文件逐一比对 SHA256，`MATCH 544 / MISMATCH 0 / MISSING 0`
- **基线清单**：`docs/baseline.sha256`（服务端 `sha256sum` 原始输出）

> 本仓库**只放代码与配置**，不含地图 / 模型 / 材质 / 音频等资源文件。
> 资源在服务器上约 17 GB，不适合进 Git。

---

## 目录结构

```
garrysmod/
├── gamemodes/rxsend_breach/      游戏模式本体（541 个 Lua，约 14.6 万行）
│   ├── gamemode/
│   │   ├── init.lua              服务端入口
│   │   ├── shared.lua            自动装载器（按 cl_ / sv_ / sh_ 前缀分发）
│   │   ├── cl_init.lua           客户端入口
│   │   ├── modules/              138 个模块 + anim_base / scp173 / scp106 子目录
│   │   ├── languages/            chinese / english / russian
│   │   └── mapconfigs/           各张地图的出生点与实体数据
│   ├── entities/                 361 个实体 / 武器 / 特效
│   ├── rxsend_breach.txt         游戏模式清单（含 convar 默认值）
│   └── .gitignore
└── cfg/rxsend-test.cfg           服务器启动配置（已剔除 private.cfg 中的密码）

deployment/                       systemd 包装与运维脚本
├── run-test-server.py            服务启动包装（ExecStart）
├── server-control.py             本地 RCON 控制 / 优雅停机
└── initialize-test-server.py     首次部署初始化

docs/
├── 01-服务器勘察报告.md           服务器 / 代码 / 缺口的完整勘察
└── baseline.sha256              基线校验清单
```

---

## 服务端运行方式

| 项目 | 值 |
|---|---|
| systemd unit | `rxsend-server.service` |
| 运行用户 | `rxsend`（非特权） |
| 启动命令 | `python3 /srv/rxsend/server/tools/deployment/run-test-server.py` |
| 游戏端口 | `30679/tcp+udp` |
| 模式 / 地图 | `rxsend_breach` / `rxsend_site19-1` |
| 存档后端 | sqlite（前缀 `rxlocal_`） |

---

## 部署流程（**不要直接改现网文件**）

服务器上没有 git，历史交付走带哈希清单的暂存包：

```
/srv/rxsend/staging/<name>/     ← 必须放在 /srv/rxsend/server 之外
├── README.txt                  操作步骤
├── apply.py                    check / apply / rollback
├── manifest.json               每个文件 old + new SHA256
└── payload.tar.gz
```

```bash
sudo python3 apply.py check                    # 只读预检，允许有玩家在线
sudo systemctl stop rxsend-server              # 正常停服
sudo python3 apply.py apply                    # 校验哈希 → 备份 → 原子替换
sudo python3 apply.py check --expect new       # 校验新文件 & 已删除文件
sudo systemctl start rxsend-server
```

回滚：`sudo python3 apply.py rollback --backup /srv/rxsend/backups/<name>`

`apply.py` 会拒绝：符号链接、路径穿越、未知归档条目、old-hash 不匹配、进程仍持有实例锁。
替换时保留原文件的 mode / UID / GID，异常时按已知哈希自动回滚。

---

## 已知缺口（详见 docs/01-服务器勘察报告.md）

1. `ROUNDS` 表只有 `normal` 和 `ww2tdm` 两个条目；`ulx forceround` 却承诺 8 个模式名。
2. `BREACH_ROLES.MINIGAMES.minigame.roles` 只有 `[1..3]`，而 `Setuphl2` / `SetupCTF` 取 `roles[4]` —— 触发即崩。
3. 这些模式所需的地图全局量（`SPAWN_NAZI_1`、`SPAWN_USA_1`、`EVENTPODAVAL`、`BREACH.CTF.*`）在本图不存在。
4. 主模式 `normal.endcheck` 的胜负判定整段被注释。
5. 18 个 SCP 出生点在 `mapconfigs/rxsend_site19-1.lua` 中缺失，回落默认表。

---

## 变更约定

- 所有改动基于本仓库分支进行，通过 `git diff` 审查后再打包。
- 每次交付打包时，`manifest.json` 的 old-hash 必须对应本仓库当前 commit 的文件哈希。
- `.gitattributes` 设为 `* -text`：禁止换行归一化，保证 git blob 与服务端文件字节一致。
- 机密（`rcon_password`、`sv_password`）只存在于服务端 `cfg/rxsend-test.private.cfg`，永不入库。

---

## 扩展点速查

| 要做什么 | 改哪里 |
|---|---|
| 新增团队 / 阵营颜色 | `modules/sh_gteams.lua` 末尾 `gteams.SetUp(...)` |
| 新增角色 | `modules/sh_roles_scp.lua` 的 `BREACH_ROLES.<阵营>`，或独立 `sh_<faction>.lua` + `BREACH.<X>.Register()` |
| 新增游戏模式 | `modules/sv_rounds.lua` 的 `ROUNDS` 表加条目（`setup`/`init`/`roundstart`/`postround`/`endcheck`） |
| 新增模式的人数分配 | `modules/sv_round_setup.lua`（参照 `SetupPlayers`） |
| 地图出生点 / 实体数据 | `gamemode/mapconfigs/<地图名>.lua` |
| 角色属性生效逻辑 | `modules/sv_player.lua` 的 `mply:ApplyRoleStats` |
