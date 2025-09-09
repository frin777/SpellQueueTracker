local SpellQueueTracker = LibStub("AceAddon-3.0"):NewAddon(
    "SpellQueueTracker",
    "AceEvent-3.0",
    "AceTimer-3.0"
)

local RC = LibStub("LibRangeCheck-3.0")

-- Конфигурация спеллов
local spellQueue = {
    { 
        id = 1752, 
        name = 'Коварный удар', 
        gcd = true, 
        priority = 4, 
        userPower = { min = 40, type = 3 }, -- энергия
        targetExists = true, -- проверка цели
        range = 2, 
        --comboPoints = { min = 1 }, -- минимум 3 очка серии
        --combat = true, -- только в бою
        color = {163/255, 133/255, 12/255}
    },

    { 
        id = 2098, 
        name = 'Потрошение', 
        gcd = true, 
        priority = 3, 
        userPower = { min = 35, type = 3 }, -- энергия
        targetExists = true, -- проверка цели
        range = 2, 
        comboPoints = { min = 1 }, -- минимум 1 очка серии
        --combat = true, -- только в бою
        color = {111/255, 111/255, 111/255}
    },


    { 
        id = 1784, 
        name = 'Незаметность', 
        gcd = true, 
        priority = 2, 
        combat = false, -- только в бою
        color = {10/255, 10/255, 222/255},
        buff = { id = 1784, present = false, aura = true },
    },

    { 
        id = 8676, 
        name = 'Внезапный удар', 
        gcd = true, 
        priority = 1, 
        range = 2, 
        userPower = { min = 60, type = 3 }, -- энергия
        targetExists = true, -- проверка цели
        color = {25/255, 25/255, 222/255},
        buff = { id = 1784, present = true, aura = true},
    },
    { 
        id = 6603, -- автоатака
        name = 'Автоатака', 
        gcd = false, 
        priority = 100, -- низкий приоритет
        targetExists = true, 
        range = 2, 
        color = {101/255, 221/255, 24/255},
    },
    
    

}

local icons = {}
local frame
local enemiesCache = 0

local defaults = { profile = {bgAlpha = 0, posX = 0, posY = 0, toggles = { interrupt = false, cooldowns = false, saves = false } } }

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
    local bgAlpha = self.db.profile.bgAlpha or 0
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
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    local bgAlpha = self.db and self.db.profile.bgAlpha or 0.5
    frame:SetBackdropColor(0, 0, 0, bgAlpha)

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

local enemiesCache = {}

function SpellQueueTracker:UpdateEnemiesCache()
    local cache = {}
    local nameplates = C_NamePlate.GetNamePlates()

    for i = 1, #nameplates do
        local unitID = nameplates[i].namePlateUnitToken
        if UnitExists(unitID) and UnitCanAttack("player", unitID) and not UnitIsDead(unitID) then
            local minRange, maxRange = RC:GetRange(unitID)
            if maxRange then
                -- Считаем юнита во всех радиусах >= maxRange
                for r = maxRange, 100 do
                    cache[r] = (cache[r] or 0) + 1
                end
            elseif minRange then
                -- fallback: если есть только minRange
                for r = minRange, 100 do
                    cache[r] = (cache[r] or 0) + 1
                end
            end
        end
    end

    enemiesCache = cache
end

-------------------------------
-- Условия спеллов
-------------------------------

local function CheckBuff(unit, buffConfig)
    local buffName = GetSpellInfo(buffConfig.id)
    if not buffName then return false end

    local i = 1
    local found = false

    -- Выбираем источник: обычные баффы или все ауры
    local unitAuraFunc = buffConfig.aura and UnitAura or UnitBuff

    while true do
        local name, _, _, stackCount, _, expirationTime = unitAuraFunc(unit, i)
        if not name then break end

        if name == buffName then
            found = true
            stackCount = stackCount or 0
            local remaining = expirationTime and (expirationTime - GetTime()) or 0

            local minStack = buffConfig.stacks and buffConfig.stacks.min or 0
            local maxStack = buffConfig.stacks and buffConfig.stacks.max or 999
            local timeCheck = buffConfig.time or 0

            -- Если aura=true → игнорируем время
            if buffConfig.aura then
                if buffConfig.present then
                    return stackCount >= minStack and stackCount <= maxStack
                else
                    return stackCount < minStack or stackCount > maxStack
                end
            else
                if buffConfig.present then
                    return remaining >= timeCheck and stackCount >= minStack and stackCount <= maxStack
                else
                    return remaining < timeCheck or stackCount < minStack or stackCount > maxStack
                end
            end
        end
        i = i + 1
    end

    if not found then
        return buffConfig.present == false
    end

    return false
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

    if spell.id == 6603 then
        if IsCurrentSpell(6603) then
            return false
        end
    end

    if spell.targetExists then
        if not UnitExists("target") or UnitIsDead("target") or not UnitCanAttack("player", "target") then
            return false
        end
    end

    if spell.combat ~= nil then
        if spell.combat and not UnitAffectingCombat("player") then
            return false
        elseif spell.combat == false and UnitAffectingCombat("player") then
            return false
        end
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

    if spell.userPower then
        local powerType = spell.userPower.type or 3
        local power = UnitPower("player", powerType)
        if spell.userPower.min and power < spell.userPower.min then return false end
        if spell.userPower.max and power > spell.userPower.max then return false end
    end

    if spell.comboPoints then
        local target = "target"
        if not UnitExists(target) or UnitIsDead(target) or not UnitCanAttack("player", target) then
            return false
        end
    
        local cp = GetComboPoints("player", target)
        local minCP = spell.comboPoints.min or 0
        local maxCP = spell.comboPoints.max or 999
    
        if cp < minCP or cp > maxCP then
            return false
        end
    end
    
    if spell.holyPower then
        local hpwr = UnitPower("player", Enum.PowerType.HolyPower or 9)
        if spell.holyPower.min and hpwr < spell.holyPower.min then return false end
        if spell.holyPower.max and hpwr > spell.holyPower.max then return false end
    end

    -- ✅ Проверка врагов с учётом радиуса
    if spell.Enemies then
        local neededCount = spell.Enemies.count or 1
        local neededRange = spell.Enemies.range or 8
        local inRange = enemiesCache[neededRange] or 0
        if inRange < neededCount then return false end
    end

    if spell.buff and not CheckBuff("player", spell.buff) then
        return false
    end

    if spell.targetHealth and UnitExists("target") and not UnitIsDead("target") then
        local thp = (UnitHealth("target") / UnitHealthMax("target")) * 100
        if spell.targetHealth.min and thp < spell.targetHealth.min then return false end
        if spell.targetHealth.max and thp > spell.targetHealth.max then return false end
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
