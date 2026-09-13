local _, EL = ...

EL.ConfigControls = EL.ConfigControls or {}

local function CurrentTheme()
    return EL.themes[EL.db.theme] or EL.themes.battlenet
end

local function SetPixelPoint(region, point, relativeTo, relativePoint, x, y)
    if PixelUtil then
        PixelUtil.SetPoint(region, point, relativeTo, relativePoint, x or 0, y or 0)
    else
        region:SetPoint(point, relativeTo, relativePoint, x or 0, y or 0)
    end
end

local function SetPixelSize(region, width, height)
    if PixelUtil then PixelUtil.SetSize(region, width, height) else region:SetSize(width, height) end
end

local function SnapConfigWindow(frame)
    if not frame or not PixelUtil then return end
    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    if not point then return end
    frame:ClearAllPoints()
    PixelUtil.SetPoint(frame, point, relativeTo or UIParent, relativePoint or point, x or 0, y or 0)
    PixelUtil.SetSize(frame, 1024, 576)
end

local function AddTitle(panel, text, y)
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, y)
    title:SetText(text)
    panel.pageTitle = title
    return title
end

local function AddUniformBorder(frame, thickness)
    thickness = thickness or 1
    frame.uniformBorders = {}
    local function PositionBorder(border, edge)
        local firstPoint = edge == "TOP" and "TOPLEFT"
            or edge == "BOTTOM" and "BOTTOMLEFT"
            or edge == "LEFT" and "TOPLEFT"
            or "TOPRIGHT"
        local secondPoint = edge == "TOP" and "TOPRIGHT"
            or edge == "BOTTOM" and "BOTTOMRIGHT"
            or edge == "LEFT" and "BOTTOMLEFT"
            or "BOTTOMRIGHT"
        border:ClearAllPoints()
        if PixelUtil then
            PixelUtil.SetPoint(border, firstPoint, frame, firstPoint, 0, 0)
            PixelUtil.SetPoint(border, secondPoint, frame, secondPoint, 0, 0)
            if edge == "TOP" or edge == "BOTTOM" then
                PixelUtil.SetHeight(border, thickness)
            else
                PixelUtil.SetWidth(border, thickness)
            end
        else
            border:SetPoint(firstPoint)
            border:SetPoint(secondPoint)
            if edge == "TOP" or edge == "BOTTOM" then border:SetHeight(thickness) else border:SetWidth(thickness) end
        end
    end
    for _, edge in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local border = frame:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface/Buttons/WHITE8X8")
        border.uniformEdge = edge
        PositionBorder(border, edge)
        frame.uniformBorders[#frame.uniformBorders + 1] = border
    end
    function frame:RefreshUniformBorderPixels()
        for _, border in ipairs(self.uniformBorders) do PositionBorder(border, border.uniformEdge) end
    end
    function frame:SetUniformBorderColor(r, g, b, a)
        self:RefreshUniformBorderPixels()
        for _, border in ipairs(self.uniformBorders) do border:SetColorTexture(r, g, b, a) end
    end
end

local function CreateCompactButton(parent, width, label)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    SetPixelSize(button, width, 30.6)
    button:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8" })
    AddUniformBorder(button)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    button.label:SetPoint("CENTER")
    button.label:SetTextColor(1, 1, 1, 1)
    button.label:SetText(label)
    function button:ApplyTheme()
        local theme = CurrentTheme()
        self:SetBackdropColor(theme.header[1], theme.header[2], theme.header[3], 0.96)
        self:SetUniformBorderColor(theme.border[1], theme.border[2], theme.border[3], 0.55)
    end
    button:SetScript("OnEnter", function(self)
        local accent = CurrentTheme().accent
        self:SetUniformBorderColor(accent[1], accent[2], accent[3], 0.75)
    end)
    button:SetScript("OnLeave", function(self) self:ApplyTheme() end)
    button:ApplyTheme()
    return button
end

EL.ConfigControls.CurrentTheme = CurrentTheme
EL.ConfigControls.SetPixelPoint = SetPixelPoint
EL.ConfigControls.SetPixelSize = SetPixelSize
EL.ConfigControls.SnapConfigWindow = SnapConfigWindow
EL.ConfigControls.AddTitle = AddTitle
EL.ConfigControls.AddUniformBorder = AddUniformBorder
EL.ConfigControls.CreateCompactButton = CreateCompactButton
