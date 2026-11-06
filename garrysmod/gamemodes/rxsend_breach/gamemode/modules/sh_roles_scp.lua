local RunConsoleCommand = RunConsoleCommand;
local FindMetaTable = FindMetaTable;
local CurTime = CurTime;
local pairs = pairs;
local string = string;
local table = table;
local timer = timer;
local hook = hook;
local math = math;
local pcall = pcall;
local unpack = unpack;
local tonumber = tonumber;
local tostring = tostring;
local ents = ents;
local ErrorNoHalt = ErrorNoHalt;
local DeriveGamemode = DeriveGamemode;
local util = util
local net = net
local player = player

local HAIRS = {"models/cultist/heads/male/hair/hair_1.mdl", "models/cultist/heads/male/hair/hair_2.mdl", "models/cultist/heads/male/hair/hair_3.mdl"}
local HAIRS_BLACK = {"models/cultist/heads/male/hair/hair_1.mdl", "models/cultist/heads/male/hair/hair_2.mdl", "models/cultist/heads/male/hair/hair_4.mdl"}
local HAIRS_WOMAN___BITCHES____ = {"models/cultist/heads/female/hair/hair_2.mdl", "models/cultist/heads/female/hair/hair_3.mdl", "models/cultist/heads/female/hair/hair_4.mdl", "models/cultist/heads/female/hair/hair_5.mdl", "models/cultist/heads/female/hair/hair_6.mdl"}

include("sh_module.lua")

BREACH_ROLES = {}

BREACH.ChaosSpy_CanBe = {
	role.SECURITY_Recruit,
	role.SECURITY_OFFICER,
}

