local Util = {}

Util.makeRect = function(filename, x, y, width, height, parent)
	local obj = display.newRect(parent or display.getCurrentStage(), x or display.contentCenterX, y or display.contentCenterY, width or 100,height or 100)
	obj.fillRef = {type = "image", filename = filename }
	obj.fill = {type = obj.fillRef.type, filename = obj.fillRef.filename}
	return obj
end

Util.angleToVector = function (angle) --angle in degrees
	local a = math.rad(angle-90)
	return math.cos(a), math.sin(a)
end
Util.vectorToAngle = function (x, y)
	return math.deg(math.atan2(y, x)) + 90
end
Util.rotatePoint = function ( x, y, angle )
	local x2 = x * math.cos(angle) - y * math.sin(angle)
	local y2 = x * math.sin(angle) + y * math.cos(angle)
	return x2, y2
end

Util.rotateAroundPoint = function(objectX, objectY, originX, originY, angle)
	local x = objectX - originX
	local y = objectY - originY
	local x2 = x * math.cos(angle) - y * math.sin(angle)
	local y2 = x * math.sin(angle) + y * math.cos(angle)
	return x2 + originX, y2 + originY
end

Util.vectorDistance = function (x, y)
	return math.sqrt(x*x + y*y)
end

return Util