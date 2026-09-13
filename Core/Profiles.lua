local _, EL = ...

local defaults = EL.defaults
local CURRENT_DATABASE_VERSION = 2

local function CopyDefaults(source, target)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            CopyDefaults(value, target[key])
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local function CopyValue(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, child in pairs(value) do copy[key] = CopyValue(child) end
    return copy
end

local function Clamp(value, minimum, maximum, fallback)
    return math.max(minimum, math.min(maximum, tonumber(value) or fallback))
end

local function GetCharacterProfileKey()
    local name, realm = UnitFullName("player")
    name = name or UnitName("player") or "Unknown"
    realm = realm and realm ~= "" and realm or GetNormalizedRealmName() or GetRealmName() or "Unknown"
    return name .. "-" .. realm, name, realm
end

function EL:MigrateProfile(profile)
    -- Money rows were introduced as opt-in. Apply that default once to profiles
    -- created before the option existed, including profiles used during testing.
    if not profile.moneyDisplayDefaultMigrated then
        profile.personalShowMoney = false
        profile.moneyDisplayDefaultMigrated = true
    end
    if profile.hideKnowledgePoints == nil then
        profile.hideKnowledgePoints = profile.showKnowledgePoints == false
    end
    if not profile.styleProfilesMigrated then
        profile.personalLootFontSize, profile.groupLootFontSize = profile.lootFontSize, profile.lootFontSize
        profile.personalProcFontSize = profile.procFontSize
        profile.personalSkillMarkerSize = profile.skillMarkerSize
        profile.personalShowSellPrice, profile.groupShowSellPrice = profile.showSellPrice, profile.showSellPrice
        profile.personalShowItemQuality, profile.groupShowItemQuality = profile.showItemQuality, profile.showItemQuality
        profile.styleProfilesMigrated = true
    end
    if not profile.sellPriceFontSizesMigrated then
        profile.personalSellPriceFontSize = math.max(6, (profile.personalLootFontSize or defaults.personalLootFontSize) - 1)
        profile.groupSellPriceFontSize = math.max(6, (profile.groupLootFontSize or defaults.groupLootFontSize) - 1)
        profile.sellPriceFontSizesMigrated = true
    end
    if not profile.displayProfilesMigrated then
        profile.personalShowIcon, profile.groupShowIcon = profile.showIcon, profile.showIcon
        profile.personalShowQuantity, profile.groupShowQuantity = profile.showQuantity, profile.showQuantity
        profile.personalShowTime, profile.groupShowTime = profile.showTime, profile.showTime
        profile.displayProfilesMigrated = true
    end
    if not profile.qualitySortProfilesMigrated then
        profile.personalSortLootByQuality = profile.sortLootByQuality or false
        profile.groupSortLootByQuality = profile.sortLootByQuality or false
        profile.qualitySortProfilesMigrated = true
    end
    if not profile.autoCollapseProfilesMigrated then
        for _, prefix in ipairs({ "personal", "group" }) do
            profile[prefix .. "AutoCollapseEnabled"] = profile.autoCollapseEnabled or false
            profile[prefix .. "AutoCollapseSeconds"] = profile.autoCollapseSeconds or 30
        end
        profile.autoCollapseProfilesMigrated = true
    end
    profile.schemaVersion = CURRENT_DATABASE_VERSION
end

function EL:NormalizeProfile(profile)
    CopyDefaults(defaults, profile)
    if not EL.themes[profile.theme] then profile.theme = defaults.theme end
    profile.maxItems = Clamp(profile.maxItems, 1, 30, defaults.maxItems)
    profile.consolidationSeconds = Clamp(profile.consolidationSeconds, 1, 60, defaults.consolidationSeconds)
    profile.consolidationMinutes = Clamp(profile.consolidationMinutes, 1, 120, defaults.consolidationMinutes)
    if profile.consolidationUseSeconds then
        profile.consolidationUseMinutes = false
    else
        profile.consolidationUseSeconds = false
        profile.consolidationUseMinutes = true
    end
    profile.autoCollapseRowInterval = Clamp(profile.autoCollapseRowInterval, 1, 60, defaults.autoCollapseRowInterval)
    for _, prefix in ipairs({ "personal", "group" }) do
        local secondsKey = prefix .. "AutoCollapseSeconds"
        profile[secondsKey] = Clamp(profile[secondsKey], 1, 60, 30)
    end
    profile.scale = Clamp(profile.scale, 0.1, 2, defaults.scale)
    profile.configScale = Clamp(profile.configScale, 0.5, 1.5, defaults.configScale)
    profile.windowWidth = Clamp(profile.windowWidth, 20, 500, defaults.windowWidth)
    profile.backgroundOpacity = Clamp(profile.backgroundOpacity, 0, 100, defaults.backgroundOpacity)
    profile.lootFontSize = Clamp(profile.lootFontSize, 8, 24, defaults.lootFontSize)
    profile.procFontSize = Clamp(profile.procFontSize, 6, 22, defaults.procFontSize)
    profile.skillMarkerSize = Clamp(profile.skillMarkerSize, 8, 30, defaults.skillMarkerSize)
    profile.personalLootFontSize = Clamp(profile.personalLootFontSize, 8, 24, defaults.personalLootFontSize)
    profile.groupLootFontSize = Clamp(profile.groupLootFontSize, 8, 24, defaults.groupLootFontSize)
    profile.personalSellPriceFontSize = Clamp(profile.personalSellPriceFontSize, 6, 24, defaults.personalSellPriceFontSize)
    profile.groupSellPriceFontSize = Clamp(profile.groupSellPriceFontSize, 6, 24, defaults.groupSellPriceFontSize)
    profile.personalProcFontSize = Clamp(profile.personalProcFontSize, 6, 22, defaults.personalProcFontSize)
    profile.personalSkillMarkerSize = Clamp(profile.personalSkillMarkerSize, 8, 30, defaults.personalSkillMarkerSize)
    if profile.personalTimeFormat ~= "12H" then profile.personalTimeFormat = "24H" end
    if profile.groupTimeFormat ~= "12H" then profile.groupTimeFormat = "24H" end
    if profile.personalSellPriceMode ~= "GOLD_SILVER" and profile.personalSellPriceMode ~= "GOLD" then profile.personalSellPriceMode = "ALL" end
    if profile.groupSellPriceMode ~= "GOLD_SILVER" and profile.groupSellPriceMode ~= "GOLD" then profile.groupSellPriceMode = "ALL" end
    if profile.growDirection ~= "UP" then profile.growDirection = "DOWN" end
    while #profile.history > 200 do table.remove(profile.history) end
    while #profile.groupHistory > 200 do table.remove(profile.groupHistory) end
    if profile.activeTab ~= "GROUP" then profile.activeTab = "PERSONAL" end
end

function EL:InitializeDatabase()
    if type(EtapLootDB) ~= "table" then EtapLootDB = {} end
    local profileKey, characterName, realmName = GetCharacterProfileKey()
    if type(EtapLootDB.profiles) ~= "table" then
        local legacyDB = EtapLootDB
        EtapLootDB = {
            profileVersion = 1,
            profiles = { [profileKey] = legacyDB },
        }
    end

    EtapLootDB.profiles = EtapLootDB.profiles or {}
    EtapLootDB.profileAssignments = EtapLootDB.profileAssignments or {}
    EtapLootDB.profiles[profileKey] = EtapLootDB.profiles[profileKey] or {}
    for key, profile in pairs(EtapLootDB.profiles) do
        if type(profile) ~= "table" then
            profile = {}
            EtapLootDB.profiles[key] = profile
        end
        self:MigrateProfile(profile)
        self:NormalizeProfile(profile)
    end

    local activeProfileKey = EtapLootDB.profileAssignments[profileKey]
    if not activeProfileKey or not EtapLootDB.profiles[activeProfileKey] then
        activeProfileKey = profileKey
        EtapLootDB.profileAssignments[profileKey] = profileKey
    end

    local characterProfile = EtapLootDB.profiles[profileKey]
    characterProfile.characterName = characterName
    characterProfile.realmName = realmName
    characterProfile.classFile = select(2, UnitClass("player"))
    EtapLootDB.profileVersion = CURRENT_DATABASE_VERSION

    self.rootDB = EtapLootDB
    self.characterKey = profileKey
    self.profileKey = activeProfileKey
    self.db = EtapLootDB.profiles[activeProfileKey]
end

local function ApplyWindowSettings(self)
    if not self.frame or not self.db.window then return end
    self.frame:ClearAllPoints()
    self.frame:SetPoint(
        self.db.window.point or "TOPLEFT",
        UIParent,
        self.db.window.point or "TOPLEFT",
        self.db.window.x or 0,
        self.db.window.y or 0
    )
    self.frame:SetShown(self.db.windowShown ~= false)
end

local function ApplyProfileSettings(self)
    self.scrollOffset = 0
    self.tabScrollOffsets = {}
    self.autoCollapseStates = nil
    self.autoCollapsedEntries = nil
    self.autoCollapseHoverTab = nil
    self._appliedGrowDirection = nil
    ApplyWindowSettings(self)
    self:Refresh()
    return true
end

local function CopySettings(self, source)
    for key, defaultValue in pairs(defaults) do
        if key ~= "history" and key ~= "groupHistory" and key ~= "windowShown" then
            local value = source[key]
            if value == nil then value = defaultValue end
            self.db[key] = CopyValue(value)
        end
    end
    return ApplyProfileSettings(self)
end

function EL:CopyProfileSettings(sourceKey)
    local source = self.rootDB and self.rootDB.profiles and self.rootDB.profiles[sourceKey]
    if not source or source == self.db then return false end
    return CopySettings(self, source)
end

function EL:ResetProfileSettings()
    if not self.db then return false end
    return CopySettings(self, defaults)
end

function EL:ActivateProfile(profileKey)
    local profiles = self.rootDB and self.rootDB.profiles
    if not profiles or not profiles[profileKey] or profileKey == self.profileKey then return false end
    self:MigrateProfile(profiles[profileKey])
    self:NormalizeProfile(profiles[profileKey])
    self.profileKey = profileKey
    self.db = profiles[profileKey]
    self.rootDB.profileAssignments = self.rootDB.profileAssignments or {}
    self.rootDB.profileAssignments[self.characterKey] = profileKey
    return ApplyProfileSettings(self)
end
