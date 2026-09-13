local _, EL = ...

local function EscapeFormat(formatString)
    if not formatString then return nil end
    local pattern = formatString:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    pattern = pattern:gsub("%%%%(%d+)%$s", "(.+)")
    pattern = pattern:gsub("%%%%(%d+)%$d", "(%%d+)")
    pattern = pattern:gsub("%%%%s", "(.+)")
    pattern = pattern:gsub("%%%%d", "(%%d+)")
    return "^" .. pattern .. "$"
end

local selfLootPatterns = {}
local groupLootPatterns = {}
local craftedItemPatterns = {}
local bonusRollPatterns = {}
function EL:BuildLootPatterns()
    wipe(selfLootPatterns)
    wipe(groupLootPatterns)
    wipe(craftedItemPatterns)
    wipe(bonusRollPatterns)

    local lootNames = {
        "LOOT_ITEM_SELF", "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF",
        "LOOT_ITEM_PUSHED_SELF_MULTIPLE", "LOOT_MONEY", "YOU_LOOT_MONEY",
    }
    for _, name in ipairs(lootNames) do
        local pattern = EscapeFormat(_G[name])
        if pattern then selfLootPatterns[#selfLootPatterns + 1] = pattern end
    end
    for _, name in ipairs({
        "LOOT_ITEM", "LOOT_ITEM_MULTIPLE", "LOOT_ITEM_PUSHED",
        "LOOT_ITEM_PUSHED_MULTIPLE",
    }) do
        local pattern = EscapeFormat(_G[name])
        if pattern then groupLootPatterns[#groupLootPatterns + 1] = pattern end
    end
    for _, name in ipairs({ "LOOT_ITEM_CREATED_SELF", "LOOT_ITEM_CREATED_SELF_MULTIPLE" }) do
        local pattern = EscapeFormat(_G[name])
        if pattern then
            craftedItemPatterns[#craftedItemPatterns + 1] = pattern
            selfLootPatterns[#selfLootPatterns + 1] = pattern
        end
    end
    for _, name in ipairs({
        "LOOT_ITEM_BONUS_ROLL", "LOOT_ITEM_BONUS_ROLL_MULTIPLE",
        "LOOT_ITEM_BONUS_ROLL_SELF", "LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE",
    }) do
        local pattern = EscapeFormat(_G[name])
        if pattern then
            bonusRollPatterns[#bonusRollPatterns + 1] = pattern
            if name:find("_SELF", 1, true) then
                selfLootPatterns[#selfLootPatterns + 1] = pattern
            else
                groupLootPatterns[#groupLootPatterns + 1] = pattern
            end
        end
    end
    self.skillUpPattern = EscapeFormat(_G.ERR_SKILL_UP_SI or _G.SKILL_RANK_UP)
end

local function MatchesAny(message, patterns)
    for _, pattern in ipairs(patterns) do
        if message:match(pattern) then return true end
    end
    return false
end

function EL:IsOwnLootMessage(message)
    return MatchesAny(message, selfLootPatterns)
end

function EL:IsCraftedItemMessage(message)
    return MatchesAny(message, craftedItemPatterns)
end

function EL:IsGroupLootMessage(message)
    return MatchesAny(message, groupLootPatterns)
end

function EL:IsBonusRollMessage(message)
    return MatchesAny(message, bonusRollPatterns)
end

function EL:GetQuantity(message, itemLink)
    if type(message) ~= "string" or type(itemLink) ~= "string" then return 1 end
    local _, linkEnd = message:find(itemLink, 1, true)
    if not linkEnd then return 1 end

    -- Only an explicit xN suffix is a quantity. Raid loot messages may carry
    -- other numeric metadata after the visible item link; treating the final
    -- number as a count can turn a roll/context ID into thousands of items.
    local amountText = message:sub(linkEnd + 1):match("[xX]%s*([%d%., ]+)")
    if not amountText then return 1 end
    return tonumber((amountText:gsub("%D", ""))) or 1
end

function EL:GetCurrencyLinkFromMessage(message)
    if type(message) ~= "string" then return nil end
    return message:match("(|c%x%x%x%x%x%x%x%x|Hcurrency:.-|h%[.-%]|h|r)")
        or message:match("(|Hcurrency:.-|h%[.-%]|h)")
end
