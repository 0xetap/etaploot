local ADDON_NAME, EL = ...

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("CHAT_MSG_LOOT")
events:RegisterEvent("CHAT_MSG_CURRENCY")
events:RegisterEvent("CHAT_MSG_MONEY")
events:RegisterEvent("CHAT_MSG_SYSTEM")
events:RegisterEvent("CHAT_MSG_TRADESKILLS")
events:RegisterEvent("CHAT_MSG_SKILL")
events:RegisterEvent("CHAT_MSG_COMBAT_MISC_INFO")
events:RegisterEvent("CHAT_MSG_OPENING")
events:RegisterEvent("UI_INFO_MESSAGE")
events:RegisterEvent("UI_ERROR_MESSAGE")
events:RegisterEvent("TRADE_SKILL_ITEM_CRAFTED_RESULT")
events:RegisterEvent("PLAYER_MONEY")
events:RegisterEvent("QUEST_TURNED_IN")
events:RegisterEvent("MERCHANT_SHOW")
events:RegisterEvent("MERCHANT_CLOSED")
events:RegisterEvent("MAIL_SHOW")
events:RegisterEvent("MAIL_CLOSED")
events:RegisterEvent("LOOT_OPENED")
events:RegisterEvent("LOOT_CLOSED")

local function FilterProfessionMessage(_, _, message)
    if not EL.db or not EL.db.enabled then return false end
    local professionDetected, skillDetected = EL:ProcessProfessionMessage(message)
    if professionDetected then
        return EL.db.showProfessionProcs == true
    end
    if skillDetected then
        return EL.db.showProfessionSkillIncrease == true
    end
    return false
end

local function InstallChatFrameInterceptors()
    for index = 1, (NUM_CHAT_WINDOWS or 10) do
        local chatFrame = _G["ChatFrame" .. index]
        if chatFrame and chatFrame.AddMessage and not chatFrame.EtapLootOriginalAddMessage then
            chatFrame.EtapLootOriginalAddMessage = chatFrame.AddMessage
            chatFrame.AddMessage = function(self, message, ...)
                if FilterProfessionMessage(nil, nil, message) then return end
                return self.EtapLootOriginalAddMessage(self, message, ...)
            end
        end
    end
end

