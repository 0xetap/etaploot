local _, EL = ...

EL.ConfigPageHelpers = EL.ConfigPageHelpers or {}
local AddCheck = EL.ConfigControls.AddCheck
local AddSlider = EL.ConfigControls.AddSlider

function EL.ConfigPageHelpers.AddAutoCollapseControls(panel, prefix, x, startY)
    local enabledKey = prefix .. "AutoCollapseEnabled"
    local fadeKey = prefix .. "AutoCollapseFade"
    local secondsKey = prefix .. "AutoCollapseSeconds"
    local enabledToggle = AddCheck(panel, "Auto-collapse loot rows", enabledKey, startY, "Shrink this loot tab by one row after each selected period of inactivity.", x)
    local fadeToggle = AddCheck(panel, "Fade rows before collapsing", fadeKey, startY - 36, "Softly fade each outgoing row before the window physically shrinks.", x)
    local secondsSlider = AddSlider(panel, secondsKey, startY - 84, 1, 60, 1, "Collapse delay: %d sec", x + 4)
    local function UpdateFadeAvailability()
        local enabled = EL.db[enabledKey] == true
        if not enabled then
            EL.db[fadeKey] = false
            fadeToggle:SetChecked(false)
            fadeToggle:ApplyTheme()
        end
        fadeToggle:SetEnabled(enabled)
        fadeToggle:SetAlpha(enabled and 1 or 0.38)
        secondsSlider:SetEnabled(enabled)
        secondsSlider:SetAlpha(enabled and 1 or 0.38)
    end
    enabledToggle:HookScript("OnClick", UpdateFadeAvailability)
    enabledToggle:HookScript("OnShow", UpdateFadeAvailability)
    UpdateFadeAvailability()
end

function EL.ConfigPageHelpers.AddSectionDescription(panel, text, x, y)
    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    description:SetPoint("TOPLEFT", x, y)
    description:SetWidth(300)
    description:SetJustifyH("LEFT")
    description:SetWordWrap(true)
    description:SetSpacing(2)
    description:SetTextColor(0.78, 0.79, 0.83, 1)
    description:SetText(text)
    return description
end


