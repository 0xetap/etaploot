local _, EL = ...

local ROW_HEIGHT = EL.UI.ROW_HEIGHT

local function GetItemTooltipAnchor(window)
    local left = window:GetLeft()
    local right = window:GetRight()
    local screenWidth = UIParent:GetWidth()
    if not left or not right or not screenWidth then return "ANCHOR_RIGHT" end
    local windowScale = window:GetEffectiveScale()
    local screenScale = UIParent:GetEffectiveScale()
    local spaceOnLeft = left * windowScale
    local spaceOnRight = (screenWidth * screenScale) - (right * windowScale)
    return spaceOnRight >= spaceOnLeft and "ANCHOR_RIGHT" or "ANCHOR_LEFT"
end

local function HideOwnedItemTooltip(row)
    row:SetScript("OnUpdate", nil)
    if GameTooltip:IsOwned(row) then GameTooltip:Hide() end
end

local function ShowGroupWhisperPrompt(row)
    local popup = EL.whisperPrompt
    if not popup then
        popup = CreateFrame("Button", "EtapLootWhisperPrompt", UIParent, "BackdropTemplate")
        popup:SetHeight(34)
        popup:SetFrameStrata("DIALOG")
        popup:SetClampedToScreen(true)
        popup:SetBackdrop({
            bgFile = "Interface/Buttons/WHITE8X8",
            edgeFile = "Interface/Buttons/WHITE8X8",
            edgeSize = 1,
        })
        popup.text = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        popup.text:SetPoint("CENTER")
        popup:SetScript("OnClick", function(self)
            if self.playerName and ChatFrame_SendTell then ChatFrame_SendTell(self.playerName) end
            self:Hide()
        end)
        popup:SetScript("OnEnter", function(self)
            local accent = (EL.themes[EL.db.theme] or EL.themes.battlenet).accent
            self:SetBackdropBorderColor(accent[1], accent[2], accent[3], 1)
        end)
        popup:SetScript("OnLeave", function(self)
            local border = (EL.themes[EL.db.theme] or EL.themes.battlenet).border
            self:SetBackdropBorderColor(unpack(border))
        end)
        popup:SetScript("OnShow", function(self)
            self.mouseWasDown = IsMouseButtonDown("LeftButton")
                or IsMouseButtonDown("RightButton")
                or IsMouseButtonDown("MiddleButton")
        end)
        popup:SetScript("OnUpdate", function(self)
            local mouseIsDown = IsMouseButtonDown("LeftButton")
                or IsMouseButtonDown("RightButton")
                or IsMouseButtonDown("MiddleButton")
            if mouseIsDown and not self.mouseWasDown then
                local overOwner = self.ownerRow and self.ownerRow:IsMouseOver()
                if not self:IsMouseOver() and not overOwner then self:Hide() end
            end
            self.mouseWasDown = mouseIsDown
        end)
        popup:SetScript("OnHide", function(self)
            self.ownerRow = nil
            self.playerName = nil
            self.mouseWasDown = false
        end)
        popup:Hide()
        table.insert(UISpecialFrames, popup:GetName())
        EL.whisperPrompt = popup
    elseif popup:IsShown() and popup.ownerRow == row then
        popup:Hide()
        return
    end

    local theme = EL.themes[EL.db.theme] or EL.themes.battlenet
    GameTooltip:Hide()
    popup.ownerRow = row
    popup.playerName = row.recipient
    local lootFont, _, lootFlags = GameFontHighlightSmall:GetFont()
    local lootFontSize = EL.db.groupLootFontSize or 12
    popup.text:SetFont(lootFont, lootFontSize, lootFlags)
    popup.text:SetText("Whisper " .. row.recipient)
    popup:SetWidth(math.max(140, popup.text:GetStringWidth() + 28))
    popup:SetHeight(math.max(34, lootFontSize + 16))
    popup:SetBackdropColor(theme.header[1], theme.header[2], theme.header[3], 0.98)
    popup:SetBackdropBorderColor(unpack(theme.border))
    popup:ClearAllPoints()
    if GetItemTooltipAnchor(EL.frame) == "ANCHOR_RIGHT" then
        popup:SetPoint("LEFT", row, "RIGHT", 8, 0)
    else
        popup:SetPoint("RIGHT", row, "LEFT", -8, 0)
    end
    popup:Show()
