local _, EL = ...

EL.ConfigPages = EL.ConfigPages or {}
local Controls = EL.ConfigControls
local AddTitle = Controls.AddTitle
local AddDropdown = Controls.AddDropdown

local SetPixelPoint = Controls.SetPixelPoint
local SetPixelSize = Controls.SetPixelSize
local AddUniformBorder = Controls.AddUniformBorder
local CreateCompactButton = Controls.CreateCompactButton

function EL.ConfigPages.CreateProfiles(context)
    local CreateScrollablePanel = context.CreateScrollablePanel
    local config = context.config
    local profilesPage, profiles = CreateScrollablePanel(430)
    AddTitle(profiles, "Profiles", -16)

    local activeProfileLabel = profiles:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    activeProfileLabel:SetPoint("TOPLEFT", 18, -64)
    activeProfileLabel:SetText("Active profile")
    local activeProfileName = profiles:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    activeProfileName:SetPoint("TOPLEFT", 18, -90)
    local profileDescription = profiles:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    profileDescription:SetPoint("TOPLEFT", 18, -126)
    profileDescription:SetPoint("RIGHT", -18, 0)
    profileDescription:SetJustifyH("LEFT")
    profileDescription:SetWordWrap(true)
    profileDescription:SetSpacing(3)
    profileDescription:SetTextColor(1, 1, 1, 1)
    profileDescription:SetText("Each character has its own profile. Activate a different profile to use its settings for the current profile. Loot history is always preserved for each character.")
    local UpdateProfilePage
    local activateProfileLabel = profiles:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    activateProfileLabel:SetPoint("TOPLEFT", 18, -180)
    activateProfileLabel:SetText("Activate profile")
    local activeProfileDropdown = AddDropdown(profiles, -204, 280, function()
        local options = {}
        for profileName in pairs((EL.rootDB and EL.rootDB.profiles) or {}) do
            options[#options + 1] = { value = profileName, label = profileName }
        end
        table.sort(options, function(a, b) return a.label < b.label end)
        return options
    end, function() return EL.profileKey end, function(value)
        if EL:ActivateProfile(value) then UpdateProfilePage() end
    end)

    local selectedSourceProfile
    local copyProfileLabel = profiles:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    copyProfileLabel:SetPoint("TOPLEFT", 18, -268)
    copyProfileLabel:SetText("Copy settings from")
    local sourceDropdown = AddDropdown(profiles, -292, 280, function()
        local options = {}
        for profileName in pairs((EL.rootDB and EL.rootDB.profiles) or {}) do
            if profileName ~= EL.profileKey then
                options[#options + 1] = { value = profileName, label = profileName }
            end
        end
        table.sort(options, function(a, b) return a.label < b.label end)
        return options
    end, function() return selectedSourceProfile end, function(value)
        selectedSourceProfile = value
    end)

    local function CreateConfirmation(message)
        local dialog = CreateFrame("Frame", nil, config, "BackdropTemplate")
        SetPixelSize(dialog, 360, 120)
        SetPixelPoint(dialog, "CENTER", config, "CENTER", 0, 0)
        dialog:SetFrameStrata("FULLSCREEN_DIALOG")
        dialog:SetFrameLevel(200)
        dialog:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8" })
        AddUniformBorder(dialog)
        dialog:Hide()
        local text = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("TOPLEFT", 28, -28)
        text:SetPoint("TOPRIGHT", -28, -28)
        text:SetJustifyH("CENTER")
        text:SetWordWrap(true)
        text:SetSpacing(3)
        text:SetText(message)
        local yes = CreateCompactButton(dialog, 92, "Yes")
        SetPixelPoint(yes, "BOTTOMRIGHT", dialog, "BOTTOM", -8, 18)
        local no = CreateCompactButton(dialog, 92, "No")
        SetPixelPoint(no, "BOTTOMLEFT", dialog, "BOTTOM", 8, 18)
        no:SetScript("OnClick", function() dialog:Hide() end)
        return dialog, yes, no
    end

    local copyConfirmation, yesButton, noButton = CreateConfirmation("Are you sure? This will overwrite your current settings with the settings of the selected profile.")
    yesButton:SetFrameLevel(copyConfirmation:GetFrameLevel() + 1)
    yesButton:RegisterForClicks("LeftButtonUp")
    noButton:SetFrameLevel(copyConfirmation:GetFrameLevel() + 1)
    noButton:RegisterForClicks("LeftButtonUp")
    yesButton:SetScript("OnClick", function()
        copyConfirmation:Hide()
        if selectedSourceProfile then EL:CopyProfileSettings(selectedSourceProfile) end
        UpdateProfilePage()
    end)

    local copyButton = CreateCompactButton(profiles, 100, "Copy")
    SetPixelPoint(copyButton, "TOPLEFT", profiles, "TOPLEFT", 314, -292)
    copyButton:SetScript("OnClick", function()
        if selectedSourceProfile then copyConfirmation:Show() end
    end)
    profiles.themeControls = profiles.themeControls or {}
    profiles.themeControls[#profiles.themeControls + 1] = copyButton
    profiles.themeControls[#profiles.themeControls + 1] = yesButton
    profiles.themeControls[#profiles.themeControls + 1] = noButton

    local resetConfirmation, resetYesButton, resetNoButton = CreateConfirmation("This will reset all settings to their default values. Are you sure?")
    resetYesButton:SetScript("OnClick", function()
        EL:ResetProfileSettings()
        resetConfirmation:Hide()
        local selectedPage = config.selectedPage
        if selectedPage then
            selectedPage:Hide()
            selectedPage:Show()
        end
        UpdateProfilePage()
    end)

    local resetButton = CreateCompactButton(profiles, 100, "Reset")
    SetPixelPoint(resetButton, "BOTTOMRIGHT", profiles, "BOTTOMRIGHT", -18, 18)
    resetButton.label:SetTextColor(1.00, 0.28, 0.28, 1)
    resetButton:SetScript("OnClick", function() resetConfirmation:Show() end)
    profiles.themeControls[#profiles.themeControls + 1] = resetButton
    profiles.themeControls[#profiles.themeControls + 1] = resetYesButton
    profiles.themeControls[#profiles.themeControls + 1] = resetNoButton

    UpdateProfilePage = function()
        activeProfileName:SetText(EL.profileKey or "Unknown")
        local classColor = EL.db.classFile and RAID_CLASS_COLORS[EL.db.classFile]
        activeProfileName:SetTextColor(
            classColor and classColor.r or 1,
            classColor and classColor.g or 1,
            classColor and classColor.b or 1
        )
        if selectedSourceProfile == EL.profileKey
            or not ((EL.rootDB and EL.rootDB.profiles) or {})[selectedSourceProfile] then
            selectedSourceProfile = nil
        end
        activeProfileDropdown.UpdateText()
        sourceDropdown.UpdateText()
    end
    profilesPage:SetScript("OnShow", UpdateProfilePage)


    return { page = profilesPage, panel = profiles, copyConfirmation = copyConfirmation, resetConfirmation = resetConfirmation, activeProfileLabel = activeProfileLabel, activateProfileLabel = activateProfileLabel, copyProfileLabel = copyProfileLabel }
end
