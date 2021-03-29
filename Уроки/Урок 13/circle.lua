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

local r = 0.3 -- радиус окружности
local angle = 30 --угол для точек
local points = {}

for i=1, 12 do
    xCoord = r * math.cos(i * angle * math.pi / 180)
    yCoord = r * math.sin(i * angle * math.pi / 180)
    points[i] = {xCoord, yCoord, 0.7}
end

local j = 1

-- таблица функций, вызываемых в зависимости от состояния
action = {
    ["PREPARE_FLIGHT"] = function()
        changeColor(colors[2]) -- смена цвета светодиодов на белый
        Timer.callLater(2, function () ap.push(Ev.MCE_PREFLIGHT) end) -- через 2 секунды отправляем команду автопилоту на запуск моторов
        Timer.callLater(4, function () changeColor(colors[3]) end)-- еще через 2 секунды (суммарно 4 секунды, так как таймеры запускаются сразу же друг за другом) меняем цвета светодиодов на зеленый
        Timer.callLater(6, function ()
            ap.push(Ev.MCE_TAKEOFF) -- еще через 2 секунды (суммарно через 6 секунд) отправляем команду автопилоту на взлет
            curr_state = "FLIGHT" -- переход в следующее состояние
        end)
    end,
    ["FLIGHT"] = function ()
        while j < #points do
            ap.goToLocalPoint(unpack(points[j]))
            j = j + 1
            curr_state = "FLIGHT"
            break
        end
        curr_state = "PIONEER_LANDING"
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
