local _, EL = ...

SLASH_ETAPLOOT1 = "/etaploot"
SLASH_ETAPLOOT2 = "/el"
SlashCmdList.ETAPLOOT = function(message)
    message = strtrim(message or ""):lower()
    if message == "clear" then
        EL:ClearHistory()
    elseif message == "debug" then
        EL.professionDebug = not EL.professionDebug
        print("EtapLoot profession debug: " .. (EL.professionDebug and "ON" or "OFF"))
    elseif message == "config" or message == "options" then
        EL:OpenConfig()
    elseif EL.frame then
        EL:SetLootWindowShown(not EL.frame:IsShown())
    end
end
