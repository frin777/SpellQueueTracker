Skills:

    { 
        id = 84963, 
        name = 'Дознание',  
        gcd = true, 
        priority = 1, 
        range = 30, 
        minMana = 10, 
        minHP = 50,
        holyPower = { min = 1, max = 7 }, 
            buff = { 
                id = 84963, 
                time = 15, 
                stacks = { min = 0, max = 2 }
                }, 
        iconPath = "Interface\\AddOns\\SpellQueueTracker\\Icons\\Paladin\\1117.png" 
    },
    

Toggles:

    /toggleinterrupt → переключает Interrupts

    /togglecooldowns → переключает Cooldowns

    /toggledefensives → переключает Defensives

    /toggleminorcds → переключает Minor CDs



проверка баффа:

    buff = { id = 32216, time = 5, stacks = { min = 1, max = 3 }, present = true },  -- бафф должен быть
    buff = { id = 1784, time = 0, present = false },                                 -- баффа быть не должно


EnergyTypes: 

    local PowerTypes = {
        MANA          = 0,
        RAGE          = 1,
        FOCUS         = 2,
        ENERGY        = 3,
        COMBO_POINTS  = 4,
        RUNES         = 5,
        RUNIC_POWER   = 6,
        SOUL_SHARDS   = 7,
        ECLIPSE       = 8,
        HOLY_POWER    = 9,
        -- дальше тоже есть, но в MoP не всё актуально
    }