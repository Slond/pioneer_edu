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


local value = 3
local i = 0

angleT = Timer.new(0.1, function()
    ap.updateYaw(-i/180*math.pi)    
i = i+value
end)


local r = 0.3
local angle = 0
local xCord = 0
local yCord = 0
local height = 0.7

pointT = Timer.new(0.1, function()
    angle = angle + value
    if angle > 360 then
        angle = 0
    end
    yCord = r*math.sin(angle * math.pi / 180)
    xCord = r*math.cos(angle * math.pi / 180)
    ap.goToLocalPoint(xCord, yCord, height)
end)

-- таблица функций, вызываемых в зависимости от состояния
action = {
    ["PREPARE_FLIGHT"] = function(x)
        changeColor(colors[2]) -- смена цвета светодиодов на белый
        Timer.callLater(2, function () ap.push(Ev.MCE_PREFLIGHT) end) -- через 2 секунды отправляем команду автопилоту на запуск моторов
        Timer.callLater(4, function () changeColor(colors[3]) end)-- еще через 2 секунды (суммарно 4 секунды, так как таймеры запускаются сразу же друг за другом) меняем цвета светодиодов на зеленый
        Timer.callLater(6, function ()
            ap.push(Ev.MCE_TAKEOFF) -- еще через 2 секунды (суммарно через 6 секунд) отправляем команду автопилоту на взлет
            ap.goToLocalPoint(0,0, height)
            curr_state = "FLIGHT_TO_FIRST_POINT" -- переход в следующее состояние
        end)
    end,
    ["FLIGHT_TO_FIRST_POINT"] = function (x)
        changeColor(colors[4]) -- смена цвета светодиодов на желтый
        Timer.callLater(1, function ()
            angleT:start()
            pointT:start()
            sleep(6) -- отправка команды автопилоту на полет к точке с координатами (0 м, 1 м, 1 м)
            curr_state = "FLIGHT_TO_LAST_POINT" -- переход в следующее состояние
        end)
    end,
    ["FLIGHT_TO_LAST_POINT"] = function (x)
        changeColor(colors[4]) -- смена цвета светодиодов на желтый
        Timer.callLater(2, function ()
            
            -- ap.goToLocalPoint(0, 0, 0.8, 6) -- отправка команды автопилоту на полет к точке взлета (0 м, 0 м, 0.8 м)
            curr_state = "PIONEER_LANDING" -- переход в следующее состояние
        end)
    end,
    ["PIONEER_LANDING"] = function (x)
        changeColor(colors[2]) -- смена цвета светодиодов на белый
        Timer.callLater(2, function ()
            -- ap.updateYaw(0)
            pointT:stop()
            angleT:stop()
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
    
    -- если коптер с чем-то столкнулся, то зажигаем светодиоды красным
    if (event == Ev.SHOCK) then
        changeColor(colors[1])
        angleT:stop()
        pointT:stop()
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
