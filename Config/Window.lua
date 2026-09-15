local ADDON_NAME, EL = ...
local GITHUB_URL = "https://github.com/0xetap/etaploot"

local Controls = EL.ConfigControls
local CurrentTheme = Controls.CurrentTheme
local SetPixelPoint = Controls.SetPixelPoint
local SetPixelSize = Controls.SetPixelSize
local SnapConfigWindow = Controls.SnapConfigWindow
local AddUniformBorder = Controls.AddUniformBorder
local CreateCompactButton = Controls.CreateCompactButton

function EL:CreateConfig()
    local config = CreateFrame("Frame", "EtapLootConfigWindow", UIParent, "BackdropTemplate")
    SetPixelSize(config, 1024, 576)
    SetPixelPoint(config, "CENTER", UIParent, "CENTER", 0, 0)
    config:SetFrameStrata("DIALOG")
    config:SetToplevel(true)
    config:SetClampedToScreen(true)
    config:SetMovable(true)
    config:EnableMouse(true)
    config:RegisterForDrag("LeftButton")
    config:SetScript("OnDragStart", config.StartMoving)
    config:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SnapConfigWindow(self)
    end)
    config:SetScript("OnShow", function(self) SnapConfigWindow(self) end)
    config:RegisterEvent("UI_SCALE_CHANGED")
    config:RegisterEvent("DISPLAY_SIZE_CHANGED")
    config:SetScript("OnEvent", function(self)
        C_Timer.After(0, function() SnapConfigWindow(self) end)
    end)
    config:SetBackdrop({
        bgFile = "Interface/Buttons/WHITE8X8",
        edgeFile = "Interface/Buttons/WHITE8X8",
        edgeSize = 1,
    })
    config:SetBackdropColor(0.025, 0.03, 0.045, 0.98)
    config:SetBackdropBorderColor(0.24, 0.28, 0.36, 1)
    config:Hide()

    local header = CreateFrame("Frame", nil, config, "BackdropTemplate")
    SetPixelPoint(header, "TOPLEFT", config, "TOPLEFT", 1, -1)
    SetPixelPoint(header, "TOPRIGHT", config, "TOPRIGHT", -1, -1)
    if PixelUtil then PixelUtil.SetHeight(header, 27) else header:SetHeight(27) end
    header:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8" })
    header:SetBackdropColor(0.055, 0.065, 0.09, 1)
    local headerIcon = header:CreateVectorGraphics(nil, "OVERLAY")
    SetPixelSize(headerIcon, 18, 18)
    SetPixelPoint(headerIcon, "LEFT", header, "LEFT", 8, 0)
    headerIcon:SetSVG("Interface\\AddOns\\EtapLoot\\Media\\EtapLootIcon.svg")
    local logo = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    logo:SetPoint("LEFT", headerIcon, "RIGHT", 6, 0)
    logo:SetJustifyH("CENTER")
    logo:SetJustifyV("MIDDLE")
    logo:SetText("EtapLoot")
    logo:SetTextColor(0.58, 0.76, 0.86)
    local subtitle = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    -- The nav/options split sits 180 pixels from the header's left edge.
    -- Match the logo's 8-pixel inset on the options side of that split.
    subtitle:SetPoint("LEFT", header, "LEFT", 188, 0)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetJustifyV("MIDDLE")
    subtitle:SetText("Track personal and group loot at a glance. Meow.")

    local close = CreateFrame("Button", nil, header, "BackdropTemplate")
    SetPixelSize(close, 20, 19)
    SetPixelPoint(close, "RIGHT", header, "RIGHT", -5, 0)
    close:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8", edgeFile = "Interface/Buttons/WHITE8X8", edgeSize = 1 })
    close:SetBackdropColor(1, 1, 1, 0.05)
    close:SetBackdropBorderColor(1, 1, 1, 0.12)
    close.text = close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    close.text:SetPoint("CENTER", close, "CENTER", 1, -1)
    close.text:SetJustifyH("CENTER")
    close.text:SetJustifyV("MIDDLE")
    -- Keep this ASCII-only; encoded multiplication glyphs are not stable
    -- across the game client's file-decoding paths.
    close.text:SetText("X")
    close.text:SetTextColor(1.00, 0.82, 0.15, 1)
    close:SetScript("OnEnter", function(self) self:SetBackdropColor(1, 0.25, 0.3, 0.20) end)
    close:SetScript("OnLeave", function(self) self:SetBackdropColor(1, 1, 1, 0.05) end)
    close:SetScript("OnClick", function() config:Hide() end)

    local sidebar = CreateFrame("Frame", nil, config, "BackdropTemplate")
    SetPixelPoint(sidebar, "TOPLEFT", config, "TOPLEFT", 1, -28)
    SetPixelPoint(sidebar, "BOTTOMLEFT", config, "BOTTOMLEFT", 1, 1)
    if PixelUtil then PixelUtil.SetWidth(sidebar, 180) else sidebar:SetWidth(180) end
    sidebar:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8" })
    sidebar:SetBackdropColor(0.02, 0.025, 0.04, 0.92)

    local function CreateScrollablePanel(contentHeight)
        local scroll = CreateFrame("ScrollFrame", nil, config)
        SetPixelPoint(scroll, "TOPLEFT", sidebar, "TOPRIGHT", 12, -5)
        SetPixelPoint(scroll, "BOTTOMRIGHT", config, "BOTTOMRIGHT", -12, 10)
        scroll:EnableMouseWheel(true)
        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(820, contentHeight)
        scroll:SetScrollChild(content)
        scroll:SetScript("OnSizeChanged", function(self, width, height)
            content:SetWidth(width)
            content:SetHeight(math.max(contentHeight, height))
            self:SetVerticalScroll(math.min(self:GetVerticalScroll(), math.max(0, content:GetHeight() - height)))
        end)
        scroll:SetScript("OnMouseWheel", function(self, delta)
            local range = math.max(0, content:GetHeight() - self:GetHeight())
            self:SetVerticalScroll(math.max(0, math.min(range, self:GetVerticalScroll() - (delta * 36))))
        end)
        scroll:Hide()
        return scroll, content
    end


    local pageContext = { config = config, CreateScrollablePanel = CreateScrollablePanel }
    local generalParts = EL.ConfigPages.CreateGeneral(pageContext)
    local consolidationParts = EL.ConfigPages.CreateConsolidation(pageContext)
    local profilesParts = EL.ConfigPages.CreateProfiles(pageContext)
    local personalParts = EL.ConfigPages.CreatePersonal(pageContext)
    local groupParts = EL.ConfigPages.CreateLootOptions(pageContext, "group")

    local generalPage, general = generalParts.page, generalParts.panel
    local growthLabel, qualityLabel = generalParts.growthLabel, generalParts.qualityLabel
    local appearanceLabel, themeLabel = generalParts.appearanceLabel, generalParts.themeLabel
    local consolidationPage, consolidation = consolidationParts.page, consolidationParts.panel
    local profilesPage, profiles = profilesParts.page, profilesParts.panel
    local copyConfirmation, resetConfirmation = profilesParts.copyConfirmation, profilesParts.resetConfirmation
    local activeProfileLabel = profilesParts.activeProfileLabel
    local activateProfileLabel, copyProfileLabel = profilesParts.activateProfileLabel, profilesParts.copyProfileLabel
    local stylingPage, styling = personalParts.page, personalParts.panel
    local personalDisplayLabel, personalValueLabel = personalParts.displayLabel, personalParts.valueLabel
    local personalProfessionLabel, personalCollapseLabel = personalParts.professionLabel, personalParts.collapseLabel
    local personalSellModeLabel = personalParts.sellModeLabel
    local groupStylingPage, groupStyling = groupParts.page, groupParts.panel
    local groupDisplayLabel, groupValueLabel = groupParts.displayLabel, groupParts.valueLabel
    local groupCollapseLabel, groupSellModeLabel = groupParts.collapseLabel, groupParts.sellModeLabel

    local navIconFiles = {
        general = "NavGeneral.svg",
        personal = "NavPersonalLoot.svg",
        group = "NavGroupLoot.svg",
        consolidation = "NavConsolidation.svg",
        profiles = "NavProfiles.svg",
    }

    local function CreateNavIcon(parent, kind)
        local icon = parent:CreateVectorGraphics(nil, "ARTWORK")
        SetPixelSize(icon, 18, 18)
        SetPixelPoint(icon, "LEFT", parent, "LEFT", 15, 0)
        icon:SetSVG("Interface\\AddOns\\EtapLoot\\Media\\" .. navIconFiles[kind])
        return icon
    end

    local tabs = {}
    local function SelectPage(page)
        generalPage:SetShown(page == generalPage)
        consolidationPage:SetShown(page == consolidationPage)
        profilesPage:SetShown(page == profilesPage)
        stylingPage:SetShown(page == stylingPage)
        groupStylingPage:SetShown(page == groupStylingPage)
        for _, tab in ipairs(tabs) do
            local selected = tab.page == page
            tab:ApplySelectionTheme(selected)
        end
        config.selectedPage = page
    end

    local function CreateTab(text, page, y, iconKind)
        local tab = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        SetPixelPoint(tab, "TOPLEFT", sidebar, "TOPLEFT", 0, y)
        SetPixelPoint(tab, "TOPRIGHT", sidebar, "TOPRIGHT", 0, y)
        if PixelUtil then PixelUtil.SetHeight(tab, 34) else tab:SetHeight(34) end
        tab:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8" })
        tab.indicator = tab:CreateTexture(nil, "OVERLAY", nil, 0)
        tab.indicator:SetTexture("Interface/Buttons/WHITE8X8")
        SetPixelPoint(tab.indicator, "TOPLEFT", tab, "TOPLEFT", 4, -3)
        SetPixelPoint(tab.indicator, "BOTTOMLEFT", tab, "BOTTOMLEFT", 4, 3)
        if PixelUtil then PixelUtil.SetWidth(tab.indicator, 3) else tab.indicator:SetWidth(3) end
        tab.indicator:Hide()
        tab.icon = CreateNavIcon(tab, iconKind)
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        tab.text:SetPoint("LEFT", 39, 0)
        tab.text:SetText(text)
        tab.page = page
        function tab:ApplySelectionTheme(selected)
            local theme = CurrentTheme()
            self:SetBackdropColor(1, 1, 1, 0)
            if selected then
                self.text:SetTextColor(theme.accent[1], theme.accent[2], theme.accent[3], 1)
                self.icon:SetAlpha(1)
                self.indicator:SetColorTexture(theme.accent[1], theme.accent[2], theme.accent[3], 1)
                self.indicator:Show()
            else
                self.text:SetTextColor(0.68, 0.68, 0.72, 1)
                self.icon:SetAlpha(0.58)
                self.indicator:Hide()
            end
        end
        tab:SetScript("OnClick", function() SelectPage(page) end)
        tab:SetScript("OnEnter", function(self)
            if config.selectedPage ~= page then
                local theme = CurrentTheme()
                self:SetBackdropColor(theme.background[1], theme.background[2], theme.background[3], 0.35)
            end
        end)
        tab:SetScript("OnLeave", function(self) self:ApplySelectionTheme(config.selectedPage == page) end)
        tabs[#tabs + 1] = tab
        return tab
    end

    CreateTab("General", generalPage, -12, "general")
    CreateTab("Personal Loot Options", stylingPage, -52, "personal")
    CreateTab("Group Loot Options", groupStylingPage, -92, "group")
    CreateTab("Loot Consolidation", consolidationPage, -132, "consolidation")
    CreateTab("Profiles", profilesPage, -172, "profiles")
    SelectPage(generalPage)

    local installedVersion = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "Development"
    local version = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    version:SetPoint("BOTTOM", 0, 52)
    version:SetText("Version " .. installedVersion)

    local githubPopup = CreateFrame("Frame", nil, config, "BackdropTemplate")
    SetPixelSize(githubPopup, 430, 128)
    SetPixelPoint(githubPopup, "CENTER", config, "CENTER", 0, 0)
    githubPopup:SetFrameStrata("FULLSCREEN_DIALOG")
    githubPopup:SetFrameLevel(200)
    githubPopup:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8" })
    AddUniformBorder(githubPopup)
    githubPopup:Hide()

    local githubPopupTitle = githubPopup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    githubPopupTitle:SetPoint("TOP", 0, -16)
    githubPopupTitle:SetText("EtapLoot on GitHub - copy this address:")

    local githubUrlBox = CreateFrame("EditBox", nil, githubPopup, "BackdropTemplate")
    SetPixelSize(githubUrlBox, 388, 26)
    SetPixelPoint(githubUrlBox, "TOP", githubPopup, "TOP", 0, -40)
    githubUrlBox:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8" })
    AddUniformBorder(githubUrlBox)
    githubUrlBox:SetFontObject(GameFontDisableSmall)
    githubUrlBox:SetTextColor(1, 1, 1, 1)
    githubUrlBox:SetTextInsets(8, 8, 0, 0)
    githubUrlBox:SetJustifyH("CENTER")
    githubUrlBox:SetAutoFocus(false)
    githubUrlBox:SetText(GITHUB_URL)
    githubUrlBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    githubUrlBox:SetScript("OnMouseUp", function(self) self:HighlightText() end)
    githubUrlBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        githubPopup:Hide()
    end)
    config:HookScript("OnHide", function() githubPopup:Hide() end)

    local githubCloseButton = CreateCompactButton(githubPopup, 92, "Close")
    SetPixelPoint(githubCloseButton, "BOTTOM", githubPopup, "BOTTOM", 0, 12)
    githubCloseButton:SetScript("OnClick", function()
        githubUrlBox:ClearFocus()
        githubPopup:Hide()
    end)

    local githubButton = CreateCompactButton(sidebar, 156, "")
    SetPixelPoint(githubButton, "BOTTOM", sidebar, "BOTTOM", 0, 12)
    githubButton.label:Hide()
    githubButton.icon = githubButton:CreateTexture(nil, "OVERLAY")
    SetPixelSize(githubButton.icon, 18.4, 18)
    githubButton.icon:SetPoint("CENTER")
    githubButton.icon:SetTexture("Interface\\AddOns\\EtapLoot\\Media\\GitHubMark.png")
    githubButton:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("EtapLoot on GitHub", 1, 1, 1)
        GameTooltip:AddLine("Click to copy the repository address.", 0.75, 0.75, 0.8)
        GameTooltip:Show()
    end)
    githubButton:HookScript("OnLeave", function() GameTooltip:Hide() end)
    githubButton:SetScript("OnClick", function()
        githubPopup:Show()
        githubPopup:Raise()
        githubUrlBox:SetText(GITHUB_URL)
        githubUrlBox:SetFocus()
        githubUrlBox:HighlightText()
    end)

    self.configFrame = config
    self.generalPanel = general
    self.consolidationPanel = consolidation
    self.profilesPanel = profiles
    self.stylingPanel = styling
    self.groupStylingPanel = groupStyling
    config.themeParts = {
        header = header,
        sidebar = sidebar,
        logo = logo,
        subtitle = subtitle,
        closeLabel = close.text,
        githubButton = githubButton,
        githubCloseButton = githubCloseButton,
        githubPopup = githubPopup,
        githubUrlBox = githubUrlBox,
        copyConfirmation = copyConfirmation,
        resetConfirmation = resetConfirmation,
        tabs = tabs,
        labels = {
            growthLabel, qualityLabel, appearanceLabel, themeLabel,
            personalDisplayLabel, personalValueLabel, personalProfessionLabel, personalCollapseLabel,
            groupDisplayLabel, groupValueLabel, groupCollapseLabel,
            personalSellModeLabel, groupSellModeLabel,
            activeProfileLabel, activateProfileLabel, copyProfileLabel,
        },
    }
    table.insert(UISpecialFrames, config:GetName())
    self:ApplyConfigTheme()