BREACH_ROLES.OBR = {
	obr = {
		name = "Отряд Быстрого Реагирования",
		color = Color(25, 25, 112),
		roles = {
			{["name"] = role.QRT_Soldier,
			 ["team"] = TEAM_QRT,
			 ["weapons"] = {"br_holster", "cw_kk_ins2_m4a1", "item_nightvision_green", "gasmask", "item_adrenaline", "item_radio", "weapon_cqc"},
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/obr/head_gear/helmet_1.mdl",
			 ["tasks"] = "l:tasks_evacuate_personnel_and_defend_comrades",
			 ["bodygroups"] = {"0101"},
			 --["bodygroup1"] = 1,
			 --["bodyresist"] = 2,
			 ["bodygroup3"] = 1,
			 ["keycard"] = "guard_3",
			 ["ammo"] = {{"cw_kk_ins2_m4a1", 300}},
			 ["health"] = 120,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 --["headresist"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/obr/obr_new.mdl",
			 ["showmodel"] = "models/cultist/humans/obr/obr_new.mdl",
			 ["level"] = 0,
			 ["customcheck"] = nil,
			 ["max"] = 5,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.9,
			 	["HITGROUP_CHEST"] = 0.9,
			 	["HITGROUP_LEFTARM"] = 0.9,
			 	["HITGROUP_RIGHTARM"] = 0.9,
			 	["HITGROUP_STOMACH"] = 0.9,
			 	["HITGROUP_GEAR"] = 0.9,
			 	["HITGROUP_LEFTLEG"] = 0.9,
			 	["HITGROUP_RIGHTLEG"] = 0.9
			 },
			},
			{["name"] = role.QRT_Marksmen,
			 ["team"] = TEAM_QRT,
			 ["weapons"] = {"br_holster", "cw_kk_ins2_m14", "item_nightvision_blue", "item_adrenaline", "item_radio", "weapon_cqc"},
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/obr/head_gear/helmet_cap.mdl",
			 ["tasks"] = "l:tasks_evacuate_personnel_and_defend_comrades",
			 ["bodygroup1"] = 1,
			 ["bodygroup3"] = 1,
			 --["bodyresist"] = 2,
			 ["keycard"] = "guard_3",
			 ["ammo"] = {{"cw_kk_ins2_m14", 300}},
			 ["health"] = 120,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/obr/obr_new.mdl",
			 ["showmodel"] = "models/cultist/humans/obr/obr_new.mdl",
			 ["level"] = 4,
			 ["customcheck"] = nil,
			 ["max"] = 2,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.9,
			 	["HITGROUP_CHEST"] = 0.8,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 0.8,
			 	["HITGROUP_GEAR"] = 0.8,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
			{["name"] = role.QRT_Medic,
			 ["team"] = TEAM_QRT,
			 ["weapons"] = {"br_holster", "cw_kk_ins2_cstm_famas", "item_deffib_medic", "item_nightvision_blue", "item_adrenaline", "item_radio", "item_medkit_4", "weapon_cqc"},
			 ["head"] = "models/cultist/humans/balaclavas_new/head_balaclava_month.mdl",
			 ["headgear"] = "models/cultist/humans/obr/head_gear/helmet_1.mdl",
			 ["tasks"] = "l:tasks_evacuate_personnel_and_defend_comrades",
			 ["bodygroup1"] = 1,
			 ["bodygroup3"] = 1,
			 ["skin"] = 1,
			 ["keycard"] = "guard_3",
			 ["ammo"] = {{"cw_kk_ins2_cstm_famas", 300}},
			 ["health"] = 140,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 --["headresist"] = 1,
			 ["bodyresist"] = 2,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/obr/obr_new.mdl",
			 ["showmodel"] = "models/cultist/humans/obr/obr_new.mdl",
			 ["level"] = 6,
			 ["customcheck"] = nil,
			 ["max"] = 2,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.8,
			 	["HITGROUP_CHEST"] = 0.8,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 0.8,
			 	["HITGROUP_GEAR"] = 0.8,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
			{["name"] = role.QRT_Shield,
			 ["team"] = TEAM_QRT,
			 ["weapons"] = {"br_holster", "item_shield", "cw_kk_ins2_m9", "item_nightvision_blue", "item_adrenaline", "item_radio", "weapon_cqc"},
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/obr/head_gear/helmet_1.mdl",
			 ["tasks"] = "l:tasks_evacuate_personnel_and_defend_comrades",
			 ["bodygroup1"] = 1,
			 ["bodygroup3"] = 1,
			 ["bodygroup5"] = 1,
			 ["keycard"] = "guard_3",
			 ["ammo"] = {{"cw_kk_ins2_m9", 120 }},
			 ["health"] = 165,
			 ["armor"] = 0,
			 ["walkspeed"] = 0.8,
			 --["headresist"] = 1,
			 --["bodyresist"] = 2,
			 ["runspeed"] = 0.9,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/obr/obr_new.mdl",
			 ["showmodel"] = "models/cultist/humans/obr/obr_new.mdl",
			 ["level"] = 27,
			 ["customcheck"] = nil,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.8,
			 	["HITGROUP_CHEST"] = 0.8,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 0.8,
			 	["HITGROUP_GEAR"] = 0.8,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
			{["name"] = role.QRT_Machinegunner,
			 ["team"] = TEAM_QRT,
			 ["weapons"] = {"br_holster", "cw_kk_ins2_m249", "item_nightvision_blue", "gasmask", "item_adrenaline", "item_radio", "weapon_cqc"},
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/obr/head_gear/helmet_1.mdl",
			 ["tasks"] = "l:tasks_evacuate_personnel_and_defend_comrades",
			 ["bodygroup1"] = 1,
			 ["bodygroup3"] = 1,
			 --["bodyresist"] = 2,
			 ["bodygroup4"] = 1,
			 ["bodygroup5"] = 1,
			 ["keycard"] = "guard_3",
			 ["ammo"] = {{"cw_kk_ins2_m249", 430 }},
			 ["health"] = 180,
			 ["armor"] = 35,
			 ["walkspeed"] = 0.8,
			 ["runspeed"] = 0.9,
			 --["headresist"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/obr/obr_new.mdl",
			 ["showmodel"] = "models/cultist/humans/obr/obr_new.mdl",
			 ["level"] = 31,
			 ["customcheck"] = nil,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.7,
			 	["HITGROUP_CHEST"] = 0.7,
			 	["HITGROUP_LEFTARM"] = 0.7,
			 	["HITGROUP_RIGHTARM"] = 0.7,
			 	["HITGROUP_STOMACH"] = 0.8,
			 	["HITGROUP_GEAR"] = 0.8,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
			{["name"] = role.QRT_ShockTrooper,
			 ["team"] = TEAM_QRT,
			 ["weapons"] = {"br_holster", "cw_kk_ins2_cstm_spas12", "item_nightvision_blue", "gasmask", "item_adrenaline", "item_radio", "weapon_cqc"},
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/obr/head_gear/helmet_1.mdl",
			 ["tasks"] = "l:tasks_evacuate_personnel_and_defend_comrades",
			 ["bodygroup1"] = 1,
			 ["bodygroup3"] = 1,
			 --["bodyresist"] = 3,
			 ["bodygroup4"] = 1,
			 ["keycard"] = "guard_3",
			 ["ammo"] = {{"cw_kk_ins2_cstm_spas12", 430 }},
			 ["health"] = 180,
			 ["armor"] = 0,
			 ["walkspeed"] = 0.8,
			 ["runspeed"] = 0.9,
			 --["headresist"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/obr/obr_new.mdl",
			 ["showmodel"] = "models/cultist/humans/obr/obr_new.mdl",
			 ["level"] = 11,
			 ["customcheck"] = nil,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.7,
			 	["HITGROUP_CHEST"] = 0.7,
			 	["HITGROUP_LEFTARM"] = 0.8,
			 	["HITGROUP_RIGHTARM"] = 0.9,
			 	["HITGROUP_STOMACH"] = 0.7,
			 	["HITGROUP_GEAR"] = 0.7,
			 	["HITGROUP_LEFTLEG"] = 0.7,
			 	["HITGROUP_RIGHTLEG"] = 0.7
			 },
		    },
			{["name"] = role.QRT_Commander,
			 ["team"] = TEAM_QRT,
			 ["weapons"] = {"br_holster" ,"cw_kk_ins2_p90", "item_nightvision_blue", "item_adrenaline", "item_radio", "weapon_cqc"},
		 	 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["tasks"] = "l:tasks_evacuate_personnel_and_defend_comrades",
			 ["headgear"] = "models/cultist/humans/obr/head_gear/helmet_beret.mdl",
			 ["bodygroup2"] = 1,
			 ["bodygroup1"] = 1,
			 --["bodyresist"] = 2,
			 ["bodygroup3"] = 1,
			 ["bodygroup4"] = 1,
			 ["bodygroup5"] = 1,
			 ["keycard"] = "guard_4",
			 ["ammo"] = {{"cw_kk_ins2_p90", 430 }},
			 ["health"] = 150,
			 ["armor"] = 0,
			 ["walkspeed"] = 0.8,
			 ["white"] = true,
			 ["runspeed"] = 0.9,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/obr/obr_new.mdl",
			 ["showmodel"] = "models/cultist/humans/obr/obr_new.mdl",
			 ["level"] = 3,
			 ["customcheck"] = nil,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.9,
			 	["HITGROUP_CHEST"] = 0.7,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 0.7,
			 	["HITGROUP_GEAR"] = 0.8,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    }
		}
	}
}
BREACH_ROLES.CLASSD = {
	classd = {
		name = "Персонал Класса-Д",
		color = Color(255, 130, 0),
		roles = {
			{["name"] = role.ClassD_Default,
			 ["team"] = TEAM_CLASSD,
			 ["weapons"] = {"br_holster" },
			 --["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["tasks"] = "l:tasks_escape_from_site19",
			 ["keycard"] = "",
			 ["ammo"] = {},
			 ["health"] = 100,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["hairm"] = HAIRS,
			 ["blackhairm"] = HAIRS_BLACK,
//			 ["headf"] = {"models/cultist/heads/female/shaky/head_1.mdl"},
			 ["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["fmodel"] = "models/cultist/humans/class_d/class_d_female.mdl",
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["level"] = 0,
			 ["customcheck"] = nil,
			 ["max"] = 13,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
			{["name"] = role.ClassD_GOCSpy,
			 ["team"] = TEAM_GOC,
			 ["weapons"] = {"br_holster", "item_knife"  , "breach_keycard_1"},
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["tasks"] = "l:tasks_sgoc",
			 ["stamina"] = 1.5,
			 ["keycard"] = "",
			 ["ammo"] = {},
			 ["health"] = 200,
			 ["armor"] = 0,
			 --["bodyresist"] = 2,
			 ["walkspeed"] = 1,
			 ["hairm"] = HAIRS,
			 ["blackhairm"] = HAIRS_BLACK,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["showmodel"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["level"] = 18,
			 ["customcheck"] = nil,
			 ["max"] = 2,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.9,
			 	["HITGROUP_CHEST"] = 0.9,
			 	["HITGROUP_LEFTARM"] = 0.9,
			 	["HITGROUP_RIGHTARM"] = 0.9,
			 	["HITGROUP_STOMACH"] = 0.9,
			 	["HITGROUP_GEAR"] = 0.9,
			 	["HITGROUP_LEFTLEG"] = 0.9,
			 	["HITGROUP_RIGHTLEG"] = 0.9
			 },
		    },
			{["name"] = role.ClassD_Pron,
			 ["team"] = TEAM_CLASSD,
			 ["weapons"] = {"br_holster" , "item_screwdriver", "breach_keycard_1"},
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["tasks"] = "l:tasks_escape_from_site19",
			 ["keycard"] = "1",
			 ["ammo"] = {},
			 ["health"] = 100,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["hairm"] = HAIRS,
			 ["blackhairm"] = HAIRS_BLACK,
//			 ["headf"] = {"models/cultist/heads/female/shaky/head_1.mdl"},
			 ["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["fmodel"] = "models/cultist/humans/class_d/class_d_female.mdl",
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["showmodel"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["level"] = 4,
			 ["customcheck"] = nil,
			 ["max"] = 2,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.ClassD_Probitiy,
			 ["team"] = TEAM_CLASSD,
			 ["weapons"] = {"br_holster" },
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["tasks"] = "l:tasks_escape_from_site19",
			 ["keycard"] = "",
			 ["ammo"] = {},
			 ["health"] = 175,
			 ["armor"] = 0,
			 ["hairm"] = HAIRS,
			 ["blackhairm"] = HAIRS_BLACK,
			 ["walkspeed"] = 1,
//			 ["headf"] = {"models/cultist/heads/female/shaky/head_1.mdl"},
			 ["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["fmodel"] = "models/cultist/humans/class_d/class_d_female.mdl",
		 	 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["maxslots"] = 12,
			 ["model"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["showmodel"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["level"] = 7,
			 ["customcheck"] = nil,
			 ["max"] = 3,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.ClassD_Thief,
			 ["team"] = TEAM_CLASSD,
			 ["weapons"] = {"br_holster"  },
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["tasks"] = "l:tasks_escape_from_site19",
			 ["ability"] = {"l:abilities_name_thief", 45, "l:abilities_thief", "nextoren/gui/special_abilities/ability_thief.png", false},
			 ["keycard"] = "",
			 ["ammo"] = {},
			 ["health"] = 110,
			 ["hairm"] = HAIRS,
			 ["blackhairm"] = HAIRS_BLACK,
			 ["armor"] = 0,
//			 ["headf"] = {"models/cultist/heads/female/shaky/head_1.mdl"},
			 ["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["fmodel"] = "models/cultist/humans/class_d/class_d_female.mdl",
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["showmodel"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["level"] = 20,
			 ["customcheck"] = nil,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.ClassD_Cannibal,
			 ["team"] = TEAM_CLASSD,
			 ["weapons"] = {"br_holster" , "weapon_cannibal"},
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["tasks"] = "l:tasks_escape_from_site19",
			 ["keycard"] = "",
			 ["ammo"] = {},
			 ["health"] = 60,
			 ["hairm"] = HAIRS,
			 ["blackhairm"] = HAIRS_BLACK,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
//			 ["headf"] = {"models/cultist/heads/female/shaky/head_1.mdl"},
			 ["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["fmodel"] = "models/cultist/humans/class_d/class_d_female.mdl",
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["showmodel"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["level"] = 30,
			 ["customcheck"] = nil,
			 ["max"] = 2,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.ClassD_Hack,
			 ["team"] = TEAM_CLASSD,
			 ["weapons"] = {"br_holster" , "hacking_doors"},
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["hackerhat"] = "models/cultist/humans/class_d/head_gear/hacker_hat.mdl",
			 ["tasks"] = "l:tasks_escape_from_site19",
			 ["stamina"] = .6,
			 ["keycard"] = "",
			 ["ammo"] = {},
			 ["health"] = 110,
			 --["bodygroup0"] = 3,
			 ["armor"] = 0,
			 ["white"] = true,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["showmodel"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["level"] = 14,
			 ["customcheck"] = nil,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.ClassD_Fat,
			 ["team"] = TEAM_CLASSD,
			 ["weapons"] = {"br_holster" },
			 ["head"] = {"models/cultist/heads/male/fat_heads/male_fat_01.mdl", "models/cultist/heads/male/fat_heads/male_fat_02.mdl", "models/cultist/heads/male/fat_heads/male_fat_03.mdl"},
			 ["tasks"] = "l:tasks_escape_from_site19",
			 ["keycard"] = "",
			 ["stamina"] = 0.5,
			 ["ammo"] = {},
			 ["health"] = 280,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 0.95,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/class_d/shaky/class_d_fat_new.mdl",
			 ["showmodel"] = "models/cultist/humans/class_d/shaky/class_d_fat_new.mdl",
			 ["level"] = 1,
			 ["customcheck"] = nil,
			 ["max"] = 2,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.8,
			 	["HITGROUP_CHEST"] = 0.8,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 0.8,
			 	["HITGROUP_GEAR"] = 0.8,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.ClassD_Bor,
			 ["team"] = TEAM_CLASSD,
			 ["weapons"] = {"br_holster" },
			 ["ability"] = {"l:abilities_name_bor", 65, "l:abilities_bor", "nextoren/gui/special_abilities/special_bor_takedown.png", false},
			 ["head"] = "models/cultist/heads/male/bor_heads/bor_head.mdl",
			 ["tasks"] = "l:tasks_escape_from_site19",
			 ["stamina"] = 1.5,
			 ["keycard"] = "",
			 ["ammo"] = {},
			 ["health"] = 220,
			 ["armor"] = 0,
			 --["skin"] = 1,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 0.95,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/class_d/shaky/class_d_bor_new.mdl",
			 ["showmodel"] = "models/cultist/humans/class_d/shaky/class_d_bor_new.mdl",
			 ["level"] = 5,
			 ["customcheck"] = nil,
			 ["max"] = 2,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 0.85,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 0.85,
			 	["HITGROUP_GEAR"] = 0.85,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.ClassD_Fast,
			 ["team"] = TEAM_CLASSD,
			 ["weapons"] = {"br_holster" },
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["tasks"] = "l:tasks_escape_from_site19",
			 ["ability"] = {"加速", 2, "切换奔跑模式", "nextoren/gui/special_abilities/sprint.png", false},
			 ["stamina"] = 1.6,
			 ["keycard"] = "",
			 ["ammo"] = {},
			 ["health"] = 120,
			 ["armor"] = 0,
			 ["hairm"] = HAIRS,
			 ["blackhairm"] = HAIRS_BLACK,
			 ["walkspeed"] = 1,
//			 ["headf"] = {"models/cultist/heads/female/shaky/head_1.mdl"},
			 ["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["fmodel"] = "models/cultist/humans/class_d/class_d_female.mdl",
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["showmodel"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["level"] = 21,
			 ["customcheck"] = nil,
			 ["max"] = 4,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.9,
			 	["HITGROUP_CHEST"] = 0.9,
			 	["HITGROUP_LEFTARM"] = 0.9,
			 	["HITGROUP_RIGHTARM"] = 0.9,
			 	["HITGROUP_STOMACH"] = 0.9,
			 	["HITGROUP_GEAR"] = 0.9,
			 	["HITGROUP_LEFTLEG"] = 0.9,
			 	["HITGROUP_RIGHTLEG"] = 0.9
			 },
		    },
			{["name"] = role.ClassD_Killer,
			 ["team"] = TEAM_CLASSD,
			 ["weapons"] = {"br_holster" , "item_knife"},
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["tasks"] = "l:tasks_escape_from_site19",
			 ["keycard"] = "",
			 ["ammo"] = {},
			 ["health"] = 115,
			 ["armor"] = 0,
			 ["hairm"] = HAIRS,
			 ["blackhairm"] = HAIRS_BLACK,
			 ["walkspeed"] = 1.1,
			 ["runspeed"] = 1.1,
			 ["jumppower"] = 1.1,
			 ["model"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["showmodel"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["level"] = 9,
			 ["max"] = 2,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
			{["name"] = role.ClassD_Hitman,
			 ["team"] = TEAM_CLASSD,
			 ["weapons"] = {"br_holster" , "item_knife"},
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["ability"] = {"l:abilities_name_hitman", 15, "l:abilities_hitman", "nextoren/gui/special_abilities/ability_uniform_steal.png", false},
			 ["tasks"] = "l:tasks_escape_from_site19",
			 ["keycard"] = "",
			 ["ammo"] = {},
			 ["stamina"] = 3,
			 ["health"] = 100,
			 ["white"] = true,
			 ["armor"] = 0,
			 ["walkspeed"] = 1.15,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["showmodel"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["level"] = 36,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
			{["name"] = role.ClassD_FartInhaler,
			 ["team"] = TEAM_CLASSD,
			 ["weapons"] = {"br_holster" , "item_knife", "breach_keycard_guard_2"},
			 --["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 --["ability"] = {"l:abilities_name_fake_people", 1, "l:abilities_shcom", "nextoren/gui/special_abilities/special_dz_portal.png", true},
			 --["ability_max"] = 5,
			 ["head"] = "models/shaky/funnyheads/head_gremlin.mdl",
			 ["tasks"] = "l:tasks_author Yanech_Moy",
			 ["keycard"] = "",
			 ["ammo"] = {},
			 ["white"] = true,
			 ["health"] = 200,
			 ["armor"] = 0,
			 ["stamina"] = 4,
			 --["hairm"] = HAIRS,
			 --["blackhairm"] = HAIRS_BLACK,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["showmodel"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["level"] = 150,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
		}
	}
}
BREACH_ROLES.SCI = {
	sci = {
		name = "Персонал",
		color = Color(66, 188, 244),
		roles = {
			{["name"] = role.SCI_Assistant,
			 ["team"] = TEAM_SCI,
			 ["weapons"] = {"br_holster", "weapon_pass_sci"},
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
//			 ["headf"] = {"models/cultist/heads/female/shaky/head_1.mdl"},
			 ["tasks"] = "l:tasks_escape_from_site19",
			 ["bodygroup4"] = 1,
			 ["keycard"] = "sci_1",
			 ["ammo"] = {},
			 ["health"] = 100,
			 ["armor"] = 0,
			 ["hairm"] = HAIRS,
			 ["blackhairm"] = HAIRS_BLACK,
			 ["walkspeed"] = 1,
			 ["recoilmultiplier"] = 6,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["genders"] = {true, false},
			 ["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["model"] = "models/cultist/humans/sci/scientist.mdl",
			 ["fmodel"] = "models/cultist/humans/sci/scientist_female.mdl",
			 ["showmodel"] = "models/cultist/humans/sci/scientist.mdl",
			 ["level"] = 0,
			 ["max"] = 5,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
		   {["name"] = role.SCI_SpyUSA,
			 ["team"] = TEAM_USA,
			 ["weapons"] = {"br_holster", "weapon_pass_sci", "breach_keycard_usa_spy","cw_kk_ins2_g17"},
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
//			 ["headf"] = {"models/cultist/heads/female/shaky/head_1.mdl"},
			 ["ability"] = {"l:abilities_name_suiu", 5, "l:abilities_suiu", "nextoren/gui/special_abilities/spy_chaos_focus.png", false},
			 ["tasks"] = "l:tasks_suiu",
			 ["bodygroup0"] = 2,
			 ["bodygroup1"] = 1,
			 ["keycard"] = "sci_2",
			 ["stamina"] = 1.5,
			 ["hairm"] = HAIRS,
			 ["blackhairm"] = HAIRS_BLACK,
			 ["ammo"] = {{"cw_kk_ins2_g17",25}},
			 ["health"] = 150,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["model"] = "models/cultist/humans/sci/scientist.mdl",
			 ["showmodel"] = "models/cultist/humans/sci/scientist.mdl",
			 ["level"] = 30,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
		    {["name"] = role.SCI_Cleaner,
			 ["team"] = TEAM_SCI,
			 ["weapons"] = {"br_holster"},
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["hackerhat"] = "models/shaky/humans/class_d/head_gear/cleaner_cap.mdl",
//			 ["headf"] = {"models/cultist/heads/female/shaky/head_1.mdl"},
			 ["hairf"] = {"models/cultist/heads/female/hair/hair_cleaner.mdl"},
			 ["genders"] = {true, false},
			 ["tasks"] = "l:tasks_escape_from_site19",
			 ["keycard"] = "1",
			 ["ammo"] = {},
			 ["health"] = 125,
			 ["recoilmultiplier"] = 3.4,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["fmodel"] = "models/cultist/humans/class_d/class_d_cleaner_female.mdl",
			 ["model"] = "models/cultist/humans/class_d/class_d_cleaner.mdl",
			 ["showmodel"] = "models/cultist/humans/class_d/class_d_cleaner.mdl",
			 ["level"] = 2,
			 ["customcheck"] = nil,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.SCI_Grunt,
			 ["team"] = TEAM_SCI,
			 ["weapons"] = {"br_holster", "weapon_pass_sci"},
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
//			 ["headf"] = {"models/cultist/heads/female/shaky/head_1.mdl"},
			 ["tasks"] = "l:tasks_escape_from_site19",
			 ["bodygroup1"] = 1,
			 ["keycard"] = "sci_2",
			 ["stamina"] = .5,
			 ["hairm"] = HAIRS,
			 ["blackhairm"] = HAIRS_BLACK,
			 ["ammo"] = {},
			 ["health"] = 100,
			 ["recoilmultiplier"] = 6,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
		 	 ["jumppower"] = 1,
			 ["genders"] = {true, false},
			 ["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["model"] = "models/cultist/humans/sci/scientist.mdl",
			 ["fmodel"] = "models/cultist/humans/sci/scientist_female.mdl",
			 ["showmodel"] = "models/cultist/humans/sci/scientist.mdl",
			 ["level"] = 12,
			 ["max"] = 4,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.SCI_SpyDZ,
			 ["team"] = TEAM_DZ,
			 ["weapons"] = {"br_holster", "weapon_pass_sci"},
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
//			 ["headf"] = {"models/cultist/heads/female/shaky/head_1.mdl"},
			 ["tasks"] = "l:tasks_escape_from_site19",
			 ["bodygroup1"] = 1,
			 ["keycard"] = "sci_2",
			 ["ammo"] = {},
			 ["health"] = 110,
			 ["stamina"] = 1.5,
			 ["hairm"] = HAIRS,
			 ["blackhairm"] = HAIRS_BLACK,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["genders"] = {true, false},
			 ["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["model"] = "models/cultist/humans/sci/scientist.mdl",
			 ["fmodel"] = "models/cultist/humans/sci/scientist_female.mdl",
			 ["showmodel"] = "models/cultist/humans/sci/scientist.mdl",
			 ["level"] = 20,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.SCI_Tester,
			 ["team"] = TEAM_SCI,
			 ["weapons"] = {"br_holster", "weapon_pass_sci"},
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
//			 ["headf"] = {"models/cultist/heads/female/shaky/head_1.mdl"},
			 ["tasks"] = "l:tasks_escape_from_site19",
			 ["bodygroup0"] = 2,
			 ["bodygroup1"] = 1,
			 ["keycard"] = "sci_3",
			 ["stamina"] = .6,
			 ["hairm"] = HAIRS,
			 ["blackhairm"] = HAIRS_BLACK,
			 ["ammo"] = {},
			 ["health"] = 100,
			 ["recoilmultiplier"] = 3,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["genders"] = {true, false},
			 ["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["model"] = "models/cultist/humans/sci/scientist.mdl",
			 ["fmodel"] = "models/cultist/humans/sci/scientist_female.mdl",
			 ["showmodel"] = "models/cultist/humans/sci/scientist.mdl",
			 ["level"] = 18,
			 ["max"] = 2,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
			{["name"] = role.SCI_Recruiter,
			 ["team"] = TEAM_SCI,
			 ["weapons"] = {"br_holster", "weapon_pass_sci"},
			 ["doctype"] = 10,
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
//			 ["headf"] = {"models/cultist/heads/female/shaky/head_1.mdl"},
			 ["ability"] = {"l:abilities_name_scirecruit", 5, "l:abilities_scirecruit", "nextoren/gui/special_abilities/ability_recruiter.png", true},
			 ["ability_max"] = 2,
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_recruitment",
			 ["bodygroup0"] = 2,
			 ["bodygroup1"] = 0,
			 ["bodygroup2"] = 1,
			 ["bodygroup3"] = 0,
			 ["bodygroup4"] = 1,
			 ["keycard"] = "sci_3",
			 ["hairm"] = HAIRS,
			 ["blackhairm"] = HAIRS_BLACK,
			 ["stamina"] = .5,
			 ["ammo"] = {},
			 ["health"] = 110,
			 ["armor"] = 0,
			 ["recoilmultiplier"] = 6,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["genders"] = {true, false},
			 ["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["model"] = "models/cultist/humans/sci/scientist.mdl",
			 ["fmodel"] = "models/cultist/humans/sci/scientist_female.mdl",
			 ["showmodel"] = "models/cultist/humans/sci/scientist.mdl",
			 ["level"] = 25,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.SCI_Medic,
			 ["team"] = TEAM_SCI,
			 ["weapons"] = {"br_holster", "weapon_pass_medic", "item_medkit_2", "item_deffib_medic"},		
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
//			 ["headf"] = {"models/cultist/heads/female/shaky/head_1.mdl"},
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_heal_teammates",
			 ["bodygroup0"] = 1,
			 ["bodygroup2"] = 1,
			 ["bodygroup3"] = 1,
			 ["bodygroup4"] = 1,
			 ["keycard"] = "sci_2",
			 ["stamina"] = 1.1,
			 ["ammo"] = {},
			 ["health"] = 100,
			 ["recoilmultiplier"] = 6,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["genders"] = {true, false},
			 ["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["model"] = "models/cultist/humans/sci/scientist.mdl",
			 ["fmodel"] = "models/cultist/humans/sci/scientist_female.mdl",
			 ["showmodel"] = "models/cultist/humans/sci/scientist.mdl",
			 ["level"] = 5,
			 ["max"] = 4,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
			{["name"] = role.SCI_Head,
			 ["team"] = TEAM_SCI,
			 ["weapons"] = {"br_holster", "weapon_pass_sci"},
			 ["headgear"] = "models/shaky/heads/head_gp.mdl",
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_coordinate_sci",
			 ["keycard"] = "sci_4",
			 ["ammo"] = {},
			 ["health"] = 115,
			 ["stamina"] = .7,
			 ["armor"] = 0,
			 ["recoilmultiplier"] = 2.5,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/sci/scientist_boss.mdl",
			 ["showmodel"] = "models/cultist/humans/sci/scientist_boss.mdl",
			 ["level"] = 34,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 0.8,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 0.8,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			}
		}
	}
}
BREACH_ROLES.SECURITY = {
	security = {
		name = "Служба Безопасности",
		color = Color(123, 104, 238),
		roles = {
			{["name"] = role.SECURITY_Recruit,
			 ["team"] = TEAM_SECURITY,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_g18", "weapon_cqc", "item_tazer"},
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["headgear"] = "models/cultist/humans/security/head_gear/helmet_cap.mdl",
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_protect_sci",
			 ["bodygroup3"] = 7,
			 ["bodygroup4"] = 1,
			 ["keycard"] = "security_1",
			 ["ammo"] = {{"item_tazer", 15}},
			 ["white"] = true,
			 ["health"] = 120,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/security/security.mdl",
			 ["showmodel"] = "models/cultist/humans/security/security.mdl",
			 ["level"] = 0,
			 ["max"] = 5,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.SECURITY_Sergeant,
			 ["team"] = TEAM_SECURITY,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_m1911", "weapon_cqc"},
			 --["usehead"] = false,
			 --["head"] = "models/cultist/humans/balaclavas_new/balaclava_half.mdl",
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["headgear"] = "models/cultist/humans/security/head_gear/helmet.mdl",
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_protect_sci",
			 ["bodygroup0"] = 1,
			 --["headresist"] = 1,
			 ["bodygroup3"] = 5,
			 ["bodygroup6"] = 1,
			 ["bodygroup5"] = 2,
			 ["bodygroup2"] = 1,
			 ["bodygroup4"] = 1,
			 --["bodygroup1"] = 1,
			 ["white"] = true,
			 ["keycard"] = "security_3",
			 --["hairm"] = HAIRS,
			 --["blackhairm"] = HAIRS_BLACK,
			 ["ammo"] = {},
			 ["health"] = 150,
			 ["armor"] = 0,
			 ["bodyresist"] = 2,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/security/security.mdl",
			 ["showmodel"] = "models/cultist/humans/security/security.mdl",
			 ["level"] = 9,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.9,
			 	["HITGROUP_CHEST"] = 0.9,
			 	["HITGROUP_LEFTARM"] = 0.9,
			 	["HITGROUP_RIGHTARM"] = 0.9,
			 	["HITGROUP_STOMACH"] = 0.9,
			 	["HITGROUP_GEAR"] = 0.9,
			 	["HITGROUP_LEFTLEG"] = 0.9,
			 	["HITGROUP_RIGHTLEG"] = 0.9
			 },
		    },
		    {["name"] = role.SECURITY_OFFICER,
		     ["team"] = TEAM_SECURITY,
		     ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_g18", "weapon_cqc", "item_tazer"},
			 --["usehead"] = true, ["randomizehead"] = false, ["randomizeface"] = true,
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_half.mdl",
			 ["headgear"] = "models/cultist/humans/security/head_gear/helmet.mdl",
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_protect_sci",
			 ["bodygroup6"] = 1,
			 ["bodygroup1"] = 1,
			 ["headresist"] = 1,
			 ["white"] = true,
			 ["bodygroup3"] = 4,
			 ["bodygroup5"] = 2,
			 ["bodyresist"] = 2,
		     ["keycard"] = "security_2",
		     ["ammo"] = {{"item_tazer", 15}},
		     ["health"] = 120,
		     ["armor"] = 0,
		     ["walkspeed"] = 1,
		     ["runspeed"] = 1,
		     ["jumppower"] = 1,
		     ["model"] = "models/cultist/humans/security/security.mdl",
		     ["showmodel"] = "models/cultist/humans/security/security.mdl",
		     ["level"] = 2,
		     ["max"] = 4
		    },
			{["name"] = role.SECURITY_Spy,
			 ["team"] = TEAM_CHAOS,
			 ["weapons"] = {"cw_kk_ins2_g18"},
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_help_d",
			 ["ability"] = {"l:abilities_name_cispy", 20, "l:abilities_cispy", "nextoren/gui/special_abilities/spy_chaos_focus.png", false},
			 ["stamina"] = 1.5,
			 ["white"] = true,
			 ["bodyresist"] = 1,
			 ["headresist"] = 1,
			 ["keycard"] = "security_1",
			 ["ammo"] = {},
			 ["health"] = 120,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/security/security.mdl",
			 ["showmodel"] = "models/cultist/humans/security/security.mdl",
			 ["level"] = 21,
			 ["max"] = 1
		    },
			{["name"] = role.SECURITY_Shocktrooper,
			 ["team"] = TEAM_SECURITY,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_mp5k", "weapon_cqc"},
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/security/head_gear/helmet_glass.mdl",
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_protect_sci",
			 ["bodygroup0"] = 1,
			 ["bodygroup2"] = 1,
			 ["bodygroup3"] = 3,
			 ["bodygroup5"] = 3,
			 --["headresist"] = 1,
			 --["bodyresist"] = 2,
			 ["white"] = true,
			 ["bodygroup6"] = 4,
			 ["keycard"] = "security_2",
			 ["ammo"] = {},
			 ["health"] = 150,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/security/security.mdl",
			 ["showmodel"] = "models/cultist/humans/security/security.mdl",
			 ["level"] = 14,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.85,
			 	["HITGROUP_CHEST"] = 0.8,
			 	["HITGROUP_LEFTARM"] = 0.8,
			 	["HITGROUP_RIGHTARM"] = 0.8,
			 	["HITGROUP_STOMACH"] = 0.8,
			 	["HITGROUP_GEAR"] = 0.8,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
			{["name"] = role.SECURITY_Warden,
			 ["team"] = TEAM_SECURITY,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_cstm_cobra", "weapon_cqc", "item_tazer"},
			 --["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_half.mdl",
			 ["headgear"] = "models/cultist/humans/security/head_gear/helmet_glass.mdl",
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_protect_sci",
			 ["bodygroup2"] = 1,
			 ["bodygroup3"] = 2,
			 ["bodygroup5"] = 1,
			 ["headresist"] = 1,
			 ["bodyresist"] = 2,
			 ["white"] = true,
			 ["bodygroup6"] = 1,
			 ["keycard"] = "security_3",
			 ["ammo"] = {{"item_tazer", 15}},
			 ["health"] = 130,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/security/security.mdl",
			 ["showmodel"] = "models/cultist/humans/security/security.mdl",
			 ["level"] = 3,
			 ["max"] = 1
		    },
			{["name"] = role.SECURITY_IMVSOLDIER,
			 ["team"] = TEAM_SECURITY,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_cstm_g19", "weapon_cqc", "item_tazer"},
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_half.mdl",--["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/security/head_gear/helmet.mdl",
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_protect_sci",
			 ["bodygroup2"] = 1,
			 ["bodygroup3"] = 5,
			 ["bodygroup5"] = 1,
			 ["headresist"] = 1,
			 ["bodyresist"] = 2,
			 ["white"] = true,
			 ["bodygroup6"] = 1,
			 ["keycard"] = "security_2",
			 ["ammo"] = {{"item_tazer", 15}},
			 ["health"] = 150,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/security/security.mdl",
			 ["showmodel"] = "models/cultist/humans/security/security.mdl",
			 ["level"] = 26,
			 ["max"] = 1
		    },
			{["name"] = role.SECURITY_Chief,
			 ["team"] = TEAM_SECURITY,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_deagle", "weapon_cqc", "item_tazer", "stungun"},
			 --["usehead"] = true, ["randomizehead"] = false, ["randomizeface"] = true,
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_half.mdl",
			 ["headgear"] = "models/cultist/humans/security/head_gear/helmet_beret.mdl",
			 --["headf"] = {"models/cultist/humans/security/head_gear/helmet_beret_female.mdl"},
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_protect_sci",
			 ["keycard"] = "security_4",
			 ["stamina"] = 1.1,
			 ["bodygroup0"] = 2,
			 ["bodygroup2"] = 1,
			 ["bodygroup4"] = 1,
			 ["white"] = true,
			 --["bodygroup1"] = 1,
			 ["female_head"] = {"models/cultist/heads/female/head_1.mdl"},
			 ["female_headgear"] = "models/cultist/humans/security/head_gear/helmet_beret_female.mdl",
			 --["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["premium_female"] = "models/cultist/humans/security/security_female.mdl",
			 ["bodygroup6"] = 1,
			 ["bodyresist"] = 2,
			 ["ammo"] = {{"stungun", 2}, {"item_tazer", 5}},
			 --["ammo"] = {{"stungun", 2}},
			 ["health"] = 130,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/security/security.mdl",
			 --["fmodel"] = "models/cultist/humans/security/security_female.mdl",
			 ["showmodel"] = "models/cultist/humans/security/security.mdl",
			 ["level"] = 38,
			 ["max"] = 1
		    }
		}
	}
}

BREACH_ROLES.SPECIAL = {
	special = {
		name = "Спец. Учёные",
		color = Color(0, 0, 0),
		roles = {
			{["name"] = role.SCI_SPECIAL_HEALER,
			 ["team"] = TEAM_SPECIAL,
			 ["weapons"] = {"br_holster", "weapon_pass_medic","item_deffib_medic"},
			 ["ability"] = {"l:abilities_name_matilda", 45, "l:abilities_matilda", "nextoren/gui/special_abilities/special_heal.png", false},
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_help_teammates",
			 ["keycard"] = "sci_3",
			 ["ammo"] = {},
			 ["health"] = 140,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 0.9,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/scp_special_scp/special_4.mdl",
			 ["showmodel"] = "models/cultist/humans/scp_special_scp/special_4.mdl",
			 ["level"] = 5,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
			{["name"] = role.SCI_SPECIAL_SLOWER,
			 ["team"] = TEAM_SPECIAL,
			 ["weapons"] = {"br_holster"},
			 ["ability"] = {"l:abilities_name_speedwone", 85, "l:abilities_speedwone", "nextoren/gui/special_abilities/special_slow.png", false},
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_help_teammates",
			 ["special_surname"] = true,
			 ["keycard"] = "sci_3",
			 ["ammo"] = {},
			 ["health"] = 150,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/scp_special_scp/special_3.mdl",
			 ["showmodel"] = "models/cultist/humans/scp_special_scp/special_3.mdl",
			 ["level"] = 10,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.SCI_SPECIAL_VISION,
			 ["team"] = TEAM_SPECIAL,
			 ["weapons"] = {"br_holster"},
			 ["ability"] = {"l:abilities_name_hedwig", 60, "l:abilities_hedwig", "nextoren/gui/special_abilities/spy_chaos_focus.png", false},
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_help_teammates",
			 ["keycard"] = "sci_3",
			 ["ammo"] = {},
			 ["health"] = 130,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/scp_special_scp/special_2.mdl",
			 ["showmodel"] = "models/cultist/humans/scp_special_scp/special_2.mdl",
			 ["level"] = 17,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.SCI_SPECIAL_MINE,
			 ["team"] = TEAM_SPECIAL,
			 ["weapons"] = {"br_holster"},
			 ["ability"] = {"l:abilities_name_feelon", 1, "l:abilities_feelon", "nextoren/gui/special_abilities/special_mine.png", true},
			 ["ability_max"] = 1,
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_help_teammates",
			 ["keycard"] = "sci_3",
			 ["special_surname"] = true,
			 ["ammo"] = {},
			 ["health"] = 160,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1.05,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/scp_special_scp/special_6.mdl",
			 ["showmodel"] = "models/cultist/humans/scp_special_scp/special_6.mdl",
			 ["level"] = 19,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.9,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.SCI_SPECIAL_INVISIBLE,
			 ["team"] = TEAM_SPECIAL,
			 ["weapons"] = {"br_holster"},
			 ["ability"] = {"l:abilities_name_invis", 201, "l:abilities_invis", "nextoren/gui/special_abilities/special_invisible.png", false},
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_help_teammates",
			 ["keycard"] = "sci_3",
			 ["ammo"] = {},
			 ["health"] = 180,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1.05,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/scp_special_scp/special_8.mdl",
			 ["showmodel"] = "models/cultist/humans/scp_special_scp/special_8.mdl",
			 ["level"] = 42,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.9,
			 	["HITGROUP_CHEST"] = 0.8,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 0.8,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.SCI_SPECIAL_SPEED,
			 ["team"] = TEAM_SPECIAL,
			 ["weapons"] = {"br_holster"},
			 ["ability"] = {"l:abilities_name_lomao", 45, "l:abilities_lomao", "nextoren/gui/special_abilities/special_sprint.png", false},
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_help_teammates",
			 ["keycard"] = "sci_3",
			 ["ammo"] = {},
			 ["health"] = 170,
			 ["special_surname"] = true,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1.16,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/scp_special_scp/special_1.mdl",
			 ["showmodel"] = "models/cultist/humans/scp_special_scp/special_1.mdl",
			 ["level"] = 30,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.SCI_SPECIAL_SHIELD,
			 ["team"] = TEAM_SPECIAL,
			 ["weapons"] = {"br_holster"},
			 ["ability"] = {"l:abilities_name_shield", 300, "l:abilities_shield", "nextoren/gui/special_abilities/special_shield.png", false},
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_help_teammates",
			 ["keycard"] = "sci_3",
			 ["ammo"] = {},
			 ["health"] = 180,
			 ["special_surname"] = true,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1.1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/scp_special_scp/special_7.mdl",
			 ["showmodel"] = "models/cultist/humans/scp_special_scp/special_7.mdl",
			 ["level"] = 35,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 0.8,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 0.8,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.SCI_SPECIAL_BOOSTER,
			 ["team"] = TEAM_SPECIAL,
			 ["weapons"] = {"br_holster"},
			 ["ability"] = {"l:abilities_name_buster", 100, "l:abilities_buster", "nextoren/gui/special_abilities/special_booster.png", false},
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_help_teammates",
			 ["keycard"] = "sci_3",
			 ["ammo"] = {},
			 ["health"] = 200,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1.06,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/scp_special_scp/special_9.mdl",
			 ["showmodel"] = "models/cultist/humans/scp_special_scp/special_9.mdl",
			 ["level"] = 40,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.SCI_SPECIAL_DAMAGE,
			 ["team"] = TEAM_SPECIAL,
			 ["weapons"] = {"br_holster"},
			 ["ability"] = {"l:abilities_name_kelen", 75, "l:abilities_kelen", "nextoren/gui/special_abilities/special_debuffscp.png", false},
			 ["tasks"] = "l:tasks_escape_from_site19"..",".." l:tasks_help_teammates",
			 ["keycard"] = "sci_3",
			 ["ammo"] = {},
			 ["health"] = 180,
			 ["walkspeed"] = 1,
			 ["special_surname"] = true,
			 ["runspeed"] = 1.05,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/scp_special_scp/special_5.mdl",
			 ["showmodel"] = "models/cultist/humans/scp_special_scp/special_5.mdl",
			 ["level"] = 40,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    }
		}
	}
}

BREACH_ROLES.MTF = {
	mtf = {
		name = "Мобильная Оперативная Группа",
		color = Color(0, 106, 219),
		roles = {
			{["name"] = role.MTF_Guard, 
			 ["team"] = TEAM_GUARD,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_cq300", "gasmask", "item_nightvision_green", "item_medkit_3", "weapon_pass_guard", "weapon_cqc"},
			 ["keycard"] = "guard_2",
			 ["tasks"] = "l:tasks_evacuate_personnel_and_terminate_enemies",
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/mog/head_gear/mog_helmet.mdl",
			 ["headresist"] = 1,
			 ["bodygroup0"] = 1,
			 ["bodygroup1"] = 1,
			 ["bodygroup7"] = 1,
			 --["headresist"] = 1,
			 ["bodyresist"] = 3,
			 --["ammo"] = {{"cw_kk_ins2_cq300", 340}},
			 ["health"] = 150,
			 ["armor"] = 0,
			 ["runspeed"] = 0.94,
			 ["model"] = "models/cultist/humans/mog/mog.mdl",
			 ["showmodel"] = "models/cultist/humans/mog/mog.mdl",
			 ["level"] = 0,
			 ["max"] = 6,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.95,
			 	["HITGROUP_CHEST"] = 0.95,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 0.95,
			 	["HITGROUP_GEAR"] = 0.95,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
			{["name"] = role.MTF_Shock, 
			 ["team"] = TEAM_GUARD,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_cstm_ksg", "item_nightvision_green", "item_medkit_3", "weapon_cqc", "gasmask"},
			 ["tasks"] = "l:tasks_evacuate_personnel_and_terminate_enemies",
			 --["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 --["headgear"] = "models/cultist/humans/mog/head_gear/mog_helmet.mdl",
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/mog/head_gear/mog_helmet.mdl",
			 ["headresist"] = 1,
			 ["bodyresist"] = 4,
			 ["bodygroup0"] = 2,
			 ["bodygroup1"] = 2,
			 ["bodygroup4"] = 1,
			 ["bodygroup3"] = 1,
			 ["bodygroup5"] = 1,
			 ["runspeed"] = 0.925,
			 ["maxslots"] = 10,
			 ["keycard"] = "guard_2",
			 ["ammo"] = {},
			 ["health"] = 150,
			 ["armor"] = 0,
			 ["model"] = "models/cultist/humans/mog/mog.mdl",
			 ["showmodel"] = "models/cultist/humans/mog/mog.mdl",
			 ["level"] = 8,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.7,
			 	["HITGROUP_CHEST"] = 0.7,
			 	["HITGROUP_LEFTARM"] = 0.8,
			 	["HITGROUP_RIGHTARM"] = 0.8,
			 	["HITGROUP_STOMACH"] = 0.7,
			 	["HITGROUP_GEAR"] = 0.7,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
			},
			{["name"] = role.MTF_Left, 
			 ["team"] = TEAM_GUARD,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_hk416c", "item_medkit_3", "weapon_cqc"},
			 ["tasks"] = "l:tasks_evacuate_personnel_and_terminate_enemies"..",".. " l:tasks_coordinate_mtf_peasants",
			 --["usehead"] = true, ["randomizehead"] = false, ["randomizeface"] = true,--, "models/cultist/heads/male/head_main_1_4.mdl"},
			 ["usehead"] = true, ["randomizehead"] = false, ["randomizeface"] = true,
			 --["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 --["headf"] = "models/cultist/heads/female/shaky/head_1.mdl",
			 ["headgear"] = "models/cultist/humans/mog/head_gear/hat_leftenant.mdl",
			 ["bodygroup0"] = 1,
			 ["bodygroup2"] = 1,
			 ["bodygroup1"] = 2,
			 ["bodygroup3"] = 1,
			 ["stamina"] = 1.4,
			 ["bodyresist"] = 3,
			 ["runspeed"] = 0.94,
			 ["maxslots"] = 10,
			 ["white"] = true,
			 ["keycard"] = "guard_4",
			 --["ammo"] = {{"cw_kk_ins2_hk416c", 340}},
			 ["health"] = 165,
			 ["armor"] = 0,
			 ["walkspeed"] = 0.87,
			 ["runspeed"] = 0.94,
			 ["jumppower"] = 0.9,
			 ["model"] = "models/cultist/humans/mog/mog.mdl",
			 ["showmodel"] = "models/cultist/humans/mog/mog.mdl",
			 ["level"] = 3,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.95,
			 	["HITGROUP_CHEST"] = 0.95,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 0.95,
			 	["HITGROUP_GEAR"] = 0.95,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
			{["name"] = role.MTF_Specialist,
			 ["team"] = TEAM_GUARD,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_blackout", "item_nightvision_blue", "item_medkit_3", "weapon_cqc","gasmask"},
			 ["tasks"] = "l:tasks_evacuate_personnel_and_terminate_enemies",
			 --["usehead"] = true, ["randomizehead"] = false, ["randomizeface"] = true,
			 --["head"] = "models/cultist/humans/balaclavas_new/balaclava_half.mdl",
			 --["headgear"] = "models/cultist/humans/a9/head_gear/a9_helmet.mdl",
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/mog/head_gear/mog_helmet_2.mdl",
			 ["headresist"] = 1,
			 ["bodyresist"] = 3,
			 ["headresist"] = 1,
			 ["bodygroup0"] = 1,
			 ["bodygroup1"] = 2,
			 ["bodygroup7"] = 1,
			 ["bodygroup3"] = 1,
			 --["bodygroup0"] = 1,
			 --["bodygroup1"] = 2,
			 --["bodygroup7"] = 1,
			 --["bodygroup3"] = 1,
			 ["runspeed"] = 0.99,
			 ["maxslots"] = 10,
			 ["keycard"] = "guard_3",
			 --["ammo"] = {{"cw_kk_ins2_blackout", 340}},
			 ["health"] = 170,
			 ["armor"] = 0,
			 ["model"] = "models/cultist/humans/mog/mog.mdl",
			 ["showmodel"] = "models/cultist/humans/mog/mog.mdl",
			 ["level"] = 21,
			 ["max"] = 2,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.95,
			 	["HITGROUP_CHEST"] = 0.95,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 0.95,
			 	["HITGROUP_GEAR"] = 0.95,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
			{["name"] = role.Dispatcher,
			 ["team"] = TEAM_GUARD,
			 ["weapons"] = {"br_holster", "item_radio", "weapon_cqc","cw_kk_ins2_g18",},
			 ["tasks"] = "l:tasks_help_teammates_through_intercom",
			 ["keycard"] = "guard_4",
			 ["ammo"] = {{"cw_kk_ins2_g18", 50}},
			 ["health"] = 100,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["genders"] = {true},
			 ["model"] = "models/cultist/humans/sci/dispatch.mdl",
			 ["showmodel"] = "models/cultist/humans/sci/dispatch.mdl",
			 ["level"] = 23,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.MTF_Medic, 
			 ["team"] = TEAM_GUARD,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_cstm_famas", "item_medkit_4", "item_deffib_medic", "item_syringe", "weapon_cqc"},
			 ["keycard"] = "guard_2",
			 ["skin"] = 1,
			 ["tasks"] = "l:tasks_evacuate_personnel_and_terminate_enemies"..", l:tasks_heal_teammates",
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/mog/head_gear/mog_helmet.mdl",
			 ["headresist"] = 1,
			 ["bodyresist"] = 3,
			 ["bodygroup0"] = 1,
			 ["bodygroup1"] = 2,
			 ["bodygroup7"] = 1,
			 ["runspeed"] = 0.94,
			 ["maxslots"] = 10,
			 ["runspeed"] = 1.1,
			 --["ammo"] = {{"cw_kk_ins2_cstm_famas", 340}},
			 ["health"] = 150,
			 ["armor"] = 0,
			 ["model"] = "models/cultist/humans/mog/mog.mdl",
			 ["showmodel"] = "models/cultist/humans/mog/mog.mdl",
			 ["level"] = 1,
			 ["max"] = 2,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.95,
			 	["HITGROUP_CHEST"] = 0.95,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 0.95,
			 	["HITGROUP_GEAR"] = 0.95,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
			{["name"] = role.MTF_Com, 
			 ["team"] = TEAM_GUARD,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_uar556", "item_medkit_3", "weapon_cqc"},
			 ["tasks"] = "l:tasks_evacuate_personnel_and_terminate_enemies"..", l:tasks_coordinate_mtf",
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_half.mdl",
			 ["headgear"] = "models/cultist/humans/mog/head_gear/helmet_beret.mdl",
			 ["stamina"] = 1.4,
			 ["bodygroup0"] = 1,
			 ["bodyresist"] = 3,
			 ["bodygroup2"] = 0,
			 ["bodygroup1"] = 2,
			 ["bodygroup3"] = 1,
			 ["bodygroup7"] = 1,
			 ["runspeed"] = 1.1,
			 ["runspeed"] = 0.98,
			 ["maxslots"] = 10,
			 ["white"] = true,
			 ["keycard"] = "guard_4",
			 --["ammo"] = {{"cw_kk_ins2_uar556", 340}},
			 ["health"] = 165,
			 ["armor"] = 0,
			 ["model"] = "models/cultist/humans/mog/mog.mdl",
			 ["showmodel"] = "models/cultist/humans/mog/mog.mdl",
			 ["level"] = 21,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.95,
			 	["HITGROUP_CHEST"] = 0.95,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 0.95,
			 	["HITGROUP_GEAR"] = 0.95,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
			{["name"] = role.MTF_HOF, 
			 ["team"] = TEAM_GUARD,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_revolver", "item_medkit_2", "weapon_cqc","item_special_document"},
			 ["tasks"] = "l:tasks_hof",
			 ["keycard"] = "6",
			 --["ammo"] = {{"cw_kk_ins2_revolver", 180}},
			 ["health"] = 100,
			 --["bodyresist"] = 1,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1.1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/mog/head_site.mdl",
			 ["showmodel"] = "models/cultist/humans/mog/head_site.mdl",
			 ["level"] = 37,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 0.8,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 0.8,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
			{["name"] = role.MTF_Security, 
			 ["team"] = TEAM_GUARD,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_m1911", "weapon_checker", "weapon_cqc","item_medkit_2"},
			 ["tasks"] = "l:tasks_mtf_checker",
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 --["head"] = "models/cultist/humans/balaclavas_new/balaclava_half.mdl",
			 ["keycard"] = "guard_3",
			 --["ammo"] = {{"cw_kk_ins2_m1911", 48}},
			 ["health"] = 185,
			 --["bodyresist"] = 1,
			 ["hairm"] = {"models/cultist/heads/male/hair/hair_1.mdl", "models/cultist/heads/male/hair/hair_2.mdl"},
			 ["blackhairm"] = {"models/cultist/heads/male/hair/hair_1.mdl", "models/cultist/heads/male/hair/hair_2.mdl"},
			 ["female_head"] = {"models/cultist/heads/female/female_head_"..math.random(1, 52)..".mdl"},
			 ["female_headgear"] = HAIRS_WOMAN___BITCHES____,
			 ["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["premium_female"] = "models/cultist/humans/mog/special_security_woman.mdl",
			 --["female_head"] = {"models/cultist/heads/female/head_1.mdl"},
			 --["female_headgear"] = "models/cultist/humans/security/head_gear/helmet_beret_female.mdl",
			 --["hairf"] = HAIRS_WOMAN___BITCHES____,
			 --["premium_female"] = "models/cultist/humans/security/security_female.mdl",
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1.2,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/mog/special_security.mdl",
			 ["showmodel"] = "models/cultist/humans/mog/special_security.mdl",
			 ["level"] = 41,
			 ["max"] = 2,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 0.95,
			 	["HITGROUP_LEFTARM"] = 0.95,
			 	["HITGROUP_RIGHTARM"] = 0.95,
			 	["HITGROUP_STOMACH"] = 0.95,
			 	["HITGROUP_GEAR"] = 0.95,
			 	["HITGROUP_LEFTLEG"] = 0.95,
			 	["HITGROUP_RIGHTLEG"] = 0.95
			 },
		    },
			{["name"] = role.MTF_Chem, 
			 ["team"] = TEAM_GUARD,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_cstm_kriss", "item_syringe", "item_adrenaline", "item_pills", "item_medkit_3", "weapon_cqc"},
			 ["tasks"] = "l:tasks_evacuate_personnel_and_terminate_enemies",
			 ["bodygroup1"] = 1,
			 ["keycard"] = "guard_3",
			 --["ammo"] = {{"cw_kk_ins2_cstm_kriss", 125}},
			 ["health"] = 120,
			 ["bodyresist"] = 3,
			 ["runspeed"] = 1,
			 ["armor"] = 0,
			 ["model"] = "models/cultist/humans/mog/mog_hazmat.mdl",
			 ["showmodel"] = "models/cultist/humans/mog/mog_hazmat.mdl",
			 ["level"] = 15,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 0.95,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 0.95,
			 	["HITGROUP_GEAR"] = 0.95,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
			{["name"] = role.MTF_Engi, 
			 ["team"] = TEAM_GUARD,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_m40a1", "item_medkit_3", "weapon_cqc"},
			 ["tasks"] = "l:tasks_evacuate_personnel_and_terminate_enemies"..", l:tasks_engi",
			 ["ability"] = {"l:abilities_name_engi", 1, "l:abilities_engi", "nextoren/gui/special_abilities/engineer_turret.png", true},
			 ["ability_max"] = 1,
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/mog/head_gear/cap_engi.mdl",
			 ["white"] = true,
			 ["bodygroup0"] = 1,
			 ["bodyresist"] = 3,
			 ["bodygroup1"] = 3,
			 ["bodygroup2"] = 1,
			 ["bodygroup7"] = 1,
			 ["runspeed"] = 1,
			 ["keycard"] = "guard_3",
			 --["ammo"] = {{"cw_kk_ins2_m40a1", 30}},
			 ["female_head"] = {"models/cultist/heads/female/head_1.mdl"},
			 ["female_headgear"] = "models/cultist/humans/mog/head_gear/cap_engi_woman.mdl",
			 --["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["premium_female"] = "models/cultist/humans/mog/mog_woman.mdl",
			 ["stamina"] = .6,
			 ["health"] = 130,
			 ["armor"] = 0,
			 ["model"] = "models/cultist/humans/mog/mog.mdl",
			 ["showmodel"] = "models/cultist/humans/mog/mog.mdl",
			 ["level"] = 7,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.95,
			 	["HITGROUP_CHEST"] = 0.95,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 0.95,
			 	["HITGROUP_GEAR"] = 0.95,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
			{["name"] = role.MTF_Jag, 
			 ["team"] = TEAM_GUARD,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_m249", "item_medkit_3", "item_drink_coffe", "item_adrenaline", "weapon_cqc","item_nightvision_green"},
			 ["tasks"] = "l:tasks_evacuate_personnel_and_terminate_enemies",
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/mog/head_gear/jugger_helmet.mdl",
			 ["runspeed"] = 0.8,
			 ["keycard"] = "guard_3",
			 --["ammo"] = {{"cw_kk_ins2_m249", 750}},
			 ["stamina"] = .6,
			 ["health"] = 240,
			 --["armor"] = 220,
			 ["model"] = "models/cultist/humans/mog/mog_jagger.mdl",
			 ["showmodel"] = "models/cultist/humans/mog/mog.mdl",
			 ["level"] = 39,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.4,
			 	["HITGROUP_CHEST"] = 0.4,
			 	["HITGROUP_LEFTARM"] = 0.4,
			 	["HITGROUP_RIGHTARM"] = 0.4,
			 	["HITGROUP_STOMACH"] = 0.4,
			 	["HITGROUP_GEAR"] = 0.4,
			 	["HITGROUP_LEFTLEG"] = 0.4,
			 	["HITGROUP_RIGHTLEG"] = 0.4
			 },
			},
		}
	}
}
BREACH_ROLES.NTF = {
	ntf = {
		name = "Armed Site Support",
		color = Color(29, 81, 56),
		roles = {
			{["name"] = role.NTF_Soldier, 
			 ["team"] = TEAM_NTF,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_p90", "item_nightvision_green", "item_medkit_3"},
			 ["tasks"] = "l:tasks_ntf",
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/ntf/head_gear/head_helmet.mdl",
			 ["bodygroup0"] = 1,
			 ["bodygroup2"] = 1,
			 ["bodygroup3"] = 1,
			 ["bodygroup4"] = 1,
			 ["bodygroup5"] = 1,
			 ["bodygroup6"] = 1,
			 ["bodygroup7"] = 1,
			 --["headresist"] = 1,
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_kk_ins2_p90", 300}},
			 ["health"] = 150,
			 ["armor"] = 125,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 0.93,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/ntf/ntf.mdl",
			 ["showmodel"] = "models/cultist/humans/ntf/ntf.mdl",
			 ["level"] = 0,
			 ["max"] = 6,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.7,
			 	["HITGROUP_CHEST"] = 0.7,
			 	["HITGROUP_LEFTARM"] = 0.8,
			 	["HITGROUP_RIGHTARM"] = 0.8,
			 	["HITGROUP_STOMACH"] = 0.7,
			 	["HITGROUP_GEAR"] = 0.7,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
			},
			{["name"] = role.NTF_Sniper, 
			 ["team"] = TEAM_NTF,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_cultist_barrett", "item_nightvision_blue", "item_adrenaline", "item_medkit_3"},
			 ["tasks"] = "l:tasks_ntf",
			 ["usehead"] = true, ["randomizehead"] = false, ["randomizeface"] = true,
			 ["headgear"] = "models/cultist/humans/ntf/head_gear/ntf_sniper_head.mdl",
			 ["bodygroup0"] = 1,
			 --["bodyresist"] = 4,
			 ["bodygroup1"] = 2,
			 ["bodygroup5"] = 1,
			 ["keycard"] = "support",
			 ["white"] = true,
			 ["ammo"] = {{"cw_kk_ins2_cultist_barrett", 70}},
			 ["health"] = 150,
			 ["armor"] = 0,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 0.93,
			 ["jumppower"] = 0.85,
			 ["female_head"] = {"models/cultist/heads/female/head_1.mdl"},
			 ["female_headgear"] = "models/cultist/humans/ntf/head_gear/ntf_sniper_head_female.mdl",
			 --["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["premium_female"] = "models/cultist/humans/ntf/ntf_female_sniper.mdl",
			 ["model"] = "models/cultist/humans/ntf/ntf.mdl",
			 ["showmodel"] = "models/cultist/humans/ntf/ntf.mdl",
			 ["level"] = 16,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 0.8,
			 	["HITGROUP_LEFTARM"] = 0.9,
			 	["HITGROUP_RIGHTARM"] = 0.9,
			 	["HITGROUP_STOMACH"] = 0.8,
			 	["HITGROUP_GEAR"] = 0.8,
			 	["HITGROUP_LEFTLEG"] = 0.9,
			 	["HITGROUP_RIGHTLEG"] = 0.9
			 },
		    },
			{["name"] = role.NTF_Specialist, 
			 ["team"] = TEAM_NTF,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_p90", "cw_kk_ins2_deagle", "item_nightvision_blue", "item_adrenaline", "item_medkit_3"},
			 ["tasks"] = "l:tasks_ntf",
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["headgear"] = "models/cultist/humans/ntf/head_gear/ntf_special_head.mdl",
			 ["ability"] = {"l:abilities_name_ntfspec", 90, "l:abilities_ntfspec", "nextoren/gui/special_abilities/special_ntf_specialist.png", false},
			 ["bodygroup0"] = 1,
			 ["bodygroup1"] = 2,
			 --["bodyresist"] = 4,
			 ["bodygroup2"] = 3,
			 ["bodygroup3"] = 1,
			 ["bodygroup5"] = 1,
			 ["bodygroup6"] = 1,
			 ["bodygroup7"] = 1,
			 ["white"] = true,
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_kk_ins2_p90", 300}, {"cw_kk_ins2_deagle", 48}},
			 ["health"] = 175,
			 ["armor"] = 0,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 0.93,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/ntf/ntf.mdl",
			 ["showmodel"] = "models/cultist/humans/ntf/ntf.mdl",
			 ["level"] = 33,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 0.7,
			 	["HITGROUP_LEFTARM"] = 0.8,
			 	["HITGROUP_RIGHTARM"] = 0.8,
			 	["HITGROUP_STOMACH"] = 0.7,
			 	["HITGROUP_GEAR"] = 0.7,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
			{["name"] = role.NTF_Commander, 
			 ["team"] = TEAM_NTF,
			 ["weapons"] = {"br_holster", "item_radio", "breach_keycard_LastHope","item_adrenaline", "item_medkit_3", "cw_kk_ins2_p90", "cw_kk_ins2_deagle", "item_nightvision_blue", "item_drink_soda"},
			 ["tasks"] = "l:tasks_ntf"..", l:tasks_coordinate_ntf",
			 ["head"] = "models/cultist/humans/balaclavas_new/head_balaclava_month.mdl",
			 ["headgear"] = "models/cultist/humans/ntf/head_gear/helmet_beret.mdl",
			 ["ability"] = {"l:abilities_name_ntfcom", 120, "l:abilities_ntfcom", "nextoren/gui/special_abilities/special_ntf_commander.png", false},
			 ["bodygroup0"] = 3,
			 ["bodygroup1"] = 1,
			 --["bodyresist"] = 4,
			 ["bodygroup2"] = 2,
			 ["bodygroup3"] = 1,
			 ["bodygroup5"] = 1,
			 ["bodygroup6"] = 1,
			 ["white"] = true,
			 ["bodygroup7"] = 1,
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_kk_ins2_p90", 300}, {"cw_kk_ins2_deagle", 48}},
			 ["health"] = 170,
			 ["armor"] = 0,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 0.93,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/ntf/ntf.mdl",
			 ["showmodel"] = "models/cultist/humans/ntf/ntf.mdl",
			 ["level"] = 10,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 0.7,
			 	["HITGROUP_LEFTARM"] = 0.8,
			 	["HITGROUP_RIGHTARM"] = 0.8,
			 	["HITGROUP_STOMACH"] = 0.7,
			 	["HITGROUP_GEAR"] = 0.7,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    }
		}
	}
}


-- STS removed from the available role pool.
BREACH_ROLES.OSN = nil
BREACH_ROLES.CHAOS = {
    chaos = {
        name = "Chaos",
        color = Color(29, 81, 56),
        roles = {
            {["name"] = role.Chaos_Grunt, 
             ["team"] = TEAM_CHAOS,
             ["weapons"] = {"br_holster", "cw_kk_ins2_ak12", "item_radio", "item_syringe","item_nightvision_blue", "item_medkit_3"},
             ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
             ["tasks"] = "l:tasks_ci",
             ["headgear"] = "models/cultist/humans/chaos/head_gear/helmet.mdl",
             ["bodygroup0"] = 1,
             ["bodygroup2"] = 1,
             ["keycard"] = "support",
             ["ammo"] = {{"cw_kk_ins2_ak12", 400}},
             ["health"] = 150,
             ["armor"] = 10,
             ["walkspeed"] = 0.86,
             ["runspeed"] = 0.88,
             ["jumppower"] = 0.85,
             --["headresist"] = 1,
             --["bodyresist"] = 3,
             ["model"] = "models/cultist/humans/chaos/chaos.mdl",
             ["showmodel"] = "models/cultist/humans/chaos/chaos.mdl",
             ["level"] = 0,
             ["max"] = 6,
             ["damage_modifiers"] = {
                 ["HITGROUP_HEAD"] = 0.7,
                 ["HITGROUP_CHEST"] = 0.7,
                 ["HITGROUP_LEFTARM"] = 0.8,
                 ["HITGROUP_RIGHTARM"] = 0.8,
                 ["HITGROUP_STOMACH"] = 0.7,
                 ["HITGROUP_GEAR"] = 0.7,
                 ["HITGROUP_LEFTLEG"] = 0.8,
                 ["HITGROUP_RIGHTLEG"] = 0.8
             },
            },
            {["name"] = role.Chaos_Commander, 
             ["team"] = TEAM_CHAOS,
             ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_cstm_scar", "item_syringe","item_nightvision_blue", "item_medkit_3"},
             ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
             ["headgear"] = "models/cultist/humans/chaos/head_gear/beret.mdl",
             ["tasks"] = "l:tasks_ci"..",".." l:tasks_coordinate_ci",
             ["ability"] = {"l:abilities_name_cicom", 4, "l:abilities_cicom", "nextoren/gui/special_abilities/special_chaos_commander.png", true},
             ["ability_max"] = 3,
             ["bodygroup0"] = 0,
             --["bodyresist"] = 3,
             ["bodygroup2"] = 1,
             ["bodygroup1"] = 1,
             --["bodygroup2"] = 1,
             ["keycard"] = "support",
             ["ammo"] = {{"cw_kk_ins2_cstm_scar",400}},
             ["health"] = 170,
             ["armor"] = 0,
             ["walkspeed"] = 0.86,
             ["runspeed"] = 0.88,
             ["jumppower"] = 0.85,
             ["white"] = true,
             ["model"] = "models/cultist/humans/chaos/chaos.mdl",
             ["showmodel"] = "models/cultist/humans/chaos/chaos.mdl",
             ["level"] = 7,
             ["max"] = 1,
             ["damage_modifiers"] = {
                 ["HITGROUP_HEAD"] = 1,
                 ["HITGROUP_CHEST"] = 0.7,
                 ["HITGROUP_LEFTARM"] = 0.8,
                 ["HITGROUP_RIGHTARM"] = 0.8,
                 ["HITGROUP_STOMACH"] = 0.7,
                 ["HITGROUP_GEAR"] = 0.7,
                 ["HITGROUP_LEFTLEG"] = 0.8,
                 ["HITGROUP_RIGHTLEG"] = 0.8
             },
            },
            {["name"] = role.Chaos_Demo, 
             ["team"] = TEAM_CHAOS,
             ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_rpg", "cw_kk_ins2_cstm_spas12", "item_syringe","item_nightvision_blue", "item_medkit_3"},
             ["tasks"] = "l:tasks_ci"..",".." l:tasks_mines",
             ["usehead"] = true, ["randomizehead"] = false, ["randomizeface"] = true,
             ["ability"] = {"l:abilities_name_chaosdemo", 1, "l:abilities_chaosmine", "nextoren/gui/special_abilities/special_chaos_claymore.png", true},
             ["ability_max"] = 1,
             ["bodygroup0"] = 3,
             --["bodyresist"] = 3,
             ["bodygroup2"] = 2,
             ["keycard"] = "support",
             ["ammo"] = {{"cw_kk_ins2_cstm_spas12", 100}, {"cw_kk_ins2_rpg", 2}},
             ["health"] = 170,
             ["armor"] = 10,
             ["walkspeed"] = 0.86,
             ["runspeed"] = 0.91,
             ["jumppower"] = 0.85,
             ["model"] = "models/cultist/humans/chaos/chaos.mdl",
             ["showmodel"] = "models/cultist/humans/chaos/chaos.mdl",
             ["level"] = 0,
             ["max"] = 1,
             ["damage_modifiers"] = {
                 ["HITGROUP_HEAD"] = 1,
                 ["HITGROUP_CHEST"] = 0.7,
                 ["HITGROUP_LEFTARM"] = 0.8,
                 ["HITGROUP_RIGHTARM"] = 0.8,
                 ["HITGROUP_STOMACH"] = 0.7,
                 ["HITGROUP_GEAR"] = 0.7,
                 ["HITGROUP_LEFTLEG"] = 0.8,
                 ["HITGROUP_RIGHTLEG"] = 0.8
             },
            },
            {["name"] = role.Chaos_Jugg, 
             ["team"] = TEAM_CHAOS,
             ["weapons"] = {"br_holster", "item_radio", "cw_cultist_machinegun_m60", "item_syringe","item_nightvision_blue", "item_medkit_3"},
             ["tasks"] = "l:tasks_ci",
             ["head"] = "models/cultist/humans/balaclavas_new/head_balaclava_month.mdl",
             ["headgear"] = "models/cultist/humans/chaos/head_gear/helmet.mdl",
             ["stamina"] = .5,
             ["bodygroup0"] = 2,
             ["bodygroup2"] = 3,
             ["bodygroup5"] = 1,
             ["keycard"] = "support",
             ["ammo"] = {{"cw_cultist_machinegun_m60", 600}},
             ["health"] = 240,
             ["armor"] = 80,
             ["walkspeed"] = 0.86,
             ["runspeed"] = 0.8,
             ["jumppower"] = 0.85,
             ["model"] = "models/cultist/humans/chaos/chaos.mdl",
             ["showmodel"] = "models/cultist/humans/chaos/chaos.mdl",
             ["level"] = 32,
             ["max"] = 1,
             ["damage_modifiers"] = {
                 ["HITGROUP_HEAD"] = 0.5,
                 ["HITGROUP_CHEST"] = 0.5,
                 ["HITGROUP_LEFTARM"] = 0.5,
                 ["HITGROUP_RIGHTARM"] = 0.5,
                 ["HITGROUP_STOMACH"] = 0.5,
                 ["HITGROUP_GEAR"] = 0.5,
                 ["HITGROUP_LEFTLEG"] = 0.5,
                 ["HITGROUP_RIGHTLEG"] = 0.5
             },
            }
        }
    }
}

BREACH_ROLES.GRU = {
	gru = {
		name = "GRU ''P'' Division",
		color = Color(29, 81, 56),
		roles = {
			{["name"] = role.GRU_Soldier, 
			 ["team"] = TEAM_GRU,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_ak117", "item_syringe", "item_medkit_3"},
			 ["head"] = "models/cultist/humans/balaclavas_new/head_balaclava_month.mdl",
			 ["tasks"] = "l:tasks_gru",
			 ["headgear"] = "models/cultist/humans/russian/head_gear/helmet_2.mdl",
			 ["bodygroup2"] = 3,
			 ["bodygroup4"] = 1,
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_kk_ins2_ak117", 315}},
			 ["white"] = true,
			 ["health"] = 130,
			 ["armor"] = 0,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 0.93,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/russian/russians.mdl",
			 ["showmodel"] = "models/cultist/humans/russian/russians.mdl",
			 ["level"] = 5,
			 ["max"] = 5,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.8,
			 	["HITGROUP_CHEST"] = 0.8,
			 	["HITGROUP_LEFTARM"] = 0.8,
			 	["HITGROUP_RIGHTARM"] = 0.8,
			 	["HITGROUP_STOMACH"] = 0.8,
			 	["HITGROUP_GEAR"] = 0.8,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
			{["name"] = role.GRU_Specialist, 
			 ["team"] = TEAM_GRU,
			 ["tasks"] = "l:tasks_gru",
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_sks", "item_syringe", "item_medkit_3"},
			 ["head"] = "models/cultist/humans/balaclavas_new/head_balaclava_month.mdl",
			 ["headgear"] = "models/cultist/humans/russian/head_gear/cap.mdl",
			 ["bodygroup0"] = 1,
			 ["bodygroup1"] = 2,
			 ["bodygroup2"] = 1,
			 ["white"] = true,
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_kk_ins2_sks", 140}},
			 ["health"] = 150,
			 ["armor"] = 0,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 0.93,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/russian/russians.mdl",
			 ["showmodel"] = "models/cultist/humans/russian/russians.mdl",
			 ["level"] = 14,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 0.9,
			 	["HITGROUP_LEFTARM"] = 0.9,
			 	["HITGROUP_RIGHTARM"] = 0.8,
			 	["HITGROUP_STOMACH"] = 0.9,
			 	["HITGROUP_GEAR"] = 0.8,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
			{["name"] = role.GRU_Jugg, 
			 ["team"] = TEAM_GRU,
			 ["tasks"] = "l:tasks_gru",
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_rkr", "item_syringe", "item_medkit_3"},
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/russian/head_gear/helmet_1.mdl",
			 ["stamina"] = .7,
			 ["bodygroup0"] = 1,
			 ["bodygroup2"] = 4,
			 ["bodygroup3"] = 1,
			 ["white"] = true,
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_kk_ins2_rkr", 800}},
			 ["health"] = 200,
			 ["armor"] = 0,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 0.93,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/russian/russians.mdl",
			 ["showmodel"] = "models/cultist/humans/russian/russians.mdl",
			 ["level"] = 21,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.35,
			 	["HITGROUP_CHEST"] = 0.35,
			 	["HITGROUP_LEFTARM"] = 0.35,
			 	["HITGROUP_RIGHTARM"] = 0.35,
			 	["HITGROUP_STOMACH"] = 0.35,
			 	["HITGROUP_GEAR"] = 0.35,
			 	["HITGROUP_LEFTLEG"] = 0.35,
			 	["HITGROUP_RIGHTLEG"] = 0.35
			 },
		    },
			{["name"] = role.GRU_Commander, 
			 ["team"] = TEAM_GRU,
			 ["tasks"] = "l:tasks_gru"..",".." l:tasks_coordinate_gru",
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_groza", "item_syringe", "item_medkit_3"},
			 ["head"] = "models/cultist/humans/balaclavas_new/head_balaclava_month.mdl",
			 ["headgear"] = "models/cultist/humans/russian/head_gear/helmet_beret.mdl",
			 ["ability"] = {"l:abilities_name_grucom", 50, "l:abilities_grucom", "nextoren/gui/special_abilities/special_gru_commander.png", false},
			 ["bodygroup0"] = 1,
			 ["bodygroup1"] = 1,
			 ["bodygroup2"] = 1,
			 ["white"] = true,
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_kk_ins2_groza", 315}},
			 ["health"] = 155,
			 ["armor"] = 0,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 0.93,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/russian/russians.mdl",
			 ["showmodel"] = "models/cultist/humans/russian/russians.mdl",
			 ["level"] = 5,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 0.7,
			 	["HITGROUP_LEFTARM"] = 0.8,
			 	["HITGROUP_RIGHTARM"] = 0.8,
			 	["HITGROUP_STOMACH"] = 0.7,
			 	["HITGROUP_GEAR"] = 0.7,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    }
		}
	}
}
BREACH_ROLES.GOC = {
	goc = {
		name = "Global Occult Coalition",
		color = Color(29, 81, 56),
		roles = {
			{["name"] = role.Goc_Grunt, 
			 ["team"] = TEAM_GOC,
			 ["weapons"] = {"br_holster", "item_radio", "cw_cultist_semisniper_arx160", "item_nightvision_white", "item_adrenaline"},
			 ["headgear"] = "models/cultist/humans/goc/head/helmet_1.mdl",
			 ["tasks"] = "l:tasks_goc",
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_cultist_semisniper_arx160", 355}},
			 ["health"] = 145,
			 --["armor"] = 300,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 0.93,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/goc/goc.mdl",
			 ["showmodel"] = "models/cultist/humans/goc/goc.mdl",
			 ["level"] = 10,
			 ["max"] = 5,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.4,
			 	["HITGROUP_CHEST"] = 0.4,
			 	["HITGROUP_LEFTARM"] = 0.4,
			 	["HITGROUP_RIGHTARM"] = 0.4,
			 	["HITGROUP_STOMACH"] = 0.4,
			 	["HITGROUP_GEAR"] = 0.4,
			 	["HITGROUP_LEFTLEG"] = 0.4,
			 	["HITGROUP_RIGHTLEG"] = 0.4
			 },
		    },
			{["name"] = role.Goc_Special, 
			 ["team"] = TEAM_GOC,
			 ["weapons"] = {"br_holster", "item_radio", "cw_cultist_goc_freedom", "item_nightvision_white", "item_adrenaline", "item_medkit_3"},
			 ["headgear"] = "models/cultist/humans/goc/head/helmet_3.mdl",
			 ["tasks"] = "l:tasks_goc",
			 ["ability"] = {"l:abilities_name_gocspec", 45, "l:abilities_gocspec", "nextoren/gui/special_abilities/ability_goc_specialist.png", false},
			 ["keycard"] = "support",
			 ["bodygroup0"] = 1,
			 ["ammo"] = {{"cw_cultist_goc_freedom", 355}},
			 ["health"] = 190,
			 --["armor"] = 300,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 0.93,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/goc/goc.mdl",
			 ["showmodel"] = "models/cultist/humans/goc/goc.mdl",
			 ["level"] = 12,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
				["HITGROUP_HEAD"] = 0.4,
				["HITGROUP_CHEST"] = 0.4,
				["HITGROUP_LEFTARM"] = 0.4,
				["HITGROUP_RIGHTARM"] = 0.4,
				["HITGROUP_STOMACH"] = 0.4,
				["HITGROUP_GEAR"] = 0.4,
				["HITGROUP_LEFTLEG"] = 0.4,
				["HITGROUP_RIGHTLEG"] = 0.4
			 },
		    },
			{["name"] = role.Goc_Commander, 
			 ["team"] = TEAM_GOC,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_nv4", "item_nightvision_white", "item_adrenaline"},
			 ["headgear"] = "models/cultist/humans/goc/head/helmet_4.mdl",
			 ["tasks"] = "l:tasks_goc"..",".." l:tasks_coordinate_goc",
			 ["ability"] = {"l:abilities_name_goccom", 80, "l:abilities_goccom", "nextoren/gui/special_abilities/special_goc_invisibility.png", false},
			 ["keycard"] = "support",
			 ["bodygroup0"] = 3,
			 ["ammo"] = {{"cw_kk_ins2_nv4", 355}},
			 ["health"] = 175,
			 --["armor"] = 300,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 0.93,
			 ["jumppower"] = 0.85,
			 ["premium_female"] = "models/cultist/humans/goc/goc_female_commander.mdl",
			 ["model"] = "models/cultist/humans/goc/goc.mdl",
			 ["showmodel"] = "models/cultist/humans/goc/goc.mdl",
			 ["level"] = 24,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.4,
			 	["HITGROUP_CHEST"] = 0.4,
			 	["HITGROUP_LEFTARM"] = 0.4,
			 	["HITGROUP_RIGHTARM"] = 0.4,
			 	["HITGROUP_STOMACH"] = 0.4,
			 	["HITGROUP_GEAR"] = 0.4,
			 	["HITGROUP_LEFTLEG"] = 0.4,
			 	["HITGROUP_RIGHTLEG"] = 0.4
			 },
		    },
			{["name"] = role.Goc_Jag, 
			 ["team"] = TEAM_GOC,
			 ["weapons"] = {"br_holster", "item_radio", "cw_cultist_goc_fate", "item_nightvision_white", "item_adrenaline"},
			 ["headgear"] = "models/cultist/humans/goc/head/helmet_2.mdl",
			 ["tasks"] = "l:tasks_goc",
			 ["ability"] = {"l:abilities_name_gocjag", 75, "l:abilities_gocjag", "nextoren/gui/special_abilities/special_goc_shield.png", false},
			 ["keycard"] = "support",
			 ["stamina"] = .5,
			 ["bodygroup0"] = 2,
			 ["ammo"] = {{"cw_cultist_goc_fate", 355}},
			 ["health"] = 240,
			 --["armor"] = 420,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 0.93,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/goc/goc.mdl",
			 ["showmodel"] = "models/cultist/humans/goc/goc.mdl",
			 ["level"] = 22,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
				["HITGROUP_HEAD"] = 0.2,
				["HITGROUP_CHEST"] = 0.2,
				["HITGROUP_LEFTARM"] = 0.2,
				["HITGROUP_RIGHTARM"] = 0.2,
				["HITGROUP_STOMACH"] = 0.2,
				["HITGROUP_GEAR"] = 0.2,
				["HITGROUP_LEFTLEG"] = 0.2,
				["HITGROUP_RIGHTLEG"] = 0.2
			 },
		    }
		}
	}
}
BREACH_ROLES.DZ = {
	dz = {
		name = "Serpent's Hand",
		color = Color(29, 81, 56),
		roles = {
			{["name"] = role.DZ_Grunt, 
			 ["team"] = TEAM_DZ,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_cstm_galil_ace", "item_adrenaline", "item_medkit_3","item_nightvision_blue"},
			 ["tasks"] = "l:tasks_sh",
			 ["bodygroup0"] = 1,
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_kk_ins2_cstm_galil_ace", 315}},
			 ["health"] = 145,
			 ["armor"] = 0,
			 --["bodyresist"] = 1,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 0.93,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/dz/dz.mdl",
			 ["showmodel"] = "models/cultist/humans/dz/dz.mdl",
			 ["level"] = 0,
			 ["max"] = 4,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 0.7,
			 	["HITGROUP_LEFTARM"] = 0.9,
			 	["HITGROUP_RIGHTARM"] = 0.9,
			 	["HITGROUP_STOMACH"] = 0.8,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.DZ_Psycho, 
			 ["team"] = TEAM_DZ,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_m590", "weapon_serpent_dagger", "cw_kk_ins2_nade_molotov", "item_adrenaline", "item_medkit_3", "item_syringe","item_nightvision_blue" },
			 ["tasks"] = "l:tasks_sh",
			 ["keycard"] = "support",
			 ["stamina"] = 1.1,
			 ["ammo"] = {{"cw_kk_ins2_m590", 60}},
			 ["bodygroup5"] = 1,
			 --["bodyresist"] = 1,
			 ["bodygroup3"] = 1,
			 ["health"] = 180,
			 ["armor"] = 0,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 0.93,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/dz/dz.mdl",
			 ["showmodel"] = "models/cultist/humans/dz/dz.mdl",
			 ["level"] = 44,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 0.7,
			 	["HITGROUP_LEFTARM"] = 0.9,
			 	["HITGROUP_RIGHTARM"] = 0.9,
			 	["HITGROUP_STOMACH"] = 0.8,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.DZ_Gas, 
			 ["team"] = TEAM_DZ,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_nade_anm14", "cw_kk_ins2_cstm_m500", "cw_scp_127", "item_adrenaline", "item_syringe", "item_pills", "item_medkit_3","item_nightvision_blue"},
			 ["tasks"] = "l:tasks_sh",
			 ["bodygroup0"] = 2,
			 --["bodyresist"] = 1,
			 ["bodygroup1"] = 2,
			 ["bodygroup2"] = 1,
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_kk_ins2_cstm_m500", 60}, {"cw_scp_127", 315}},
			 ["health"] = 160,
			 ["armor"] = 0,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 0.93,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/dz/dz.mdl",
			 ["showmodel"] = "models/cultist/humans/dz/dz.mdl",
			 ["level"] = 15,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 0.7,
			 	["HITGROUP_LEFTARM"] = 0.9,
			 	["HITGROUP_RIGHTARM"] = 0.9,
			 	["HITGROUP_STOMACH"] = 0.8,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    },
			{["name"] = role.DZ_Commander, 
			 ["team"] = TEAM_DZ,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_cstm_g36c", "item_adrenaline", "item_medkit_4","item_nightvision_blue"},
			 ["tasks"] = "l:tasks_sh"..",".." l:tasks_coordinate_sh",
			 ["ability"] = {"l:abilities_name_shcom", 90, "l:abilities_shcom", "nextoren/gui/special_abilities/special_dz_portal.png", false},
			 ["bodygroup0"] = 3,
			 --["bodyresist"] = 1,
			 ["bodygroup1"] = 3,
			 ["bodygroup2"] = 2,
			 ["bodygroup3"] = 1,
			 ["bodygroup4"] = 1,
			 ["bodygroup5"] = 1,
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_kk_ins2_cstm_g36c", 315}},
			 ["health"] = 150,
			 ["armor"] = 0,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 0.93,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/dz/dz.mdl",
			 ["premium_female"] = "models/cultist/humans/dz/dz_fat.mdl",
			 ["showmodel"] = "models/cultist/humans/dz/dz.mdl",
			 ["level"] = 13,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 0.7,
			 	["HITGROUP_LEFTARM"] = 0.9,
			 	["HITGROUP_RIGHTARM"] = 0.9,
			 	["HITGROUP_STOMACH"] = 0.8,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
		    }
		}
	}
}
BREACH_ROLES.FBI = {
	fbi = {
		name = "Federal Bureau of Investigation | Unusual Incidents Unit",
		color = Color(29, 81, 56),
		roles = {
			{["name"] = role.UIU_Soldier, 
			 ["team"] = TEAM_USA,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_m16a4", "item_nightvision_blue", "cw_kk_ins2_nade_m84"},
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/fbi/head_gear/helmet.mdl",
			 ["tasks"] = "l:tasks_uiu",
			 ["bodygroup2"] = 1,
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_kk_ins2_m16a4", 315}},
			 ["health"] = 135,
			 ["armor"] = 0,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 1.05,
			 --["headresist"] = 1,
			 --["bodyresist"] = 3,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/fbi/fbi.mdl",
			 ["showmodel"] = "models/cultist/humans/fbi/fbi.mdl",
			 ["level"] = 7,
			 ["max"] = 15,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.7,
			 	["HITGROUP_CHEST"] = 0.7,
			 	["HITGROUP_LEFTARM"] = 0.8,
			 	["HITGROUP_RIGHTARM"] = 0.8,
			 	["HITGROUP_STOMACH"] = 0.7,
			 	["HITGROUP_GEAR"] = 0.7,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
			{["name"] = role.UIU_Commander, 
			 ["team"] = TEAM_USA,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_m4a1", "item_nightvision_blue", "cw_kk_ins2_nade_m84"},
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/fbi/head_gear/cap_com.mdl",
			 ["tasks"] = "l:tasks_uiu"..",".." l:tasks_coordinate_uiu",
			 ["ability"] = {"l:abilities_name_uiucom", 45, "l:abilities_uiucom", "nextoren/gui/special_abilities/special_fbi_commander.png", false},
			 ["bodygroup2"] = 1,
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_kk_ins2_m4a1",315}},
			 ["health"] = 145,
			 ["armor"] = 0,
			 --["headresist"] = 1,
			 --["bodyresist"] = 3,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 1.05,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/fbi/fbi.mdl",
			 ["showmodel"] = "models/cultist/humans/fbi/fbi.mdl",
			 ["level"] = 23,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.7,
			 	["HITGROUP_CHEST"] = 0.6,
			 	["HITGROUP_LEFTARM"] = 0.8,
			 	["HITGROUP_RIGHTARM"] = 0.8,
			 	["HITGROUP_STOMACH"] = 0.6,
			 	["HITGROUP_GEAR"] = 0.6,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
			{["name"] = role.UIU_Specialist, 
			 ["team"] = TEAM_USA,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_ao5_br99", "item_nightvision_blue", "cw_kk_ins2_nade_m84"},
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["headgear"] = "models/cultist/humans/fbi/head_gear/helmet.mdl",
			 ["tasks"] = "l:tasks_uiu",
			 ["ability"] = {"l:abilities_name_uiuspec", 30, "l:abilities_uiuspec", "nextoren/gui/special_abilities/special_fbi_hacker.png", false},
			 ["bodygroup1"] = 3,
			 ["bodygroup2"] = 1,
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_kk_ins2_ao5_br99", 315}},
			 ["health"] = 140,
			 ["armor"] = 0,
			 --["headresist"] = 1,
			 --["bodyresist"] = 3,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 1.05,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/fbi/fbi.mdl",
			 ["showmodel"] = "models/cultist/humans/fbi/fbi.mdl",
			 ["level"] = 28,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.7,
			 	["HITGROUP_CHEST"] = 0.6,
			 	["HITGROUP_LEFTARM"] = 0.8,
			 	["HITGROUP_RIGHTARM"] = 0.8,
			 	["HITGROUP_STOMACH"] = 0.6,
			 	["HITGROUP_GEAR"] = 0.6,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
			{["name"] = role.UIU_Clocker, 
			 ["team"] = TEAM_USA,
			 ["weapons"] = {"br_holster", "item_radio", "cw_fbi_revolver", "weapon_fbi_knife", "cw_kk_ins2_nade_m84", "item_nightvision_blue"},
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_full.mdl",
			 ["tasks"] = "l:tasks_uiu",
			 ["ability"] = {"l:abilities_name_uiuclocker", 75, "l:abilities_uiuclocker", "nextoren/gui/special_abilities/special_fbi_clocker.png", false},
			 ["bodygroup0"] = 1,
			 ["bodygroup1"] = 2,
			 --["bodyresist"] = 2,
			 ["bodygroup2"] = 2,
			 ["white"] = true,
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_fbi_revolver", 48}},
			 ["health"] = 200,
			 ["stamina"] = 2,
			 ["armor"] = 0,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 1.2,
			 ["jumppower"] = 0.85,
			 ["female_head"] = {"models/cultist/heads/female/head_1.mdl"},
			 --["female_headgear"] = "models/cultist/humans/ntf/head_gear/ntf_sniper_head_female.mdl",
			 --["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["premium_female"] = "models/cultist/humans/fbi/fbi_woman.mdl",
			 ["model"] = "models/cultist/humans/fbi/fbi.mdl",
			 ["showmodel"] = "models/cultist/humans/fbi/fbi.mdl",
			 ["level"] = 45,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.7,
			 	["HITGROUP_CHEST"] = 0.6,
			 	["HITGROUP_LEFTARM"] = 0.8,
			 	["HITGROUP_RIGHTARM"] = 0.8,
			 	["HITGROUP_STOMACH"] = 0.6,
			 	["HITGROUP_GEAR"] = 0.6,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    }
		}
	}
}
BREACH_ROLES.COTSK = {
	cotsk = {
		name = "Children of the Scarlet King",
		color = Color(29, 81, 56),
		roles = {
			{["name"] = role.Cult_Grunt, 
			 ["team"] = TEAM_COTSK,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_karma45","item_nightvision_blue"},
			 ["keycard"] = "support",
			 ["tasks"] = "l:tasks_cotsk",
			 ["ammo"] = {{"cw_kk_ins2_karma45", 315}},
			 ["bodygroup1"] = 1,
			 ["health"] = 150,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/cultists/cultist.mdl",
			 ["showmodel"] = "models/cultist/humans/cultists/cultist.mdl",
			 ["level"] = 10,
			 ["max"] = 5,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.7,
			 	["HITGROUP_CHEST"] = 0.7,
			 	["HITGROUP_LEFTARM"] = 0.8,
			 	["HITGROUP_RIGHTARM"] = 0.8,
			 	["HITGROUP_STOMACH"] = 0.7,
			 	["HITGROUP_GEAR"] = 0.7,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
			{["name"] = role.Cult_Psycho, 
			 ["team"] = TEAM_COTSK,
			 ["weapons"] = {"br_holster", "item_radio", "cw_cultist_assrifle_volk", "cw_kk_ins2_nade_molotov", "item_syringe","item_nightvision_blue"},
			 ["tasks"] = "l:tasks_cotsk",
			 ["ability"] = {"l:abilities_name_cotskpsycho", 205, "l:abilities_cotskpsycho", "nextoren/gui/special_abilities/special_scarlet_last_chance.png", false},
			 ["keycard"] = "support",
			 ["bodygroup0"] = 1,
			 ["bodygroup1"] = 2,
			 ["ammo"] = {{"cw_cultist_assrifle_volk", 315}},
			 ["health"] = 190,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/cultists/cultist.mdl",
			 ["showmodel"] = "models/cultist/humans/cultists/cultist.mdl",
			 ["level"] = 16,
			 ["max"] = 2,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.7,
			 	["HITGROUP_CHEST"] = 0.7,
			 	["HITGROUP_LEFTARM"] = 0.8,
			 	["HITGROUP_RIGHTARM"] = 0.8,
			 	["HITGROUP_STOMACH"] = 0.7,
			 	["HITGROUP_GEAR"] = 0.7,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
			{["name"] = role.Cult_Commander, 
			 ["team"] = TEAM_COTSK,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_acr", "ritual_paper", "item_medkit_3","item_nightvision_blue"},
			 ["tasks"] = "l:tasks_cotsk"..",".." l:tasks_coordinate_cotsk",
			 --["ability"] = {"Energy Ball", 80, "Вы выпускаете во врага энергетический шар.", "nextoren/gui/special_abilities/special_scarlet_magic.png", false},
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_kk_ins2_acr", 315}},  ----aoc_spikedmaceshield_stab анимация !!!ВАЖНО
			 ["bodygroup0"] = 2,
			 ["bodygroup1"] = 3,
			 ["bodygroup2"] = 1,
			 ["health"] = 180,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1.05,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/cultists/cultist.mdl",
			 ["showmodel"] = "models/cultist/humans/cultists/cultist.mdl",
			 ["level"] = 10,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.7,
			 	["HITGROUP_CHEST"] = 0.7,
			 	["HITGROUP_LEFTARM"] = 0.8,
			 	["HITGROUP_RIGHTARM"] = 0.8,
			 	["HITGROUP_STOMACH"] = 0.7,
			 	["HITGROUP_GEAR"] = 0.7,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
			{["name"] = role.Cult_Specialist, 
			 ["team"] = TEAM_COTSK,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_dmr25", "ritual_paper", "item_medkit_3", "item_adrenaline","item_nightvision_blue"},
			 ["tasks"] = "l:tasks_cotsk",
			 ["ability"] = {"猎手视野", 50, "探测一定范围内的敌人", "nextoren/gui/special_abilities/special_scarlet_enemy_scan.png", false},
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_kk_ins2_dmr25", 315}},
			 ["bodygroup0"] = 3,
			 ["bodygroup1"] = 4,
			 ["bodygroup2"] = 2,
			 ["bodygroup3"] = 1,
			 ["health"] = 195,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 0.95,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/cultists/cultist.mdl",
			 ["showmodel"] = "models/cultist/humans/cultists/cultist.mdl",
			 ["level"] = 43,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 0.7,
			 	["HITGROUP_CHEST"] = 0.7,
			 	["HITGROUP_LEFTARM"] = 0.8,
			 	["HITGROUP_RIGHTARM"] = 0.8,
			 	["HITGROUP_STOMACH"] = 0.7,
			 	["HITGROUP_GEAR"] = 0.7,
			 	["HITGROUP_LEFTLEG"] = 0.8,
			 	["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    }
		}
	}
}
BREACH_ROLES.SCP = {
	scp = {
		name = "SCP",
		color = Color( 0, 0, 0 ),
		roles = {
            {name = "SCP-3114", team = TEAM_SCP, tasks = "左键抓击，R 掐人，右键窃皮；三分钟自动爆皮，掐人也会爆皮。", health = 3000, armor = 0,
             walkspeed = 1, runspeed = 1, jumppower = 1, model = "models/rxsend/scp3114/scp3114.mdl", showmodel = "models/rxsend/scp3114/scp3114.mdl", level = 0},

			{["name"] = "SCP-912", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 700,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_912.mdl",
			 ["showmodel"] = "models/cultist/scp/scp_912.mdl",
			 ["level"] = 0
		    },
			{["name"] = "SCP-106", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 2500,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_106.mdl",
			 ["showmodel"] = "models/cultist/scp/scp_106.mdl",
			 ["level"] = 0
		    },
			{["name"] = "SCP-049", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 3000,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_049.mdl",
			 ["showmodel"] = "models/cultist/scp/scp_049.mdl",
			 ["level"] = 0
		    },
		    --[[
			{["name"] = "SCP-1027-RU", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 3200,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_1027ru.mdl"},
			 ["showmodel"] = "models/cultist/scp/scp_1027ru.mdl",
			 ["level"] = 0
		    },
		    --]]
		    --
			{["name"] = "SCP-638", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 3000,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp638/scp_638.mdl",
			 ["showmodel"] = "models/cultist/scp/scp638/scp_638.mdl",
			 ["level"] = 0
		    },
		    --[[
			{["name"] = "SCP-1015-RU", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 1800,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/1015ru.mdl"},
			 ["showmodel"] = "models/cultist/scp/1015ru.mdl",
			 ["level"] = 0
		    },
			{["name"] = "SCP-035", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 1500,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_035.mdl"},
			 ["showmodel"] = "models/cultist/scp/scp_035.mdl",
			 ["level"] = 0
		    },--]]
		    {["name"] = "SCP-542", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 2300,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_542.mdl",
			 ["showmodel"] = "models/cultist/scp/scp_542.mdl",
			 ["level"] = 0
		    },
		    {["name"] = "SCP-999", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_scp999",
			 ["health"] = 1000,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_999_new.mdl",
			 ["showmodel"] = "models/cultist/scp/scp_999_new.mdl",
			 ["level"] = 0
		    },
		    {["name"] = "SCP-1903", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 3200,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_1903.mdl",
			 ["showmodel"] = "models/cultist/scp/scp_1903.mdl",
			 ["level"] = 0
		    },
		    {["name"] = "SCP-973", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 3200,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_973/scp_973.mdl",
			 ["showmodel"] = "models/cultist/scp/scp_973/scp_973.mdl",
			 ["level"] = 0
		    },
		    
		    {["name"] = "SCP-173", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 2000,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/173.mdl",
			 ["showmodel"] = "models/cultist/scp/173.mdl",
			 ["level"] = 0
		    },
		    
		    {["name"] = "SCP-2012", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 2000,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/shaky/scp/scp2012/scp_2012.mdl",
			 ["showmodel"] = "models/shaky/scp/scp2012/scp_2012.mdl",
			 ["level"] = 0
		    },
		    
		    {["name"] = "SCP-811", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 3600,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_811.mdl",
			 ["showmodel"] = "models/cultist/scp/scp_811.mdl",
			 ["level"] = 0
		    },
		    {["name"] = "SCP-076-2", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 1000,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_076.mdl",
			 ["showmodel"] = "models/cultist/scp/scp_076.mdl",
			 ["level"] = 0
		    },
		    {["name"] = "SCP-096", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 2550,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_096.mdl",
			 ["showmodel"] = "models/cultist/scp/scp_096.mdl",
			 ["level"] = 0
		    },
		    {["name"] = "SCP-062-DE", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 2200,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_062de.mdl",
			 ["showmodel"] = "models/cultist/scp/scp_062de.mdl",
			 ["level"] = 0
		    },
		    {["name"] = "SCP-062-FR", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 1500,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_062fr_new.mdl",
			 ["showmodel"] = "models/cultist/scp/scp_062fr_new.mdl",
			 ["level"] = 0
		    },
		    {["name"] = "SCP-457", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 3700,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_457.mdl",
			 ["showmodel"] = "models/cultist/scp/scp_457.mdl",
			 ["level"] = 0
		    },
		    --[[
		    {["name"] = "SCP-860", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 3000,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_860.mdl"},
			 ["showmodel"] = "models/cultist/scp/scp_860.mdl",
			 ["level"] = 0
		    },]]
		    --]]
		    {["name"] = "SCP-682", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 6000,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_682.mdl",
			 ["showmodel"] = "models/cultist/scp/scp_682.mdl",
			 ["level"] = 0
		    },
		    {["name"] = "SCP-082", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 2800,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_082.mdl",
			 ["showmodel"] = "models/cultist/scp/scp_082.mdl",
			 ["level"] = 0
		    },
		    {["name"] = "SCP-939", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 2500,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_939.mdl",
			 ["showmodel"] = "models/cultist/scp/scp_939.mdl",
			 ["level"] = 0
		    },
		    --[[{["name"] = "SCP-035", 
			 ["team"] = TEAM_SCP,
			 ["tasks"] = "l:tasks_kill_everyone_except_sh",
			 ["health"] = 750,
			 ["armor"] = 0,
			 ["walkspeed"] = 1,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/scp/scp_939.mdl",
			 ["showmodel"] = "models/cultist/scp/scp_939.mdl",
			 ["level"] = 0
		    },]]
		}
	}
}

--[[
BREACH_ROLES.MINIGAMES = {
	minigame = {
		name = "Armed Site Support",
		color = Color(29, 81, 56),
		roles = {
			{["name"] = role.Nazi, 
			 ["team"] = TEAM_NAZI,
			 ["weapons"] = {"br_holster", "cw_kk_ins2_nazi"},
			 ["tasks"] = "l:tasks_terminate_enemies",
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["headgear"] = "models/cultist/humans/specialmod/nazi/headgear/helmet.mdl",
			 ["ammo"] = {{"cw_kk_ins2_nazi", 2000}},
			 ["health"] = 100,
			 ["armor"] = 0,
			 ["white"] = true,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1.3,
			 ["model"] = "models/cultist/humans/specialmod/nazi/nazi.mdl",
			 ["showmodel"] = "models/cultist/humans/specialmod/nazi/nazi.mdl",
			 ["level"] = 0,
			 ["max"] = 32,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 100,
			 	["HITGROUP_CHEST"] = 100,
			 	["HITGROUP_LEFTARM"] = 100,
			 	["HITGROUP_RIGHTARM"] = 100,
			 	["HITGROUP_STOMACH"] = 100,
			 	["HITGROUP_GEAR"] = 100,
			 	["HITGROUP_LEFTLEG"] = 100,
			 	["HITGROUP_RIGHTLEG"] = 100
			 },
			},
			{["name"] = role.USA, 
			 ["team"] = TEAM_AMERICA,
			 ["weapons"] = {"br_holster", "cw_kk_ins2_usa"},
			 ["tasks"] = "l:tasks_terminate_enemies",
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["headgear"] = "models/cultist/humans/specialmod/american/headgear/helmet.mdl",
			 ["ammo"] = {{"cw_kk_ins2_usa", 2000}},
			 ["health"] = 100,
			 ["armor"] = 0,
			 ["white"] = true,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1.3,
			 ["model"] = "models/cultist/humans/specialmod/american/american.mdl",
			 ["showmodel"] = "models/cultist/humans/specialmod/american/american.mdl",
			 ["level"] = 0,
			 ["max"] = 32,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 100,
			 	["HITGROUP_CHEST"] = 100,
			 	["HITGROUP_LEFTARM"] = 100,
			 	["HITGROUP_RIGHTARM"] = 100,
			 	["HITGROUP_STOMACH"] = 100,
			 	["HITGROUP_GEAR"] = 100,
			 	["HITGROUP_LEFTLEG"] = 100,
			 	["HITGROUP_RIGHTLEG"] = 100
			 },
			},
			{["name"] = role.ArenaParticipant, 
			 ["team"] = TEAM_ARENA,
			 ["weapons"] = {"br_holster", "flamberge"},
			 ["tasks"] = "l:tasks_arena",
			 ["ammo"] = {},
			 --["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 --["headgear"] = "models/cultist/humans/specialmod/nazi/headgear/helmet.mdl",
			 ["health"] = 100,
			 ["armor"] = 0,
			 ["white"] = true,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1.3,
			 ["model"] = "models/shaky/scp/scp2012/scp_2012.mdl",
			 ["showmodel"] = "models/shaky/scp/scp2012/scp_2012.mdl",
			 ["level"] = 0,
			 ["max"] = 64,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
		}
	}
}]]

BREACH_ROLES.FBI_AGENTS = {
	fbi_agents = {
		name = "Federal Bureau of Investigation | Unusual Incidents Unit (Agents)",
		color = Color(29, 81, 56),
		roles = {
			{["name"] = role.UIU_Agent,
			 ["team"] = TEAM_USA,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_aug", "cw_jk_p226", "item_nightvision_green"},
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_half.mdl",
			 ["headgear"] = "models/cultist/humans/fbi/head_gear/fbi_agent_hat.mdl",
			 ["tasks"] = "l:tasks_uiu",
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_jk_p226", 200}, {"cw_kk_ins2_aug", 315}},
			 ["health"] = 135,
			 ["armor"] = 0,
			 --["bodyresist"] = 2,
			 ["walkspeed"] = 0.85,
			 ["random_accessories"] = {
				["bodygroup0"] = {0, 3},
				["bodygroup1"] = {0, 1},
				["headgears"] = {
					["bodygroup0"] = {0, 3},
				},
			 },
			 ["runspeed"] = 1,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/fbi/fbi_agent.mdl",
			 ["showmodel"] = "models/cultist/humans/fbi/fbi_agent.mdl",
			 ["level"] = 7,
			 ["max"] = 15,
			 ["damage_modifiers"] = {
				["HITGROUP_HEAD"] = 0.7,
				["HITGROUP_CHEST"] = 0.7,
				["HITGROUP_LEFTARM"] = 0.8,
				["HITGROUP_RIGHTARM"] = 0.8,
				["HITGROUP_STOMACH"] = 0.7,
				["HITGROUP_GEAR"] = 0.7,
				["HITGROUP_LEFTLEG"] = 0.8,
				["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
		    {["name"] = role.UIU_Agent_Sniper,
			 ["team"] = TEAM_USA,
			 ["weapons"] = {"br_holster", "item_radio","cw_kk_ins2_dmr25", "cw2_kk_ins2_p30", "item_nightvision_blue", "cw_kk_ins2_nade_m84"},
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_half.mdl",
			 ["headgear"] = "models/cultist/humans/ntf/head_gear/ntf_sniper_head.mdl",
			 ["tasks"] = "l:tasks_uiu",
			 ["keycard"] = "support",
			 --["ammo"] = {{"cw_kk_ins2_dmr25", 70}},
			 ["ammo"] = {{"cw2_kk_ins2_p30", 200}, {"cw_kk_ins2_dmr25", 70}},
			 ["health"] = 135,
			 ["armor"] = 0,
			 --["bodyresist"] = 2,
			 ["walkspeed"] = 0.85,
			 ["bodygroup1"] = 1,
			 ["bodygroup3"] = 1,
			 ["random_accessories"] = {
				["bodygroup0"] = {0, 3},
				["headgears"] = {
					["bodygroup0"] = {0, 3},
				},
			 },
			 ["runspeed"] = 1,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/fbi/fbi_agent.mdl",
			 ["showmodel"] = "models/cultist/humans/fbi/fbi_agent.mdl",
			 ["level"] = 9,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
				["HITGROUP_HEAD"] = 0.7,
				["HITGROUP_CHEST"] = 0.7,
				["HITGROUP_LEFTARM"] = 0.8,
				["HITGROUP_RIGHTARM"] = 0.8,
				["HITGROUP_STOMACH"] = 0.7,
				["HITGROUP_GEAR"] = 0.7,
				["HITGROUP_LEFTLEG"] = 0.8,
				["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
		    {["name"] = role.UIU_Agent_Commander,
			 ["team"] = TEAM_USA,
			 ["weapons"] = {"br_holster", "item_radio", "cw_jk_ins2_scar", "cw_jk_p226", "item_nightvision_blue", "cw_kk_ins2_nade_m84"},
			 ["head"] = "models/cultist/humans/balaclavas_new/balaclava_half.mdl",
			 ["headgear"] = "models/cultist/humans/fbi/head_gear/beret.mdl",
			 ["ability"] = {"l:abilities_name_uiucom", 45, "l:abilities_uiucom", "nextoren/gui/special_abilities/special_fbi_commander.png", false},
			 ["tasks"] = "l:tasks_uiu",
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_jk_p226", 200}, {"cw_jk_ins2_scar", 315}},
			 ["health"] = 135,
			 --["bodyresist"] = 2,
			 ["armor"] = 0,
			 ["walkspeed"] = 0.85,
			 ["random_accessories"] = {
				["bodygroup0"] = {0, 3},
			 },
			 ["runspeed"] = 1,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/fbi/fbi_agent.mdl",
			 ["showmodel"] = "models/cultist/humans/fbi/fbi_agent.mdl",
			 ["level"] = 13,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
				["HITGROUP_HEAD"] = 0.7,
				["HITGROUP_CHEST"] = 0.7,
				["HITGROUP_LEFTARM"] = 0.8,
				["HITGROUP_RIGHTARM"] = 0.8,
				["HITGROUP_STOMACH"] = 0.7,
				["HITGROUP_GEAR"] = 0.7,
				["HITGROUP_LEFTLEG"] = 0.8,
				["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
		    {["name"] = role.UIU_Agent_Specialist,
			 ["team"] = TEAM_USA,
			 ["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_arse_m1014", "cw_jk_p226", "item_nightvision_blue", "cw_kk_ins2_nade_m84"},
			 ["head"] = "models/cultist/humans/fbi/heads/agent_specialist_head.mdl",
			 ["ability"] = {"l:abilities_name_uiuagentspec", 90, "l:abilities_uiuagentspec", "nextoren/gui/special_abilities/uiu_special_agent.png", false},
			 ["tasks"] = "l:tasks_uiu",
			 ["keycard"] = "support",
			 ["ammo"] = {{"cw_jk_p226", 200}, {"cw_kk_ins2_arse_m1014", 315}},
			 ["health"] = 135,
			 ["armor"] = 0,
			 --["bodyresist"] = 2,
			 ["walkspeed"] = 0.85,
			 --["headresist"] = 1,
			 ["bodygroup3"] = 1,
			 ["random_accessories"] = {
				["bodygroup0"] = {0, 3},
			 },
			 ["runspeed"] = 1,
			 ["jumppower"] = 0.85,
			 ["model"] = "models/cultist/humans/fbi/fbi_agent.mdl",
			 ["showmodel"] = "models/cultist/humans/fbi/fbi_agent.mdl",
			 ["level"] = 29,
			 ["max"] = 1,
			 ["damage_modifiers"] = {
				["HITGROUP_HEAD"] = 0.7,
				["HITGROUP_CHEST"] = 0.7,
				["HITGROUP_LEFTARM"] = 0.8,
				["HITGROUP_RIGHTARM"] = 0.8,
				["HITGROUP_STOMACH"] = 0.7,
				["HITGROUP_GEAR"] = 0.7,
				["HITGROUP_LEFTLEG"] = 0.8,
				["HITGROUP_RIGHTLEG"] = 0.8
			 },
		    },
			{["name"] = role.UIU_Agent_Information,
			["team"] = TEAM_USA,
			["weapons"] = {"br_holster", "item_radio", "cw_kk_ins2_deagle", "item_nightvision_blue", "cw_kk_ins2_nade_m84"},
			["ability"] = {"l:abilities_name_uiuagentinfo", 60, "l:abilities_uiuagentinfo", "nextoren/gui/special_abilities/special_fbi_hacker.png", false},
			["ability_max"] = 2,
			["head"] = "models/shaky/heads/head_gp.mdl",
			["tasks"] = "l:tasks_uiu",
			["keycard"] = "support",
			["ammo"] = {{"cw_kk_ins2_deagle", 315}},
			["health"] = 135,
			--["bodyresist"] = 2,
			["armor"] = 0,
			["walkspeed"] = 0.85,
			["random_accessories"] = {
				["bodygroup0"] = {0, 3},
			},
			["bodygroup0"] = 1,
			["bodygroup1"] = 2,
			["bodygroup2"] = 2,
			["headgear"] = "models/cultist/humans/fbi/head_gear/beret.mdl",
			["runspeed"] = 1,
			["jumppower"] = 0.85,
			["model"] = "models/cultist/humans/fbi/fbi_agent.mdl",
			["showmodel"] = "models/cultist/humans/fbi/fbi_agent.mdl",
			["level"] = 54,
			["max"] = 1,
			["damage_modifiers"] = {
				["HITGROUP_HEAD"] = 0.7,
				["HITGROUP_CHEST"] = 0.7,
				["HITGROUP_LEFTARM"] = 0.8,
				["HITGROUP_RIGHTARM"] = 0.8,
				["HITGROUP_STOMACH"] = 0.7,
				["HITGROUP_GEAR"] = 0.7,
				["HITGROUP_LEFTLEG"] = 0.8,
				["HITGROUP_RIGHTLEG"] = 0.8
			},
			},
		}
	}
}

BREACH_ROLES.OTHER = {
	other = {
		name = "Other",
		color = Color(255, 255, 255),
		roles = {
			{["name"] = role.ClassD_Banned,
			 ["team"] = TEAM_CLASSD,
			 ["weapons"] = {"br_holster"},
			 --["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["tasks"] = "l:tasks_escape_from_site19",
			 ["keycard"] = "",
			 ["ammo"] = {},
			 ["health"] = 80,
			 ["armor"] = 0,
			 ["maxslots"] = 4,
			 ["walkspeed"] = 1,
			 ["hairm"] = HAIRS,
			 ["blackhairm"] = HAIRS_BLACK,
//			 ["headf"] = {"models/cultist/heads/female/shaky/head_1.mdl"},
			 ["hairf"] = HAIRS_WOMAN___BITCHES____,
			 ["fmodel"] = "models/cultist/humans/class_d/class_d_female.mdl",
			 ["runspeed"] = 1,
			 ["jumppower"] = 1,
			 ["model"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["showmodel"] = "models/cultist/humans/class_d/class_d.mdl",
			 ["level"] = 0,
			 ["customcheck"] = nil,
			 ["max"] = 0,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},

		}
	}
}

BREACH_ROLES.MINIGAMES = {
	minigame = {
		name = "Armed Site Support",
		color = Color(29, 81, 56),
		roles = {
			{["name"] = role.Nazi, 
			 ["team"] = TEAM_NAZI,
			 ["weapons"] = {"br_holster", "cw_kk_ins2_nazi","item_drink_water"},
			 ["tasks"] = "l:tasks_terminate_enemies",
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["headgear"] = "models/cultist/humans/specialmod/nazi/headgear/helmet.mdl",
			 ["ammo"] = {{"cw_kk_ins2_nazi", 2000}},
			 ["health"] = 100,
			 ["armor"] = 0,
			 ["white"] = true,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1.3,
			 ["model"] = "models/cultist/humans/specialmod/nazi/nazi.mdl",
			 ["showmodel"] = "models/cultist/humans/specialmod/nazi/nazi.mdl",
			 ["level"] = 0,
			 ["max"] = 32,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 100,
			 	["HITGROUP_CHEST"] = 100,
			 	["HITGROUP_LEFTARM"] = 100,
			 	["HITGROUP_RIGHTARM"] = 100,
			 	["HITGROUP_STOMACH"] = 100,
			 	["HITGROUP_GEAR"] = 100,
			 	["HITGROUP_LEFTLEG"] = 100,
			 	["HITGROUP_RIGHTLEG"] = 100
			 },
			},
			{["name"] = role.USA, 
			 ["team"] = TEAM_AMERICA,
			 ["weapons"] = {"br_holster", "cw_kk_ins2_usa","item_hamburger"},
			 ["tasks"] = "l:tasks_terminate_enemies",
			 ["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 ["headgear"] = "models/cultist/humans/specialmod/american/headgear/helmet.mdl",
			 ["ammo"] = {{"cw_kk_ins2_usa", 2000}},
			 ["health"] = 100,
			 ["armor"] = 0,
			 ["white"] = true,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1.3,
			 ["model"] = "models/cultist/humans/specialmod/american/american.mdl",
			 ["showmodel"] = "models/cultist/humans/specialmod/american/american.mdl",
			 ["level"] = 0,
			 ["max"] = 32,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 100,
			 	["HITGROUP_CHEST"] = 100,
			 	["HITGROUP_LEFTARM"] = 100,
			 	["HITGROUP_RIGHTARM"] = 100,
			 	["HITGROUP_STOMACH"] = 100,
			 	["HITGROUP_GEAR"] = 100,
			 	["HITGROUP_LEFTLEG"] = 100,
			 	["HITGROUP_RIGHTLEG"] = 100
			 },
			},
			{["name"] = role.ArenaParticipant, 
			 ["team"] = TEAM_ARENA,
			 ["weapons"] = {"br_holster", "weapon_scp_2012","item_nightvision_white"},
			 ["tasks"] = "l:tasks_arena",
			 --["ammo"] = {{"cw_kk_ins2_ak12", 2000}},
			 --["usehead"] = true, ["randomizehead"] = true, ["randomizeface"] = true,
			 --["headgear"] = "models/cultist/humans/specialmod/nazi/headgear/helmet.mdl",
			 ["health"] = 100,
			 ["armor"] = 0,
			 ["white"] = true,
			 ["walkspeed"] = 0.86,
			 ["runspeed"] = 1,
			 ["jumppower"] = 1.3,
			 ["model"] = "models/cultist/scp/scp2012/scp_2012.mdl",
			 ["showmodel"] = "models/cultist/scp/scp2012/scp_2012.mdl",
			 ["level"] = 0,
			 ["max"] = 64,
			 ["damage_modifiers"] = {
			 	["HITGROUP_HEAD"] = 1,
			 	["HITGROUP_CHEST"] = 1,
			 	["HITGROUP_LEFTARM"] = 1,
			 	["HITGROUP_RIGHTARM"] = 1,
			 	["HITGROUP_STOMACH"] = 1,
			 	["HITGROUP_GEAR"] = 1,
			 	["HITGROUP_LEFTLEG"] = 1,
			 	["HITGROUP_RIGHTLEG"] = 1
			 },
			},
		}
	}
}

--[[
local tab = {}

local num = {}

for i = 0, 45 do
    tab[i] = false
    num[i] = 0
end

for i, v in pairs(BREACH_ROLES) do
    print(i, v)
    for _, role in pairs(v[string.lower(i)].roles) do
    	if role.level > 45 then continue end
        tab[role.level] = true
        num[role.level] = num[role.level] + 1
    end
end

for i, v in pairs(tab) do
    if v == false then print(i) end
end

print("----------------------------")

for i, v in pairs(num) do
	if v > 1 then print(i, v) end
end]]
if BREACH.Nu7 then BREACH.Nu7.RegisterRoles() end
if BREACH.HeavyArmor then BREACH.HeavyArmor.Apply() end

-- Rebuilding the base table must restore module-owned appearance rosters too.
if BREACH.Alpha9 then BREACH.Alpha9.Register() end
if BREACH.Iris then BREACH.Iris.Register() end
if BREACH.GOCTheory then BREACH.GOCTheory.Register() end
