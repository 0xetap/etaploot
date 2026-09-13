local _, EL = ...

EL.ConfigPages = EL.ConfigPages or {}
local Controls = EL.ConfigControls
local AddTitle = Controls.AddTitle
local AddCheck = Controls.AddCheck
local AddSlider = Controls.AddSlider
local AddDropdown = Controls.AddDropdown

function EL.ConfigPages.CreateGeneral(context)
    local CreateScrollablePanel = context.CreateScrollablePanel
    local generalPage, general = CreateScrollablePanel(510)
    AddTitle(general, "General", -16)
    AddCheck(general, "Enable loot tracking", "enabled", -58, "Capture newly looted items.")
    AddCheck(general, "Show looted items", "showLootedItems", -92, "Display items received from loot sources.")
    AddCheck(general, "Show crafted items", "showCraftedItems", -126, "Display items created through professions.")
    AddCheck(general, "Enable speed loot", "speedLoot", -58, "Loot all available items without showing Blizzard's loot window.", 290)
    AddCheck(general, "Show minimap button", "showMinimapButton", -92, "Show a draggable shortcut beside the minimap.", 290)
    AddCheck(general, "Only show equippable items", "equippableOnly", -126, "Hide materials, consumables, and other non-equipment.", 290)
    EL.lockWindowToggle = AddCheck(general, "Lock the window", "locked", -58, "Prevent dragging the loot window.", 562)

    local appearanceLabel = general:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    appearanceLabel:SetPoint("TOPLEFT", 18, -182)
    appearanceLabel:SetText("Appearance")

    local themeLabel = general:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    themeLabel:SetPoint("TOPLEFT", 18, -224)
    themeLabel:SetText("Theme")
    AddDropdown(general, -246, 250, function()
        local options = {}
        for _, key in ipairs({ "class", "parchment", "midnight", "battlenet", "web3", "glass" }) do
            local info = EL.themes[key]
            if info then options[#options + 1] = { value = key, label = info.label } end
        end
        return options
    end, function() return EL.db.theme end, function(value)
        EL.db.theme = value
        EL:Refresh()
    end, 16)

    local growthLabel = general:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    growthLabel:SetPoint("TOPLEFT", 18, -306)
    growthLabel:SetText("Window growth direction")
    AddDropdown(general, -328, 250, function()
        return {
            { value = "DOWN", label = "Grow downward" },
            { value = "UP", label = "Grow upward" },
        }
    end, function() return EL.db.growDirection end, function(value)
        EL.db.growDirection = value
        EL:Refresh()
    end)

    local qualityLabel = general:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    qualityLabel:SetPoint("TOPLEFT", 18, -388)
    qualityLabel:SetText("Minimum item quality")
    AddDropdown(general, -410, 250, function()
        local options = {}
        for value = 0, 5 do
            local color = ITEM_QUALITY_COLORS[value]
            local label = color.hex .. _G["ITEM_QUALITY" .. value .. "_DESC"] .. "|r"
            options[#options + 1] = { value = value, label = label }
        end
        return options
    end, function() return EL.db.minimumQuality end, function(value)
        EL.db.minimumQuality = value
        EL:Refresh()
    end)
    AddSlider(general, "maxItems", -224, 1, 30, 1, "Visible items: %d", 292)
    AddSlider(general, "scale", -286, 0.1, 2, 0.1, "Window scale: %.1f", 292)
    AddSlider(general, "backgroundOpacity", -348, 0, 100, 1, "Background opacity: %d%%", 292)
    AddSlider(general, "windowWidth", -410, 20, 500, 5, "Window width: %d px", 292)
    AddSlider(general, "configScale", -224, 0.5, 1.5, 0.1, "Settings UI scale: %.1f", 562)
    AddCheck(general, "Show window border", "showWindowBorder", -300, "Show the themed border around the Recent Loot window.", 562)

    return { page = generalPage, panel = general, growthLabel = growthLabel, qualityLabel = qualityLabel, appearanceLabel = appearanceLabel, themeLabel = themeLabel }
end
