-- The gamemode dictionary is enforced by LoadLang/cvar_br_language.
-- GMod blocks changing its own language from server-provided Lua. The local
-- client launcher selects zh-CN; remote players choose it in GMod settings.
local function applyChinese()
    RunConsoleCommand("cvar_br_language", "chinese")
    if GetConVar("breach_config_language") then RunConsoleCommand("breach_config_language", "chinese") end
    if ALLLANGUAGES.chinese then LoadLang("chinese") end
end
hook.Add("InitPostEntity", "RXChineseLanguage", applyChinese)

-- Read-only diagnostics for local acceptance; exposes no remote execution path.
concommand.Add("rx_language_status", function()
    local lang = GetConVar("cvar_br_language")
    local menu = GetConVar("breach_config_language")
    print("[RX CHINESE STATUS] " .. util.TableToJSON({language = langtouse,
        configured = lang and lang:GetString(), menu = menu and menu:GetString(),
        dictionary = clang and clang.LangName, missing = BREACH.Localization.missing,
        roles = table.Count(clang and clang.role or {})}))
end)
