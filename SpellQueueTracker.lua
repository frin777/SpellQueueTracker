local SpellQueueTracker = LibStub("AceAddon-3.0"):NewAddon(
    "SpellQueueTracker",
    "AceEvent-3.0",
    "AceTimer-3.0"
)

local RC = LibStub("LibRangeCheck-3.0")

local spellQueue = {
    { id = 84963, gcd = true, priority = 1, range = 30, minMana = 10, holyPower = { min = 1, max = 7 }, buff = { id = 84963, time = 2 }, iconPath = "Interface\\AddOns\\SpellQueueTracker\\Icons\\Paladin\\1117.png" },
    { id = 20271, gcd = true, priority = 1, range = 30, minMana = 10, iconPath = "Interface\\AddOns\\SpellQueueTracker\\Icons\\Paladin\\1066.png" },
    { id = 20271, gcd = true, priority = 1, range = 30, minMana = 10, iconPath = "Interface\\AddOns\\SpellQueueTracker\\Icons\\Paladin\\1066.png" },
    { id = 20271, gcd = true, priority = 1, range = 30, minMana = 10, iconPath = "Interface\\AddOns\\SpellQueueTracker\\Icons\\Paladin\\1066.png" },
    { id = 20271, gcd = true, priority = 1, range = 30, minMana = 10, iconPath = "Interface\\AddOns\\SpellQueueTracker\\Icons\\Paladin\\1066.png" },
    { id = 20271, gcd = true, priority = 1, range = 30, minMana = 10, iconPath = "Interface\\AddOns\\SpellQueueTracker\\Icons\\Paladin\\1066.png" },
    { id = 35395, gcd = true, priority = 2, range = 1, holyPower = { min = 0, max = 4 }, iconPath = "Interface\\AddOns\\SpellQueueTracker\\Icons\\Paladin\\1065.png" },
    { id = 879, gcd = true, priority = 3, range = 30, minHP = 50, iconPath = "Interface\\AddOns\\SpellQueueTracker\\Icons\\Paladin\\1078.png" },
    { id = 85256, gcd = true, priority = 4, range = 1, holyPower = { min = 3 }, iconPath = "Interface\\AddOns\\SpellQueueTracker\\Icons\\Paladin\\1067.png" },
    { id = 53385, gcd = true, priority = 0, range = 1, holyPower = { min = 3 }, Enemies = { count = 2, range = 8 }, iconPath = "Interface\\AddOns\\SpellQueueTracker\\Icons\\Paladin\\1077.png" },
}

local icons = {}
local frame
local enemiesCache = 0

local defaults = { profile = { posX = 0, posY = 0 } }

-------------------------------
-- Методы аддона
-------------------------------

function SpellQueueTracker:SavePosition()
    local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
    self.db.profile.point = point
    self.db.profile.relativePoint = relativePoint
    self.db.profile.posX = xOfs
    self.db.profile.posY = yOfs
end

function SpellQueueTracker:RestorePosition()
    local point = self.db.profile.point or "CENTER"
    local relativePoint = self.db.profile.relativePoint or "CENTER"
    local x = self.db.profile.posX or 0
    local y = self.db.profile.posY or 0
    frame:ClearAllPoints()
    frame:SetPoint(point, UIParent, relativePoint, x, y)
end

-------------------------------
-- Инициализация
-------------------------------

function SpellQueueTracker:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("SpellQueueTrackerDB", defaults, true)
end

function SpellQueueTracker:OnEnable()
    frame = CreateFrame("Frame", "SpellQueueTrackerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(400, 34)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame:SetBackdropBorderColor(0, 0, 0, 1)
    frame:SetFrameLevel(10)

    -- Создаем иконки
    for i, spell in ipairs(spellQueue) do
        local parent = frame
        if spell.gcd == false then
            parent = UIParent
        end

        local iconFrame = CreateFrame("Frame", nil, parent)
        iconFrame:SetSize(32, 32)

        if i == 1 then
            iconFrame:SetPoint("LEFT", frame, "LEFT", 1, 0)
        else
            iconFrame:SetPoint("LEFT", icons[i-1], "RIGHT", 10, 0)
        end

        if spell.gcd == false then
            iconFrame:SetFrameStrata("TOOLTIP")
        else
            iconFrame:SetFrameStrata("HIGH")
        end

        local texture = iconFrame:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints()
        iconFrame.icon = texture
        iconFrame:Hide()
        icons[i] = iconFrame
    end

    -- Привязка оверлея к первой иконке
    if GCDOverlay then
        GCDOverlay:SetParent(icons[1])
        GCDOverlay:SetPoint("CENTER", icons[1], "CENTER", 0, 0)
    end

    self:RestorePosition()

    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then self:StartMoving() end
    end)
    frame:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
        SpellQueueTracker:SavePosition()
    end)

    self.timerQueue = self:ScheduleRepeatingTimer("UpdateQueue", 0.1)
    self.timerEnemies = self:ScheduleRepeatingTimer("UpdateEnemiesCache", 0.33)
