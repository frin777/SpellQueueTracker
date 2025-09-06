-- LibSpec.lua
local ADDON_NAME = ...
local LibSpec = {}
_G[ADDON_NAME .. "Spec"] = LibSpec

-- Возвращает класс и текущий спек для Retail MoP
function LibSpec:GetClassAndSpec()
    local className = select(2, UnitClass("player")) or "Неизвестно"
    local specName = "Unknown"
    print(className)
    if type(GetSpecialization) == "function" then
        local specIndex = GetSpecialization()
        if specIndex and type(specIndex) == "number" then
            local _, name = GetSpecializationInfo(specIndex)
            if name and name ~= "" then
                specName = name
            end
        end
    end

    return className, specName
end

return LibSpec
