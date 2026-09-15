local _, EL = ...

local function PositionMinimapButton(button)
    local angle = math.rad(EL.db.minimap.angle or 225)
    local radius = 80
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

function EL:CreateMinimapButton()
    local button = CreateFrame("Button", "EtapLootMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetClampedToScreen(true)
    button:RegisterForClicks("LeftButtonUp", "MiddleButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button.icon = button:CreateVectorGraphics(nil, "OVERLAY")
    button.icon:SetAllPoints(button)
    button.icon:SetSVG("Interface\\AddOns\\EtapLoot\\Media\\EtapLootIcon.svg")

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("EtapLoot", 0.58, 0.76, 0.86)
        GameTooltip:AddLine("Left-click: Open settings", 1, 1, 1)
        GameTooltip:AddLine("Middle-click: Lock/unlock loot window", 0.75, 0.75, 0.8)
        GameTooltip:AddLine("Right-click: Toggle loot window", 0.75, 0.75, 0.8)
        GameTooltip:AddLine("Drag: Move button", 0.75, 0.75, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    button:SetScript("OnClick", function(_, mouseButton)
        if button.wasDragged then return end
        if mouseButton == "MiddleButton" then
            EL.db.locked = not EL.db.locked
            if EL.lockWindowToggle then
                EL.lockWindowToggle:SetChecked(EL.db.locked)
                EL.lockWindowToggle:ApplyTheme()
            end
            EL:Refresh()
        elseif mouseButton == "RightButton" then
            EL:SetLootWindowShown(not EL.frame:IsShown())
        else
            EL:OpenConfig()
        end
    end)
    button:SetScript("OnDragStart", function(self)
        self.wasDragged = true
        self:SetScript("OnUpdate", function(dragged)
            local scale = Minimap:GetEffectiveScale()
            local cursorX, cursorY = GetCursorPosition()
            local centerX, centerY = Minimap:GetCenter()
            cursorX, cursorY = cursorX / scale, cursorY / scale
            EL.db.minimap.angle = math.deg(math.atan2(cursorY - centerY, cursorX - centerX))
            PositionMinimapButton(dragged)
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        C_Timer.After(0, function() self.wasDragged = false end)
    end)

    self.minimapButton = button
    PositionMinimapButton(button)
end

function EL:UpdateMinimapButton()
    if not self.minimapButton then return end
    self.minimapButton:SetShown(self.db.showMinimapButton)
    PositionMinimapButton(self.minimapButton)
end
