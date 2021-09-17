-- количество светодиодов на основной плате пионера
local ledNumber = 4
-- создание порта управления светодиодами
local leds = Ledbar.new(ledNumber)
-- ассоциируем функцию распаковки таблиц из модуля table для упрощения
local unpack = table.unpack

-- переменная текущего состояния
local curr_state = "PREPARE_FLIGHT"
        


-- функция, изменяющая цвет 4-х RGB светодиодов на основной плате пионера
local function changeColor(color)
    -- проходим в цикле по всем светодиодам с 0 по 3
    for i=0, ledNumber - 1 do
        leds:set(i, unpack(color))
    end
end

-- таблица цветов в формате RGB для передачи в функцию changeColor
local colors = {
        {1, 0, 0}, -- красный
        {1, 1, 1}, -- белый
        {0, 1, 0}, -- зеленый
        {1, 1, 0}, -- желтый
        {1, 0, 1}, -- фиолетовый
        {0, 0, 1}, -- синий
        {0, 0, 0}  -- черный/отключение светодиодов
}

local points = {
        {0, 0, 0.7},
        {0.25, 0.77, 0.7},
        {0.5, 0, 0.7},
        {-0.15, 0.48, 0.7},
        {0.65, 0.48, 0.7}
}


-- таблица функций, вызываемых в зависимости от состояния
action = {
    ["PREPARE_FLIGHT"] = function()
        changeColor(colors[2]) -- смена цвета светодиодов на белый
        Timer.callLater(2, function () ap.push(Ev.MCE_PREFLIGHT) end) -- через 2 секунды отправляем команду автопилоту на запуск моторов
        Timer.callLater(4, function () changeColor(colors[3]) end)-- еще через 2 секунды (суммарно 4 секунды, так как таймеры запускаются сразу же друг за другом) меняем цвета светодиодов на зеленый
        Timer.callLater(6, function ()
            ap.push(Ev.MCE_TAKEOFF) -- еще через 2 секунды (суммарно через 6 секунд) отправляем команду автопилоту на взлет
            curr_state = "FLIGHT_TO_FIRST_POINT" -- переход в следующее состояние
        end)
    end,
    ["FLIGHT_TO_FIRST_POINT"] = function ()
        changeColor(colors[4]) -- смена цвета светодиодов на желтый
        Timer.callLater(2, function ()
            ap.goToLocalPoint(unpack(points[1])) -- отправка команды автопилоту на полет к точке из списка points под номером 1
            curr_state = "FLIGHT_TO_SECOND_POINT" -- переход в следующее состояние
        end)
    end,
    ["FLIGHT_TO_SECOND_POINT"] = function ()
        changeColor(colors[3]) -- смена цвета светодиодов на зеленый
        Timer.callLater(2, function ()
            ap.goToLocalPoint(unpack(points[2])) -- отправка команды автопилоту на полет к точке из списка points под номером 2
            curr_state = "FLIGHT_TO_THIRD_POINT" -- переход в следующее состояние
        end)
    end,
    ["FLIGHT_TO_THIRD_POINT"] = function ()
        changeColor(colors[2]) -- смена цвета светодиодов на белый
        Timer.callLater(2, function ()
            ap.goToLocalPoint(unpack(points[3])) -- отправка команды автопилоту на полет к точке из списка points под номером 3
            curr_state = "FLIGHT_TO_FORTH_POINT" -- переход в следующее состояние
        end)
    end,
    ["FLIGHT_TO_FORTH_POINT"] = function ()
        changeColor(colors[5]) -- смена цвета светодиодов на фиолетовый
        Timer.callLater(2, function ()
            ap.goToLocalPoint(unpack(points[4])) -- отправка команды автопилоту на полет к точке из списка points под номером 4
            curr_state = "FLIGHT_TO_FIFTH_POINT" -- переход в следующее состояние
        end)
    end,
    ["FLIGHT_TO_FIFTH_POINT"] = function ()
        changeColor(colors[3]) -- смена цвета светодиодов на зеленый
        Timer.callLater(2, function ()
            ap.goToLocalPoint(unpack(points[5])) -- отправка команды автопилоту на полет к точке из списка points под номером 5
            curr_state = "FLIGHT_TO_LAST_POINT" -- переход в следующее состояние
        end)
    end,
    ["FLIGHT_TO_LAST_POINT"] = function (x)
        changeColor(colors[5]) -- смена цвета светодиодов на фиолетовый
        Timer.callLater(2, function ()
            ap.goToLocalPoint(unpack(points[1])) -- отправка команды автопилоту на полет к точке из списка points под номером 1
            curr_state = "PIONEER_LANDING" -- переход в следующее состояние
        end)
    end,
    ["PIONEER_LANDING"] = function ()
        changeColor(colors[6]) -- смена цвета светодиодов на синий
        Timer.callLater(2, function ()
            ap.push(Ev.MCE_LANDING) -- отправка команды автопилоту на посадку
        end)
    end
}

-- функция обработки событий, автоматически вызывается автопилотом
function callback(event)
    -- если достигнута необходимая высота, то выполняем функцию из таблицы, соответствующую текущему состоянию
    if (event == Ev.TAKEOFF_COMPLETE) then
        action[curr_state]()
    end
    -- если пионер с чем-то столкнулся, то зажигаем светодиоды красным и выключаем двигатели
    if (event == Ev.SHOCK) then
        changeColor(colors[1])
        ap.push(ENGINES_DISARM)
    end
    -- если пионер достигнул точки, то выполняем функцию из таблицы, соответствующую текущему состоянию
    if (event == Ev.POINT_REACHED) then
        action[curr_state]()
    end
    -- если пионер приземлился, то выключаем светодиоды
    if (event == Ev.COPTER_LANDED) then
        changeColor(colors[7])
    end
end


-- включаем светодиод (красный цвет)
changeColor(colors[1])
-- запускаем одноразовый таймер на 2 секунды, а когда он закончится, выполняем первую функцию из таблицы (подготовка к полету)
Timer.callLater(2, function () action[curr_state]() end)
