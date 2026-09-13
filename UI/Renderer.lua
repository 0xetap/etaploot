local _, EL = ...

local ROW_HEIGHT = EL.UI.ROW_HEIGHT
local HEADER_HEIGHT = EL.UI.HEADER_HEIGHT
local MAX_VISIBLE_ITEMS = EL.UI.MAX_VISIBLE_ITEMS

local PROFESSION_PROC_LABELS = {
    PERCEPTION = "Perception!",
    FINESSE = "Finesse!",
    MULTICRAFT = "Multicraft!",
    INGENUITY = "Ingenuity!",
    RESOURCEFULNESS = "Resourcefulness!",
}

local function GetProfessionProcLabel(source)
    if type(source) ~= "string" then return nil end
    if PROFESSION_PROC_LABELS[source] then return PROFESSION_PROC_LABELS[source] end
    local labels = {}
    for procSource in source:gmatch("[^+]+") do
        local label = PROFESSION_PROC_LABELS[procSource]
        if not label then return nil end
        labels[#labels + 1] = label
    end
    return #labels > 0 and table.concat(labels, "  ") or nil
end

function EL:RefreshWindow()
    local frame = self.frame
    if not frame or not frame:IsShown() then return end
    self:CancelAutoCollapseFade()
    if self.whisperPrompt then self.whisperPrompt:Hide() end
    frame:SetScale(self.db.scale)
    frame:SetWidth(self.db.windowWidth)
    frame.resizeHandle:SetShown(not self.db.locked)
    frame.resizeHandle:UpdateUnlockedVisual()
    self:AnchorWindowForGrowth()
    self:ApplyTheme()

    for _, row in ipairs(frame.rows) do
        row:Hide()
        if row.badge and row.badge.procFade then
            row.badge.procFade:Stop()
            row.badge:SetAlpha(1)
        end
    end
    local isGroupTab = self.db.activeTab == "GROUP"
    local function TabSetting(groupKey, personalKey)
        if isGroupTab then return self.db[groupKey] end
        return self.db[personalKey]
    end
    local lootFontSize = TabSetting("groupLootFontSize", "personalLootFontSize")
    local sellPriceFontSize = TabSetting("groupSellPriceFontSize", "personalSellPriceFontSize")
    local procFontSize = isGroupTab and math.max(6, lootFontSize - 2) or self.db.personalProcFontSize
    local skillMarkerSize = self.db.personalSkillMarkerSize
    local showConfiguredSellPrice = TabSetting("groupShowSellPrice", "personalShowSellPrice")
    local sellPriceMode = TabSetting("groupSellPriceMode", "personalSellPriceMode")
    local showItemQuality = TabSetting("groupShowItemQuality", "personalShowItemQuality")
    local showIcon = TabSetting("groupShowIcon", "personalShowIcon")
    local showQuantity = TabSetting("groupShowQuantity", "personalShowQuantity")
    local showTime = TabSetting("groupShowTime", "personalShowTime")
    local timeFormat = TabSetting("groupTimeFormat", "personalTimeFormat")
    local autoCollapseEnabled = TabSetting("groupAutoCollapseEnabled", "personalAutoCollapseEnabled")
    local autoCollapseSeconds = TabSetting("groupAutoCollapseSeconds", "personalAutoCollapseSeconds")
    local history = TabSetting("groupHistory", "history")
    local filteredItems = {}
    for _, item in ipairs(history) do
        local isMoney = item.kind == "MONEY"
        if isMoney then
            if not isGroupTab and self.db.personalShowMoney == true then
                filteredItems[#filteredItems + 1] = item
            end
        else
            local passesQuality = (tonumber(item.quality) or 0) >= (self.db.minimumQuality or 0)
            local passesEquipment = not self.db.equippableOnly
                or (item.kind ~= "CURRENCY" and self:IsEquippableItem(item.link or item.id))
            if passesQuality and passesEquipment and isGroupTab then
                filteredItems[#filteredItems + 1] = item
            elseif passesQuality and passesEquipment then
                local source = item.source or "LOOT"
                local currencyVisible = source ~= "CURRENCY" or self:IsCurrencyVisible(item.name)
                if ((source == "LOOT" or (source == "CURRENCY" and currencyVisible)) and self.db.showLootedItems)
                    or (source == "CRAFT" and self.db.showCraftedItems) then
                    filteredItems[#filteredItems + 1] = item
                end
            end
        end
    end
    local sortByQuality = TabSetting("groupSortLootByQuality", "personalSortLootByQuality")
    if sortByQuality and #filteredItems > 1 then
        local lootOrder = {}
        for index, item in ipairs(filteredItems) do lootOrder[item] = index end
        table.sort(filteredItems, function(left, right)
            local leftQuality = tonumber(left.quality) or 0
            local rightQuality = tonumber(right.quality) or 0
            if leftQuality == rightQuality then return lootOrder[left] < lootOrder[right] end
            return leftQuality > rightQuality
        end)
    end
    local autoCollapsed = false
    local autoCollapseCanHover = false
    self.nextAutoCollapseAt = nil
    local autoCollapseTabKey = isGroupTab and "GROUP" or "PERSONAL"
    if autoCollapseEnabled and self.db.locked then
        self.autoCollapseStates = self.autoCollapseStates or {}
        self.autoCollapsedEntries = self.autoCollapsedEntries or {}
        local state = self.autoCollapseStates[autoCollapseTabKey] or { appliedSteps = 0 }
        local expired = self.autoCollapsedEntries[autoCollapseTabKey] or {}
        self.autoCollapseStates[autoCollapseTabKey] = state
        self.autoCollapsedEntries[autoCollapseTabKey] = expired

        local activeItems = {}
        for _, item in ipairs(filteredItems) do
            local receivedMarker = item.lootedAt or item.time or true
            if expired[item] ~= receivedMarker then activeItems[#activeItems + 1] = item end
        end
        local configuredMaxItems = math.min(MAX_VISIBLE_ITEMS, self.db.maxItems)
        while #activeItems > configuredMaxItems do
            local item = table.remove(activeItems)
            expired[item] = item.lootedAt or item.time or true
        end

        local latestLootAt
        for _, item in ipairs(activeItems) do
            local lootedAt = tonumber(item.lootedAt)
            if lootedAt and (not latestLootAt or lootedAt > latestLootAt) then latestLootAt = lootedAt end
        end
        if latestLootAt then
            if state.latestLootAt ~= latestLootAt then
                state.latestLootAt = latestLootAt
                state.appliedSteps = 0
            end
            local initialDelay = autoCollapseSeconds or 30
            local rowInterval = self.db.autoCollapseRowInterval or 2
            local elapsed = math.max(0, time() - latestLootAt)
            local targetSteps = elapsed >= initialDelay
                and (1 + math.floor((elapsed - initialDelay) / rowInterval))
                or 0
            local newSteps = math.max(0, targetSteps - (state.appliedSteps or 0))
            for _ = 1, math.min(newSteps, #activeItems) do
                local item = table.remove(activeItems)
                expired[item] = item.lootedAt or item.time or true
            end
            state.appliedSteps = targetSteps
            autoCollapsed = #activeItems == 0
            if not autoCollapsed then
                self.nextAutoCollapseAt = targetSteps == 0
                    and (latestLootAt + initialDelay)
                    or (latestLootAt + initialDelay + (targetSteps * rowInterval))
            end
        end
        autoCollapsed = #activeItems == 0 and #filteredItems > 0
        -- Older history must remain available while hovered even when the
        -- active rows already fill the configured visible-item capacity.
        autoCollapseCanHover = #activeItems < #filteredItems
        if self.autoCollapseHoverTab == autoCollapseTabKey and autoCollapseCanHover then
            autoCollapsed = false
        else
            filteredItems = activeItems
        end
    else
        if self.autoCollapseStates then self.autoCollapseStates[autoCollapseTabKey] = nil end
        if self.autoCollapsedEntries then self.autoCollapsedEntries[autoCollapseTabKey] = nil end
        if self.autoCollapseHoverTab == autoCollapseTabKey then self.autoCollapseHoverTab = nil end
    end
    self.filteredItemCount = #filteredItems
    local configuredMaxItems = math.min(MAX_VISIBLE_ITEMS, self.db.maxItems)
    local maxOffset = math.max(0, #filteredItems - configuredMaxItems)
    self.scrollOffset = math.max(0, math.min(self.scrollOffset or 0, maxOffset))
    local visibleCapacity = math.min(#filteredItems, configuredMaxItems)
    local visibleItems = {}
    for index = self.scrollOffset + 1, math.min(#filteredItems, self.scrollOffset + visibleCapacity) do
        visibleItems[#visibleItems + 1] = filteredItems[index]
    end
    local count = #visibleItems
    self.currentVisibleCount = count
    for index = 1, count do
        local item = visibleItems[index]
        local isMoney = item.kind == "MONEY"
        local row = frame.rows[index] or EL:CreateLootRow(frame)
        frame.rows[index] = row
        row:ClearAllPoints()
        if self.db.growDirection == "UP" then
            row:SetPoint("BOTTOMLEFT", 7, HEADER_HEIGHT + 4 + ((index - 1) * ROW_HEIGHT))
            row:SetPoint("BOTTOMRIGHT", -7, HEADER_HEIGHT + 4 + ((index - 1) * ROW_HEIGHT))
        else
            row:SetPoint("TOPLEFT", 7, -HEADER_HEIGHT - 4 - ((index - 1) * ROW_HEIGHT))
            row:SetPoint("TOPRIGHT", -7, -HEADER_HEIGHT - 4 - ((index - 1) * ROW_HEIGHT))
        end
        row.itemLink = isMoney and nil or item.link
        if isGroupTab and item.recipient and not item.recipientClass and self.GetGroupMemberName then
            local _, recipientClass = self:GetGroupMemberName(nil, item.recipient, nil)
            item.recipientClass = recipientClass
        end
        row.recipient = isGroupTab and item.recipient or nil
        row.recipientClass = isGroupTab and item.recipientClass or nil
        local lootFont, _, lootFlags = GameFontHighlightSmall:GetFont()
        row.text:SetFont(lootFont, lootFontSize, lootFlags)
        row.quantity:SetFont(lootFont, lootFontSize, lootFlags)
        row.sellPrice:SetFont(lootFont, sellPriceFontSize, lootFlags)
        row.badge.text:SetFont(row.badge.font, procFontSize, row.badge.fontFlags)
        local skillMarkerWidth = skillMarkerSize * 0.86
        row.badge.skillArrow:SetSize(skillMarkerWidth, skillMarkerSize)
        row.icon:SetTexture(isMoney and (item.icon or "Interface\\Icons\\INV_Misc_Coin_01") or item.icon)
        local rowShowsIcon = isMoney or showIcon
        row.icon:SetShown(rowShowsIcon)
        local skillUps = not isMoney and (tonumber(item.skillUps) or (item.skillUp and 1)) or nil
        local bonusSource = not isMoney and (skillUps and "SKILL_UP" or item.bonusSource) or nil
        local professionProcLabel = GetProfessionProcLabel(bonusSource)
        if bonusSource == "SKILL_UP" and self.db.showProfessionSkillIncrease == false then
            bonusSource = nil
        elseif professionProcLabel
            and self.db.showProfessionProcs == false then
            bonusSource = nil
            professionProcLabel = nil
        end
        local isProfessionProc = professionProcLabel ~= nil
        local procElapsed = isProfessionProc and math.max(0, time() - (tonumber(item.lootedAt) or time())) or 0
        if isProfessionProc and procElapsed >= 7 then
            bonusSource = nil
            isProfessionProc = false
        end
        local sellPrice = tonumber(item.sellPrice)
        if not isMoney and sellPrice == nil then
            sellPrice = select(11, C_Item.GetItemInfo(item.link)) or 0
            item.sellPrice = sellPrice
        end
        local showSellPrice = not isMoney and showConfiguredSellPrice and sellPrice > 0
        row.sellPrice:SetShown(showSellPrice)
        if showSellPrice then
            row.sellPrice:SetText(EL:FormatSellPrice(sellPrice * (item.quantity or 1), sellPriceMode))
        end
        row.badge:SetShown(bonusSource ~= nil)
        if bonusSource == "SKILL_UP" then
            row.badge.text:Hide()
            row.badge.skillArrow:Show()
            local atlas = skillUps >= 3 and "Professions-Icon-Skill-High"
                or skillUps == 2 and "Professions-Icon-Skill-Medium"
                or "Professions-Icon-Skill-Low"
            row.badge.skillArrow:SetAtlas(atlas, false)
        elseif isProfessionProc then
            row.badge.text:Show()
            row.badge.skillArrow:Hide()
            row.badge.text:SetText(professionProcLabel)
            local accent = (self.themes[self.db.theme] or self.themes.battlenet).accent
            row.badge.text:SetTextColor(unpack(accent))
            row.badge.text:SetShadowColor(0, 0, 0, 0)
            row.badge.text:SetShadowOffset(0, 0)
        elseif bonusSource == "BONUS_ROLL" then
            row.badge.text:Show()
            row.badge.skillArrow:Hide()
            row.badge.text:SetText("Bonus Roll!")
            row.badge.text:SetTextColor(1.00, 0.82, 0.32, 1)
            row.badge.text:SetShadowColor(1.00, 0.58, 0.08, 0.85)
            row.badge.text:SetShadowOffset(1, -1)
        end
        if isProfessionProc then
            local startAlpha = procElapsed <= 5 and 1 or math.max(0, 1 - ((procElapsed - 5) / 2))
            local fade = row.badge.procFade.alpha
            fade:SetStartDelay(math.max(0, 5 - procElapsed))
            fade:SetDuration(math.max(0.05, 7 - math.max(5, procElapsed)))
            fade:SetFromAlpha(startAlpha)
            fade:SetToAlpha(0)
            row.badge:SetAlpha(startAlpha)
            row.badge.procFade:Play()
        end
        row.bonusSource = bonusSource
        if bonusSource then row.badge:SetWidth(bonusSource == "SKILL_UP" and skillMarkerWidth + 2 or row.badge.text:GetStringWidth() + 12) end

        local quantityValue = tonumber(item.quantity) or 1
        local showRowQuantity = not isMoney and showQuantity and quantityValue > 1
        row.quantity:ClearAllPoints()
        row.quantity:SetPoint("RIGHT", -4, 0)
        row.quantity:SetText(showRowQuantity and ("|cffffffffx%d|r"):format(quantityValue) or "")
        row.quantity:SetShown(showRowQuantity)

        row.sellPrice:ClearAllPoints()
        if showRowQuantity then
            row.sellPrice:SetPoint("RIGHT", row.quantity, "LEFT", -8, 0)
        else
            row.sellPrice:SetPoint("RIGHT", -4, 0)
        end

        row.badge:ClearAllPoints()
        if showSellPrice then
            row.badge:SetPoint("RIGHT", row.sellPrice, "LEFT", -8, 0)
        elseif showRowQuantity then
            row.badge:SetPoint("RIGHT", row.quantity, "LEFT", -8, 0)
        else
            row.badge:SetPoint("RIGHT", -4, 0)
        end

        row.text:ClearAllPoints()
        if rowShowsIcon then
            row.text:SetPoint("LEFT", row.icon, "RIGHT", 7, 0)
        else
            row.text:SetPoint("LEFT", 3, 0)
        end
        if bonusSource then
            row.text:SetPoint("RIGHT", row.badge, "LEFT", -8, 0)
        elseif showSellPrice then
            row.text:SetPoint("RIGHT", row.sellPrice, "LEFT", -8, 0)
        elseif showRowQuantity then
            row.text:SetPoint("RIGHT", row.quantity, "LEFT", -4, 0)
        else
            row.text:SetPoint("RIGHT", -4, 0)
        end

        local displayedTime = item.time
        if showTime and item.lootedAt then
            displayedTime = date(timeFormat == "12H" and "%I:%M %p" or "%H:%M", item.lootedAt)
        end
        local prefix = showTime and not isMoney and ("|cffffffff" .. (displayedTime or "") .. "|r  ") or ""
        local itemText = isMoney
            and C_CurrencyInfo.GetCoinTextureString(tonumber(item.amount) or 0, lootFontSize)
            or item.link
        if not isMoney and item.kind ~= "CURRENCY" and not showItemQuality then
            local color = ITEM_QUALITY_COLORS[item.quality or 0] or ITEM_QUALITY_COLORS[0]
            itemText = color.hex .. "[" .. item.name .. "]|r"
        end
        row.text:SetText(prefix .. itemText)
        row:Show()
    end
    frame.empty:SetText(isGroupTab and "Items looted by other group members will appear here." or "Looted items will appear here.")
    frame.empty:SetShown(count == 0 and not autoCollapsed)
    if autoCollapsed then
        frame:SetHeight(HEADER_HEIGHT + 2)
    else
        frame:SetHeight(count == 0 and 82 or (HEADER_HEIGHT + 8 + (count * ROW_HEIGHT)))
    end
    local hoverArea = frame.collapseHoverArea
    hoverArea:ClearAllPoints()
    hoverArea:SetScale(frame:GetScale())
    hoverArea:SetWidth(frame:GetWidth())
    hoverArea:SetHeight(8 + (configuredMaxItems * ROW_HEIGHT))
    if self.db.growDirection == "UP" then
        hoverArea:SetPoint("BOTTOM", frame, "BOTTOM", 0, HEADER_HEIGHT)
    else
        hoverArea:SetPoint("TOP", frame, "TOP", 0, -HEADER_HEIGHT)
    end
    hoverArea:SetShown(autoCollapseCanHover)
    self:ScheduleAutoCollapseTimer()
end
