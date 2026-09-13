local _, EL = ...

function EL:Refresh()
    if self.RefreshWindow then self:RefreshWindow() end
    if self.UpdateMinimapButton then self:UpdateMinimapButton() end
    if self.UpdateSpeedLoot then self:UpdateSpeedLoot() end
    if self.configFrame and self.configFrame:IsShown() and self.ApplyConfigTheme then
        self:ApplyConfigTheme()
    end
end


