local _, EL = ...

local ROW_HEIGHT = EL.UI.ROW_HEIGHT
local HEADER_HEIGHT = EL.UI.HEADER_HEIGHT
local MAX_VISIBLE_ITEMS = EL.UI.MAX_VISIBLE_ITEMS

function EL:SetLootWindowShown(shown)
    shown = shown and true or false
    if self.db then self.db.windowShown = shown end
    if self.frame then self.frame:SetShown(shown) end
end

function EL:CreateWindow()
    local frame = CreateFrame("Frame", "EtapLootWindow", UIParent, "BackdropTemplate")
    frame:Hide()
    frame:SetSize(300, 110)
    frame:SetPoint(self.db.window.point, UIParent, self.db.window.point, self.db.window.x, self.db.window.y)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f) if not EL.db.locked then f:StartMoving() end end)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        EL:AnchorWindowForGrowth(true)
        local point, _, _, x, y = f:GetPoint()
        EL.db.window.point, EL.db.window.x, EL.db.window.y = point, x, y
    end)
    frame:SetBackdrop({
        bgFile = "Interface/Buttons/WHITE8X8",
        edgeFile = "Interface/Buttons/WHITE8X8",
        edgeSize = 1,
    })

    frame.bodyBackground = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
    frame.bodyBackground:SetPoint("TOPLEFT", 1, -HEADER_HEIGHT - 1)
    frame.bodyBackground:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.bodyBackground:SetTexture("Interface/Buttons/WHITE8X8")

    frame.gradient = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    frame.gradient:SetPoint("TOPLEFT", 1, -HEADER_HEIGHT - 1)
    frame.gradient:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.gradient:SetTexture("Interface/Buttons/WHITE8X8")

    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetHeight(HEADER_HEIGHT)
    header:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8" })
    header.gradient = header:CreateTexture(nil, "BACKGROUND", nil, 1)
    header.gradient:SetAllPoints()
    header.gradient:SetTexture("Interface/Buttons/WHITE8X8")
    frame.header = header

    local function AddPixelBorder(button)
        button.pixelBorders = {}
        for _, edge in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
            local border = button:CreateTexture(nil, "OVERLAY")
            border:SetTexture("Interface/Buttons/WHITE8X8")
            local firstPoint = edge == "TOP" and "TOPLEFT"
                or edge == "BOTTOM" and "BOTTOMLEFT"
                or edge == "LEFT" and "TOPLEFT"
                or "TOPRIGHT"
            local secondPoint = edge == "TOP" and "TOPRIGHT"
                or edge == "BOTTOM" and "BOTTOMRIGHT"
                or edge == "LEFT" and "BOTTOMLEFT"
                or "BOTTOMRIGHT"
            if PixelUtil then
                PixelUtil.SetPoint(border, firstPoint, button, firstPoint, 0, 0)
                PixelUtil.SetPoint(border, secondPoint, button, secondPoint, 0, 0)
                if edge == "TOP" or edge == "BOTTOM" then
                    PixelUtil.SetHeight(border, 1)
                else
                    PixelUtil.SetWidth(border, 1)
                end
            else
                border:SetPoint(firstPoint)
                border:SetPoint(secondPoint)
                if edge == "TOP" or edge == "BOTTOM" then border:SetHeight(1) else border:SetWidth(1) end
            end
            button.pixelBorders[#button.pixelBorders + 1] = border
        end
        function button:SetPixelBorderColor(r, g, b, a)
            for _, border in ipairs(self.pixelBorders) do border:SetColorTexture(r, g, b, a) end
        end
    end

    local function CreateModernButton(width, label)
        local button = CreateFrame("Button", nil, header, "BackdropTemplate")
        button:SetSize(width, 19)
        button:SetBackdrop({
            bgFile = "Interface/Buttons/WHITE8X8",
            edgeFile = "Interface/Buttons/WHITE8X8",
            edgeSize = 1,
        })
        button:SetBackdropColor(1, 1, 1, 0.06)
        button:SetBackdropBorderColor(1, 1, 1, 0.12)
        button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        button.label:SetPoint("CENTER", 0, 0)
        button.label:SetText(label)
        button:SetScript("OnEnter", function(self)
            self:SetBackdropColor(1, 1, 1, 0.15)
            self:SetBackdropBorderColor(1, 1, 1, 0.28)
        end)
        button:SetScript("OnLeave", function(self)
            self:SetBackdropColor(1, 1, 1, 0.06)
            self:SetBackdropBorderColor(1, 1, 1, 0.12)
        end)
        button:SetScript("OnMouseDown", function(self) self.label:SetPoint("CENTER", 0, -1) end)
        button:SetScript("OnMouseUp", function(self) self.label:SetPoint("CENTER", 0, 0) end)
        return button
    end

    local function CreateTab(label, tabKey)
        local button = CreateFrame("Button", nil, header)
        button:SetSize(68, HEADER_HEIGHT)
        button.tabKey = tabKey
        button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        button.label:SetPoint("CENTER", 0, 0)
        button.label:SetText(label)
        button.indicator = button:CreateTexture(nil, "OVERLAY")
        button.indicator:SetHeight(2)
        button.indicator:SetPoint("BOTTOMLEFT", 6, 0)
        button.indicator:SetPoint("BOTTOMRIGHT", -6, 0)
        button:SetScript("OnEnter", function(self) self.isHovered = true; EL:UpdateLootTabs() end)
        button:SetScript("OnLeave", function(self) self.isHovered = false; EL:UpdateLootTabs() end)
        button:SetScript("OnClick", function(self) EL:SetActiveTab(self.tabKey) end)
        return button
    end

    frame.tabs = {
        PERSONAL = CreateTab("Personal", "PERSONAL"),
        GROUP = CreateTab("Group", "GROUP"),
    }
    frame.tabs.PERSONAL:SetPoint("LEFT", 4, 0)
    frame.tabs.GROUP:SetPoint("LEFT", frame.tabs.PERSONAL, "RIGHT", 0, 0)

    local close = CreateModernButton(20, "X")
    close:SetPoint("RIGHT", -5, 0)
    close.label:SetFontObject("GameFontNormalSmall")
    close.label:ClearAllPoints()
    close.label:SetPoint("CENTER", 1, -1)
    close.label:SetTextColor(1.00, 0.82, 0.15, 1)
    close:SetBackdropColor(1, 1, 1, 0.05)
    close:SetBackdropBorderColor(1, 1, 1, 0.12)
    close:SetScript("OnEnter", function(self)
        self:SetBackdropColor(1, 0.25, 0.3, 0.20)
        self:SetBackdropBorderColor(1, 1, 1, 0.12)
    end)
    close:SetScript("OnLeave", function(self)
        self:SetBackdropColor(1, 1, 1, 0.05)
        self:SetBackdropBorderColor(1, 1, 1, 0.12)
    end)
    close:SetScript("OnMouseDown", function(self) self.label:SetPoint("CENTER", 1, -2) end)
    close:SetScript("OnMouseUp", function(self) self.label:SetPoint("CENTER", 1, -1) end)
    close:SetScript("OnClick", function() EL:SetLootWindowShown(false) end)

    local clear = CreateModernButton(52, "Clear")
    clear:SetPoint("RIGHT", close, "LEFT", -6, 0)
    AddPixelBorder(clear)
    clear:SetScript("OnClick", function() EL:ClearHistory() end)
    function clear:ApplyTheme()
        local theme = EL.themes[EL.db.theme] or EL.themes.battlenet
        local background = theme.button or { 1, 1, 1, 0.06 }
        local border = theme.buttonBorder or { 1, 1, 1, 0.12 }
        self:SetBackdropColor(unpack(background))
        self:SetBackdropBorderColor(0, 0, 0, 0)
        self:SetPixelBorderColor(unpack(border))
    end
    clear:SetScript("OnEnter", function(self)
        local theme = EL.themes[EL.db.theme] or EL.themes.battlenet
        local background = theme.buttonHover or { 1, 1, 1, 0.15 }
        local border = theme.buttonHoverBorder or { 1, 1, 1, 0.28 }
        self:SetBackdropColor(unpack(background))
        self:SetBackdropBorderColor(0, 0, 0, 0)
        self:SetPixelBorderColor(unpack(border))
    end)
    clear:SetScript("OnLeave", function(self) self:ApplyTheme() end)
    frame.clearButton = clear

    frame.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    frame.empty:SetJustifyH("CENTER")
    frame.empty:SetJustifyV("MIDDLE")
    frame.empty:SetWordWrap(true)
    frame.empty:SetSpacing(3)
    frame.empty:SetText("Looted items will appear here.")
    frame.rows = {}
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
        EL:PauseAutoCollapseForHover()
        EL:ScrollHistory(delta)
    end)
    frame:HookScript("OnEnter", function()
        EL:PauseAutoCollapseForHover()
    end)

    local resizeHandle = CreateFrame("Button", nil, frame)
    resizeHandle:SetSize(20, 20)
    resizeHandle:EnableMouse(true)
    resizeHandle:RegisterForDrag("LeftButton")
    resizeHandle.edgeH = resizeHandle:CreateTexture(nil, "OVERLAY")
    resizeHandle.edgeH:SetSize(12, 2)
    resizeHandle.edgeV = resizeHandle:CreateTexture(nil, "OVERLAY")
    resizeHandle.edgeV:SetSize(2, 10)
    resizeHandle.edgeH:Hide()
    resizeHandle.edgeV:Hide()
    local resizePulse = resizeHandle:CreateAnimationGroup()
    resizePulse:SetLooping("BOUNCE")
    local resizePulseAlpha = resizePulse:CreateAnimation("Alpha")
    resizePulseAlpha:SetFromAlpha(1)
    resizePulseAlpha:SetToAlpha(0.50)
    resizePulseAlpha:SetDuration(1.25)
    resizePulseAlpha:SetSmoothing("IN_OUT")
    local function SetResizeIconShown(shown)
        resizeHandle.edgeH:SetShown(shown)
        resizeHandle.edgeV:SetShown(shown)
    end
    function resizeHandle:UpdateUnlockedVisual()
        local unlocked = not EL.db.locked
        SetResizeIconShown(unlocked or self.dragging or self:IsMouseOver())
        if unlocked then
            if not resizePulse:IsPlaying() then resizePulse:Play() end
        else
            resizePulse:Stop()
            self:SetAlpha(1)
        end
    end
    resizeHandle:SetScript("OnEnter", function() SetResizeIconShown(true) end)
    resizeHandle:SetScript("OnLeave", function(self)
        if not self.dragging and EL.db.locked then SetResizeIconShown(false) end
    end)
    resizeHandle:SetScript("OnDragStart", function(self)
        if EL.db.locked then return end
        self.dragging = true
        EL.resizeDragging = true
        EL.autoCollapseHoverTab = EL.db.activeTab or "PERSONAL"
        EL:RefreshWindow()
        SetResizeIconShown(true)
        local cursorX, cursorY = GetCursorPosition()
        self.startCursorX = cursorX / frame:GetEffectiveScale()
        self.startCursorY = cursorY / frame:GetEffectiveScale()
        self.startWidth = frame:GetWidth()
        self.startItemCount = EL.db.maxItems
        self.refreshElapsed = 0
        self:SetScript("OnUpdate", function(handle, elapsed)
            handle.refreshElapsed = handle.refreshElapsed + elapsed
            if handle.refreshElapsed < (1 / 30) then return end
            handle.refreshElapsed = 0
            local currentX, currentY = GetCursorPosition()
            currentX = currentX / frame:GetEffectiveScale()
            currentY = currentY / frame:GetEffectiveScale()
            local width = math.max(20, math.min(500, handle.startWidth + currentX - handle.startCursorX))
            EL.db.windowWidth = math.floor((width / 5) + 0.5) * 5
            local verticalDelta = EL.db.growDirection == "UP"
                and (currentY - handle.startCursorY)
                or (handle.startCursorY - currentY)
            verticalDelta = math.max(
                (1 - handle.startItemCount) * ROW_HEIGHT,
                math.min((MAX_VISIBLE_ITEMS - handle.startItemCount) * ROW_HEIGHT, verticalDelta)
            )
            EL.db.maxItems = math.max(1, math.min(MAX_VISIBLE_ITEMS, math.floor(handle.startItemCount + (verticalDelta / ROW_HEIGHT) + 0.5)))
            EL:RefreshWindow()
        end)
    end)
    resizeHandle:SetScript("OnDragStop", function(self)
        self.dragging = false
        EL.resizeDragging = false
        self.refreshElapsed = 0
        self:SetScript("OnUpdate", nil)
        if not self:IsMouseOver() and EL.db.locked then SetResizeIconShown(false) end
        EL.autoCollapseHoverTab = nil
        EL:RefreshWindow()
    end)
    frame.resizeHandle = resizeHandle
    frame:SetFrameLevel(10)
    resizeHandle:SetFrameLevel(frame:GetFrameLevel() + 20)
    local collapseHoverArea = CreateFrame("Frame", nil, UIParent)
    collapseHoverArea:SetFrameStrata(frame:GetFrameStrata())
    collapseHoverArea:SetFrameLevel(9)
    collapseHoverArea:EnableMouse(true)
    collapseHoverArea:EnableMouseWheel(true)
    if collapseHoverArea.SetPropagateMouseClicks then collapseHoverArea:SetPropagateMouseClicks(true) end
    collapseHoverArea:SetScript("OnMouseWheel", function(_, delta)
        EL:PauseAutoCollapseForHover()
        EL:ScrollHistory(delta)
    end)
    collapseHoverArea:SetScript("OnEnter", function()
        EL:PauseAutoCollapseForHover()
    end)
    collapseHoverArea:Hide()
    frame.collapseHoverArea = collapseHoverArea
    frame:HookScript("OnHide", function()
        collapseHoverArea:Hide()
        EL.autoCollapseHoverTab = nil
        EL:CancelAutoCollapseTimer()
        if EL.autoCollapseHoverTicker then
            EL.autoCollapseHoverTicker:Cancel()
            EL.autoCollapseHoverTicker = nil
        end
    end)
    frame:HookScript("OnShow", function()
        EL:RefreshWindow()
    end)
    self.frame = frame
    frame:SetShown(self.db.windowShown ~= false)
end
