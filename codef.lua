local leds = Ledbar.new(4)
unpack = table.unpack

points = {}
height = 1

point_num = 0

for i=0, 179 do
    xCord = r*math.cos(i*math.pi/180)
    yCord = r*math.sin(i*math.pi/180)
    points.i+1 = {xCord, yCord, height}
end

function callback(event)
    if event = Ev.TAKEOFF_COMPLETE or event == Ev.POINT_REACHED then
        point_num = point_num + 1
        if point_num > 180 then
            ap.goToLocalPoint(unpack(points[point_num]))
            ap.updateYaw(-2)
        else
            point_num = point_num - 180
        end
    end
end

Timer.callLater(2, function()
    ap.push(Ev.MCE_PREFLIGHT)
    sleep(2)
    ap.push(Ev.MCE_TAKEOFF)
end)