local _, EL = ...

local Controls = EL.ConfigControls
local CurrentTheme = Controls.CurrentTheme
local AddUniformBorder = Controls.AddUniformBorder

local activeDropdown
function Controls.AddDropdown(panel, y, width, getOptions, getValue, setValue, x)
    local dropdownScale = 0.90
    local scaledWidth = width * dropdownScale
    local buttonHeight = 34 * dropdownScale
    local rowHeight = 28 * dropdownScale
    local rowSpacing = 30 * dropdownScale
    local popupPadding = 8 * dropdownScale
    local button = CreateFrame("Button", nil, panel, "BackdropTemplate")
    if PixelUtil then
        PixelUtil.SetSize(button, scaledWidth, buttonHeight)
        PixelUtil.SetPoint(button, "TOPLEFT", panel, "TOPLEFT", x or 16, y)
    else
        button:SetSize(scaledWidth, buttonHeight)
        button:SetPoint("TOPLEFT", x or 16, y)
    end
    button:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8" })
    button:SetBackdropColor(0.055, 0.065, 0.095, 1)
    AddUniformBorder(button)
    button:SetUniformBorderColor(0.27, 0.34, 0.45, 1)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    button.text:SetPoint("LEFT", 12, 0)
    button.text:SetPoint("RIGHT", -34, 0)
    button.text:SetJustifyH("LEFT")
    button.text:SetTextColor(1, 1, 1, 1)
    button.arrow = button:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    button.arrow:SetPoint("RIGHT", -12, 1)
    button.arrow:SetText("v")
    button.arrow:SetTextColor(0.62, 0.78, 0.84)

    local popup = CreateFrame("Frame", nil, button, "BackdropTemplate")
    popup:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -4)
    if PixelUtil then PixelUtil.SetWidth(popup, scaledWidth) else popup:SetWidth(scaledWidth) end
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetFrameLevel(100)
    popup:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8" })
    popup:SetBackdropColor(0.03, 0.035, 0.06, 0.99)
    AddUniformBorder(popup)
    popup:SetUniformBorderColor(0.28, 0.38, 0.50, 1)
    popup:Hide()
    popup.rows = {}

    local function UpdateText()
        local current = getValue()
        for _, option in ipairs(getOptions()) do
            if option.value == current then button.text:SetText(option.label); return end
        end
        button.text:SetText("Select...")
    end

    local function BuildPopup()
        local theme = CurrentTheme()
        local accent = theme.accent
        local options = getOptions()
        local popupHeight = popupPadding + (#options * rowSpacing)
        if PixelUtil then PixelUtil.SetHeight(popup, popupHeight) else popup:SetHeight(popupHeight) end
        for index, option in ipairs(options) do
            local row = popup.rows[index]
            if not row then
                row = CreateFrame("Button", nil, popup)
                row:SetHeight(rowHeight)
                row:SetPoint("TOPLEFT", 4, -4 - ((index - 1) * rowSpacing))
                row:SetPoint("TOPRIGHT", -4, -4 - ((index - 1) * rowSpacing))
                row.hover = row:CreateTexture(nil, "BACKGROUND")
                row.hover:SetAllPoints()
                row.hover:SetColorTexture(0.30, 0.48, 0.58, 0.14)
                row.hover:Hide()
                row.selected = row:CreateTexture(nil, "ARTWORK")
                row.selected:SetPoint("TOPLEFT", 0, -4)
                row.selected:SetPoint("BOTTOMLEFT", 0, 4)
                row.selected:SetWidth(2)
                row.selected:SetColorTexture(0.43, 0.68, 0.76, 1)
                row.text = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                row.text:SetPoint("LEFT", 11, 0)
                row.text:SetTextColor(1, 1, 1, 1)
                row:SetScript("OnEnter", function(self) self.hover:Show() end)
                row:SetScript("OnLeave", function(self) self.hover:Hide() end)
                popup.rows[index] = row
            end
            local selected = option.value == getValue()
            local optionValue = option.value
            row.text:SetText(option.label)
            row.selected:SetColorTexture(accent[1], accent[2], accent[3], 1)
            row.hover:SetColorTexture(accent[1], accent[2], accent[3], 0.14)
            row.selected:SetShown(selected)
            row:SetScript("OnClick", function()
                setValue(optionValue)
                UpdateText()
                popup:Hide()
                activeDropdown = nil
            end)
            row:Show()
        end
        for index = #options + 1, #popup.rows do popup.rows[index]:Hide() end
    end

    function button:ApplyTheme()
        local theme = CurrentTheme()
        local accent, header = theme.accent, theme.header
        self:SetBackdropColor(header[1], header[2], header[3], 1)
        self:SetUniformBorderColor(accent[1] * 0.65, accent[2] * 0.65, accent[3] * 0.65, 0.55)
        self.arrow:SetTextColor(accent[1], accent[2], accent[3], 1)
        popup:SetBackdropColor(theme.background[1], theme.background[2], theme.background[3], 0.99)
        popup:SetUniformBorderColor(accent[1] * 0.65, accent[2] * 0.65, accent[3] * 0.65, 0.55)
    end
    button:SetScript("OnShow", function(self) UpdateText(); self:ApplyTheme() end)
    button:SetScript("OnEnter", function(self)
        local accent = CurrentTheme().accent
        self:SetUniformBorderColor(accent[1], accent[2], accent[3], 0.75)
    end)
    button:SetScript("OnLeave", function(self) self:ApplyTheme() end)
    button:SetScript("OnClick", function()
        if activeDropdown and activeDropdown ~= popup then activeDropdown:Hide() end
        if popup:IsShown() then
            popup:Hide()
            activeDropdown = nil
        else
            BuildPopup()
            popup:ClearAllPoints()
            popup:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -4)
            popup:Show()
            local scrollFrame = panel:GetParent()
            local popupBottom = popup:GetBottom()
            local visibleBottom = scrollFrame and scrollFrame:GetBottom()
            if popupBottom and visibleBottom and popupBottom < visibleBottom then
                popup:ClearAllPoints()
                popup:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, 4)
            end
            activeDropdown = popup
        end
    end)
    button.UpdateText = UpdateText
    panel.themeControls = panel.themeControls or {}
    panel.themeControls[#panel.themeControls + 1] = button
    UpdateText()
    button:ApplyTheme()
    return button
end


