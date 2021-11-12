import sensor, image, time, pyb

sensor.reset()
sensor.set_pixformat(sensor.RGB565)
sensor.set_framesize(sensor.QVGA)
sensor.skip_frames(time = 2000)
clock = time.clock()

while(True):
    clock.tick()

    img = sensor.snapshot()


    # Character and string rotation can be done at 0, 90, 180, 270, and etc. degrees.
    img.draw_string(0, 200, str(clock.fps()), color = (255, 0, 0), scale = 2, mono_space = False,
                        char_rotation = 0, char_hmirror = False, char_vflip = False,
                        string_rotation = 0, string_hmirror = False, string_vflip = False)

    img.draw_line(0,220,100,220,(0,255,0),2)
    img.draw_rectangle(0,220,100,220,(0,244,0),2,1)

    print(clock.fps())
