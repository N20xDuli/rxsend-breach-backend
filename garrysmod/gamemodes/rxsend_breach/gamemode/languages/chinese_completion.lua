-- Load after chinese.lua. This file extends the Chinese dictionary; it does
-- not register another selectable language or change role identifiers.
local language = chinese
assert(istable(language), "chinese.lua must be loaded before chinese_completion.lua")

language.role.SCP035 = "SCP-035"
language.role.SCP1015RU = "SCP-1015-RU"
language.role.SCP1027RU = "SCP-1027-RU"

language.loading = "正在加载…"
language.loading_phase1 = "正在清理地图"
language.loading_phase2 = "正在重置回合状态"
language.loading_phase3 = "正在重新分配角色"
language.loading_phase4 = "正在生成物品"
language.loading_phase5 = "正在启动回合"
language.loading_advice = "提示"
language.loading_advice1 = "食用食物可以恢复生命值。"
language.loading_advice2 = "佩戴防毒面具可以防止红冰对你造成致命伤害。"
language.loading_advice3 = "电梯门可能夹伤里面的人或物体，请小心。"
language.loading_advice4 = "近战武器可以对 SCP 造成更多伤害。"
language.loading_advice5 = "清洁工可以从垃圾桶中找到有用的物品。"
language.menu_hudstyle = "新版状态界面"

language.abilities_name_fatjug = "弹药储备"
language.abilities_fatjug = "查看你携带的全部弹药。"
language["Anderson Robotics"] = "安德森机器人公司"
language["Hammer Down"] = "落锤特遣大队"
language.weaponry_took_ammo_security_pt1 = "你已经领取过装备，请检查背包。"
language.weaponry_took_ammo_security_pt2 = "已向你发放一套装备。"
language.weaponry_take_ammo = "已向你发放当前配发武器所需的弹药。"
language.donate_level_less15 = "（等级低于 15）"

-- Referenced by gameplay code, but absent from all three original dictionaries.
language.spyusa_hacking_successful2 = "终端入侵成功，设施坐标已发送给特异事故处，增援正在赶来。"
language.deffib_headshot = language.deffib_headshot_pt1
language.f2_no_objectives = "暂无任务"
language.abilities_name_chaosdemo = "部署定向地雷"
language.abilities_chaosmine = "在面前的地面放置一枚定向地雷。每条生命只能使用一次。"
language.admin_expired = "你的限时管理员权限已到期。"

local descriptions = BREACH.Descriptions.chinese
descriptions[role.AR_Coordinator] = "你是安德森机器人公司的协调员。\n\n设施内存在一台具有自主意识的计算机。\n\n找到它，并设法将它带离设施，完成此次行动任务。"
descriptions[role.AR_Executor] = "你是安德森机器人公司的行动专家。\n\n设施内存在一台具有自主意识的计算机。\n\n找到它，并设法将它带离设施，完成此次行动任务。"
descriptions[role.ClassD_Banned] = "你因累计违规警告而被分配到惩罚角色。\n\n此角色带有多项负面效果；成功逃脱达到规定次数后，才能解除角色惩罚。\n\n请遵守服务器规则。"
-- The English source accidentally repeats the pilot's helipad restriction.
-- The Russian commander description matches the commander's actual role.
descriptions[role.NTF_Commander] = "你是机动特遣队 Epsilon-11「九尾狐」的指挥官。\n\n向队员下达命令，组织小队行动，并完成当前任务。"
descriptions[role.MTF_O5] = "你是 O5 议会成员。\n\n设施发生了异常，而你的 O5 门禁卡似乎遗落在巡视过的轻收容区。\n\n尽快找回门禁卡，并乘坐单轨列车撤离设施。"

ALLLANGUAGES.chinese = language
