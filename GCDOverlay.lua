-- GCD Overlay Frame
GCDOverlay = CreateFrame("Frame", nil, UIParent)
GCDOverlay:SetSize(64, 64)
GCDOverlay:SetFrameStrata("FULLSCREEN_DIALOG")
GCDOverlay:Hide()

-- Cooldown
local cooldown = CreateFrame("Cooldown", nil, GCDOverlay, "CooldownFrameTemplate")
cooldown:SetAllPoints()
cooldown:SetSwipeColor(0, 0, 0, 0.8)
cooldown:SetDrawEdge(false)
cooldown:SetReverse(false)
cooldown:SetDrawBling(false)

-- Get current GCD (с учетом haste и формы)
local function GetCurrentGCD()
    local base = select(2, UnitClass("player")) == "DRUID" and ({[1]=1.0, [2]=1.0})[GetShapeshiftForm()] or 1.5
    local gcd = base / (1 + UnitSpellHaste("player") / 100)
    return gcd < 0.75 and 0.75 or gcd
end

GCDOverlay:RegisterEvent("SPELL_UPDATE_COOLDOWN")
GCDOverlay:RegisterEvent("PLAYER_ENTERING_WORLD")
GCDOverlay:RegisterEvent("UPDATE_SHAPESHIFT_FORM")

GCDOverlay:SetScript("OnEvent", function()
    local start, dur = GetSpellCooldown(61304)
    if dur > 0 and dur <= 1.6 then
        cooldown:SetCooldown(start, dur)
    end
end)
