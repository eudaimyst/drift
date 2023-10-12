
local Camera = {}

local camera
local cameraView
local cameraTarget

local cameraOffsetX, cameraOffsetY = 0, display.contentHeight/6

local rotateVector = function (x, y, angle)
	local ca, sa = math.cos(angle), math.sin(angle)
	return x * ca - y * sa, x * sa + y * ca
end
local getDistance = function (x1, y1, x2, y2)
	return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end
local getAngle = function (x1, y1, x2, y2)
	return math.atan2(y2-y1, x2-x1)
end

Camera.registerObject = function(obj)
	print(obj.width)
	local newObj = display.newRect(cameraView, 0, 0, obj.width, obj.height)
	newObj.obj = obj
	--print(obj.fillRef.type, obj.fillRef.filename)
	newObj.fill = {type = obj.fillRef.type, filename = obj.fillRef.filename}
	--print(newObj.fill)
	newObj.stroke = obj.stroke
	cameraView.objects[#cameraView.objects+1] = newObj
	cameraView:bringToFront()
end

Camera.new = function(stage, x, y, w, h) --x and y are the starting position of the camera
	local cx, cy = display.contentCenterX, display.contentCenterY
	camera = display.newRect(stage, x or cx, y or cy, w or display.contentWidth/4, h or display.contentHeight/4)
	local cvWidth, cvHeight = camera.width, camera.height
	cameraView = display.newContainer(stage, cvWidth, cvHeight)
	cameraView.objects = {}
	cameraView.anchorX, cameraView.anchorY = 0, 0
	cameraView.bringToFront = function(self) stage:insert(self) end
	local containerBG = display.newRect(cameraView, 0, 0, cvWidth, cvHeight)
	containerBG:setFillColor(0)
	camera.alpha = 0.5
	
	return camera
end

Camera.registerTarget = function(_target)
	cameraTarget = _target
end

Camera.updatePosition = function()
	local dx, dy, dr = cameraTarget.x - camera.x, cameraTarget.y - camera.y, cameraTarget.rotation - camera.rotation
	camera.x, camera.y = camera.x + dx , camera.y + dy
	camera.rotation = camera.rotation + dr/100
end

Camera.onFrame = function()
	
	Camera.updatePosition()

	local dx, dy = 0, 0
	for i=1,#cameraView.objects do
		local camObj = cameraView.objects[i]
		local obj = camObj.obj
		if obj.width > camera.width or obj.height > camera.height then
			local dx, dy = obj.x - camera.x, obj.y - camera.y
			local anchorX, anchorY = dx / camObj.width, dy / camObj.height
			camObj.anchorX, camObj.anchorY = .5 - anchorX, .5 - anchorY
			camObj.rotation = obj.rotation - camera.rotation
		else
			--angle to object normalised to camera rotation
			local angle = getAngle(camera.x, camera.y, obj.x, obj.y) - math.rad(camera.rotation)
			--delta x and y normalised to camera rotation
			local dx, dy = rotateVector(obj.x - camera.x, obj.y - camera.y, -math.rad(camera.rotation))
			camObj.x, camObj.y = dx, dy
			if obj == cameraTarget.rect then
				camObj.rotation = obj.rotation - camera.rotation
			else
				camObj.rotation = obj.rotation
			end
		end
	end
end

return Camera