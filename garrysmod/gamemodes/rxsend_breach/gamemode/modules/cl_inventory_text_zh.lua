-- Display-only Chinese labels. Never use these strings as weapon or ammo identifiers.
-- Accept a class, a weapon/entity, a stored definition, or {class = ..., weapon = ...}.
-- An explicit class is optional and is useful for definitions without ClassName.
BREACH = BREACH or {}
BREACH.InventoryUIText = BREACH.InventoryUIText or {}
local Text = BREACH.InventoryUIText

local names = {
    battery_1 = "普通电池", battery_2 = "高容量电池", battery_3 = "增强电池",
    item_special_document = "机密文件", ritual_paper = "仪式图纸",
    item_cheemer = "奇默装置", item_nu7_terminal = "落锤便携式战术终端",
    hand_key = "门禁断手", hacking_doors = "门禁破解装置",
    gasmask = "防毒面具", item_chaos_radio = "混沌分裂者对讲机",
    item_radio = "对讲机", item_ntf_shield = "九尾狐战术盾牌", item_shield = "战术盾牌",
    riot_shield = "防暴盾牌", heavy_shield = "重型防弹盾牌", deployable_shield = "可部署盾牌",
    item_drink_294 = "SCP-294 饮品", item_drink_dado_fire = "烫口果汁",
    item_drink_dado_radioactive = "辐射口味果汁", item_drink_energy = "能量饮料",
    item_drink_soda = "苏打水", item_drink_water = "饮用水", item_drink_coffee = "咖啡",
    item_eyedrops_1 = "眼药水", item_eyedrops_2 = "改进型眼药水", item_eyedrops_3 = "实验型眼药水",
    item_medkit_1 = "急救医疗包", item_medkit_2 = "办公用医疗包",
    item_medkit_3 = "特殊护理医疗包", item_medkit_4 = "通用医疗包",
    item_pills = "止痛药", item_adrenaline = "肾上腺素注射器", item_syringe = "机能强化注射器",
    item_deffib_medic = "便携式除颤仪", item_hamburger = "汉堡", item_keys = "车钥匙",
    item_screwdriver = "螺丝刀", item_toolkit = "工具箱", item_tazer = "电击器",
    item_nightvision_green = "绿色夜视仪", item_nightvision_blue = "蓝色夜视仪",
    item_nightvision_red = "热成像夜视仪", item_nightvision_white = "原型夜视仪",
    item_nightvision_goc = "全球超自然联盟原型夜视仪",
    item_knife = "自制小刀", event_item_knife = "加固小刀", flamberge = "波刃剑",
    copper_coin = "铜币", silver_coin = "银币", gold_coin = "金币",
    item_scp_005 = "SCP-005 异常钥匙", item_scp_109 = "SCP-109 异常水壶",
    item_scp_1033 = "SCP-1033-RU 防护装置", item_scp_215 = "SCP-215 眼镜",
    item_scp_427 = "SCP-427 吊坠", item_scp_268 = "SCP-268 帽子",
    item_scp_714 = "SCP-714 戒指", item_scp_207 = "SCP-207 饮料",
    item_scp_500 = "SCP-500 药丸", item_scp_447 = "SCP-447 黏液",
    item_scp_1499 = "SCP-1499 防毒面具", cw_scp_127 = "SCP-127 活体枪",
    weapon_scp_062 = "SCP-062-FR 能力", weapon_scp_076 = "SCP-076-2 能力",
    weapon_scp_076_defend = "SCP-076-2 防御能力", weapon_scp_860 = "SCP-860-2 能力",
    weapon_scp_049_2 = "SCP-049-2 能力", weapon_scp_049_2_1 = "SCP-049-2 变体能力",
    weapon_scp_1015ru = "SCP-1015-RU 能力", weapon_scp_1033 = "SCP-1033-RU 能力",
    weapon_scp_2012_crossbow = "SCP-2012 弩", weapon_scp_912_knife = "SCP-912 战术匕首",
    weapon_scp_973_rage = "SCP-973 狂暴能力", weapon_scp_999 = "SCP-999 能力",
    br_holster = "空手", inspect_hands = "检查动作", weapon_position = "动作定位工具",
    br_vort = "弗地冈人之手", br_vort2 = "弗地冈人之手（二型）", br_vort3 = "弗地冈人之手（三型）",
    br_s_nav_300 = "S-Nav 300 导航仪", br_keycard_editor = "门禁配置工具",
    br_entity_remover = "实体移除工具", gmod_camera = "相机", weapon_flashlight = "手电筒",
    weapon_special_gaus = "电磁炮", weapon_serpent_dagger = "蛇之手 M9 刺刀",
    weapon_fbi_knife = "联邦调查局战术匕首", weapon_cqc = "缴械动作",
    weapon_checker = "身份检查", weapon_cannibal = "吞食尸体", weapon_usa_instruction = "教诲",
    weapon_breachmelee_crowbar = "撬棍", event_weapon_breachmelee_crowbar = "戈登的撬棍",
    weapon_breachmelee_hammer = "锤子", weapon_breachmelee_pipe = "管钳",
    weapon_breachmelee_fireaxe = "消防斧", cwc_cbar = "撬棍",
    weapon_pass_guard = "军事人员身份卡", weapon_pass_medic = "医疗人员身份卡",
    weapon_pass_sci = "科研人员身份卡", br_id_med = "医疗人员身份卡",
    breach_keycard_6 = "万能权限卡", breach_keycard_7 = "O5 权限卡",
    breach_keycard_crack = "破解权限卡", breach_keycard_support = "支援权限卡",
    breach_keycard_usa_spy = "内部通讯权限卡",
    armor_light = "轻型护甲", armor_light_armor = "轻型防弹衣", armor_heavy_armor = "重型防弹衣",
    armor_light_hat = "轻型头盔", armor_heavy_hat = "重型头盔",
    armor_small_bag = "小型背包", armor_big_bag = "大型背包",
    armor_medic = "医疗人员制服", armor_mtf = "机动特遣队制服", armor_sci = "科研人员制服",
    armor_goc = "全球超自然联盟制式装甲",
    armor_hazmat_blue = "蓝色防化服", armor_hazmat_orange = "橙色防化服",
    armor_hazmat_white = "白色防化服", armor_hazmat_yellow = "黄色防化服", armor_hazmat_black = "黑色防化服",
    armor_lighthazmat_1 = "白色轻型防化服", armor_lighthazmat_2 = "黄色轻型防化服",
    taunt_gangnam = "江南舞蹈", taunt_new = "维加舞蹈", taunt_new2 = "欢乐舞蹈",
    taunt_new3 = "舞蹈动作（三）", taunt_twerk = "舞蹈动作（扭臀）",
    cw_smoke_grenade = "烟雾弹", cw_frag_grenade = "破片手雷", cw_flash_grenade = "闪光弹",
    cw_nu7_m134 = "M134 转管机枪", cw_deagle = "沙漠之鹰手枪",
    cw_kk_ins2_rpg_pro = "RPG 火箭筒", cw_kk_ins2_doi_enfield = "恩菲尔德步枪",
    cw_kk_ins2_cstm_mel_ninjato = "忍者刀", cw_kk_ins2_doi_mel_kabar = "KA-BAR 战斗刀",
    cw_kk_ins2_doi_mel_kabar2 = "重力装置", cw_kk_ins2_doi_mel_kabar3 = "细刃匕首",
    cw_kk_ins2_doi_mel_kabar4 = "费尔贝恩匕首", cw_kk_ins2_doi_mel_kabar5 = "特制近战武器",
    cw_kk_ins2_mel_bayonet = "军用刺刀", cw_kk_ins2_mel_gurkha = "廓尔喀弯刀",
    cw_kk_ins2_ao5_mel_mach = "砍刀", cw_kk_ins2_doi_mel_enfield = "恩菲尔德刺刀",
    cw_kk_ins2_doi_mel_brass = "指虎", cw_kk_ins2_nam_mel_ak = "AK 刺刀",
    cw_kk_ins2_doi_bino_de = "德式望远镜", cw_kk_ins2_doi_bino_gb = "英式望远镜",
    cw_kk_ins2_doi_bino_us = "美式望远镜", cw_kk_ins2_doi_flame_de = "德式喷火器",
    cw_kk_ins2_doi_flame_gb = "英式喷火器", cw_kk_ins2_doi_flame_us = "美式喷火器",
    cw_kk_ins2_doi_mel_shovel_de = "德式工兵铲", cw_kk_ins2_doi_mel_shovel_gb = "英式工兵铲",
    cw_kk_ins2_doi_mel_shovel_us = "美式工兵铲", cw_kk_ins2_nade_kk2 = "信号弹",
    cw_kk_ins2_nade_ied = "遥控简易爆炸装置", cw_kk_ins2_nade_anm14 = "AN/M14 燃烧弹",
    cw_kk_ins2_cstm_nade_rdgm = "RDG-M 烟雾弹", cw_kk_ins2_nam_nade_rdg1 = "RDG-1 烟雾弹",
    cw_kk_ins2_nam_nade_rgd5 = "RGD-5 高爆手雷", cw_kk_ins2_doi_molotov = "ETFW-46 燃烧瓶",
    cw_kk_ins2_obr_shield = "持枪防弹盾牌", cw_kk_ins2_nam_nambu = "南部手枪",
    cw_kk_ins2_nam_sks = "SKS 半自动步枪", cw_kk_ins2_sks = "SKS 半自动步枪",
    cw_kk_ins2_doi_piat = "PIAT 反坦克发射器", cw_kk_ins2_flashlight = "枪械手电筒"
}

