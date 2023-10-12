local Debug = {}

local stage = display.currentStage

local car
local velocityText, angleVelocityText, onTrackText, posText

Debug.init = function(_car)
	velocityText = display.newText(stage, "Velocity: ", 0, 0, native.systemFont, 8)
	angleVelocityText = display.newText(stage, "Angle Velocity: ", 0, 10, native.systemFont, 8)
	posText = display.newText(stage, "Position: ", 0, 20, native.systemFont, 8)
	--onTrackText = display.newText(stage, "On Track: ", 0, 30, native.systemFont, 8)
	--onTrackText.anchorX, onTrackText.anchorY = 0, 0
	posText.anchorX, posText.anchorY = 0, 0
	velocityText.anchorX, velocityText.anchorY = 0, 0
	angleVelocityText.anchorX, angleVelocityText.anchorY = 0, 0

	car = _car

end

Debug.update = function()
	
	velocityText.text = "Velocity: " .. math.floor(car.linearVelocity)
	angleVelocityText.text = "Angle Velocity: " .. math.floor(car.angularVelocity)
	posText.text = "Position: " .. math.floor(car.x) .. ", " .. math.floor(car.y)

end

return Debug