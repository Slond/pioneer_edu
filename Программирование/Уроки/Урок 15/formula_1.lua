-- количество светодиодов на основной плате пионера
local ledNumber = 29
-- создание порта управления светодиодами
local leds = Ledbar.new(ledNumber)
-- ассоциируем функцию распаковки таблиц из модуля table для упрощения
local unpack = table.unpack

local rc = Sensors.rc

-- переменная текущего состояния
local curr_state = "PREPARE_FLIGHT"

-- функция, изменяющая цвет 4-х RGB светодиодов на основной плате пионера
local function changeColor(color)
    -- проходим в цикле по всем светодиодам с 0 по 3
    for i=0, ledNumber - 1 do 
        leds:set(i, unpack(color))
    end
end

local colors = { 
    red = {1,0,0},
    green = {0,1,0},
    blue = {0,0,1},
    purple = {1, 0, 1},
    cyan = {0, 1, 1},
    yellow = {1, 1, 0},
    white = {1, 1, 1},
    black = {0, 0, 0}
}



local arrayOfNumbers = { -- числа от 1 до 10
    {12,8,4,9,14,19,24},
    {6,2,3,4,10,14,13,17,21,22,23,24,25},
    {1,2,3,4,5,9,13,19,25,24,23,22,21},
    {2,4,7,9,12,13,14,19,24},
    {5,4,3,2,1,6,11,12,13,14,15,20,25,24,23,22,21},
    {4,8,12,13,14,17,19,22,23,24},
    {2,3,4,5,10,14,18,23},
    {2,3,4,7,9,13,17,19,22,23,24},
    {2,3,4,7,9,12,13,14,19,24,23,22},
    {1,6,11,16,21,3,4,5,8,10,13,15,18,20,23,24,25}
} 

local laps = 1

function numberLed(number, color)
    for p = 1, #arrayOfNumbers[number] do
        leds:set(arrayOfNumbers[number][p]+3, unpack(color))  
    end
end


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
local height = 0.5

pointT = Timer.new(0.1, function()
    angle = angle + value
    if angle >= 360 then
        angle = angle - 360
        laps = laps + 1
    end
    yCord = r*math.sin(angle * math.pi / 180)
    xCord = r*math.cos(angle * math.pi / 180)
    ap.goToLocalPoint(xCord, yCord, height)
end)



lapT = Timer.new(1, function()
    changeColor(colors.black)
    sleep(0.1)
    numberLed(laps, colors.green)
end)

checkT = Timer.new(0.1, function () -- создаем таймер, который будет вызывать нашу функцию 10 раз в секунуду
    _, _, _, _, _, _, _, ch8 = rc() -- считываем сигнал с 8 канала на пульте, значение от -1 до 1
    if(ch8 < 0) then  -- если сигнал с пульта -1 (SWA вверх), то включаем
        pointT:start()
        angleT:start()
        if laps > 10 then
            laps = laps - 10
        end
    else -- если сигнал с пульта 1 (SWA вниз), то выключаем
        pointT:stop()
        angleT:stop()
        curr_state = "PIONEER_LANDING"
    end
end)

-- таблица функций, вызываемых в зависимости от состояния
action = {
    ["PREPARE_FLIGHT"] = function(x)
        changeColor(colors.white) -- смена цвета светодиодов на белый
        Timer.callLater(2, function () ap.push(Ev.MCE_PREFLIGHT) end) -- через 2 секунды отправляем команду автопилоту на запуск моторов
        Timer.callLater(4, function () changeColor(colors.green) end)-- еще через 2 секунды (суммарно 4 секунды, так как таймеры запускаются сразу же друг за другом) меняем цвета светодиодов на зеленый
        Timer.callLater(6, function ()
            ap.push(Ev.MCE_TAKEOFF) -- еще через 2 секунды (суммарно через 6 секунд) отправляем команду автопилоту на взлет
            ap.goToLocalPoint(0,0, height)
            curr_state = "FLIGHT_TO_FIRST_POINT" -- переход в следующее состояние
        end)
    end,
    ["FLIGHT_TO_FIRST_POINT"] = function (x)
        changeColor(colors.yellow) -- смена цвета светодиодов на желтый
        Timer.callLater(1, function ()
            checkT:start()
            lapT:start()
        end)
    end,
    ["PIONEER_LANDING"] = function (x)
        changeColor(colors.white) -- смена цвета светодиодов на белый
        Timer.callLater(2, function ()
            checkT:stop()
            ap.goToLocalPoint(0, 0, height)
            lapT:stop()
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
        changeColor(colors.red)
        angleT:stop()
        pointT:stop()
    end
    
    -- если пионер достигнул точки, то выполняем функцию из таблицы, соответствующую текущему состоянию
    if (event == Ev.POINT_REACHED) then
        action[curr_state]()
    end

    -- если пионер приземлился, то выключаем светодиоды
    if (event == Ev.COPTER_LANDED) then
        changeColor(colors.black)
    end

end

-- включаем светодиод (красный цвет)
changeColor(colors.red)
-- запускаем одноразовый таймер на 2 секунды, а когда он закончится, выполняем первую функцию из таблицы (подготовка к полету)
Timer.callLater(2, function () action[curr_state]() end)
