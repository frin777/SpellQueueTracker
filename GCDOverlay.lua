-- GCD Overlay Frame
local GCDOverlay = CreateFrame("Frame", nil, UIParent)
GCDOverlay:SetSize(64, 64)
GCDOverlay:SetPoint("CENTER", 0, -100)
GCDOverlay:SetFrameStrata("HIGH")
GCDOverlay:Hide()

-- Cooldown
local cooldown = CreateFrame("Cooldown", nil, GCDOverlay, "CooldownFrameTemplate")
cooldown:SetAllPoints()
cooldown:SetSwipeColor(0, 0, 0, 0.8)
cooldown:SetDrawEdge(false)
cooldown:SetReverse(false)
cooldown:SetDrawBling(false)

-- Get current GCD (with haste and form checks)
local function GetCurrentGCD()
    local base = select(2, UnitClass("player")) == "DRUID" and ({[1]=1.0, [2]=1.0})[GetShapeshiftForm()] or 1.5
    local gcd = base / (1 + UnitSpellHaste("player") / 100)
    return gcd < 0.75 and 0.75 or gcd
end

-- On GCD spell (61304 — The Power of the Thunder King, used as GCD proxy)
GCDOverlay:RegisterEvent("SPELL_UPDATE_COOLDOWN")
GCDOverlay:RegisterEvent("PLAYER_ENTERING_WORLD")
GCDOverlay:RegisterEvent("UPDATE_SHAPESHIFT_FORM")

GCDOverlay:SetScript("OnEvent", function()
    local start, dur = GetSpellCooldown(61304)
    if dur > 0 and dur <= 1.6 then
        GCDOverlay:Show()
        cooldown:SetCooldown(start, dur)
    else
        GCDOverlay:Hide()
    end
end)