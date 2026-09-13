local _, EL = ...

local SIGNAL_WINDOW = 1.5
local CONTEXT_GRACE = 0.5

local function IsRecent(record, now, window)
    return record and (now - record.at) <= (window or SIGNAL_WINDOW)
end

function EL:InitializeMoneyTracking()
    -- ADDON_LOADED can run before the character's money has been populated.
    -- Do not treat that early value as an authoritative starting balance.
    self.lastKnownMoney = nil
    self.moneyTrackingReady = false
    self.pendingMoneyGain = nil
    self.pendingLootMoneySignal = nil
    self.lastContextMoneyGain = nil
    self.lastChatMoneyGain = nil
    self.lastQuestMoneyGain = nil
    self.activeMoneyActivities = {}
    self.moneyMerchantOpen = false
    self.moneyMailOpen = false
    self.moneyLootOpen = false
    self.moneyContextGrace = nil
end

function EL:SynchronizeMoneyBaseline()
    local currentMoney = GetMoney()
    self.lastKnownMoney = currentMoney
    -- A zero balance during login may be a transient, not the character's
    -- real balance. In that case the first money event becomes baseline-only.
    self.moneyTrackingReady = (tonumber(currentMoney) or 0) > 0
    self.pendingMoneyGain = nil
    self.pendingLootMoneySignal = nil
end

function EL:SetMoneyContext(context, isOpen)
    local now = GetTime()
    self.activeMoneyActivities = self.activeMoneyActivities or {}
    if context == "MERCHANT" then
        self.moneyMerchantOpen = isOpen
    elseif context == "MAIL" then
        self.moneyMailOpen = isOpen
    elseif context == "LOOT" then
        self.moneyLootOpen = isOpen
    end
    if isOpen then
        -- Every SHOW event starts a fresh activity. This also protects against
        -- a missed CLOSE event leaving a previous visit open indefinitely.
        self.activeMoneyActivities[context] = { source = context }
        self.moneyContextGrace = nil
        -- Keep an established rolling baseline. Replacing it here with a
        -- transient zero would make the next sale look like the full balance.
        if not self.moneyTrackingReady then
            local currentMoney = GetMoney()
            self.lastKnownMoney = currentMoney
            self.moneyTrackingReady = (tonumber(currentMoney) or 0) > 0
        end
        self.pendingMoneyGain = nil
        self.pendingLootMoneySignal = nil
        self.lastContextMoneyGain = nil
    else
        local activity = self.activeMoneyActivities[context]
        self.activeMoneyActivities[context] = nil
        if activity then
            self.moneyContextGrace = {
                source = context,
                activity = activity,
                expiresAt = now + CONTEXT_GRACE,
            }
        end
    end
end

function EL:GetMoneyContext()
    local activities = self.activeMoneyActivities or {}
    if self.moneyMailOpen and activities.MAIL then return "MAIL", activities.MAIL end
    if self.moneyMerchantOpen and activities.MERCHANT then return "MERCHANT", activities.MERCHANT end
    if self.moneyLootOpen and activities.LOOT then return "LOOT", activities.LOOT end
    local grace = self.moneyContextGrace
    if grace and GetTime() <= grace.expiresAt then return grace.source, grace.activity end
    self.moneyContextGrace = nil
    return nil
end

function EL:HandlePlayerMoneyChanged()
    local currentMoney = GetMoney()
    if not self.moneyTrackingReady then
        -- PLAYER_MONEY may be the event that supplies the initial balance.
        -- Store it as the baseline without reporting it as income.
        self.lastKnownMoney = currentMoney
        self.moneyTrackingReady = (tonumber(currentMoney) or 0) > 0
        self.pendingMoneyGain = nil
        self.pendingLootMoneySignal = nil
        return
    end
    local previousMoney = tonumber(self.lastKnownMoney)
    if previousMoney == nil or previousMoney <= 0 then
        self.lastKnownMoney = currentMoney
        self.moneyTrackingReady = (tonumber(currentMoney) or 0) > 0
        self.pendingMoneyGain = nil
        self.pendingLootMoneySignal = nil
        return
    end
    -- A temporary zero snapshot must not replace a known positive baseline;
    -- otherwise its restoration would be reported as newly gained money.
    if (tonumber(currentMoney) or 0) <= 0 then
        self.pendingMoneyGain = nil
        self.pendingLootMoneySignal = nil
        return
    end
    self.lastKnownMoney = currentMoney
    local amount = currentMoney - previousMoney
    if amount <= 0 then return end

    local now = GetTime()
    if IsRecent(self.lastQuestMoneyGain, now) and self.lastQuestMoneyGain.amount == amount then
        self.lastQuestMoneyGain = nil
        return
    end

    local lootSignal = self.pendingLootMoneySignal
    if lootSignal and (now - lootSignal.at) <= SIGNAL_WINDOW then
        self.pendingLootMoneySignal = nil
        self.pendingMoneyGain = nil
        self:RecordChatMoney(amount, lootSignal.activity)
        return
    end

    local context, activity = self:GetMoneyContext()
    if context then
        activity.entry = self:AddMoney(amount, context, activity.entry)
        self.lastContextMoneyGain = { amount = amount, at = now }
        return
    end

    -- PLAYER_MONEY may arrive before CHAT_MSG_MONEY. Keep an unclassified
    -- positive delta briefly; it is only admitted when the loot event follows.
    self.pendingMoneyGain = { amount = amount, at = now }
