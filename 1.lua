local curr_state = "_GEO_TAKEOFF_1"
local magnet = Gpio.new(Gpio.C, 3, Gpio.OUTPUT)
local rc = Sensors.rc
local leds = Ledbar.new(29)

local colors = {
    red =       {1,0,0},
    green =     {0,0.4,0},
    blue =      {0,0,1},
    purple =    {1,0,1},
    cyan =      {0,1,1},
    yellow =    {1,1,0},
    white =     {1,1,1},
    black =     {0,0,0}
}

local str = {{3},{2,3,4},{1,3,5},{2,3,4},{3},{},{},
        {3},{2,4},{1,2,3,4,5},{2,4},{3},{},{},
        {3},{2,3,4},{1,3,5},{2,3,4},{3},
        {},{},{},{}}

function flag()
    for i=4,14 do
        leds:set(i,0,112/255,1)
    end
    leds:set(14,0,0,0)
    leds:set(15,0,0,0)
    leds:set(16,1,215/255,0)
    leds:set(17,0,0,0)
    leds:set(18,0,0,0)
    for i=19, 29 do
        leds:set(i, 0, 112/255, 0)
    end
    sleep(10)
end
    
function ledOn(x,y,color)
    leds:set(5*(y-1)+x+matrixLeds, unpack(color))
end

function ledsOff()
    for i=0, 29 do
        leds:set(i,0,0,0)
    end
end

function run(color, timeS)
    local matrix = {{},{},{},{},{}}
    local i = 1
    while str[i] do
        local j = 1
        table.remove(matrix,1)
        table.insert(matrix, str[i])
        while matrix[j] do
            local k = 1
            while matrix[j][k] do
                ledOn(j,matrix[j][k], color)
                k = k + 1
            end
            j = j + 1
        end
    sleep(timeS)
    ledsOff()
    i = i + 1
    end
end

action = {
	["_GEO_TAKEOFF_1"] = function (x) 
        magnet:set()
		ap.push(Ev.MCE_PREFLIGHT)
		sleep(2)
		ap.push(Ev.MCE_TAKEOFF)

		-- переход в следующее состояние
		curr_state = "_GO_TO_POINT_1"
	end,
	["_GO_TO_POINT_1"] = function (x) 
		ap.goToLocalPoint(-2, 0.5, 1.5)

		-- переход в следующее состояние
		curr_state = "_GEO_LANDING_1"
	end,
	["_GEO_LANDING_1"] = function (x) 
		ap.push(Ev.MCE_LANDING)

		-- переход в следующее состояние
		curr_state = "_GEO_TAKEOFF_2"
	end,
	["_GEO_TAKEOFF_2"] = function (x) 
		ap.push(Ev.MCE_PREFLIGHT)
		sleep(2)
		ap.push(Ev.MCE_TAKEOFF)

		-- переход в следующее состояние
		curr_state = "_GO_TO_POINT_2"
	end,
	["_GO_TO_POINT_2"] = function (x) 
		ap.goToLocalPoint(2.5, 2.5, 1)

		-- переход в следующее состояние
		curr_state = "_GEO_LANDING_2"
	end,
	["_GEO_LANDING_2"] = function (x) 
		magnet:reset()
        run(colors.red, 0.6)
        flag()
        
        ap.push(Ev.MCE_LANDING)

		-- переход в следующее состояние
		curr_state = "_FINAL_NODE_1"
	end,
	["_FINAL_NODE_1"] = function (x) 
		-- выключение двигателей и конец программы
		ap.push(Ev.ENGINES_DISARM)
		curr_state = "NONE"

	end,
}

-- функция обработки событий, автоматически вызывается автопилотом
function callback(event)
	if (event == Ev.TAKEOFF_COMPLETE) then
		action[curr_state]()
	end

	if (event == Ev.POINT_REACHED) then
		action[curr_state]()
	end

	if (event == Ev.COPTER_LANDED) then
		sleep(2)
		action[curr_state]()
	end
end

startT = Timer.new(0.1, function()
    _,_,_,_,_,_,_,ch8 = rc()
    if ch8 > 0 then
        action[curr_state]()
    else
        leds:set(0,0,1,0)
    end
end
)

