local _, EL = ...

local HEADER_HEIGHT = EL.UI.HEADER_HEIGHT

function EL:AnchorWindowForGrowth(force)
    local frame = self.frame
    if not frame then return end
    local growUp = self.db.growDirection == "UP"
    local oldDirection = self._appliedGrowDirection

    if (force or oldDirection ~= self.db.growDirection) and frame:IsVisible() then
        local left = frame:GetLeft()
        local edge = growUp and frame:GetBottom() or frame:GetTop()
        if left and edge then
            frame:ClearAllPoints()
            frame:SetPoint(growUp and "BOTTOMLEFT" or "TOPLEFT", UIParent, "BOTTOMLEFT", left, edge)
        end
    end

    frame.header:ClearAllPoints()
    frame.resizeHandle:ClearAllPoints()
    frame.empty:ClearAllPoints()
    frame.bodyBackground:ClearAllPoints()
    frame.gradient:ClearAllPoints()
    if growUp then
        frame.header:SetPoint("BOTTOMLEFT", 1, 1)
        frame.header:SetPoint("BOTTOMRIGHT", -1, 1)
        frame.bodyBackground:SetPoint("TOPLEFT", 1, -1)
        frame.bodyBackground:SetPoint("BOTTOMRIGHT", -1, HEADER_HEIGHT + 1)
        frame.gradient:SetPoint("TOPLEFT", 1, -1)
        frame.gradient:SetPoint("BOTTOMRIGHT", -1, HEADER_HEIGHT + 1)
        frame.resizeHandle:SetPoint("TOPRIGHT", -2, -2)
        frame.resizeHandle.edgeH:ClearAllPoints()
        frame.resizeHandle.edgeV:ClearAllPoints()
        frame.resizeHandle.edgeH:SetPoint("TOPRIGHT", -2, -2)
        frame.resizeHandle.edgeV:SetPoint("TOPRIGHT", -2, -4)
        frame.empty:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -1)
        frame.empty:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, HEADER_HEIGHT + 1)
    else
        frame.header:SetPoint("TOPLEFT", 1, -1)
        frame.header:SetPoint("TOPRIGHT", -1, -1)
        frame.bodyBackground:SetPoint("TOPLEFT", 1, -HEADER_HEIGHT - 1)
        frame.bodyBackground:SetPoint("BOTTOMRIGHT", -1, 1)
        frame.gradient:SetPoint("TOPLEFT", 1, -HEADER_HEIGHT - 1)
        frame.gradient:SetPoint("BOTTOMRIGHT", -1, 1)
        frame.resizeHandle:SetPoint("BOTTOMRIGHT", -2, 2)
        frame.resizeHandle.edgeH:ClearAllPoints()
        frame.resizeHandle.edgeV:ClearAllPoints()
        frame.resizeHandle.edgeH:SetPoint("BOTTOMRIGHT", -2, 2)
        frame.resizeHandle.edgeV:SetPoint("BOTTOMRIGHT", -2, 4)
        frame.empty:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -HEADER_HEIGHT)
        frame.empty:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 0)
    end
    self._appliedGrowDirection = self.db.growDirection
end
