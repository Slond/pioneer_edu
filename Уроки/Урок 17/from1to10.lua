-- Указываем количество светодиодов
local ledbar = Ledbar.new(29)

-- переменная текущего состояния
local curr_state = "START"

-- 4 светодиода на базовой плате
local matrixLeds = 4 

-- 25 светодиодов на доп. модуле
local modulLeds = 25

-- Используется для распаковки массива
local unpack = table.unpack 



-- Массив для вывода чисел от 1 до 10
local arrayOfNumbers = { 
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


-- RGB коды основных цветов
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


-- Функция для вывода числа от 0 до 10 на доп. модуль
function numberLed(number, color)
    for i = 1, #arrayOfNumbers[number] do
        ledbar:set(arrayOfNumbers[number][i]+matrixLeds-1, unpack(color))
    end
end


-- numberLed(1, colors.green)



-- Функция выключения всех светодиодов
function allLedsOff()
    for i = 0, matrixLeds+modulLeds-1 do
        ledbar:set(i, unpack(colors.black))
    end
end


--На случай сильной яркости
function setColor(color, brightness)
    local j = 1
    local newArr = {}
    while color[j] do
        newArr[j] = color[j]*brightness
        j = j+1
    end
    return newArr
end
-- Данную функцию используйте вместо цвета, т.е. писать не colors.green, a setColor(colors.green, 0.5), чтобы получить яркость в 2 раза меньше от максимума


-- функция обработки событий, автоматически вызывается автопилотом
function callback(event)
end


for k=1, 10 do
    numberLed(k, colors.green)
    sleep(1)
    allLedsOff()
    sleep(1)
end