end

function EL:CreateLootRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:RegisterForClicks("LeftButtonUp")
    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel", function(_, delta)
        EL:PauseAutoCollapseForHover()
        EL:ScrollHistory(delta)
    end)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(24, 24)
    row.icon:SetPoint("LEFT", 2, 0)

    row.badge = CreateFrame("Frame", nil, row)
    row.badge:SetHeight(20)
    row.badge.text = row.badge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.badge.text:SetPoint("CENTER", 0, 0)
    local badgeFont, badgeSize, badgeFlags = GameFontHighlightSmall:GetFont()
    row.badge.font = badgeFont
    row.badge.fontFlags = badgeFlags
    row.badge.text:SetFont(badgeFont, math.max(6, badgeSize - 2), badgeFlags)
    row.badge.procFade = row.badge:CreateAnimationGroup()
    row.badge.procFade.alpha = row.badge.procFade:CreateAnimation("Alpha")
    row.badge.procFade.alpha:SetSmoothing("IN_OUT")
    row.badge.procFade:SetScript("OnFinished", function()
        row.badge:SetAlpha(0)
        EL:RefreshWindow()
    end)
    row.badge.skillArrow = row.badge:CreateTexture(nil, "OVERLAY")
    row.badge.skillArrow:SetPoint("CENTER")
    row.badge.skillArrow:SetSize(12, 14)
    row.badge.skillArrow:Hide()

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("RIGHT", -4, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    row.text:SetMaxLines(1)

    -- Keep stack counts separate from the item link so the item name can be
    -- truncated without ever hiding the quantity.
    row.quantity = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.quantity:SetJustifyH("RIGHT")
    row.quantity:SetWordWrap(false)
    row.quantity:SetMaxLines(1)

    row.sellPrice = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.sellPrice:SetPoint("RIGHT", -4, 0)
    row.sellPrice:SetJustifyH("RIGHT")

    row:SetScript("OnEnter", function(self)
        self:SetScript("OnUpdate", nil)
        EL:PauseAutoCollapseForHover()
        if EL.whisperPrompt and EL.whisperPrompt:IsShown() then return end
        if not self.itemLink then return end
        GameTooltip:SetOwner(self, GetItemTooltipAnchor(parent))
        GameTooltip:SetHyperlink(self.itemLink)
        if self.recipient then
            GameTooltip:AddLine(" ")
            local classColor = self.recipientClass and RAID_CLASS_COLORS[self.recipientClass]
            GameTooltip:AddDoubleLine(
                "Looted by",
                self.recipient,
                0.65, 0.68, 0.74,
                classColor and classColor.r or 0.95,
                classColor and classColor.g or 0.95,
                classColor and classColor.b or 1
            )
        end
        if self.bonusSource == "BONUS_ROLL" then
            GameTooltip:AddLine("Bonus Roll!", 1.00, 0.78, 0.24)
        end
        GameTooltip:Show()
        self:SetScript("OnUpdate", function(owner)
            if not owner:IsMouseOver() then HideOwnedItemTooltip(owner) end
        end)
    end)
    row:SetScript("OnLeave", HideOwnedItemTooltip)
    row:SetScript("OnClick", function(self, mouseButton)
        if self.itemLink and IsModifiedClick("CHATLINK") then
            ChatEdit_InsertLink(self.itemLink)
        elseif mouseButton == "LeftButton" and self.recipient then
            ShowGroupWhisperPrompt(self)
        end
    end)
    return row
end
