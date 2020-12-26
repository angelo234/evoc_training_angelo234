local M = {}

local playerInstance = 'scenario_player0'
local helper = require('scenario/scenariohelper')

local wp_num = 0

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
	
	wp_num = 0
	
	--Reset barrier position (place it underground)
	local barrier = scenetree.findObject("moving_barrier1")
	
	local newPosition = Point3F(297, -98, 0)
	barrier:setPosition(newPosition)
end

local function onRaceStart()
	reset()
	
	helper.flashUiMessage("Get up to 80km/h (50mph) for the lane change. A barrier will appear on one side and avoid it.", 5)
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

local function onRaceWaypoint(data, goal)
	--Increment waypoint number
	wp_num = wp_num + 1
	
	local wp = data.waypointName
	
	--Tell player to get up to 80 km/h or 50 mph
	if wp == 'wp1' then
		
	
	elseif wp == 'wp3' then
		if lc1_speed_checked == false then
			local text = "You didn't do the lane change maneuver!"
			
			scenario_scenarios.finish({failed = text})
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
	if lc1_activated == true and lc1_speed_checked == false then
		local fail_msg = "You went the wrong way!"
		
		if data.triggerName == 'lc1_speed_check' and lc1_speed_checked == false then
			--If player entered too slowly, fail them

			--20.1 m/s = 72.4 km/h
			if getVehicleSpeed() < 20.1 then
				local fail_speed_msg = "Your speed was too slow. You need to be going at least 80 km/h or 50 mph."
			
				scenario_scenarios.finish({failed = fail_speed_msg})
			end
			
			lc1_speed_checked = true			
		end	
	end
	
	if data.triggerName == 'lc1' and lc1_activated == false then
		lc1_activated = true
		
		--Randomly choose path to take (0 for left, 1 for right)
		local rand = math.random(0, 1)
		
		lc1_goleft = rand == 0
		
		--Places barrier to block one side
		
		local barrier = scenetree.findObject("moving_barrier1")
		
		if rand == 0 then
			--helper.flashUiMessage("LEFT", 2)
			
			--Block right side
			
			local newPosition = Point3F(289, -98, 34.344)
			barrier:setPosition(newPosition)
			
		else
			--helper.flashUiMessage("RIGHT", 2)
			
			--Block left side
			
			local newPosition = Point3F(297, -98, 34.344)
			barrier:setPosition(newPosition)
		end
		
		be:reloadStaticCollision(false)

	elseif data.triggerName == 'stopsign1_trigger' then
		--If player didn't stop and went over trigger, fail them
		if stop1_flag == true then
			local text = "You didn't stop at the stop sign!"
		
			scenario_scenarios.finish({failed = text})
		end		

	elseif data.triggerName == 'stopsign2_trigger' then
		--If player didn't stop and went over trigger, fail them
		if stop2_flag == true then
			local text = "You didn't stop at the stop sign!"
		
			scenario_scenarios.finish({failed = text})
		end		
	end
end

M.onBeamNGTrigger = onBeamNGTrigger
M.onRaceStart = onRaceStart
M.onRaceTick = onRaceTick
M.onRaceWaypoint = onRaceWaypoint
 
return M