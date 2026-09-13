local _, EL = ...

local Controls = EL.ConfigControls
local CurrentTheme = Controls.CurrentTheme
local AddUniformBorder = Controls.AddUniformBorder
local TOOLTIP_FONT_SIZE = 10
local TOOLTIP_LINE_SPACING = 3
local TOOLTIP_MIN_TEXT_WIDTH = 100
local TOOLTIP_MAX_TEXT_WIDTH = 300
local TOOLTIP_HORIZONTAL_PADDING = 10
local TOOLTIP_VERTICAL_PADDING = 8
local TOOLTIP_CURSOR_OFFSET_X = 12
local TOOLTIP_CURSOR_OFFSET_Y = 18

local function GetCheckboxTooltip()
    if Controls.checkboxTooltip then return Controls.checkboxTooltip end

    local tooltip = CreateFrame("Frame", "EtapLootCheckboxTooltip", UIParent, "BackdropTemplate")
    tooltip:SetFrameStrata("TOOLTIP")
    tooltip:SetClampedToScreen(true)
    tooltip:EnableMouse(false)
    tooltip:SetBackdrop({
        bgFile = "Interface/Buttons/WHITE8X8",
        edgeFile = "Interface/Buttons/WHITE8X8",
        edgeSize = 1,
    })
    tooltip:SetBackdropColor(0.025, 0.025, 0.035, 0.98)

    tooltip.text = tooltip:CreateFontString(nil, "OVERLAY")
    tooltip.text:SetFontObject(GameTooltipText)
    local fontPath, _, fontFlags = tooltip.text:GetFont()
    tooltip.text:SetFont(fontPath, TOOLTIP_FONT_SIZE, fontFlags)
    tooltip.text:SetTextColor(0.78, 0.78, 0.82, 1)
    tooltip.text:SetJustifyH("LEFT")
    tooltip.text:SetJustifyV("TOP")
    tooltip.text:SetWordWrap(true)
    tooltip.text:SetSpacing(TOOLTIP_LINE_SPACING)
    tooltip.text:SetPoint("TOPLEFT", TOOLTIP_HORIZONTAL_PADDING, -TOOLTIP_VERTICAL_PADDING)
    tooltip:Hide()

    Controls.checkboxTooltip = tooltip
    return tooltip
end

local function ShowCheckboxTooltip(description)
    local tooltip = GetCheckboxTooltip()
    local theme = CurrentTheme()
    tooltip:SetBackdropBorderColor(theme.border[1], theme.border[2], theme.border[3], 0.55)

    tooltip.text:SetWidth(TOOLTIP_MAX_TEXT_WIDTH)
    tooltip.text:SetText(description)
    -- Find the narrowest width that keeps the same number of wrapped lines as
    -- the maximum width. This avoids a wide empty tail beside the last line.
    local maximumWidthHeight = tooltip.text:GetStringHeight()
    local low, high = TOOLTIP_MIN_TEXT_WIDTH, TOOLTIP_MAX_TEXT_WIDTH
    while high - low > 1 do
        local candidate = math.floor((low + high) * 0.5)
        tooltip.text:SetWidth(candidate)
        if tooltip.text:GetStringHeight() <= maximumWidthHeight + 0.5 then
            high = candidate
        else
            low = candidate
        end
    end
    local textWidth = high
    tooltip.text:SetWidth(textWidth)
    local textHeight = math.ceil(tooltip.text:GetStringHeight())
    local width = textWidth + (TOOLTIP_HORIZONTAL_PADDING * 2)
    local height = textHeight + (TOOLTIP_VERTICAL_PADDING * 2)
    if PixelUtil then PixelUtil.SetSize(tooltip, width, height) else tooltip:SetSize(width, height) end

    tooltip:ClearAllPoints()
    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    tooltip:SetPoint(
        "BOTTOMLEFT",
        UIParent,
        "BOTTOMLEFT",
        (cursorX / uiScale) + TOOLTIP_CURSOR_OFFSET_X,
        (cursorY / uiScale) + TOOLTIP_CURSOR_OFFSET_Y
    )
    tooltip:Show()
end

function Controls.AddCheck(panel, text, key, y, description, x)
    local box = CreateFrame("CheckButton", nil, panel, "BackdropTemplate")
    if PixelUtil then
        PixelUtil.SetSize(box, 20, 20)
        PixelUtil.SetPoint(box, "TOPLEFT", panel, "TOPLEFT", x or 18, y - 3)
    else
        box:SetSize(20, 20)
        box:SetPoint("TOPLEFT", x or 18, y - 3)
    end
    box:SetHitRectInsets(0, -240, 0, 0)
    box:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8" })
    box:SetBackdropColor(0.055, 0.065, 0.095, 1)
    AddUniformBorder(box)
    box.Text = box:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    box.Text:SetPoint("LEFT", box, "RIGHT", 10, 0)
    box.Text:SetTextColor(1, 1, 1, 1)
    box.Text:SetText(text)
    local function Update(self)
        local checked = self:GetChecked()
        local theme = CurrentTheme()
        local accent, header, border = theme.accent, theme.header, theme.border
        self:SetBackdropColor(checked and accent[1] * 0.55 or header[1], checked and accent[2] * 0.55 or header[2], checked and accent[3] * 0.55 or header[3], 1)
        self:SetUniformBorderColor(checked and accent[1] or border[1], checked and accent[2] or border[2], checked and accent[3] or border[3], checked and 0.70 or 0.55)
    end
    box:SetScript("OnShow", function(self) self:SetChecked(EL.db[key]); Update(self) end)
    box:SetScript("OnClick", function(self) EL.db[key] = self:GetChecked() and true or false; Update(self); EL:Refresh() end)
    box:SetScript("OnEnter", function(self)
        self:SetUniformBorderColor(0.48, 0.68, 0.76, 0.75)
        ShowCheckboxTooltip(description)
    end)
    box:SetScript("OnLeave", function(self)
        Update(self)
        GetCheckboxTooltip():Hide()
    end)
    box.ApplyTheme = Update
    panel.themeControls = panel.themeControls or {}
    panel.themeControls[#panel.themeControls + 1] = box
    return box
end
