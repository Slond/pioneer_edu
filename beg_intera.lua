local ledbar = Ledbar.new(29)
local matrixLeds = 3

local unpack = table.unpack

function callback(event)
end

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


local str = {{1,2,3,4,5},{1},{1},{1},{},{},
        {1,2,3,4,5},{1,3,5},{1,3,5},{1,3,5},{},{},
        {1,2,3,4,5},{1,5},{1,5},{1,2,3,4,5},{},{},
        {2,3,4},{1,5},{1,5},{2,4},{},{},
        {1,2,3,4,5},{3},{2,4},{1,5},{},{},
        {2,3,4,5},{1,3},{1,3},{2,3,4,5},{},{},
        {1,2,3,4,5},{3},{3},{1,2,3,4,5},
        {},{},{},{}}
    
function ledOn(x,y,color)
    ledbar:set(5*(y-1)+x+matrixLeds, unpack(color))
end

function ledsOff()
    for i=0, 29 do
        ledbar:set(i,0,0,0)
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

while true do
run(colors.red, 0.5)
end
