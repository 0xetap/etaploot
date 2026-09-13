local _, EL = ...

local MAX_VISIBLE_ITEMS = EL.UI.MAX_VISIBLE_ITEMS

function EL:SetActiveTab(tabKey)
    if tabKey ~= "PERSONAL" and tabKey ~= "GROUP" then return end
    if self.db.activeTab == tabKey then return end
    self.tabScrollOffsets = self.tabScrollOffsets or {}
    self.tabScrollOffsets[self.db.activeTab] = self.scrollOffset or 0
    self.autoCollapseHoverTab = nil
    self.db.activeTab = tabKey
    self.scrollOffset = self.tabScrollOffsets[tabKey] or 0
    self:RefreshWindow()
end

function EL:UpdateLootTabs()
    if not self.frame or not self.frame.tabs then return end
    local theme = self.themes[self.db.theme] or self.themes.battlenet
    for tabKey, tab in pairs(self.frame.tabs) do
        local selected = self.db.activeTab == tabKey
        if selected then
            tab.label:SetTextColor(unpack(theme.accent))
            tab.indicator:SetColorTexture(unpack(theme.accent))
            tab.indicator:Show()
        else
            local color = tab.isHovered and theme.text or { 0.62, 0.63, 0.68, 1 }
            tab.label:SetTextColor(unpack(color))
            tab.indicator:Hide()
        end
    end
end

function EL:ScrollHistory(delta)
    if not self.frame or not self.db then return end
    if self.db.growDirection == "UP" then delta = -delta end
    local configuredMaxItems = math.min(MAX_VISIBLE_ITEMS, self.db.maxItems)
    local maxOffset = math.max(0, (self.filteredItemCount or 0) - configuredMaxItems)
    local offset = self.scrollOffset or 0
    if delta < 0 then
        offset = math.min(maxOffset, offset + 1)
    elseif delta > 0 then
        offset = math.max(0, offset - 1)
    end
    if offset ~= (self.scrollOffset or 0) then
        self.scrollOffset = offset
        self:RefreshWindow()
    end
end
