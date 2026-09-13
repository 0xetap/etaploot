local _, EL = ...

local AddCheck = EL.ConfigControls.AddCheck
local AddSlider = EL.ConfigControls.AddSlider

function EL.ConfigPages.CreatePersonal(context)
    local parts = EL.ConfigPages.CreateLootOptions(context, "personal")
    local styling = parts.panel
    local professionLabel = styling:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    professionLabel:SetPoint("TOPLEFT", 370, -58)
    professionLabel:SetText("Profession Indicators")
    EL.ConfigPageHelpers.AddSectionDescription(styling, "Customize profession proc and skill-up markers. Control profession messages, Knowledge, and Moxie currencies.", 370, -82)
    local showProcsToggle = AddCheck(styling, "Show profession procs", "showProfessionProcs", -126, "Show profession proc indicators in Personal loot and hide their matching chat messages.", 370)
    local procSizeSlider = AddSlider(styling, "personalProcFontSize", -166, 6, 22, 1, "Proc font size: %d", 374)
    local showSkillToggle = AddCheck(styling, "Show profession skill increase", "showProfessionSkillIncrease", -220, "Show profession skill-increase markers in Personal loot and hide their matching chat messages.", 370)
    local skillSizeSlider = AddSlider(styling, "personalSkillMarkerSize", -260, 8, 30, 1, "Skill marker size: %d", 374)
    AddCheck(styling, "Hide knowledge points", "hideKnowledgePoints", -332, "Hide received Midnight profession Knowledge currencies from Personal history.", 370)
    AddCheck(styling, "Hide profession currencies", "hideProfessionCurrencies", -366, "Hide Artisan profession Moxie currencies from Personal history.", 370)
    local function UpdateProfessionControlAvailability()
        local procsEnabled = EL.db.showProfessionProcs == true
        procSizeSlider:SetEnabled(procsEnabled)
        procSizeSlider:SetAlpha(procsEnabled and 1 or 0.38)
        local skillEnabled = EL.db.showProfessionSkillIncrease == true
        skillSizeSlider:SetEnabled(skillEnabled)
        skillSizeSlider:SetAlpha(skillEnabled and 1 or 0.38)
    end
    showProcsToggle:HookScript("OnClick", UpdateProfessionControlAvailability)
    showProcsToggle:HookScript("OnShow", UpdateProfessionControlAvailability)
    showSkillToggle:HookScript("OnClick", UpdateProfessionControlAvailability)
    showSkillToggle:HookScript("OnShow", UpdateProfessionControlAvailability)
    UpdateProfessionControlAvailability()
    parts.professionLabel = professionLabel
    return parts
end
