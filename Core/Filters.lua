local _, EL = ...

function EL:IsEquippableItem(itemInfo)
    if not itemInfo then return false end
    if C_Item.IsEquippableItem then
        local equippable = C_Item.IsEquippableItem(itemInfo)
        if equippable ~= nil then return equippable end
    elseif IsEquippableItem then
        return IsEquippableItem(itemInfo)
    end
    local _, _, _, equipLocation = C_Item.GetItemInfoInstant(itemInfo)
    return equipLocation ~= nil and equipLocation ~= ""
end

function EL:PassesFilters(itemID, quality)
    if quality < (self.db.minimumQuality or 0) then return false end
    if self.db.equippableOnly and not self:IsEquippableItem(itemID) then return false end
    return true
end


