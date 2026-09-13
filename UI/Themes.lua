local _, EL = ...

function EL:ApplyTheme()
    if not self.frame then return end
    local theme = self.themes[self.db.theme] or self.themes.battlenet
    local opacity = math.max(0, math.min(100, tonumber(self.db.backgroundOpacity) or 100)) / 100
    local bodyVisible = opacity > 0
    self.frame:SetBackdropColor(theme.background[1], theme.background[2], theme.background[3], 0)
    self.frame.bodyBackground:SetColorTexture(theme.background[1], theme.background[2], theme.background[3], 1)
    self.frame.bodyBackground:SetAlpha(opacity)
    self.frame.bodyBackground:SetShown(bodyVisible)
    if self.db.showWindowBorder ~= false then
        self.frame:SetBackdropBorderColor(unpack(theme.border))
    else
        self.frame:SetBackdropBorderColor(0, 0, 0, 0)
    end
    self.frame.header:SetBackdropColor(theme.header[1], theme.header[2], theme.header[3], 1)
    if self.frame.clearButton and self.frame.clearButton.ApplyTheme then
        self.frame.clearButton:ApplyTheme()
    end
    self:UpdateLootTabs()
    self.frame.resizeHandle.edgeH:SetColorTexture(theme.accent[1], theme.accent[2], theme.accent[3], 0.9)
    self.frame.resizeHandle.edgeV:SetColorTexture(theme.accent[1], theme.accent[2], theme.accent[3], 0.9)
    if theme.gradient and bodyVisible then
        self.frame.gradient:SetGradient("HORIZONTAL", CreateColor(unpack(theme.gradient.from)), CreateColor(unpack(theme.gradient.to)))
        self.frame.gradient:SetAlpha(opacity)
        self.frame.gradient:Show()
    else
        self.frame.gradient:Hide()
    end
    if theme.headerGradient then
        self.frame.header.gradient:SetGradient("HORIZONTAL", CreateColor(unpack(theme.headerGradient.from)), CreateColor(unpack(theme.headerGradient.to)))
        self.frame.header.gradient:SetAlpha(1)
        self.frame.header.gradient:Show()
    else
        self.frame.header.gradient:Hide()
    end
end
