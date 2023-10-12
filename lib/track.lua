local Camera = require("lib.camera")
local Util = require("lib.util")
local Car = require("lib.car")
local physics = require("physics")


local Track = {}
local trackGroup -- created in main, passed in to init so it's inserted before car
local trackPosX, trackPosY

local segmentCount = 1

local trackWidth = 60
local segmentHeight = 150
local offsetRandMax = 100
local prevSegmentOffset = 0
local segmentsDrawn = 2
local currentX = 0

local trackAngle = 0

local objectTypes = {
	cone = {filename = "cone.png", width = 10, height = 10}
}
local objects = {}

local function objectCollision( self, event )
	
	if ( event.phase == "began" ) then
		--print( self.myName .. ": collision began with " .. event.other.myName )
		if event.other == Car.getCar().phys then
			print("hit car")
			
			self:applyAngularImpulse( .1 )
		end

	elseif ( event.phase == "ended" ) then
		--print( self.myName .. ": collision ended with " .. event.other.myName )
	end
end

Track.newObject = function(objectType, x, y)
	local obj = {}
	obj.rect = Util.makeRect(objectType.filename, x, y, objectType.width, objectType.height, trackGroup)
	Camera.registerObject(obj.rect)
	
	
	obj.phys = display.newRect(trackGroup, x, y, objectType.width, objectType.height)
	obj.phys.isVisible = false
	objects[#objects+1] = obj
	physics.addBody(obj.phys,"dynamic", { box={halfWidth = objectType.width/2, halfHeight = objectType.height/2} })
	obj.phys.linearDamping = 1
	obj.phys.angularDamping = 4
	obj.phys.collision = objectCollision
	obj.phys:addEventListener( "collision" )
end

Track.new = function (_trackGroup)
	trackGroup = _trackGroup
	local stage = display.currentStage
	trackPosX, trackPosY = display.contentCenterX, display.contentCenterY
	local track = {x = 0, y = 0, rotation = 0}
	track.rect = Util.makeRect("track.png", trackPosX, trackPosY, 3000, 3000, trackGroup)
	track.mask = display.newRect(trackGroup, trackPosX, trackPosY, 3000, 3000)
	track.mask.isHitTestable = true
	local mask = graphics.newMask("track_mask.png")
	track.mask:setMask(mask)
	track.mask.maskScaleX = 2.929
	track.mask.maskScaleY = 2.929
	physics.addBody(track.mask, "static", {isSensor = true})
	--track.maskX, track.maskY = trackPosX, trackPosY
	--display.newImageRect(trackGroup, "track.png", 3000, 3000)
	Camera.registerObject(track.rect)
	for i = 1, 100 do
		Track.newObject(objectTypes.cone, i * 10, 0)
	end
	for i = 1, segmentsDrawn do
		--Track.drawSegment()
	end
	return track
end

Track.drawSegment = function ()

	local xOffset = math.random(-offsetRandMax, offsetRandMax)
	
	local trackLineLeft = display.newLine(trackGroup, -trackWidth + prevSegmentOffset, -segmentHeight * (segmentCount - 1), -trackWidth + xOffset,-segmentHeight * segmentCount)
	local trackLineRight = display.newLine(trackGroup, trackWidth + prevSegmentOffset, -segmentHeight * (segmentCount - 1), trackWidth + xOffset,-segmentHeight * segmentCount)
	trackLineLeft.x = trackLineLeft.x - 10
	trackLineRight.x = trackLineRight.x + 10
	trackLineLeft.strokeWidth = 10
	trackLineRight.strokeWidth = 10
	trackLineLeft:setStrokeColor(1, .3, .3)
	trackLineRight:setStrokeColor(.3, .3, 1)
	currentX = currentX + xOffset 
	local coneLeft = display.newImageRect(trackGroup, "cone.png", 10, 10)
	coneLeft.x, coneLeft.y = -trackWidth + currentX, -segmentHeight * segmentCount
	local coneRight = display.newImageRect(trackGroup, "cone.png", 10, 10)
	coneRight.x, coneRight.y = trackWidth + currentX, -segmentHeight * segmentCount
	coneLeft:setFillColor(1, .3, .3)
	coneRight:setFillColor(.3, .3, 1)
	prevSegmentOffset = xOffset
	segmentCount = segmentCount + 1
	trackWidth = trackWidth - .05
	segmentHeight = segmentHeight - .2
	
end

Track.onFrame = function ()

	for i = 1, #objects do
		local obj = objects[i]
		obj.rect.x, obj.rect.y, obj.rect.rotation = obj.phys.x, obj.phys.y, obj.phys.rotation
	end
	--print(camY)
	--[[ 
	if (camY < -segmentHeight * (segmentCount - segmentsDrawn)) then
		Track.drawSegment()
	end
	]]
end

return Track