local descriptions = {
    battery_1 = "为电击器补充电量的普通电池。", battery_2 = "为电击器补充电量的高容量电池。",
    battery_3 = "为电击器补充电量的增强电池。",
    item_special_document = "特定角色任务所需的设施文件。", ritual_paper = "猩红之子使用的仪式资料。",
    hand_key = "可用于特定门禁的断手。", hacking_doors = "用于破解门禁的装置。",
    item_cheemer = "可携带的奇默装置。", item_keys = "用于车辆的钥匙。",
    item_nu7_terminal = "落锤小队使用的便携式战术终端。",
    item_deffib_medic = "用于救援倒下人员的医疗设备。", item_tazer = "使用电池供电的电击设备。",
    item_radio = "用于无线电通讯。", item_chaos_radio = "混沌分裂者使用的通讯设备。",
    item_scp_1033 = "提供异常防护的装置，防护耗尽后失效。",
    armor_small_bag = "穿戴后增加 1 个携带栏位。", armor_big_bag = "穿戴后增加 3 个携带栏位。",
    item_scp_005 = "具有异常开锁能力的钥匙。", item_scp_500 = "具有异常治疗效果的药丸。",
    item_scp_447 = "具有异常效果的绿色黏液。", item_scp_1499 = "带有异常效果的防毒面具。",
    br_holster = "收起当前持有的装备。", inspect_hands = "用于检查交互的动作。"
}

