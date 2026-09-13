local _, EL = ...

EL.ConfigPages = EL.ConfigPages or {}
local Controls = EL.ConfigControls
local AddTitle = Controls.AddTitle
local AddCheck = Controls.AddCheck
local AddSlider = Controls.AddSlider

function EL.ConfigPages.CreateConsolidation(context)
    local CreateScrollablePanel = context.CreateScrollablePanel
    local consolidationPage, consolidation = CreateScrollablePanel(390)
    AddTitle(consolidation, "Loot Consolidation", -16)
    AddCheck(consolidation, "Consolidate matching loot", "consolidateLoot", -62, "Combine repeated drops of the same item and quality.")
    local consolidationDescription = consolidation:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    consolidationDescription:SetPoint("TOPLEFT", 18, -104)
    consolidationDescription:SetPoint("RIGHT", -18, 0)
    consolidationDescription:SetJustifyH("LEFT")
    consolidationDescription:SetWordWrap(true)
    consolidationDescription:SetSpacing(3)
    consolidationDescription:SetTextColor(1, 1, 1, 1)
    consolidationDescription:SetText("When enabled, repeated loot of the same item type and quality is combined into one row. The quantity increases whenever a matching item is received within the timeframe selected below. Once the timeframe is exceeded, any acquired items start in a new row.")

    local secondsToggle = AddCheck(consolidation, "Use seconds", "consolidationUseSeconds", -170, "Consolidate loot received within the selected number of seconds.")
    AddSlider(consolidation, "consolidationSeconds", -214, 1, 60, 1, "Seconds: %d", 22)
    local minutesToggle = AddCheck(consolidation, "Use minutes", "consolidationUseMinutes", -170, "Consolidate loot received within the selected number of minutes.", 370)
    AddSlider(consolidation, "consolidationMinutes", -214, 1, 120, 1, "Minutes: %d", 374)

    local function SelectConsolidationUnit(useSeconds)
        EL.db.consolidationUseSeconds = useSeconds
        EL.db.consolidationUseMinutes = not useSeconds
        secondsToggle:SetChecked(useSeconds)
        minutesToggle:SetChecked(not useSeconds)
        secondsToggle:ApplyTheme()
        minutesToggle:ApplyTheme()
    end
    secondsToggle:SetScript("OnClick", function() SelectConsolidationUnit(true) end)
    minutesToggle:SetScript("OnClick", function() SelectConsolidationUnit(false) end)

    return { page = consolidationPage, panel = consolidation }
end
