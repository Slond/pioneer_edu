from pyb import UART, LED

import sensor, lcd, image, time, utime

ledBlue = LED(2)
ledGreen = LED(3)

ledBlue.on()
sensor.reset()                      # Перезапустить камеру
sensor.set_pixformat(sensor.RGB565) # Ставим формат камеры RGB565
sensor.set_framesize(sensor.LCD)   # Выставляем размеры видео 320x240
sensor.skip_frames(100)     # Пауза необходима для выполнения настроек
clock = time.clock()                # Создаем объект для отслеживания FPS
lcd.init()
#lcd.set_backlight(True)
ledBlue.off()

#Init uart

uart = UART(3)
uart.init(9600, bits=8, parity=None, stop=1, timeout_char=1000) # Инициализируем UART

M_LED_COUNT = 10
led_counter = M_LED_COUNT
led_mode = 0
while(True):
   clock.tick()                    # Update the FPS clock.
   clk = utime.ticks_ms()
   img = sensor.snapshot()         # Получить картинку и записать ее в переменную
   #print(clock.fps())

   for r in img.find_rects(threshold = 40000):
       img.draw_rectangle(r.x(), r.y(), r.w(), r.h(), (255, 0, 0))
       for p in r.corners():
           img.draw_circle(p[0], p[1], 5, color = (0, 255, 0))
       print(r)

   lcd.display(img)

   print(img.get_histogram().get_statistics().l_mean())
   uart.writechar(img.get_histogram().get_statistics().l_mean())
   led_counter = led_counter - 1
   if (led_counter == 0):
       if (led_mode == 0):
           ledGreen.on()
       else:
           ledGreen.off()
       led_mode = 1 - led_mode
       led_counter = M_LED_COUNT
   while (clk + 100 > utime.ticks_ms()):
       pass
