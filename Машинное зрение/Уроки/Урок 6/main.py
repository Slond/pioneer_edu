import sensor, image, time, math, pyb
from pyb import UART, LED

sensor.reset()
sensor.set_pixformat(sensor.RGB565)
screen_w = 160
screen_h = 120
sensor.set_framesize(sensor.QQVGA)
sensor.skip_frames(30)
sensor.set_auto_whitebal(False)

uart = UART(3)
uart.init(9600, bits=8, parity=None, stop=1, timeout_char=1000)

red_led = pyb.LED(1)
green_led = pyb.LED(2)
blue_led = pyb.LED(3)


clock = time.clock()

def sendPacket(ledState, dx, dy):
    uart.writechar(0xBB) # packet begin byte
    uart.writechar(ledState)
    uart.writechar(dx.to_bytes(1, 'big')[0])
    uart.writechar(dy.to_bytes(1, 'big')[0])
    uart.writechar(0xFF) # packet end byte

while True:
    clock.tick()
    img = sensor.snapshot()
    #img.rotation_corr(z_rotation = 90)
    apriltag_array = img.find_apriltags()#.sort(key=lambda x: x.id())

    if len(apriltag_array) == 0:
        red_led.on()
        green_led.off()
        blue_led.off()
        sendPacket(0, 0, 0) # send info, no qr code found
    else:
        for tag in apriltag_array:
            img.draw_rectangle(tag.rect(), color = (255, 0, 0))
            img.draw_cross(tag.cx(), tag.cy(), color = (0, 255, 0))
            red_led.off()
            green_led.off()
            blue_led.on()
            print_args = (tag.id(), (180 * tag.rotation())/math.pi)
            print("Tag Number", str(tag.id()))
            dx = int(tag.cx() - screen_w/2)
            dy = int(tag.cy() - screen_h/2)
            print("dx=" + str(dx) + ", dy=" + str(dy))
            sendPacket(tag.id(), dx, -dy)
            break
print(clock.fps())















