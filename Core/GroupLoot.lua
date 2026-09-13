local _, EL = ...

function EL:GetGroupMemberName(sourceGUID, sourceName, message)
    if not IsInGroup() then return nil end
    if issecretvalue then
        if issecretvalue(sourceGUID) then sourceGUID = nil end
        if issecretvalue(sourceName) then sourceName = nil end
        if issecretvalue(message) then message = nil end
    end
    local prefix = IsInRaid() and "raid" or "party"
    local count = IsInRaid() and GetNumGroupMembers() or (GetNumSubgroupMembers and GetNumSubgroupMembers() or 4)
    for index = 1, count do
        local unit = prefix .. index
        local guid = UnitGUID(unit)
        if guid and guid ~= UnitGUID("player") then
            local name, realm = UnitName(unit)
            local fullName = realm and realm ~= "" and (name .. "-" .. realm) or name
            local classFile = select(2, UnitClass(unit))
            local senderMatches = sourceName and sourceName ~= ""
                and (sourceName == name or sourceName == fullName or sourceName:match("^[^-]+") == name)
            if sourceGUID == guid or senderMatches
                or ((not sourceGUID or sourceGUID == "") and message and name and message:find(name, 1, true)) then
                return fullName, classFile
            end
        end
    end
    return nil
end

