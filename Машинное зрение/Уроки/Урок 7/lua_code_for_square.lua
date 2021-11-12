local ledNumber = 4

local leds = Ledbar.new(ledNumber)

local colors = {
        {0.1, 0, 0}, -- красный
        {0.1, 0.1, 0.1}, -- белый
        {0, 0.1, 0}, -- зеленый
        {0.1, 0.1, 0}, -- желтый
        {0.1, 0, 0.1}, -- фиолетовый
        {0, 0, 0.1}, -- синий
        {0, 0, 0}  -- черный/отключение светодиодов
}

local unpack = table.unpack

function changeColor(color)
    -- проходим в цикле по всем светодиодам с 0 по 3
    for i=0, ledNumber - 1 do
        leds:set(i, unpack(color))
    end
end

------------------------------------

local uartNum  = 4              -- номер UART (на коптере их два: 1 и 4)
local baudRate = 9600           -- скорость передачи данных
local dataBits = 8              -- количество принимаемых бит
local stopBits = 1
local parity = Uart.PARITY_NONE -- бит чётности
local uart = Uart.new(uartNum, baudRate, parity, stopBits) -- создание порта управления UART-ом

function getc()                 -- функция чтения пакета
	while uart:bytesToRead() == 0 do
	end
	return uart:read(1) -- чтение одного бита
end


function ord(chr, signed)       -- функция распаковки и опознавания битов (знаковые или беззнаковые)
	local specifier = "B"
	if signed then
		specifier = "b"
	end
	return string.unpack(specifier, chr)
end

function getData()              -- функция побитовой распаковки
	while true do
		if (ord(getc()) == 0xBB) then 
			break
		end
	end
	local ledstate = ord(getc())    -- считывание id метки
	local dx = ord(getc(), true)    -- cчитывание смещения метки по dx относительно центра камеры
	local dy = ord(getc(), true)    -- cчитывание смещения метки по dy относительно центра камеры
	ord(getc())                     -- считывание конца пакета 
    return ledstate, dx, dy
end

------------------------------------
height = 0.7 -- высота полета


xCord = 0
yCord = 0

function new_point(x,y) -- полет в новую точку
    xCord = xCord + x
    yCord = yCord + y
    ap.goToLocalPoint(xCord,yCord,height)
end

------------------------------------


forw = false -- флаги движения
right = false
left = false
back = false

function finding() -- функция поиска метки
    if (mark == 1) then
        changeColor(colors[1])
        forw = true
        right = false
		left = false
		back = false
    end
    if (mark == 2) then
        changeColor(colors[2])
        forw = false
        right = true
		left = false
		back = false
    end
	if (mark == 3) then
        changeColor(colors[3])
        forw = false
        right = false
		left = true
		back = false
    end
	if (mark == 4) then
        changeColor(colors[4])
        forw = false
        right = false
		left = false
		back = true
    end
end


------------------------------------

goT = Timer.new(0.1, function() -- основной таймер
    mark, dx, dy = getData() -- получение данных с камеры каждые 0.1 с
    relative_x = dx/600 --примерный перевод пикселей камеры в метры для полёта
    relative_y = dy/600
    finding() -- поиск метки
    if forw then
        new_point(0, 0.04)
    end
    if right then
        new_point(0.04, 0)
    end
	if left then
		new_point(-0.04, 0)
	end
	if back then
		new_point(0,-0.04)
	end
end)

------------------------------------
function callback(event)
end

------------------------------------

changeColor(colors[6])
ap.push(Ev.MCE_PREFLIGHT)
sleep(3)
ap.push(Ev.MCE_TAKEOFF)
ap.goToLocalPoint(0,0,height)
goT:start()
