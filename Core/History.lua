local _, EL = ...

local function RefreshHistory(self, history, tabKey)
    while #history > 200 do table.remove(history) end
    if (self.db.activeTab or "PERSONAL") == tabKey then
        self.scrollOffset = 0
        self.tabScrollOffsets = self.tabScrollOffsets or {}
        self.tabScrollOffsets[tabKey] = 0
    end
    self:RefreshWindow()
end

function EL:AddItem(itemLink, quantity, bonusSource, itemSource, skillUps, recipient, recipientClass)
    local itemID = C_Item.GetItemInfoInstant(itemLink)
    if not itemID then return end

    local function Store()
        if (itemSource or "LOOT") == "CRAFT" and not bonusSource and self.ConsumeCraftingResult then
            bonusSource = self:ConsumeCraftingResult(itemLink)
        end
        local name, resolvedLink, quality, _, _, _, _, _, _, icon, sellPrice = C_Item.GetItemInfo(itemLink)
        if not name or not self:PassesFilters(itemID, quality or 0) then return end
        local lootedAt = time()
        local consolidated
        local history = recipient and self.db.groupHistory or self.db.history
        local wasConsolidated = false
        local previousLootedAt, previousTime

        if self.db.consolidateLoot then
            local timeframe = self.db.consolidationUseSeconds
                and (self.db.consolidationSeconds or 30)
                or ((self.db.consolidationMinutes or 5) * 60)
            local cutoff = lootedAt - timeframe
            for index, existing in ipairs(history) do
                if existing.id == itemID
                    and existing.quality == (quality or 0)
                    and existing.bonusSource == bonusSource
                    and (existing.source or "LOOT") == (itemSource or "LOOT")
                    and (existing.skillUps or (existing.skillUp and 1)) == skillUps
                    and existing.recipient == recipient
                    and (existing.lootedAt or 0) >= cutoff then
                    previousLootedAt, previousTime = existing.lootedAt, existing.time
                    existing.quantity = (existing.quantity or 1) + (quantity or 1)
                    existing.link = resolvedLink or itemLink
                    existing.name = name
                    existing.icon = icon
                    existing.sellPrice = sellPrice or 0
                    existing.recipientClass = recipientClass or existing.recipientClass
                    existing.time = date("%H:%M", lootedAt)
                    existing.lootedAt = lootedAt
                    consolidated = table.remove(history, index)
                    wasConsolidated = true
                    table.insert(history, 1, consolidated)
                    break
                end
            end
        end

        if not consolidated then table.insert(history, 1, {
            id = itemID,
            link = resolvedLink or itemLink,
            name = name,
            quality = quality or 0,
            icon = icon,
            quantity = quantity or 1,
            bonusSource = bonusSource,
            source = itemSource or "LOOT",
            skillUps = skillUps,
            sellPrice = sellPrice or 0,
            recipient = recipient,
            recipientClass = recipientClass,
            time = date("%H:%M", lootedAt),
            lootedAt = lootedAt,
        }) end
        if not recipient then
            self.lastSkillTransaction = {
                entry = consolidated or history[1],
                quantity = quantity or 1,
                wasConsolidated = wasConsolidated,
                previousLootedAt = previousLootedAt,
                previousTime = previousTime,
                lootedAt = lootedAt,
                time = date("%H:%M", lootedAt),
                at = GetTime(),
            }
        end
        RefreshHistory(self, history, recipient and "GROUP" or "PERSONAL")
    end

    if C_Item.GetItemInfo(itemLink) then
        Store()
    else
        Item:CreateFromItemID(itemID):ContinueOnItemLoad(Store)
    end
end

function EL:AddCurrency(currencyLink, quantity)
    local currencyID = C_CurrencyInfo.GetCurrencyIDFromLink(currencyLink)
        or tonumber(currencyLink:match("currency:(%d+)"))
    local info = C_CurrencyInfo.GetCurrencyInfoFromLink(currencyLink)
    if (not info or not info.name or not info.iconFileID) and currencyID then
        info = C_CurrencyInfo.GetCurrencyInfo(currencyID) or info
    end
    currencyID = currencyID or (info and info.currencyID)
    if not info or not info.name or not currencyID then return end
    local receivedAt = time()
    local amount = quantity or 1
    local consolidated

    if self.db.consolidateLoot then
        local timeframe = self.db.consolidationUseSeconds
            and (self.db.consolidationSeconds or 30)
            or ((self.db.consolidationMinutes or 5) * 60)
        local cutoff = receivedAt - timeframe
        for index, existing in ipairs(self.db.history) do
            if existing.kind == "CURRENCY" and existing.id == currencyID
                and (existing.lootedAt or 0) >= cutoff then
                existing.quantity = (existing.quantity or 1) + amount
                existing.link = currencyLink
                existing.name = info.name
                existing.icon = info.iconFileID
                existing.time = date("%H:%M", receivedAt)
                existing.lootedAt = receivedAt
                consolidated = table.remove(self.db.history, index)
                table.insert(self.db.history, 1, consolidated)
                break
            end
        end
    end

    if not consolidated then
        table.insert(self.db.history, 1, {
            kind = "CURRENCY",
            id = currencyID,
            link = currencyLink,
            name = info.name,
            quality = info.quality or 1,
            icon = info.iconFileID,
            quantity = amount,
            source = "CURRENCY",
            sellPrice = 0,
            time = date("%H:%M", receivedAt),
            lootedAt = receivedAt,
        })
    end

    RefreshHistory(self, self.db.history, "PERSONAL")
end

function EL:AddMoney(amount, moneySource, activityEntry)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end

    local receivedAt = time()
    local entry
    if activityEntry and activityEntry.kind == "MONEY" then
        for index, existing in ipairs(self.db.history) do
            if existing == activityEntry then
                existing.amount = (tonumber(existing.amount) or 0) + amount
                existing.time = date("%H:%M", receivedAt)
                existing.lootedAt = receivedAt
                entry = table.remove(self.db.history, index)
                table.insert(self.db.history, 1, entry)
                break
            end
        end
    end

    if not entry then
        entry = {
            kind = "MONEY",
            amount = amount,
            icon = "Interface\\Icons\\INV_Misc_Coin_01",
            moneySource = moneySource,
            source = "MONEY",
            quality = 0,
            quantity = 1,
            sellPrice = 0,
            time = date("%H:%M", receivedAt),
            lootedAt = receivedAt,
        }
        table.insert(self.db.history, 1, entry)
    end

    RefreshHistory(self, self.db.history, "PERSONAL")
    return entry
end

function EL:IsCurrencyVisible(name)
    if type(name) ~= "string" then return true end

    local isKnowledge = name:match("^Midnight .+ Knowledge$") ~= nil
    if isKnowledge and self.db.hideKnowledgePoints == true then return false end

    local isProfessionMoxie = name:match("^Artisan .+ Moxie$") ~= nil
    if isProfessionMoxie and self.db.hideProfessionCurrencies == true then return false end

    return true
end

function EL:ClearHistory()
    local activeTab = self.db.activeTab or "PERSONAL"
    if activeTab == "GROUP" then
        wipe(self.db.groupHistory)
    else
        wipe(self.db.history)
    end
    self.scrollOffset = 0
    self.tabScrollOffsets = self.tabScrollOffsets or {}
    self.tabScrollOffsets[activeTab] = 0
    self:RefreshWindow()
end
