local M = {}

local helper = require('scenario/scenariohelper')

local lc1_activated = false
local lc1_speed_checked = false
local lc1_goleft = false

local stop1_flag = false
local stop2_flag = false

local function reset()
	lc1_activated = false
	lc1_speed_checked = false
	lc1_goleft = false
	
	stop1_flag = false
	stop2_flag = false
	
	--Reset lane change arrow rotation (place it underground)
	scenetree.findObject("lc1_sign"):setField('rotation', 0, '0 0 1 270')
end

local function onRaceStart()
	reset()
	
	helper.flashUiMessage("Get up to 80km/h (50mph) for the lane change. An arrow sign will appear to tell you which lane to swerve to.", 5)
end

local function getVehicleSpeed()
	local playerCarData = map.objects[map.objectNames['scenario_player0']]
	return playerCarData.vel:length()
end

local function getVehicleRotation()
	local veh = be:getPlayerVehicle(0)
	if not veh then return end

	local vdata = map.objects[veh:getID()]
	if not vdata then return end

	local dir = vdata.dirVec:normalized()
	local rot = math.deg(math.atan2(dir:dot(vec3(1,0,0)), dir:dot(vec3(0,-1,0))))
	
	if rot < 0 then
		rot = rot + 360	
	end
	
	return rot
end

local function onRaceTick(tick)	
	if stop1_flag == true then
		--If player stopped for stop sign, then update flag so player doesn't fail
		if getVehicleSpeed() <= 0.5 then
			helper.flashUiMessage("Continue on.", 4)
			
			stop1_flag = false
		end
	elseif stop2_flag == true then
		--If player stopped for stop sign, then update flag so player doesn't fail
		if getVehicleSpeed() <= 0.5 then
			helper.flashUiMessage("Continue on.", 4)
			
			stop2_flag = false
		end
	end
end

local function passOnDir(dir, msg, fail_msg)
	local rot = getVehicleRotation()
		
	--If vehicle is pointed right way, don't fail player
	if rot >= dir - 90 and rot <= dir + 90 then
		if msg ~= nil then 
			helper.flashUiMessage(msg, 4)
		end		
	--Otherwise fail player
	else
		scenario_scenarios.finish({failed = fail_msg})
	end
end

local function failOnDir(dir, fail_msg, msg)
	local rot = getVehicleRotation()

	--If vehicle is pointed in wrong dir, fail player
	if rot >= dir - 90 and rot <= dir + 90 then
		scenario_scenarios.finish({failed = fail_msg})
	else
		if msg ~= nil then 
			helper.flashUiMessage(msg, 4)
		end
	end
end

local function onRaceWaypointReached(data, goal)
	local wp = data.waypointName
	
	print("onRaceWaypointReached")
	
	--Tell player to get up to 80 km/h or 50 mph
	if wp == 'wp1' then
		
	
	elseif wp == 'wp3' then
		if lc1_speed_checked == false then
			scenario_scenarios.finish({failed = "You didn't do the lane change maneuver!"})
		end
		
	elseif wp == 'wp7' then
		helper.flashUiMessage("Reverse through the slalom course.", 4)
		
	elseif wp == 'wp8' or wp == 'wp9' or wp == 'wp10' or wp == 'wp11' then
		passOnDir(270, nil, "You need to reverse through!")
		
		if wp == 'wp11' then
			helper.flashUiMessage("Reverse into the bay.", 4)
		end
	
	elseif wp == 'wp12' then
		helper.flashUiMessage("Continue to the left.", 4)
	
	elseif wp == 'wp18' then
		stop1_flag = true
		
	elseif wp == 'wp50' then
		stop2_flag = true
		
	end
end

local function onBeamNGTrigger(data)
	if data.triggerName == 'lc1' and not lc1_activated then
		lc1_activated = true
		
		--Randomly choose path to take (0 for left, 1 for right)
		local rand = math.random(0, 1)
		
		lc1_goleft = rand == 0
		
		-- Flip arrow sign to point to the side to travel
		
		if rand == 0 then
			-- Point left
			scenetree.findObject("lc1_sign"):setField('rotation', 0, '0 0 1 180')
			
		else
			-- Point right
			scenetree.findObject("lc1_sign"):setField('rotation', 0, '0 0 1 0')
		end
	end
	
	if lc1_activated and not lc1_speed_checked then
		if data.triggerName == 'lc1_speed_check' then
			--If player entered too slowly, fail them

			--20.1 m/s = 72.4 km/h
			if getVehicleSpeed() < 20.1 then
				scenario_scenarios.finish({failed = "Your speed was too slow. You need to be going at least 80 km/h or 50 mph."})
			end
			
			lc1_speed_checked = true			
		end	
	end
	
	-- Check if player entered correct lane
	if lc1_speed_checked then
	
		if (data.triggerName == 'lc1_trigger_left' and not lc1_goleft) 
		or (data.triggerName == 'lc1_trigger_right' and lc1_goleft) then
			scenario_scenarios.finish({failed = "You went the wrong way!"})
		end
	end

	if data.triggerName == 'stopsign1_trigger' then
		--If player didn't stop and went over trigger, fail them
		if stop1_flag == true then
			scenario_scenarios.finish({failed = "You didn't stop at the stop sign!"})
		end		

	elseif data.triggerName == 'stopsign2_trigger' then
		--If player didn't stop and went over trigger, fail them
		if stop2_flag == true then
			scenario_scenarios.finish({failed = "You didn't stop at the stop sign!"})
		end		
	end
end

M.onBeamNGTrigger = onBeamNGTrigger
M.onRaceStart = onRaceStart
M.onRaceTick = onRaceTick
M.onRaceWaypointReached = onRaceWaypointReached
 
return M