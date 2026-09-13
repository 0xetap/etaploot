local ADDON_NAME, EL = ...

local speedLoot = {
    hiddenParent = CreateFrame("Frame", nil, UIParent),
    ticker = nil,
    isLooting = false,
    lootFailed = false,
}
speedLoot.hiddenParent:Hide()

local function CancelTicker()
    if speedLoot.ticker then
        speedLoot.ticker:Cancel()
        speedLoot.ticker = nil
    end
end

local function ShowBlizzardLootFrame()
    speedLoot.lootFailed = true
    if not LootFrame then return end
    LootFrame:SetParent(UIParent)
    LootFrame:SetFrameStrata("HIGH")
    LootFrame:Show()
end

local function HideBlizzardLootFrame()
    if LootFrame and EL.db and EL.db.speedLoot then
        LootFrame:Hide()
        LootFrame:SetParent(speedLoot.hiddenParent)
    end
end

local function LootOneSlot(slot)
    local slotType = GetLootSlotType(slot)
    if slotType == Enum.LootSlotType.None then return true end

    local _, _, _, _, _, locked = GetLootSlotInfo(slot)
    if locked then return false end

    LootSlot(slot)
    return true
end

local function StartLooting(numSlots)
    CancelTicker()
    speedLoot.isLooting = true
    speedLoot.lootFailed = false
    local slot = numSlots

    speedLoot.ticker = C_Timer.NewTicker(0.033, function()
        if slot >= 1 then
            if not LootOneSlot(slot) then
                ShowBlizzardLootFrame()
                CancelTicker()
                return
            end
            slot = slot - 1
        else
            CancelTicker()
        end
    end, numSlots + 1)
end

function EL:UpdateSpeedLoot()
    if not LootFrame or not self.db then return end
    if self.db.speedLoot and not speedLoot.lootFailed then
        HideBlizzardLootFrame()
    else
        LootFrame:SetParent(UIParent)
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("LOOT_READY")
events:RegisterEvent("LOOT_OPENED")
events:RegisterEvent("LOOT_CLOSED")
events:RegisterEvent("UI_ERROR_MESSAGE")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName ~= ADDON_NAME then return end
        EL:UpdateSpeedLoot()

        if LootFrame then
            LootFrame:HookScript("OnShow", function(frame)
                if EL.db and EL.db.speedLoot and not speedLoot.lootFailed then
                    frame:Hide()
                    frame:SetParent(speedLoot.hiddenParent)
                end
            end)
        end

        if LootFrame and LootFrame.UpdateShownState then
            hooksecurefunc(LootFrame, "UpdateShownState", function(frame)
                if EL.db and EL.db.speedLoot and not speedLoot.lootFailed and not frame.isInEditMode then
                    frame:SetParent(speedLoot.hiddenParent)
                end
            end)
        end
    elseif (event == "LOOT_READY" or event == "LOOT_OPENED") and EL.db and EL.db.speedLoot then
        local numSlots = GetNumLootItems()
        if numSlots > 0 and not speedLoot.isLooting then
            HideBlizzardLootFrame()
            C_Timer.After(0, function()
                if EL.db and EL.db.speedLoot and not speedLoot.lootFailed then HideBlizzardLootFrame() end
            end)
            StartLooting(numSlots)
        end
    elseif event == "LOOT_CLOSED" then
        CancelTicker()
        speedLoot.isLooting = false
        speedLoot.lootFailed = false
        EL:UpdateSpeedLoot()
    elseif event == "UI_ERROR_MESSAGE" and speedLoot.isLooting and EL.db and EL.db.speedLoot then
        local _, message = ...
        if message == ERR_INV_FULL or message == ERR_ITEM_MAX_COUNT or message == ERR_LOOT_ROLL_PENDING then
            ShowBlizzardLootFrame()
        end
    end
end)
