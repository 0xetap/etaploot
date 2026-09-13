local _, EL = ...

local Controls = EL.ConfigControls
local AddTitle = Controls.AddTitle
local AddCheck = Controls.AddCheck
local AddSlider = Controls.AddSlider
local AddDropdown = Controls.AddDropdown
local AddSectionDescription = EL.ConfigPageHelpers.AddSectionDescription

-- Both tabs share their layout and controls; only the saved-setting prefix
-- and Personal's extra money toggle differ. Profession controls are added
-- separately by Personal.lua.
function EL.ConfigPages.CreateLootOptions(context, prefix)
    local personal = prefix == "personal"
    local page, panel = context.CreateScrollablePanel(688)
    AddTitle(panel, personal and "Personal Loot Options" or "Group Loot Options", -16)

    local function Section(text, x, y, description)
        local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("TOPLEFT", x, y)
        label:SetText(text)
        AddSectionDescription(panel, description, x, y - 24)
        return label
    end

    local function SettingDropdown(y, suffix, options)
        local key = prefix .. suffix
        return AddDropdown(panel, y, 250, function() return options end,
            function() return EL.db[key] end, function(value)
                EL.db[key] = value
                EL:Refresh()
            end)
    end

    local displayLabel = Section("Item Display", 18, -58, "Choose how loot entries are presented, including text, icons, quantities, quality sorting, and timestamps.")
    AddSlider(panel, prefix .. "LootFontSize", -126, 8, 24, 1, "Loot font size: %d")
    AddCheck(panel, "Show item icons", prefix .. "ShowIcon", -180, "Display icons beside " .. prefix .. " items.")
    AddCheck(panel, "Show stack quantities", prefix .. "ShowQuantity", -214, "Show " .. prefix .. " stack quantities greater than one.")
    if personal then
        AddCheck(panel, "Show money received", "personalShowMoney", -248, "Show positive money gains from loot, vendor sales, quest rewards, and mail.")
    end
    local offset = personal and -34 or 0
    AddCheck(panel, "Show item quality indicators", prefix .. "ShowItemQuality", -248 + offset, "Show profession-quality markers embedded in " .. prefix .. " item links.")
    AddCheck(panel, "Sort loot by item quality", prefix .. "SortLootByQuality", -282 + offset, "Show higher-quality " .. prefix .. " loot first while preserving loot order within each quality.")
    local showTime = AddCheck(panel, "Show loot time", prefix .. "ShowTime", -316 + offset, "Display the time each " .. prefix .. " item was received.")
    local timeFormat = SettingDropdown(-346 + offset, "TimeFormat", {
        { value = "12H", label = "12-hour time" }, { value = "24H", label = "24-hour time" },
    })
    local function UpdateTimeFormat()
        local enabled = EL.db[prefix .. "ShowTime"] == true
        timeFormat:SetEnabled(enabled)
        timeFormat:SetAlpha(enabled and 1 or 0.38)
    end
    showTime:HookScript("OnClick", UpdateTimeFormat)
    showTime:HookScript("OnShow", UpdateTimeFormat)
    UpdateTimeFormat()

    local valueLabel = Section("Vendor Values", 18, -438, "Show vendor sell prices and choose their denominations and text size.")
    AddCheck(panel, "Show vendor sell prices", prefix .. "ShowSellPrice", -498, "Show vendor values for " .. prefix .. " loot.")
    local sellModeLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    sellModeLabel:SetPoint("TOPLEFT", 18, -536)
    sellModeLabel:SetText("Sell price denominations")
    SettingDropdown(-556, "SellPriceMode", {
        { value = "ALL", label = "Gold, silver, and copper" },
        { value = "GOLD_SILVER", label = "Gold and silver" },
        { value = "GOLD", label = "Gold only" },
    })
    AddSlider(panel, prefix .. "SellPriceFontSize", -610, 6, 24, 1, "Sell price font size: %d")

    local collapseLabel = Section("Auto-Collapse", 370, -438, "Automatically shrink the loot window after a period of inactivity. Rows can fade before being removed.")
    EL.ConfigPageHelpers.AddAutoCollapseControls(panel, prefix, 370, -510)
    return { page = page, panel = panel, displayLabel = displayLabel, valueLabel = valueLabel, collapseLabel = collapseLabel, sellModeLabel = sellModeLabel }
end