end

function EL:RecordChatMoney(amount, activity)
    local now = GetTime()
    local context, currentActivity = self:GetMoneyContext()
    activity = activity or currentActivity or { source = context or "LOOT" }
    local source = activity.source or context or "LOOT"
    activity.entry = self:AddMoney(amount, source, activity.entry)
    self.lastChatMoneyGain = { amount = amount, at = now }
    if source ~= "LOOT" then self.lastContextMoneyGain = { amount = amount, at = now } end
end

function EL:HandleLootMoneyMessage()
    local now = GetTime()
    if not self.moneyTrackingReady then
        -- Ignore money chat during startup until PLAYER_LOGIN has established
        -- a trustworthy balance. This prevents recording the full balance.
        self.lastKnownMoney = GetMoney()
        self.moneyTrackingReady = (tonumber(self.lastKnownMoney) or 0) > 0
        self.pendingMoneyGain = nil
        self.pendingLootMoneySignal = nil
        return
    end
    local _, activity = self:GetMoneyContext()
    local pending = self.pendingMoneyGain
    if IsRecent(pending, now) then
        self.pendingMoneyGain = nil
        self.pendingLootMoneySignal = nil
        self:RecordChatMoney(pending.amount, pending.activity or activity)
        return
    end
    self.pendingMoneyGain = nil

    local currentMoney = GetMoney()
    local previousMoney = tonumber(self.lastKnownMoney)
    if not previousMoney or previousMoney <= 0 then
        self.lastKnownMoney = currentMoney
        self.moneyTrackingReady = (tonumber(currentMoney) or 0) > 0
        return
    end
    local amount = currentMoney - previousMoney
    if amount > 0 then
        self.lastKnownMoney = currentMoney
        self:RecordChatMoney(amount, activity)
        return
    end

    -- Mail collection can emit a money chat line as well. If its PLAYER_MONEY
    -- event was already recorded, this is the same transaction, not fresh loot.
    if IsRecent(self.lastContextMoneyGain, now) or IsRecent(self.lastQuestMoneyGain, now) then return end

    local signal = { at = now, activity = activity }
    self.pendingLootMoneySignal = signal
    C_Timer.After(0.2, function()
        if EL.pendingLootMoneySignal ~= signal then return end
        EL.pendingLootMoneySignal = nil
        local delayedMoney = GetMoney()
        local previousMoney = tonumber(EL.lastKnownMoney)
        if not previousMoney or previousMoney <= 0 then
            EL.lastKnownMoney = delayedMoney
            EL.moneyTrackingReady = (tonumber(delayedMoney) or 0) > 0
            return
        end
        local delayedAmount = delayedMoney - previousMoney
        if delayedMoney > 0 then EL.lastKnownMoney = delayedMoney end
        if delayedAmount > 0 then EL:RecordChatMoney(delayedAmount, signal.activity) end
    end)
end

function EL:HandleQuestMoneyReward(moneyReward)
    local amount = math.floor(tonumber(moneyReward) or 0)
    if amount <= 0 then return end

    local now = GetTime()
    local pending = self.pendingMoneyGain
    if IsRecent(pending, now) and pending.amount == amount then self.pendingMoneyGain = nil end
    self.pendingLootMoneySignal = nil
    self.lastQuestMoneyGain = { amount = amount, at = now }
    self.lastKnownMoney = GetMoney()
    if IsRecent(self.lastChatMoneyGain, now) and self.lastChatMoneyGain.amount == amount then
        self.lastChatMoneyGain = nil
        return
    end
    self:AddMoney(amount, "QUEST")
end
