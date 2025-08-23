✅ Конфиг заклинаний (пример)


local spellQueue = {
    { 
        id       = 84963, -- Дознание
        priority = 1,
        range    = 30,
        gcd      = true,
        name     = "Дознание",
        iconPath = "Interface\\AddOns\\SpellQueueTracker\\Icons\\Paladin\\1117.png",
        buff     = { name = "Дознание", minStack = 2, maxStack = 5 }, -- проверка стаков
        holyPower = { min = 1 },  -- минимальное количество Holy Power
        minMana  = 10
    },
    -- Добавляйте другие спеллы по аналогии
}
    




✅ Пример с кастомным условием:
{
    id = 12345,
    name = 'Мой спелл',
    gcd = true,
    priority = 6,
    customCondition = function()
        -- Пример: проверка, что здоровье цели больше 50%
        if UnitExists("target") then
            local hp = (UnitHealth("target") / UnitHealthMax("target")) * 100
            return hp > 50
        end
        return false
    end
}



🛠 Поддерживаемые поля:
Поле	Тип	Описание
id	number	ID заклинания (обязательно).
name	string	Название (для читаемости).
gcd	boolean	Учитывает ли глобальный кулдаун.
priority	number	Приоритет (меньше — выше).
range	number	Максимальная дистанция до цели.
minMana	number	Минимальный % маны.
holyPower	table	{ min = X, max = Y } проверка ресурса Holy Power.
buff	table	Проверка баффа: { id, time, stacks = { min, max } }.
Enemies	table	{ count, range } проверка количества врагов.
customCondition	function	Своя функция, должна возвращать true/false.
iconPath	string	Путь к кастомной иконке.