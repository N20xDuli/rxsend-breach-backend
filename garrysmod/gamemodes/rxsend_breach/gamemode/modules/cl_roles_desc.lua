BREACH = BREACH || {}
BREACH.Descriptions = BREACH.Descriptions || {}
BREACH.Descriptions.russian = BREACH.Descriptions.russian || {}
BREACH.Descriptions.english = BREACH.Descriptions.english || {}

function BREACH.GetDescription(rolename)
    if rolename == "SCP-3114" then rolename = role.SCP3114 or "SCP3114" end
    if BREACH.Nu7 and BREACH.Nu7.FindMember(rolename) then return BREACH.Nu7.MissionText end
    if BREACH:IsUiuAgent(rolename) then
        return "黑入召唤陆军组的支援电脑\n黑入设施内其他电脑\n刺杀设施主管获取密令\n窃取设施资料，封锁设施"
    end

	local mylang = "chinese"
	local langtable = BREACH.Descriptions.chinese or {}

	if !langtable[rolename] and rolename:find("SCP") then
		if mylang == "russian" or mylang == "ukraine" then
			return "你是 SCP 异常实体。\n\n与其他 SCP 合作，消灭蛇之手以外的人类，并逃离设施！"
		else
			return "你是 SCP 异常实体。\n\n与其他 SCP 合作，消灭蛇之手以外的人类，并逃离设施！"
		end
	elseif !langtable[rolename] then
		if mylang == "russian" or mylang == "ukraine" then
			return "你的角色："..GetLangRole(rolename).."\n\n请完成当前角色的任务。"
		else
			return "你的角色："..GetLangRole(rolename).."\n\n请完成当前角色的任务。"
		end
	else
		return langtable[rolename]
	end

end