local _, EL = ...

function EL:CancelAutoCollapseTimer()
    if not self.autoCollapseTimer then return end
    self.autoCollapseTimer:Cancel()
    self.autoCollapseTimer = nil
end

function EL:ScheduleAutoCollapseTimer(delayOverride)
    self:CancelAutoCollapseTimer()
    if not self.frame or not self.db then return end
    if not delayOverride and not self.nextAutoCollapseAt then return end

    local delay = delayOverride or math.max(0.05, self.nextAutoCollapseAt - time())
    self.autoCollapseTimer = C_Timer.NewTimer(delay, function()
        self.autoCollapseTimer = nil
        if not self.frame or not self.db then return end
        local whisperVisible = self.whisperPrompt and self.whisperPrompt:IsShown()
        if self.resizeDragging or self.autoCollapseHoverTab or whisperVisible then
            self:ScheduleAutoCollapseTimer(0.25)
            return
        end
        if self.nextAutoCollapseAt and time() < self.nextAutoCollapseAt then
            self:ScheduleAutoCollapseTimer()
            return
        end
        local fadeEnabled
        if self.db.activeTab == "GROUP" then
            fadeEnabled = self.db.groupAutoCollapseFade
        else
            fadeEnabled = self.db.personalAutoCollapseFade
        end
        if not fadeEnabled or not self:StartAutoCollapseFade() then
            self:RefreshWindow()
        end
    end)
end

function EL:StartAutoCollapseHoverMonitor()
    if self.autoCollapseHoverTicker then return end
    self.autoCollapseHoverTicker = C_Timer.NewTicker(0.10, function()
        if not self.autoCollapseHoverTab then
            self.autoCollapseHoverTicker:Cancel()
            self.autoCollapseHoverTicker = nil
            return
        end
        local whisperVisible = self.whisperPrompt and self.whisperPrompt:IsShown()
        if not self.resizeDragging
            and not whisperVisible
            and not self.frame:IsMouseOver()
            and not self.frame.collapseHoverArea:IsMouseOver() then
            self.autoCollapseHoverTab = nil
            self.autoCollapseHoverTicker:Cancel()
            self.autoCollapseHoverTicker = nil
            self:RefreshWindow()
        end
    end)
end

function EL:CancelAutoCollapseFade()
    local animation = self.autoCollapseFadeActive
    if not animation then return end
    self.autoCollapseFadeActive = nil
    animation:Stop()
    if animation.row then animation.row:SetAlpha(1) end
end

function EL:PauseAutoCollapseForHover()
    if not self.db or not self.frame then return end
    local tabKey = self.db.activeTab == "GROUP" and "GROUP" or "PERSONAL"
    local enabled = tabKey == "GROUP" and self.db.groupAutoCollapseEnabled or self.db.personalAutoCollapseEnabled
    if not enabled then return end
    local wasHovering = self.autoCollapseHoverTab == tabKey
    self:CancelAutoCollapseFade()
    self.autoCollapseHoverTab = tabKey
    self:StartAutoCollapseHoverMonitor()
    if not wasHovering then self:RefreshWindow() end
end

function EL:StartAutoCollapseFade()
    local row = self.frame and self.frame.rows[self.currentVisibleCount or 0]
    if not row or not row:IsShown() then return false end
    local animation = row.autoCollapseFade
    if not animation then
        animation = row:CreateAnimationGroup()
        animation.row = row
        local alpha = animation:CreateAnimation("Alpha")
        alpha:SetFromAlpha(1)
        alpha:SetToAlpha(0)
        alpha:SetDuration(0.4)
        alpha:SetSmoothing("IN_OUT")
        animation:SetScript("OnFinished", function(group)
            if EL.autoCollapseFadeActive ~= group then return end
            EL.autoCollapseFadeActive = nil
            group.row:SetAlpha(1)
            EL:RefreshWindow()
        end)
        row.autoCollapseFade = animation
    end
    row:SetAlpha(1)
    self.autoCollapseFadeActive = animation
    animation:Play()
    return true
end
