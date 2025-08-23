local function InitToggles()
    local SQT = LibStub("AceAddon-3.0"):GetAddon("SpellQueueTracker")
    if not SQT then return end

    local db = SQT.db
    if not db then return end  -- db не готово

    db.profile.toggles = db.profile.toggles or {
        interrupt = false,
        cooldowns = false,
        defensives = false,
    }

    -- Создаем фрейм для тоглов
    local TogglesFrame = CreateFrame("Frame", "SQT_TogglesFrame", UIParent, "BackdropTemplate")
    TogglesFrame:SetSize(200, 140)
    TogglesFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
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

    -- Функция создания кнопки
    local function CreateToggleButton(name, parent, yOffset, key)
        local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        btn:SetSize(180, 30)
        btn:SetPoint("TOP", parent, "TOP", 0, yOffset)
        btn:SetText(name .. ": " .. (db.profile.toggles[key] and "ON" or "OFF"))

        btn:SetScript("OnClick", function()
            db.profile.toggles[key] = not db.profile.toggles[key]
            btn:SetText(name .. ": " .. (db.profile.toggles[key] and "ON" or "OFF"))
            print(name .. " toggled " .. (db.profile.toggles[key] and "ON" or "OFF"))
        end)

        return btn
    end

    -- Создаем три кнопки
    local interruptBtn = CreateToggleButton("Interrupts", TogglesFrame, -10, "interrupt")
    local cooldownsBtn = CreateToggleButton("Cooldowns", TogglesFrame, -50, "cooldowns")
    local defensivesBtn = CreateToggleButton("Defensives", TogglesFrame, -90, "defensives")

    -- Сохраняем ссылки на кнопки для основного аддона
    SQT.Toggles = {
        frame = TogglesFrame,
        buttons = {
            interrupt = interruptBtn,
            cooldowns = cooldownsBtn,
            defensives = defensivesBtn,
        }
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