events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        InstallChatFrameInterceptors()
        -- ADDON_LOADED normally initializes everything. Retry at login when an
        -- unusual load order prevented the window from being completed.
        if not EL.frame then
            events:GetScript("OnEvent")(events, "ADDON_LOADED", ADDON_NAME)
        else
            EL.frame:SetShown(EL.db.windowShown ~= false)
            EL:Refresh()
        end
        -- Money can report as zero during ADDON_LOADED. Try the baseline again
        -- at login; Money.lua still treats zero as unconfirmed.
        if EL.db then EL:SynchronizeMoneyBaseline() end
        return
    elseif event == "ADDON_LOADED" then
        local loadedName = ...
        if loadedName ~= ADDON_NAME then return end
        EL:InitializeDatabase()
        EL:InitializeMoneyTracking()
        EL:UpdateClassTheme()
        EL:BuildLootPatterns()
        ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", FilterProfessionMessage)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_TRADESKILLS", FilterProfessionMessage)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_SKILL", FilterProfessionMessage)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", FilterProfessionMessage)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_COMBAT_MISC_INFO", FilterProfessionMessage)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_OPENING", FilterProfessionMessage)
        InstallChatFrameInterceptors()
        EL:CreateWindow()
        EL:CreateMinimapButton()
        EL:Refresh()
    elseif event == "TRADE_SKILL_ITEM_CRAFTED_RESULT" and EL.db and EL.db.enabled then
        EL:HandleCraftingResult(...)
    elseif event == "PLAYER_MONEY" then
        if EL.db and EL.db.enabled then
            EL:HandlePlayerMoneyChanged()
        else
            EL.lastKnownMoney = GetMoney()
            EL.moneyTrackingReady = (tonumber(EL.lastKnownMoney) or 0) > 0
        end
    elseif event == "CHAT_MSG_MONEY" and EL.db and EL.db.enabled then
        EL:HandleLootMoneyMessage()
    elseif event == "QUEST_TURNED_IN" and EL.db and EL.db.enabled then
        local _, _, moneyReward = ...
        EL:HandleQuestMoneyReward(moneyReward)
    elseif event == "MERCHANT_SHOW" then
        EL:SetMoneyContext("MERCHANT", true)
    elseif event == "MERCHANT_CLOSED" then
        EL:SetMoneyContext("MERCHANT", false)
    elseif event == "MAIL_SHOW" then
        EL:SetMoneyContext("MAIL", true)
    elseif event == "MAIL_CLOSED" then
        EL:SetMoneyContext("MAIL", false)
    elseif event == "LOOT_OPENED" then
        EL:SetMoneyContext("LOOT", true)
    elseif event == "LOOT_CLOSED" then
        EL:SetMoneyContext("LOOT", false)
    elseif (event == "CHAT_MSG_SYSTEM"
        or event == "CHAT_MSG_TRADESKILLS"
        or event == "CHAT_MSG_SKILL"
        or event == "CHAT_MSG_COMBAT_MISC_INFO"
        or event == "CHAT_MSG_OPENING")
        and EL.db and EL.db.enabled then
        EL:ProcessProfessionMessage(...)
    elseif (event == "UI_INFO_MESSAGE" or event == "UI_ERROR_MESSAGE") and EL.db and EL.db.enabled then
        local _, message = ...
        EL:ProcessProfessionMessage(message)
    elseif event == "CHAT_MSG_CURRENCY" and EL.db and EL.db.enabled then
        local message = ...
        local currencyLink = EL:GetCurrencyLinkFromMessage(message)
        if currencyLink then EL:AddCurrency(currencyLink, EL:GetQuantity(message, currencyLink)) end
    elseif event == "CHAT_MSG_LOOT" and EL.db and EL.db.enabled then
        local message = ...
        local currencyLink = EL:GetCurrencyLinkFromMessage(message)
        if currencyLink then
            EL:AddCurrency(currencyLink, EL:GetQuantity(message, currencyLink))
            return
        end
        if EL:DetectProfessionBonusMessage(message) then return end
        -- Do not depend on the surrounding color syntax. Retail may use
        -- either legacy hex colors or newer named-color markup.
        local itemLink = message:match("(|Hitem:[^|]+|h%[.-%]|h)")
        if itemLink then
            local isBonusRoll = EL:IsBonusRollMessage(message)
            local isOwnLoot = EL:IsOwnLootMessage(message)
            if not isOwnLoot then
                -- CHAT_MSG_LOOT also carries raid roll/pass/need traffic. Only
                -- recipient-loot templates belong in Group history.
                if not EL:IsGroupLootMessage(message) then return end
                local sourceGUID = select(12, ...)
                local sourceName = select(2, ...)
                local recipient, recipientClass = EL:GetGroupMemberName(sourceGUID, sourceName, message)
                if recipient then
                    EL:AddItem(itemLink, EL:GetQuantity(message, itemLink), isBonusRoll and "BONUS_ROLL" or nil, "LOOT", nil, recipient, recipientClass)
                end
                -- Never reinterpret an unresolved group/raid message as the
                -- player's own loot.
                return
            end
            local bonusSource = isBonusRoll and "BONUS_ROLL" or nil
            local pending = EL.pendingProfessionBonus
            if not bonusSource and pending and GetTime() <= pending.expiresAt then bonusSource = pending.source end
            EL.pendingProfessionBonus = nil
            local itemSource = EL:IsCraftedItemMessage(message) and "CRAFT" or "LOOT"
            if itemSource == "CRAFT" then
                bonusSource = EL:ConsumeCraftingResult(itemLink) or bonusSource
            end
            if EL.professionDebug then print(("EtapLoot debug: next loot tagged %s"):format(bonusSource or "NONE")) end
            local skillUps
            if EL.pendingSkillUp and GetTime() <= EL.pendingSkillUp.expiresAt then
                skillUps = EL.pendingSkillUp.points or 1
                EL.pendingSkillUp = nil
            end
            EL:AddItem(itemLink, EL:GetQuantity(message, itemLink), bonusSource, itemSource, skillUps)
        end
    end
end)
