BREACH = BREACH or {}
BREACH.RemoteAdmin = BREACH.RemoteAdmin or {}
local RA = BREACH.RemoteAdmin

-- Only these commands can cross the panel's network boundary.
RA.Actions = {
    grant_admin = {name = "授予管理员", command = "ulx adduser", targets = true, single = true, kind = "account_admin", ownerOnly = true, confirm = true},
    revoke_admin = {name = "撤销管理员", command = "ulx removeuser", targets = true, single = true, kind = "account_admin", ownerOnly = true, confirm = true},
    group_allow = {name = "授予组权限", command = "ulx groupallow", kind = "group_permission", confirm = true},
    group_deny = {name = "撤销直接权限", command = "ulx groupdeny", kind = "group_permission", confirm = true},
    dummy = {name = "生成测试角色", command = "ulx breach_dummy", kind = "role"},
    force_start = {name = "强制开始对局", command = "ulx breach_start", confirm = true},
    role = {name = "设置角色", command = "ulx dev_force_spawn", targets = true, kind = "role"},
    hp = {name = "设置生命值", command = "ulx hp", targets = true, kind = "hp"},
    god = {name = "开启无敌", command = "ulx god", targets = true},
    ungod = {name = "关闭无敌", command = "ulx ungod", targets = true},
    bring = {name = "拉到身边", command = "ulx bring", targets = true},
    goto_player = {name = "传送过去", command = "ulx goto", targets = true, single = true},
    noclip = {name = "切换穿墙", command = "ulx noclip", targets = true},
    slay = {name = "处决", command = "ulx slay", targets = true, confirm = true},
    kick = {name = "踢出", command = "ulx kick", targets = true, single = true, kind = "reason", confirm = true},
    ban = {name = "封禁", command = "ulx ban", targets = true, single = true, kind = "ban", confirm = true},
    gag = {name = "禁语音", command = "ulx gag", targets = true, single = true, kind = "ban"},
    ungag = {name = "解除语音禁言", command = "ulx ungag", targets = true, single = true},
    mute = {name = "禁文字", command = "ulx mute", targets = true, single = true, kind = "ban"},
    unmute = {name = "解除文字禁言", command = "ulx unmute", targets = true, single = true},
    support = {name = "刷新支援", command = "ulx forcesupport", kind = "support"},
    restart_round = {name = "重启回合", command = "ulx restart_round", confirm = true},
    restart_game = {name = "重启游戏", command = "ulx restart_game", confirm = true},
}
RA.Supports = {
    {id = "NTF", name = "九尾狐"}, {id = "FBI", name = "UIU 特工组"},
    {id = "CHAOS", name = "混沌分裂者"}, {id = "GOC", name = "全球超自然联盟"},
    {id = "GRU", name = "格鲁乌 P 部门"}, {id = "COTSK", name = "猩红之子"},
    {id = "DZ", name = "蛇之手"}, {id = "OBR", name = "快速反应部队"},
    {id = "NU7", name = "Nu-7 落锤"},
}

function RA.RoleList()
    local result = {}
    for faction, groups in pairs(BREACH_ROLES or {}) do
        for _, group in pairs(groups) do
            for _, r in ipairs(group.roles or {}) do
                if isstring(r.name) then result[#result + 1] = {id = r.name, group = faction == 'ALPHA9' and group.name or faction} end
            end
        end
    end
    table.sort(result, function(a, b) return a.group == b.group and a.id < b.id or a.group < b.group end)
    return result
end