local ammoNames = {
    ar2 = "步枪弹药", gru = "GRU 弹药", smg1 = "冲锋枪弹药", pistol = "手枪弹药",
    revolver = "左轮手枪弹药", goc = "全球超自然联盟弹药", shotgun = "霰弹枪弹药",
    buckshot = "霰弹枪弹药", sniper = "狙击步枪弹药", sniperround = "狙击步枪弹药",
    sniperpenetratedround = "穿甲狙击弹", ["357"] = ".357 马格南弹",
    rpg_rocket = "火箭弹", rpg_round = "火箭弹", crossbowbolt = "弩箭",
    ar2altfire = "能量球", smg1_grenade = "枪榴弹", grenade = "手雷",
    scp062ammo = "SCP-062 专用弹药", scp127teeth = "SCP-127 牙齿弹药",
    ["frag grenades"] = "破片手雷", ["flash grenades"] = "闪光弹", ["smoke grenades"] = "烟雾弹",
    incendiary = "燃烧弹", c4 = "C4 炸药", ied = "简易爆炸装置",
    ["12 gauge"] = "12 号霰弹", ["25mm flare"] = "25 毫米信号弹", ["40mm"] = "40 毫米榴弹",
    ["88mm rocket"] = "88 毫米火箭弹", ["at4 launcher"] = "AT4 火箭弹",
    ["m10a1 rocket"] = "M10A1 火箭弹", ["m6a1 rocket"] = "M6A1 火箭弹",
    ["m213 flare"] = "M213 信号弹", panzerfaust = "铁拳火箭弹",
    ["pg-7vm grenade"] = "PG-7VM 火箭弹", ["piat bomb"] = "PIAT 反坦克弹",
    [".22 lr"] = ".22 LR 弹药", [".30 carbine"] = ".30 卡宾枪弹",
    [".30-06 springfield"] = ".30-06 斯普林菲尔德弹", [".30-06"] = ".30-06 弹药",
    [".303 british"] = ".303 英式弹药", [".32 acp"] = ".32 ACP 弹药",
    [".338 lapua"] = ".338 拉普阿弹", [".357 magnum"] = ".357 马格南弹",
    [".38 special"] = ".38 特种弹", [".380 acp"] = ".380 ACP 弹药",
    [".380/200"] = ".380/200 弹药", [".44 magnum"] = ".44 马格南弹",
    [".45 acp"] = ".45 ACP 弹药", [".50 ae"] = ".50 AE 弹药",
    ["7.92x33mm kurz"] = "7.92×33 毫米短弹", ["7.92x57mm mauser"] = "7.92×57 毫米毛瑟弹"
}

