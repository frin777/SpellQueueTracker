-- Аддон WoW с кнопкой на миникарте и окном с классом и спеком

local ADDON_NAME = ...
local MyAddon = {}
_G[ADDON_NAME] = MyAddon

-- Загружаем библиотеки (LibStub + LDB + DBIcon должны быть в TOC)
local LDB = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")

-- SavedVariables
MyAddonDB = MyAddonDB or { minimap = { hide = false } }

-- Создаём LDB объект
local ldbObject = LDB:NewDataObject(ADDON_NAME, {
    type = "data source",
    text = ADDON_NAME,
    icon = "Interface\\Icons\\INV_Misc_QuestionMark",
    OnClick = function(_, button)
        if button == "LeftButton" then
            MyAddon:ToggleWindow()
        end
    end,
    OnTooltipShow = function(tt)
        tt:AddLine(ADDON_NAME)
        tt:AddLine("ЛКМ: открыть окно", 1, 1, 1)
    end,
})

-- Создаём окно
function MyAddon:CreateWindow()
    if self.frame then return end

    local f = CreateFrame("Frame", "MyAddonMainFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(300, 200)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f.title = f:CreateFontString(nil, "OVERLAY")
    f.title:SetFontObject("GameFontHighlight")
    f.title:SetPoint("LEFT", f.TitleBg, "LEFT", 5, 0)
    f.title:SetText(ADDON_NAME)

    -- Текстовое поле для инфо
    f.infoText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.infoText:SetPoint("TOP", f, "TOP", 0, -40)

    f:Hide()
    self.frame = f
end

-- Получаем класс и спек
function MyAddon:GetClassAndSpec()
    local className = select(1, UnitClass("player")) or "Неизвестно"
    local specName = "Unknown"

    -- Retail / WotLK+
    if GetSpecialization then
        local specIndex = GetSpecialization()
        print(specIndex)
        if specIndex then
            local id, name = GetSpecializationInfo(specIndex)
            if name then
                specName = name
            end
        end
    -- Classic Era / TBC / WotLK
    elseif GetTalentTabInfo then
        local maxPoints, bestSpec = 0, ""
        for i = 1, 3 do
            local name, _, pointsSpent = GetTalentTabInfo(i, false, false, 1)
            -- защита от неправильного типа
            if type(pointsSpent) == "number" and pointsSpent > maxPoints then
                maxPoints = pointsSpent
                bestSpec = name
            end
        end
        if bestSpec ~= "" then
            specName = bestSpec
        end
    end

    return className, specName
end

-- Обновление текста в окне
function MyAddon:UpdateWindow()
    if not self.frame then return end
    local className, specName = self:GetClassAndSpec()
    self.frame.infoText:SetText("Класс: " .. className .. " – " .. specName)
end

function MyAddon:ToggleWindow()
    if not self.frame then self:CreateWindow() end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self:UpdateWindow()
        self.frame:Show()
    end
end

-- Регистрируем иконку на миникарте при загрузке
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, addon)
    if addon == ADDON_NAME then
        DBIcon:Register(ADDON_NAME, ldbObject, MyAddonDB.minimap)
    end
end)