end

function SpellQueueTracker:OnDisable()
    if self.timerQueue then self:CancelTimer(self.timerQueue) end
    if self.timerEnemies then self:CancelTimer(self.timerEnemies) end
    if frame then frame:Hide() end
    if GCDOverlay then GCDOverlay:Hide() end
end

-------------------------------
-- Враги
-------------------------------

function SpellQueueTracker:UpdateEnemiesCache()
    local count = 0
    local nameplates = C_NamePlate.GetNamePlates()
    for i = 1, #nameplates do
        local unitID = nameplates[i].namePlateUnitToken
        if UnitExists(unitID) and UnitCanAttack("player", unitID) and not UnitIsDead(unitID) then
            local dist = RC:GetRange(unitID, 1)
            if dist and dist <= 8 then count = count + 1 end
        end
    end
    enemiesCache = count
end

-------------------------------
-- Условия спеллов
-------------------------------

local function CheckConditions(spell)
    if spell.minHP or spell.maxHP then
        local hp = (UnitHealth("player") / UnitHealthMax("player")) * 100
        if spell.minHP and hp < spell.minHP then return false end
        if spell.maxHP and hp > spell.maxHP then return false end
    end
    if spell.minMana then
        local mana = (UnitPower("player", 0) / UnitPowerMax("player", 0)) * 100
        if mana < spell.minMana then return false end
    end
    if spell.holyPower then
        local hpwr = UnitPower("player", Enum.PowerType.HolyPower or 9)
        if spell.holyPower.min and hpwr < spell.holyPower.min then return false end
        if spell.holyPower.max and hpwr > spell.holyPower.max then return false end
    end
    if spell.Enemies and enemiesCache < (spell.Enemies.count or 1) then return false end
    if spell.buff then
        local buffName = GetSpellInfo(spell.buff.id)
        local i = 1
        while true do
            local name = UnitBuff("player", i)
            if not name then break end
            if name == buffName then
                if spell.buff.time then
                    local _, _, _, _, _, expirationTime = UnitBuff("player", i)
                    if expirationTime - GetTime() > spell.buff.time then return false end
                else
                    return false
                end
            end
            i = i + 1
        end
    end
    if spell.customCondition and type(spell.customCondition) == "function" then
        if not spell.customCondition() then return false end
    end
    return true
end

-------------------------------
-- Обновление очереди
-------------------------------

function SpellQueueTracker:UpdateQueue()
    local available = {}
    local target = UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target") and "target" or nil

    for _, spell in ipairs(spellQueue) do
        local _, _, defaultTex = GetSpellInfo(spell.id)
        local start, duration = GetSpellCooldown(spell.id)
        local onCooldown = (start > 0 and duration > 1.5) and (start + duration - GetTime() > 0)

        local inRange = true
        if spell.range and target then
            local dist = RC:GetRange(target, spell.id)
            inRange = dist and dist <= spell.range
        end

        if not onCooldown and inRange and CheckConditions(spell) then
            table.insert(available, { id = spell.id, prio = spell.priority, tex = spell.iconPath or defaultTex, custom = spell.iconPath and true or false, gcd = spell.gcd })
        end
    end

    table.sort(available, function(a, b) return a.prio < b.prio end)

    for i, iconFrame in ipairs(icons) do
        local spell = available[i]
        if spell then
            iconFrame.icon:SetTexture(spell.tex)
            iconFrame.icon:SetTexCoord(spell.custom and 0 or 0.08, spell.custom and 1 or 0.92, spell.custom and 0 or 0.08, spell.custom and 1 or 0.92)
            iconFrame:Show()
    
            -- Управление GCD overlay
            if i == 1 and spell.gcd and GCDOverlay then
                GCDOverlay:SetParent(iconFrame)
                GCDOverlay:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
                GCDOverlay:SetSize(iconFrame:GetWidth(), iconFrame:GetHeight())
                GCDOverlay:Show()
            end
        else
            iconFrame:Hide()
        end
    end
    
    local firstSpell = available[1]
    if not firstSpell or not firstSpell.gcd then
        if GCDOverlay then GCDOverlay:Hide() end
    end
  
end
