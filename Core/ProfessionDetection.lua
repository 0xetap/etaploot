local _, EL = ...

-- Some chat events, notably in protected dungeon contexts, carry secret
-- strings. They still pass type(value) == "string", but WoW forbids string
-- methods such as :lower() and :match() on them from addon code.
local function IsReadableMessage(message)
    if type(message) ~= "string" then return false end
    return not (issecretvalue and issecretvalue(message))
end

local function IsReadableTable(value)
    if type(value) ~= "table" then return false end
    return not (issecretvalue and issecretvalue(value))
end

local function CopyCraftEntry(entry, quantity, source, transaction)
    return {
        id = entry.id,
        link = entry.link,
        name = entry.name,
        quality = entry.quality,
        icon = entry.icon,
        quantity = quantity,
        source = entry.source or "CRAFT",
        bonusSource = source,
        sellPrice = entry.sellPrice,
        skillUps = entry.skillUps,
        time = transaction.time,
        lootedAt = transaction.lootedAt,
    }
end

function EL:GetCraftingResultBonusSource(data)
    if not IsReadableTable(data) then return nil end
    local sources = {}
    if data.bonusCraft == true or (tonumber(data.multicraft) or 0) > 0 then
        sources[#sources + 1] = "MULTICRAFT"
    end
    if data.hasIngenuityProc == true and (tonumber(data.concentrationSpent) or 0) > 0 then
        sources[#sources + 1] = "INGENUITY"
    end
    if IsReadableTable(data.resourcesReturned) and next(data.resourcesReturned) ~= nil then
        sources[#sources + 1] = "RESOURCEFULNESS"
    end
    return #sources > 0 and table.concat(sources, "+") or nil
end

function EL:ApplyCraftingResultRetroactively(source, itemID)
    local transaction = self.lastSkillTransaction
    local entry = transaction and transaction.entry
    if transaction and entry
        and GetTime() - transaction.at <= 3
        and (entry.source or "LOOT") == "CRAFT"
        and (not itemID or entry.id == itemID) then
        if entry.bonusSource == source then return true end
        if transaction.wasConsolidated and (entry.quantity or 1) > transaction.quantity then
            entry.quantity = entry.quantity - transaction.quantity
            entry.lootedAt = transaction.previousLootedAt
            entry.time = transaction.previousTime
            local tagged = CopyCraftEntry(entry, transaction.quantity, source, transaction)
            table.insert(self.db.history, 1, tagged)
            transaction.entry = tagged
            while #self.db.history > 200 do table.remove(self.db.history) end
        else
            entry.bonusSource = source
        end
        self:RefreshWindow()
        return true
    end

    local now = time()
    for _, recent in ipairs(self.db.history or {}) do
        if (recent.source or "LOOT") == "CRAFT"
            and (not itemID or recent.id == itemID)
            and now - (tonumber(recent.lootedAt) or 0) <= 3 then
            recent.bonusSource = source
            self:RefreshWindow()
            return true
        end
    end
    return false
end

function EL:HandleCraftingResult(data)
    local source = self:GetCraftingResultBonusSource(data)
    if not source then return false end
    local itemID = tonumber(data.itemID)
    if not itemID and type(data.hyperlink) == "string" then
        itemID = C_Item.GetItemInfoInstant(data.hyperlink)
    end
    if self:ApplyCraftingResultRetroactively(source, itemID) then
        self.pendingCraftingResult = nil
    else
        self.pendingCraftingResult = {
            source = source,
            itemID = itemID,
            expiresAt = GetTime() + 3,
        }
    end
    if self.professionDebug then
        print(("EtapLoot debug: detected %s from crafting result"):format(source))
    end
    return true
end

function EL:ConsumeCraftingResult(itemLink)
    local pending = self.pendingCraftingResult
    if not pending then return nil end
    if GetTime() > pending.expiresAt then
        self.pendingCraftingResult = nil
        return nil
    end
    local itemID = C_Item.GetItemInfoInstant(itemLink)
    if pending.itemID and itemID ~= pending.itemID then return nil end
    self.pendingCraftingResult = nil
    return pending.source
end

function EL:ApplySkillUpRetroactively(points)
    local transaction = self.lastSkillTransaction
    if not transaction or GetTime() - transaction.at > 3 then return false end
    local entry = transaction.entry
    if not entry then return false end
    if entry.skillUps or entry.skillUp then
        entry.skillUps = (entry.skillUps or 1) + points
        entry.skillUp = nil
        self:RefreshWindow()
        return true
    end

    if transaction.wasConsolidated and (entry.quantity or 1) > transaction.quantity then
        entry.quantity = entry.quantity - transaction.quantity
        entry.lootedAt = transaction.previousLootedAt
        entry.time = transaction.previousTime
        local tagged = {
            id = entry.id,
            link = entry.link,
            name = entry.name,
            quality = entry.quality,
            icon = entry.icon,
            quantity = transaction.quantity,
            source = entry.source or "LOOT",
            bonusSource = entry.bonusSource,
            sellPrice = entry.sellPrice,
            skillUps = points,
            time = transaction.time,
            lootedAt = transaction.lootedAt,
        }
        table.insert(self.db.history, 1, tagged)
        transaction.entry = tagged
        while #self.db.history > 200 do table.remove(self.db.history) end
    else
        entry.skillUps = points
    end
    self:RefreshWindow()
    return true
end

function EL:DetectSkillUpMessage(message)
    if not IsReadableMessage(message) or not self.skillUpPattern then return false end
    local skillName, newRank = message:match(self.skillUpPattern)
    newRank = tonumber(newRank)
    if not skillName or not newRank then return false end
    if self.lastSkillMessage == message and self.lastSkillDetection and GetTime() - self.lastSkillDetection < 0.5 then return true end
    self.lastSkillMessage = message
    self.lastSkillDetection = GetTime()
    self.skillRanks = self.skillRanks or {}
    local previousRank = self.skillRanks[skillName]
    local points = previousRank and math.max(1, newRank - previousRank) or 1
    self.skillRanks[skillName] = math.max(newRank, previousRank or 0)
    if self:ApplySkillUpRetroactively(points) then
        self.pendingSkillUp = nil
    else
        self.pendingSkillUp = { expiresAt = GetTime() + 5, points = points }
    end
    return true
end

local procKeywords = {
    { keyword = "perception", source = "PERCEPTION" },
    { keyword = "finesse", source = "FINESSE" },
    { keyword = "multicraft", source = "MULTICRAFT" },
    { keyword = "ingenuity", source = "INGENUITY" },
    { keyword = "resourcefulness", source = "RESOURCEFULNESS" },
}

function EL:GetProfessionBonusSource(message)
    if not IsReadableMessage(message) then return nil end
    local lowerMessage = message:lower()
    if not lowerMessage:find("your ", 1, true) then return nil end
    for _, proc in ipairs(procKeywords) do
        if lowerMessage:find(proc.keyword, 1, true) then return proc.source end
    end
    return nil
end

function EL:DetectProfessionBonusMessage(message)
    local source = self:GetProfessionBonusSource(message)
    if not source then return false end
    local lastDetection = self.lastProfessionDetection
    if lastDetection and lastDetection.source == source and GetTime() - lastDetection.at < 0.5 then
        return true
    end
    self.lastProfessionDetection = { source = source, at = GetTime() }
    self.pendingProfessionBonus = { source = source, expiresAt = GetTime() + 5 }
    if self.professionDebug then
        print(("EtapLoot debug: detected %s proc (waiting for next loot)"):format(source))
    end
    return true
end

function EL:ProcessProfessionMessage(message)
    if not self.db or not self.db.enabled then return false, false end
    local professionDetected = self:DetectProfessionBonusMessage(message)
    if professionDetected then return true, false end
    return false, self:DetectSkillUpMessage(message)
end
