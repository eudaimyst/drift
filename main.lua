-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
local physics = require("physics")
local Car = require("lib.car")
local Debug = require("lib.debug")
local Camera = require("lib.camera")
local Track = require("lib.track")

local stage = display.currentStage

physics.start()
physics.setGravity(0,0);

local debug = true
local cx, cy = display.contentCenterX, display.contentCenterY + display.contentCenterY/2
local camWidth, camHeight = display.contentWidth, display.contentHeight
camWidth, camHeight= display.contentWidth, display.contentHeight
local camera = Camera.new(stage, cx, cy, camWidth, camHeight)
local track = Track.new(stage)
local car = Car.new(cx, cy)
Camera.registerTarget(car)

if debug == true then
	Debug.init(car)
end

local prevTime = 0
local onFrame = function(event)
	local dt = event.time - prevTime
	prevTime = event.time
	car:onFrame(dt)
	Camera:onFrame()
	Track:onFrame()
	if debug == true then
		Debug.update()
	end
end

local onKeyEvent = function(event)

	if event.phase == "down" then
		if event.keyName == "up" then
			car:linearInput("accel", true)
		elseif event.keyName == "down" then
			car:linearInput("brake", true)
		elseif event.keyName == "left" then
			car:linearInput("steerLeft", true)
		elseif event.keyName == "right" then
			car:linearInput("steerRight", true)
		end
	elseif event.phase == "up" then
		if event.keyName == "up" then
			car:linearInput("accel", false)
		elseif event.keyName == "down" then
			car:linearInput("brake", false)
		elseif event.keyName == "left" then
			car:linearInput("steerLeft", false)
		elseif event.keyName == "right" then
			car:linearInput("steerRight", false)
		end
	end


end

Runtime:addEventListener("key", onKeyEvent )
Runtime:addEventListener("enterFrame", onFrame )