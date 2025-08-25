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

    -- Основной фрейм
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

    -- Текстовое уведомление
    local alertFrame = CreateFrame("Frame", nil, UIParent)
    alertFrame:SetSize(400, 50)
    alertFrame:SetPoint("CENTER", 0, 200)
    local alertText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    alertText:SetPoint("CENTER")
    alertText:Hide()
    local alertTimer

    local function ShowAlert(name, state)
        local color = state == "ON" and "|cff00ff00" or "|cffff0000"
        alertText:SetText(name .. " : " .. color .. state .. "|r")
        alertText:Show()
        if alertTimer then alertTimer:Cancel() end
        alertTimer = C_Timer.NewTimer(2, function()
            alertText:Hide()
            alertTimer = nil
        end)
    end

    -- Общая функция переключения
    local function ToggleOption(key, name, updater)
        db.profile.toggles[key] = not db.profile.toggles[key]
        if updater then updater() end
        ShowAlert(name, db.profile.toggles[key] and "ON" or "OFF")
    end

    -- Функция, которая создаёт кнопку и slash-команду сразу
    local function RegisterToggle(name, key, yOffset)
        local btn = CreateFrame("Button", nil, TogglesFrame, "UIPanelButtonTemplate")
        btn:SetSize(180, 30)
        btn:SetPoint("TOP", 0, yOffset)

        local function UpdateText()
            btn:SetText(name .. ": " .. (db.profile.toggles[key] and "ON" or "OFF"))
        end
        UpdateText()

        btn:SetScript("OnClick", function() ToggleOption(key, name, UpdateText) end)

        -- Slash-команда
        _G["SLASH_" .. key:upper() .. "1"] = "/toggle" .. key
        SlashCmdList[key:upper()] = function()
            ToggleOption(key, name, UpdateText)
        end

        return btn
    end

    -- Создаём все тоглы через один список
    local toggles = {
        {"Interrupts", "interrupt", -10},
        {"Cooldowns", "cooldowns", -50},
        {"Defensives", "defensives", -90},
        {"Minor CDs", "minorcds", -130}
    }

    local buttons = {}
    for _, toggle in ipairs(toggles) do
        local name, key, yOffset = unpack(toggle)
        buttons[key] = RegisterToggle(name, key, yOffset)
    end

    SQT.Toggles = { frame = TogglesFrame, buttons = buttons }
end

-- Ждём загрузки аддона
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "SpellQueueTracker" then
        InitToggles()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
