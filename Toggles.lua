local function InitToggles()
    local SQT = LibStub("AceAddon-3.0"):GetAddon("SpellQueueTracker")
    if not SQT or not SQT.db then return end

    local db = SQT.db
    db.profile.toggles = db.profile.toggles or {
        interrupt = false,
        cooldowns = false,
        defensives = false,
        minorcds = false,
    }

    -- Создаём основной фрейм
    local TogglesFrame = CreateFrame("Frame", "SQT_TogglesFrame", UIParent, "BackdropTemplate")
    TogglesFrame:SetSize(200, 180)
    TogglesFrame:SetPoint("CENTER")
    TogglesFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    TogglesFrame:SetBackdropColor(0, 0, 0, 0.7)
    TogglesFrame:SetMovable(true)
    TogglesFrame:EnableMouse(true)
    TogglesFrame:RegisterForDrag("LeftButton")
    TogglesFrame:SetScript("OnDragStart", TogglesFrame.StartMoving)
    TogglesFrame:SetScript("OnDragStop", TogglesFrame.StopMovingOrSizing)

    -- ✅ Создаём текстовое уведомление по центру экрана
    local alertFrame = CreateFrame("Frame", nil, UIParent)
    alertFrame:SetSize(400, 50)
    alertFrame:SetPoint("CENTER", 0, 200)

    local alertText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    alertText:SetPoint("CENTER")
    alertText:Hide()

    local alertTimer -- ссылка на активный таймер

    -- Функция для показа текста
    local function ShowAlert(name, state)
        local color = state == "ON" and "|cff00ff00" or "|cffff0000" -- зелёный или красный
        alertText:SetText(name .. " : " .. color .. state .. "|r")
        alertText:Show()

        -- Если уже есть таймер, отменяем его
        if alertTimer then
            alertTimer:Cancel()
        end

        -- Создаём новый таймер на скрытие
        alertTimer = C_Timer.NewTimer(2, function()
            alertText:Hide()
            alertTimer = nil
        end)
    end

    -- Функция создания кнопки
    local function CreateToggleButton(name, key, yOffset)
        local btn = CreateFrame("Button", nil, TogglesFrame, "UIPanelButtonTemplate")
        btn:SetSize(180, 30)
        btn:SetPoint("TOP", 0, yOffset)

        local function UpdateText()
            btn:SetText(name .. ": " .. (db.profile.toggles[key] and "ON" or "OFF"))
        end

        UpdateText()
        btn:SetScript("OnClick", function()
            db.profile.toggles[key] = not db.profile.toggles[key]
            UpdateText()
            local state = db.profile.toggles[key] and "ON" or "OFF"
            print(name .. " toggled " .. state)

            -- ✅ Показать сообщение по центру экрана с цветом
            ShowAlert(name, state)
        end)

        return btn
    end

    -- Создаём кнопки
    local buttons = {}
    local toggles = {
        {"Interrupts", "interrupt", -10},
        {"Cooldowns", "cooldowns", -50},
        {"Defensives", "defensives", -90},
        {"Minor CDs", "minorcds", -130}
    }

    for _, toggle in ipairs(toggles) do
        buttons[toggle[2]] = CreateToggleButton(toggle[1], toggle[2], toggle[3])
    end

    SQT.Toggles = {
        frame = TogglesFrame,
        buttons = buttons
    }
end

-- Ждём загрузки аддона SpellQueueTracker
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "SpellQueueTracker" then
        InitToggles()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
