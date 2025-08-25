local SpellQueueTracker = LibStub("AceAddon-3.0"):NewAddon(
    "SpellQueueTracker",
    "AceEvent-3.0",
    "AceTimer-3.0"
)

local RC = LibStub("LibRangeCheck-3.0")

-- Конфигурация спеллов
local spellQueue = {
    { 
        id = 31884, 
        name = 'Гнев карателя', 
        gcd = false, 
        priority = 1, 
        range = 30, 
        color = {163/255, 133/255, 12/255}, 
        toggle = "cooldowns" 
    },
    { 
        id = 105809, 
        name = 'Святой каратель', 
        gcd = false, 
        priority = 1, 
        range = 30, 
        color = {163/255, 133/255, 120/255}, 
        toggle = "cooldowns" 
    },
    { 
        id = 84963, 
        name = 'Дознание', 
        userHealth = { min = 0, max = 100 }, 
        userMana = { min = 0, max = 100 }, 
        gcd = true, priority = 1, range = 30, 
        holyPower = { min = 1, max = 7 }, 
        buff = { id = 84963, time = 2, stacks = { min = 0, max = 2 }}, 
        color = {239/255, 235/255, 62/255}, 
        toggle = "minorcds" 
    },
    { 
        id = 20271, 
        name = 'Правосудие', 
        gcd = true, 
        priority = 3, 
        range = 30,
        color = {245/255, 58/255, 72/255}
    },
    { 
        id = 35395, 
        name = 'Удар война Света', 
        gcd = true, 
        priority = 4, 
        range = 1, 
        holyPower = { min = 0, max = 4 }, 
        color = {0/255, 22/255, 199/255}, 
        iconPath = "Interface\\AddOns\\SpellQueueTracker\\Icons\\Paladin\\1065.png" 
    },
    { 
        id = 879, 
        name = 'Экзорцизм', 
        gcd = true, 
        priority = 5, 
        range = 30, 
        minHP = 50, 
        color = {207/255, 158/255, 215/255}, 
        iconPath = "Interface\\AddOns\\SpellQueueTracker\\Icons\\Paladin\\1078.png"
    },
    { 
        id = 85256, 
        name = 'Вердикт храмовника', 
        gcd = true, 
        priority = 2, 
        range = 1, 
        holyPower = { min = 3 }, 
        color = {88/255, 64/255, 47/255},  
        iconPath = "Interface\\AddOns\\SpellQueueTracker\\Icons\\Paladin\\1067.png" 
    },
    { 
        id = 53385, 
        name = 'Божественная буря', 
        gcd = true, 
        priority = 2, 
        range = 1, 
        holyPower = { min = 3 }, 
        Enemies = { count = 2, range = 8 }, 
        color = {181/255, 155/255, 99/255}, 
        iconPath = "Interface\\AddOns\\SpellQueueTracker\\Icons\\Paladin\\1077.png" 
    },
}

local icons = {}
local frame
local enemiesCache = 0

local defaults = { profile = { posX = 0, posY = 0, toggles = { interrupt = false, cooldowns = false, saves = false } } }

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
            iconFrame:SetPoint("LEFT", icons[i-1], "RIGHT", 5, 0)
        end

        if spell.gcd == false then
            iconFrame:SetFrameStrata("TOOLTIP")
        else
            iconFrame:SetFrameStrata("HIGH")
        end

        local texture = iconFrame:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints()
        iconFrame.icon = texture

        -- Полоска сверху
        local bar = iconFrame:CreateTexture(nil, "OVERLAY")
        bar:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 0, 0)
        bar:SetPoint("TOPRIGHT", iconFrame, "TOPRIGHT", 0, 0)
        bar:SetHeight(3)
        if spell.color and type(spell.color) == "table" and #spell.color >= 3 then
            bar:SetColorTexture(spell.color[1], spell.color[2], spell.color[3], 1)
        end
        iconFrame.bar = bar

        iconFrame:Hide()
        icons[i] = iconFrame
    end

    -- Привязка оверлея к первой иконке
    if GCDOverlay and icons[1] then
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
    local db = SpellQueueTracker.db
    local toggles = db and db.profile.toggles or {}

    if spell.toggle ~= nil and toggles[spell.toggle] == false then
        return false
    end

    if spell.userHealth then
        local hp = (UnitHealth("player") / UnitHealthMax("player")) * 100
        if spell.userHealth.min and hp < spell.userHealth.min then return false end
        if spell.userHealth.max and hp > spell.userHealth.max then return false end
    end

    if spell.userMana then
        local mana = (UnitPower("player", 0) / UnitPowerMax("player", 0)) * 100
        if spell.userMana.min and mana < spell.userMana.min then return false end
        if spell.userMana.max and mana > spell.userMana.max then return false end
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
        local found = false
        while true do
            local name, _, _, stackCount, _, expirationTime = UnitBuff("player", i)
            if not name then break end

            if name == buffName then
                found = true
                stackCount = stackCount or 0
                local remaining = expirationTime - GetTime()

                local minStack = spell.buff.stacks and spell.buff.stacks.min or 0
                local maxStack = spell.buff.stacks and spell.buff.stacks.max or 999

                if remaining < (spell.buff.time or 0) and stackCount >= minStack and stackCount <= maxStack then
                    return true
                else
                    return false
                end
            end
            i = i + 1
        end

        if not found then return true end
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

    -- Формируем список доступных спеллов
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
            table.insert(available, {
                id = spell.id,
                prio = spell.priority,
                tex = spell.iconPath or defaultTex,
                custom = spell.iconPath and true or false,
                gcd = spell.gcd
            })
        end
    end

    table.sort(available, function(a, b) return a.prio < b.prio end)

    -- Обновляем иконки
    for i, iconFrame in ipairs(icons) do
        local spell = available[i]
        if spell then
            iconFrame.icon:SetTexture(spell.tex)
            iconFrame.icon:SetTexCoord(
                spell.custom and 0 or 0.08,
                spell.custom and 1 or 0.92,
                spell.custom and 0 or 0.08,
                spell.custom and 1 or 0.92
            )

            -- Безопасная установка цвета полоски
            if iconFrame.bar then
                local colorSet = false
                for _, s in ipairs(spellQueue) do
                    if s.id == spell.id and s.color and type(s.color) == "table" and #s.color >= 3 then
                        iconFrame.bar:SetColorTexture(s.color[1], s.color[2], s.color[3], 1)
                        iconFrame.bar:Show()
                        colorSet = true
                        break
                    end
                end
                if not colorSet then
                    iconFrame.bar:Hide()
                end
            end

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
            if iconFrame.bar then iconFrame.bar:Hide() end
        end
    end

    local firstSpell = available[1]
    if not firstSpell or not firstSpell.gcd then
        if GCDOverlay then GCDOverlay:Hide() end
    end
end
