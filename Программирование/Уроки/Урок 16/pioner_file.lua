-- количество светодиодов на основной плате пионера
local ledNumber = 4
-- создание порта управления светодиодами
local leds = Ledbar.new(ledNumber)

-- функция, изменяющая цвет 4-х RGB светодиодов на основной плате пионера
local function changeColor(red, green, blue)
   for i=0, ledNumber - 1, 1 do
       leds:set(i, red, green, blue)
   end
end

-- функция, которая меняет цвет светодиодов на красный и выключает таймер
local function emergency()
   takePhotoTimer:stop()
   -- так как после остановки таймера его функция выполнится еще раз, то меняем цвета светодиодов на красный через секунду
   Timer.callLater(1, function () changeColor(1, 0, 0) end)
end

-- определяем функцию анализа возникающих событий в системе
function callback(event)
   -- проверка, низкое ли напряжение на аккумуляторе
   if (event == Ev.LOW_VOLTAGE2) then
       emergency()
   end
end

changeColor(1, 0, 0) -- red

-- инициализируем Uart интерфейс
local uartNum = 4 -- номер Uart интерфейса (USART4)
local baudRate = 9600 -- скорость передачи данных
local dataBits = 8
local stopBits = 1
local parity = Uart.PARITY_NONE
local uart = Uart.new(uartNum, baudRate, parity, stopBits) -- создание протокола обмена

changeColor(1, 0, 1) --purple

local N = 10
local i = 7
local strUnpack = string.unpack
function getData() -- функция приёма байта данных
   i = i + 1
   if (i == N + 1) then i = 0 end
   buf = uart:read(uart:bytesToRead()) or '0'
   if (#buf == 0) then buf = '\0' end
   leds:set(1, 0, i/N, 0.5 - 0.5*i/10)
   if (strUnpack ~= nil) then
       local b = strUnpack("B", buf)
       return b -- примерно должно так работать
   else
       return 20
   end
end


local takerFunction = function () -- функция для периодического чтения данных из UART
 local intensity = getData() / 100.0
 changeColor(intensity, intensity, intensity)
end
local interval = 0.1
getMeasureTimer = Timer.new(interval, takerFunction) -- таймер для создания фото
getMeasureTimer:start()


changeColor(1, 0.2, 0) -- orange