end

function EL:ApplyConfigTheme()
    local config = self.configFrame
    if not config or not self.db then return end
    local theme = self.themes[self.db.theme] or self.themes.battlenet
    local parts = config.themeParts
    local background, header, accent, border = theme.background, theme.header, theme.accent, theme.border
    if not self.configScaleDragging then config:SetScale(self.db.configScale or 1) end

    local surfaceAlpha = 0.80
    config:SetBackdropColor(background[1], background[2], background[3], surfaceAlpha)
    config:SetBackdropBorderColor(unpack(border))
    parts.header:SetBackdropColor(header[1], header[2], header[3], surfaceAlpha)
    parts.sidebar:SetBackdropColor(background[1] * 0.72, background[2] * 0.72, background[3] * 0.72, surfaceAlpha)
    parts.logo:SetTextColor(unpack(accent))
    parts.subtitle:SetTextColor(accent[1], accent[2], accent[3], 0.72)
    parts.githubButton:ApplyTheme()
    parts.githubCloseButton:ApplyTheme()
    parts.githubPopup:SetBackdropColor(background[1], background[2], background[3], 0.98)
    parts.githubPopup:SetUniformBorderColor(border[1], border[2], border[3], 0.55)
    parts.githubUrlBox:SetBackdropColor(header[1], header[2], header[3], 0.96)
    parts.githubUrlBox:SetUniformBorderColor(border[1], border[2], border[3], 0.55)
    for _, label in ipairs(parts.labels) do label:SetTextColor(unpack(accent)) end
    parts.closeLabel:SetTextColor(1.00, 0.82, 0.15, 1)
    parts.copyConfirmation:SetBackdropColor(background[1], background[2], background[3], 0.98)
    parts.copyConfirmation:SetUniformBorderColor(border[1], border[2], border[3], 0.55)
    parts.resetConfirmation:SetBackdropColor(background[1], background[2], background[3], 0.98)
    parts.resetConfirmation:SetUniformBorderColor(border[1], border[2], border[3], 0.55)

    for _, panel in ipairs({ self.generalPanel, self.consolidationPanel, self.profilesPanel, self.stylingPanel, self.groupStylingPanel }) do
        if panel.pageTitle then panel.pageTitle:SetTextColor(unpack(accent)) end
        for _, control in ipairs(panel.themeControls or {}) do
            if control.ApplyTheme then control:ApplyTheme() end
        end
    end
    for _, tab in ipairs(parts.tabs) do
        tab:ApplySelectionTheme(tab.page == config.selectedPage)
    end
end

function EL:OpenConfig()
    if not self.configFrame then self:CreateConfig() end
    if not self.configFrame then return end
    self.configFrame:Show()
    self.configFrame:Raise()
end
