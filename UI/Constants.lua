local _, EL = ...

EL.UI = EL.UI or {}
EL.UI.ROW_HEIGHT = 30
EL.UI.HEADER_HEIGHT = 27
EL.UI.MAX_VISIBLE_ITEMS = 30

function EL:FormatSellPrice(value, mode)
    local goldIcon = "|TInterface/MoneyFrame/UI-GoldIcon:0:0:2:0|t"
    local silverIcon = "|TInterface/MoneyFrame/UI-SilverIcon:0:0:2:0|t"
    if mode == "ALL" then return C_CurrencyInfo.GetCoinTextureString(value) end
    local gold = math.floor(value / 10000)
    local silver = math.floor(value / 100) % 100
    if mode == "GOLD" and gold > 0 then return gold .. goldIcon end
    local parts = {}
    if gold > 0 then parts[#parts + 1] = gold .. goldIcon end
    if silver > 0 or gold == 0 then parts[#parts + 1] = silver .. silverIcon end
    return table.concat(parts, " ")
end

