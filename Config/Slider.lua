local _, EL = ...

local Controls = EL.ConfigControls
local CurrentTheme = Controls.CurrentTheme
local AddUniformBorder = Controls.AddUniformBorder
local SnapConfigWindow = Controls.SnapConfigWindow

function Controls.AddSlider(panel, key, y, minimum, maximum, step, formatText, x)
    local slider = CreateFrame("Slider", nil, panel, "BackdropTemplate")
    if PixelUtil then
        PixelUtil.SetPoint(slider, "TOPLEFT", panel, "TOPLEFT", x or 22, y - 23)
        PixelUtil.SetSize(slider, 250, 8)
    else
        slider:SetPoint("TOPLEFT", x or 22, y - 23)
        slider:SetSize(250, 8)
    end
    slider:EnableMouse(true)
    -- Keep the slim visual track while providing a practical interaction
    -- target around its full width, including both endpoints.
    slider:SetHitRectInsets(-4, -4, -6, -6)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetOrientation("HORIZONTAL")
    slider:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8" })
    slider:SetBackdropColor(0.055, 0.065, 0.095, 1)
    AddUniformBorder(slider, 1)
    slider:SetUniformBorderColor(0.20, 0.25, 0.34, 1)
    for _, border in ipairs(slider.uniformBorders) do border:SetDrawLayer("ARTWORK", 7) end
    local fill = slider:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT", 2, 0)
    fill:SetHeight(4)
    fill:SetColorTexture(0.30, 0.50, 0.61, 0.72)
    slider.fill = fill
    local thumb = slider:CreateTexture(nil, "OVERLAY", nil, 7)
    thumb:SetSize(14, 18)
    thumb:SetColorTexture(0.62, 0.79, 0.86, 1)
    slider:SetThumbTexture(thumb)
    thumb:SetDrawLayer("OVERLAY", 7)
    local thumbOutline = CreateFrame("Frame", nil, slider)
    thumbOutline:SetAllPoints(thumb)
    thumbOutline:SetFrameLevel(slider:GetFrameLevel() + 10)
    thumbOutline:EnableMouse(false)
    AddUniformBorder(thumbOutline, 1)
    thumbOutline:SetUniformBorderColor(0, 0, 0, 0.9)
    slider.thumbOutline = thumbOutline
    slider.Text = slider:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    slider.Text:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 8)
    slider.Text:SetTextColor(1, 1, 1, 1)
    slider.Low = slider:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    slider.Low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -5)
    slider.Low:SetText(tostring(minimum))
    slider.High = slider:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    slider.High:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -5)
    slider.High:SetText(tostring(maximum))
    slider:SetScript("OnShow", function(self) self:SetValue(EL.db[key]) end)
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor((value / step) + 0.5) * step
        EL.db[key] = value
        self.Text:SetText(formatText:format(value))
        local range = maximum - minimum
        self.fill:SetWidth(math.max(1, ((value - minimum) / range) * 246))
        if key ~= "configScale" or not self.isDragging then
            if EL.RefreshWindow then EL:RefreshWindow() end
            if key == "configScale" and EL.ApplyConfigTheme then EL:ApplyConfigTheme() end
        end
    end)
    if key == "configScale" then
        -- The native Slider drag calculation uses the slider's current
        -- effective scale. Since this control changes that scale while it is
        -- being dragged, native input can fight the custom cursor-relative
        -- calculation below. A transparent sibling owns mouse input for this
        -- one slider so its visual value has a single source of truth.
        slider:EnableMouse(false)
        local dragSurface = CreateFrame("Frame", nil, panel)
        dragSurface:SetAllPoints(slider)
        dragSurface:SetFrameLevel(slider:GetFrameLevel() + 20)
        dragSurface:EnableMouse(true)
        dragSurface:SetHitRectInsets(-4, -4, -6, -6)
        slider.dragSurface = dragSurface

        local function ClampToStep(value)
            value = math.floor((value / step) + 0.5) * step
            return math.max(minimum, math.min(maximum, value))
        end

        local function ValueAtCursor()
            local left = slider:GetLeft()
            local effectiveScale = slider:GetEffectiveScale()
            if not left or not effectiveScale or effectiveScale <= 0 then return nil end
            local trackWidth = math.max(1, slider:GetWidth() * effectiveScale)
            local cursorX = GetCursorPosition()
            local normalized = (cursorX - (left * effectiveScale)) / trackWidth
            return ClampToStep(minimum + (normalized * (maximum - minimum))), cursorX
        end

        local function ApplyScaleAroundThumb(newScale)
            local config = EL.configFrame
            if not config or config:GetScale() == newScale then return end
            local beforeX, beforeY = thumb:GetCenter()
            local beforeScale = thumb:GetEffectiveScale()
            local point, relativeTo, relativePoint, x, y = config:GetPoint(1)
            config:SetScale(newScale)
            local afterX, afterY = thumb:GetCenter()
            local afterScale = thumb:GetEffectiveScale()
            if not beforeX or not afterX or not point then return end
            local parentScale = UIParent:GetEffectiveScale()
            local shiftX = ((beforeX * beforeScale) - (afterX * afterScale)) / parentScale
            local shiftY = ((beforeY * beforeScale) - (afterY * afterScale)) / parentScale
            config:ClearAllPoints()
            config:SetPoint(point, relativeTo or UIParent, relativePoint or point, (x or 0) + shiftX, (y or 0) + shiftY)
        end
        local function FinishScaleDrag(self)
            if not self.isDragging then return end
            self.isDragging = false
            EL.configScaleDragging = false
            self.dragStartCursorX = nil
            self.dragStartValue = nil
            self.dragTrackWidth = nil
            C_Timer.After(0, function()
                if EL.configFrame and SnapConfigWindow then SnapConfigWindow(EL.configFrame) end
                EL:Refresh()
            end)
        end

        dragSurface:SetScript("OnMouseDown", function(_, mouseButton)
            if mouseButton ~= "LeftButton" then return end
            slider.isDragging = true
            EL.configScaleDragging = true
            local value, cursorX = ValueAtCursor()
            if not value then
                FinishScaleDrag(slider)
                return
            end
            if value ~= EL.db[key] then
                slider:SetValue(value)
                ApplyScaleAroundThumb(value)
            end
            slider.dragStartCursorX = cursorX
            slider.dragStartValue = EL.db[key]
            slider.dragTrackWidth = math.max(1, slider:GetWidth() * slider:GetEffectiveScale())
        end)
        dragSurface:SetScript("OnMouseUp", function(_, mouseButton)
            if mouseButton == "LeftButton" then FinishScaleDrag(slider) end
        end)
        dragSurface:SetScript("OnUpdate", function()
            if not slider.isDragging then return end
            if not IsMouseButtonDown("LeftButton") then
                FinishScaleDrag(slider)
                return
            end
            local cursorX = GetCursorPosition()
            local value = slider.dragStartValue
                + (((cursorX - slider.dragStartCursorX) / slider.dragTrackWidth) * (maximum - minimum))
            value = ClampToStep(value)
            if value ~= EL.db[key] then
                slider:SetValue(value)
                ApplyScaleAroundThumb(value)
            end
        end)
        slider:SetScript("OnHide", function() FinishScaleDrag(slider) end)
    end
    function slider:ApplyTheme()
        local theme = CurrentTheme()
        local accent = theme.accent
        self.fill:SetColorTexture(accent[1], accent[2], accent[3], 0.72)
        thumb:SetColorTexture(accent[1], accent[2], accent[3], 1)
        self:SetBackdropColor(theme.header[1], theme.header[2], theme.header[3], 1)
        self:SetUniformBorderColor(theme.border[1], theme.border[2], theme.border[3], 0.55)
        self.thumbOutline:SetUniformBorderColor(0, 0, 0, 0.9)
    end
    panel.themeControls = panel.themeControls or {}
    panel.themeControls[#panel.themeControls + 1] = slider
    slider:ApplyTheme()
    return slider
end
