-- создание порта управления светодиодом
local ledbar = Ledbar.new(8)

-- переменная текущего состояния
local curr_state = "START"

-- таблица функций, вызываемых в зависимости от состояния
action = {
	["START"] = function(x)

		ledbar:set(0, 1, 0.0, 0.0)

		sleep(1000 / 1000.0) 
		ledbar:set(1, 0.0, 1, 0.0)

		sleep(1000 / 1000.0) 
		ledbar:set(2, 0.0, 0.0, 1)

		sleep(1000 / 1000.0) 
		ledbar:set(3, 1, 1, 0.0)

		-- выключение двигателей и конец программы
		ap.push(Ev.ENGINES_DISARM)
		curr_state = "NONE"

	end,
}

-- функция обработки событий, автоматически вызывается автопилотом
function callback(event)
	if (event == Ev.ALTITUDE_REACHED) then
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

-- вызов функции из таблицы состояний, соответствующей первому состоянию
action[curr_state]()