-- These are model names, not untranslated interface words.
local models = {
    AKM = true, ACR = true, AUG = true, AWM = true, FAMAS = true, FAL = true, GOL = true,
    KSG = true, MSR = true, RPK = true, SVD = true, USR = true, USP = true, VSS = true,
    ASVAL = true, HK = true, IMI = true, FN = true, SG = true, MP = true, SCAR = true,
    GLOCK = true, UMP = true, UZI = true, KRISS = true, AEK = true, AN = true, LMG = true,
    RPG = true, PKM = true, M249 = true, DP = true, MG = true, BAR = true, CS = true,
    MR = true, S = true, L = true, H = true, STD = true, CQB = true, SOCOM = true,
    SD = true, SAW = true, GOC = true, GRU = true, SCP = true, RU = true, FR = true,
    ID = true, O = true, MTF = true, CI = true, UIU = true, ACP = true, AE = true, LR = true,
    ARX = true, ACE = true, ARM = true, SAR = true, PIAT = true, SKS = true, AK = true
}
local modelTranslations = {
    ["desert eagle"] = "沙漠之鹰", ["sig sauer"] = "西格绍尔", ["glock"] = "GLOCK",
    ["heckler & koch"] = "HK", ["kriss vector"] = "KRISS Vector", ["vector"] = "维克托",
    ["colt commando"] = "柯尔特突击型", ["king cobra"] = "眼镜王蛇", ["colt"] = "柯尔特",
    ["pecheneg"] = "佩切涅格", ["vickers"] = "维克斯", ["lewis"] = "刘易斯",
    ["dragunov"] = "德拉古诺夫", ["groza"] = "格罗扎", ["imbel"] = "英贝尔",
    ["springfield"] = "斯普林菲尔德", ["thompson"] = "汤普森", ["garand"] = "加兰德",
    ["mauser"] = "毛瑟", ["walther"] = "沃尔特", ["webley"] = "韦伯利",
    ["welrod"] = "威尔罗德", ["enfield"] = "恩菲尔德", ["browning"] = "勃朗宁",
    ["sten"] = "斯登", ["owen"] = "欧文", ["bren"] = "布伦", ["suomi"] = "索米",
    ["panzerfaust"] = "铁拳", ["minimi"] = "米尼米", ["keltec"] = "凯尔泰克",
    ["kel-tec"] = "凯尔泰克", ["volk"] = "沃尔克", ["karma"] = "卡尔玛",
    ["blackout"] = "黑障", ["freedom"] = "自由", ["fate"] = "命运",
    ["makarov"] = "马卡洛夫", ["mosin nagant"] = "莫辛纳甘", ["galil"] = "加利尔",
    ["deagle"] = "沙漠之鹰",
    ["carbine"] = "卡宾枪", ["minigun"] = "转管机枪", ["modern"] = "现代型"
}
local translationPhrases = {}
for phrase in pairs(modelTranslations) do translationPhrases[#translationPhrases + 1] = phrase end
table.sort(translationPhrases, function(a, b) return #a > #b end)

local function clean(value)
    if type(value) ~= "string" then return nil end
    value = value:gsub("[%c]", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" or #value > 512 then return nil end
    return value
end

local function chineseText(value)
    value = clean(value)
    if not value or value:find("l:", 1, true) or value:find("#", 1, true)
        or value:find("_", 1, true) or value:lower():find("phrase not found", 1, true) then return nil end
    local han = false
    for i = 1, #value do
        local b = value:byte(i)
        if b >= 208 and b <= 211 then return nil end -- Cyrillic UTF-8 lead bytes.
        if b >= 228 and b <= 233 then han = true end
    end
    if not han then return nil end
    for word in value:gmatch("[A-Za-z][A-Za-z0-9%.%-]*") do
        if not word:find("%d") and not models[word:upper()] then return nil end
    end
    return value
end

local function field(object, key)
    if object == nil then return nil end
    local kind = type(object)
    if kind == "string" or kind == "number" or kind == "boolean" or kind == "function" then return nil end
    local ok, value = pcall(function() return object[key] end)
    if ok then return value end
end

local function call(object, method)
    local fn = field(object, method)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object)
    if ok then return value end
end

local function definition(class)
    if not class or class == "" then return nil end
    if weapons and weapons.GetStored then
        local stored = weapons.GetStored(class)
        if stored then return stored end
    end
    if scripted_ents and scripted_ents.GetStored then
        local stored = scripted_ents.GetStored(class)
        if stored then return stored.t or stored end
    end
end

local classCache = setmetatable({}, {__mode = "k"})
local function registeredClass(object)
    if type(object) ~= "table" then return nil end
    if classCache[object] then return classCache[object] end
    if weapons and weapons.GetList then
        for _, value in pairs(weapons.GetList()) do
            local class = value.ClassName
            if class and (value == object or definition(class) == object) then
                classCache[object] = class
                return class
            end
        end
    end
    if scripted_ents and scripted_ents.GetList then
        for class, value in pairs(scripted_ents.GetList()) do
            if value == object or value.t == object then
                classCache[object] = class
                return class
            end
        end
    end
end

local function resolve(item, explicitClass)
    local class = clean(explicitClass)
    if type(item) == "string" then class = class or clean(item) end
    class = class or clean(call(item, "GetClass")) or clean(field(item, "ClassName"))
        or clean(field(item, "class")) or clean(field(item, "Class"))
    local wrapped = field(item, "weapon") or field(item, "entity") or field(item, "t")
    if wrapped then
        item = wrapped
        class = class or clean(call(item, "GetClass")) or clean(field(item, "ClassName"))
            or (type(item) == "string" and clean(item))
    end
    class = class or registeredClass(item) or ""
    class = class:lower()
    local data = item
    if type(item) == "string" or item == nil then data = definition(class) or {} end
    return class, data
end

local function zhLanguage()
    if ALLLANGUAGES and type(ALLLANGUAGES.chinese) == "table" then return ALLLANGUAGES.chinese end
    if type(chinese) == "table" then return chinese end
    return {}
end

local function translatedName(class, data)
    local language = zhLanguage()
    local translated = language.weaponry and chineseText(language.weaponry[class])
    if translated then return translated end
    local printName = field(data, "PrintName")
    if type(printName) == "string" then
        local key = printName:match("^l:([%w_]+)$")
        if key then return chineseText(language[key]) end
    end
    return chineseText(printName)
end

local function contains(value, part)
    return value:find(part, 1, true) ~= nil
end

local function category(class, data)
    local armorType = field(data, "ArmorType")
    if armorType == "Bag" or contains(class, "_bag") then return "背包" end
    if armorType == "Hat" or contains(class, "_hat") then return "头盔" end
    if armorType == "Clothes" or contains(class, "hazmat") then return "服装" end
    if armorType == "Armor" or class:match("^armor_") then return "护甲" end
    if class:match("^breach_keycard") or contains(class, "weapon_pass_") or class == "br_id_med" then return "权限卡" end
    if contains(class, "document") or class == "ritual_paper" then return "任务道具" end
    if class:match("^battery_") then return "电池" end
    if class:match("^item_scp_") or class == "item_drink_294" then return "异常道具" end
    if class:match("^weapon_scp_?") then return "异常能力" end
    if contains(class, "shield") then return "盾牌" end
    if contains(class, "medkit") or contains(class, "pills") or contains(class, "syringe")
        or contains(class, "adrenaline") or contains(class, "deffib") or contains(class, "eyedrops") then return "医疗用品" end
    if contains(class, "drink") or contains(class, "hamburger") then return "补给品" end
    if contains(class, "radio") then return "通讯设备" end
    if contains(class, "nightvision") or class == "gasmask" then return "穿戴设备" end
    if contains(class, "coin") then return "代币" end
    if class:match("^taunt_") or class == "br_holster" or class == "inspect_hands"
        or class == "weapon_cqc" or class == "weapon_checker" or class == "weapon_cannibal" then return "角色动作" end
    local lowerName = (clean(field(data, "PrintName")) or ""):lower()
    local hint = class .. " " .. lowerName .. " " .. (clean(field(data, "Category")) or ""):lower()
    if contains(hint, "bino") then return "望远镜" end
    if contains(hint, "_mel_") or contains(hint, "melee") or contains(hint, "knife")
        or contains(hint, "dagger") or class == "flamberge" or class == "cwc_cbar" then return "近战武器" end
    if contains(hint, "grenade") or contains(hint, "_nade_") then return "投掷物" end
    if contains(hint, "flame") then return "喷火器" end
    if contains(hint, "launcher") or contains(hint, "rpg") or contains(hint, "panzerfaust") then return "发射器" end
    if contains(hint, "shotgun") or contains(hint, "m1014") or contains(hint, "ksg") then return "霰弹枪" end
    if contains(hint, "sniper") or contains(hint, "awm") or contains(hint, "l115") or contains(hint, "dragunov") then return "狙击步枪" end
    if contains(hint, "submachine") or contains(hint, " smg") or contains(hint, "mp5") or contains(hint, "mp7")
        or contains(hint, "thompson") or contains(hint, "suomi") or contains(hint, "vector") then return "冲锋枪" end
    if contains(hint, "machine gun") or contains(hint, "machinegun") or contains(hint, " lmg")
        or contains(hint, "minigun") or contains(hint, "pecheneg") then return "机枪" end
    if contains(hint, "pistol") or contains(hint, "revolver") or contains(hint, "glock") or contains(hint, "deagle") then return "手枪" end
    local primary = field(data, "Primary")
    local ammo = (clean(field(primary, "Ammo")) or ""):lower()
    if ammo == "shotgun" or ammo == "buckshot" or ammo == "12 gauge" then return "霰弹枪" end
    if ammo == "sniper" or ammo:find(".338", 1, true) then return "狙击步枪" end
    if ammo == "gru" then return "机枪" end
    if ammo == "smg1" then return "冲锋枪" end
    if ammo == "pistol" or ammo == "revolver" then return "手枪" end
    if ammo == "ar2" or ammo == "goc" or ammo == "5.56x45mm" or ammo == "5.45x39mm"
        or ammo == "7.62x39mm" then return "步枪" end
    if ammo == "9x19mm" or ammo == ".45 acp" or ammo == ".357 magnum" or ammo == ".50 ae" then return "手枪" end
    if class:match("^cw_?") or (ammo ~= "" and ammo ~= "none") then return "枪械" end
    if class:match("^br_") or class:match("^gmod_") then return "工具" end
    if field(data, "Equipableitem") then return "穿戴设备" end
    if class:match("^item_") then return "随身装备" end
    return "特殊装备"
end

local function modelName(class, data)
    local value = clean(field(data, "PrintName")) or ""
    if value:find("l:", 1, true) or value:find("_", 1, true) or value:find("%.lua") then value = "" end
    local lower = value:lower()
    local translated = {}
    for _, phrase in ipairs(translationPhrases) do
        if lower:find(phrase, 1, true) then
            translated[#translated + 1] = modelTranslations[phrase]
            local start, finish = lower:find(phrase, 1, true)
            lower = lower:sub(1, start - 1) .. string.rep(" ", finish - start + 1) .. lower:sub(finish + 1)
            value = value:sub(1, start - 1) .. string.rep(" ", finish - start + 1) .. value:sub(finish + 1)
        end
    end
    for word in value:gmatch("[%a%d][%a%d%.%-%/]*") do
        local upper = word:upper()
        if models[upper] or (word:find("%d") and word:match("^%a[%w%.%-%/]*%d[%w%.%-%/]*$") and #word <= 16)
            or word:match("^%d+%.?%d*$") then
            translated[#translated + 1] = upper
        elseif word:match("^SCAR%-[HL]$") then
            translated[#translated + 1] = word
        end
    end
    if #translated > 0 then return table.concat(translated, " ") end
    -- Last resort: a concrete model token from the registered class, never the raw class.
    for word in class:gmatch("[^_]+") do
        local upper = word:upper()
        if models[upper] or (word:find("%d") and word:match("^%a+%d[%w]*$") and #word <= 12) then
            if word ~= "cw2" and not word:match("^ins%d") then return upper end
        end
    end
end

function Text.Class(item, explicitClass)
    local class = resolve(item, explicitClass)
    return class
end

function Text.Category(item, explicitClass)
    local class, data = resolve(item, explicitClass)
    return category(class, data)
end

function Text.Name(item, explicitClass)
    local class, data = resolve(item, explicitClass)
    if names[class] then return names[class] end
    local level = class:match("^breach_keycard_(%d+)$")
    if level then return level .. " 级权限卡" end
    local department, clearance = class:match("^breach_keycard_([a-z]+)_(%d+)$")
    if clearance then
        local departments = {sci = "科研", security = "安保", guard = "警卫"}
        return clearance .. " 级" .. (departments[department] or "") .. "权限卡"
    end
    local localized = translatedName(class, data)
    if localized then return localized end
    local scp = class:match("scp_?(%d+)")
    if scp then
        local suffix = class:match("scp_?%d+_?(ru)") or class:match("scp_?%d+_?(fr)")
        return "SCP-" .. scp .. (suffix and "-" .. suffix:upper() or "") .. " " .. category(class, data)
    end
    local kind = category(class, data)
    local model = modelName(class, data)
    if model then return model .. " " .. kind end
    local variant = class:match("_(%d+)$")
    if variant then return kind .. "（" .. variant .. " 型）" end
    return kind
end

function Text.AmmoName(id)
    local name = id
    if type(id) == "string" and ammoNames[id:lower()] then return ammoNames[id:lower()] end
    if type(id) == "number" or (type(id) == "string" and id:match("^%d+$")) then
        if game and game.GetAmmoName then name = game.GetAmmoName(tonumber(id)) else name = nil end
    end
    name = clean(name)
    if not name then return "未识别弹药" end
    local lower = name:lower()
    if lower == "none" or lower == "" then return "无需弹药" end
    if ammoNames[lower] then return ammoNames[lower] end
    local caliber, length, rimmed = lower:match("^(%d+%.?%d*)x(%d+%.?%d*)mm(r?)$")
    if caliber then return caliber .. "×" .. length .. " 毫米" .. (rimmed == "r" and "凸缘弹" or "弹药") end
    if lower:match("^40mm_kk_%d+$") then return "40 毫米榴弹" end
    local localized = chineseText(name)
    if localized then return localized end
    local measure = lower:match("^(%d+%.?%d*)mm$")
    if measure then return measure .. " 毫米弹药" end
    if contains(lower, "grenade") then return "榴弹" end
    if contains(lower, "rocket") then return "火箭弹" end
    if contains(lower, "flare") then return "信号弹" end
    return "特殊弹药"
end

function Text.Description(item, explicitClass)
    local class, data = resolve(item, explicitClass)
    if descriptions[class] then return descriptions[class] end
    local custom = chineseText(field(data, "InvDescription"))
    if custom then return custom end
    local kind = category(class, data)
    local primary = field(data, "Primary")
    local ammo = field(primary, "Ammo")
    if type(ammo) == "string" and ammo ~= "" and ammo:lower() ~= "none" then
        return "使用" .. Text.AmmoName(ammo) .. "的" .. kind .. "。"
    end
    return ""
end
