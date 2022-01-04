local M = {}

local helper = require('scenario/scenariohelper')

local wp_num = 0
local park1_flag = false
local park2_flag = false
local stop1_flag = false

local function reset()
	wp_num = 0
	park1_flag = false
	park2_flag = false
	stop1_flag = false
end

local function onRaceStart()
	reset()
	
	helper.flashUiMessage("Head over to the right.",  4)
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
	--Increment waypoint number
	wp_num = wp_num + 1
	
	local wp = data.waypointName
	
	if wp == 'wp1' then
		helper.flashUiMessage("Make a U-turn into the space to the right.", 4)
	
	elseif wp == 'wp2' then
		helper.flashUiMessage("Perform a three point turn.", 4)
	
	--wp3 = 3 point turn exit waypoint
	elseif wp == 'wp3' then
		failOnDir(90, "You didn't turn around!", 
		"Stop alongside the parking space ahead to perform a parallel park maneuver.")
	
	elseif wp == 'wp4' then
		helper.flashUiMessage("Perform the parallel park maneuver into the parking space.", 4)
	
	elseif wp == 'wp5' then
		if not park1_flag then
			local text = "You didn't do the parallel park maneuver before!"
		
			scenario_scenarios.finish({failed = text})
		end
	elseif wp == 'wp6' then
		passOnDir(107, "Reverse out", "You are facing the wrong way!")

	elseif wp == 'wp7' then
		helper.flashUiMessage("Enter forward into the bay to the left.",  4)
	
	elseif wp == 'wp8' then
		helper.flashUiMessage("Reverse through the slalom cones.",  4)
	
	elseif wp == 'wp9' or wp == 'wp10' or wp == 'wp11' then
		failOnDir(140, "You are not driving in reverse!", nil)
	
	elseif wp == 'wp12' then
		helper.flashUiMessage("Stop alongside the parking space ahead to perform another parallel park maneuver.",  4)
	
	elseif wp == 'wp13' then
		helper.flashUiMessage("Perform the parallel park maneuver into the parking space.", 4)
	
	elseif wp == 'wp14' then
		if not park2_flag then
			local text = "You didn't do the parallel park maneuver before!"
		
			scenario_scenarios.finish({failed = text})
		end
	
	elseif wp == 'wp15' then
		stop1_flag = true
		
	elseif wp == 'wp15a' then
		--If player didn't stop and reached the next waypoint, fail them
		if stop1_flag then
			local text = "You didn't stop at the stop sign!"
		
			scenario_scenarios.finish({failed = text})
		end
		
	elseif wp == 'wp16' then
		helper.flashUiMessage("Reverse back to the start.", 4)
		
	elseif wp == 'wp17' or wp == 'wp18' or wp == 'wp19' then
		failOnDir(180, "You are not driving in reverse!", nil)
		
	end
end

local function onBeamNGTrigger(data)
	--1st parallel parking
	if data.triggerName == 'park1' then
		if wp_num == 4 then
			if park1_flag == false then
				park1_flag = true
				helper.flashUiMessage("Drive towards the next waypoint.", 4)
			end
		end
	--2nd parallel parking
	elseif data.triggerName == 'park2' then
		if wp_num == 13 then
			if park2_flag == false then
				park2_flag = true
				helper.flashUiMessage("Drive towards the next waypoint.", 4)
			end
		end
	end
	
end

M.onBeamNGTrigger = onBeamNGTrigger
M.onRaceStart = onRaceStart
M.onRaceTick = onRaceTick
M.onRaceWaypointReached = onRaceWaypointReached
 
return M