local Util = require("lib.util")
local Camera = require("lib.camera")

local stage = display.currentStage

local Car = {}
local car

local accelerationForce = 2
local brakingForce = 1 - .02
local steeringForce = .0008
local steeringForce2 = .015
local inertiaForce = .0001

local targetDT = 1/60 * 1000
local timeScaleFactor = 1

Car.getCar = function()
	return car
end

Car.new = function (spawnX, spawnY)
	car = {x = spawnX, y = spawnY, rotation = 0, linearVelocity = 0, angularVelocity = 0}
	--create rect to display car, needs to be its own object to offset by camera
	local rect = Util.makeRect("car-top.png", spawnX, spawnY, 30, 30, stage)
	rect.anchorY = 20
	--display.newImageRect(stage,"car-top.png",30,30)
	Camera.registerObject(rect)
	--rect.x, rect.y = spawnX, spawnY
	--create physics object for car
	local phys = display.newRect(stage, 0, 0, 30, 30)
	phys.isVisible = false
	phys.x, phys.y = spawnX, spawnY
	physics.addBody(phys,"dynamic", {density = 1, box={halfWidth = 6, halfHeight = 10} })
	phys.linearDamping = 1
	phys.angularDamping = 7
	
	--set references to car for future reference
	car.rect, car.phys = rect, phys

	car.accel, car.brake, car.steerLeft, car.steerRight = {}, {}, {}, {}
	car.moveFuncs = {car.accel, car.brake, car.steerLeft, car.steerRight}
	
	car.accel.func = function (self)
		local carAngleX, carAngleY = Util.angleToVector(self.phys.rotation)
		self.phys:applyForce( timeScaleFactor * carAngleX * accelerationForce, timeScaleFactor* carAngleY * accelerationForce, self.x, self.y )
		self.phys:applyTorque( timeScaleFactor * car.angularVelocity * (math.sqrt(self.linearVelocity)) * inertiaForce)
	end
	
	car.brake.func = function (self)
		local x, y = self.phys:getLinearVelocity()
		self.phys:setLinearVelocity( timeScaleFactor * x * brakingForce, timeScaleFactor * y * brakingForce )
	end
	
	car.steerLeft.func = function (self)
		--self.phys:applyTorque( self.linearVelocity*-steeringForce)
		self.phys:applyTorque( timeScaleFactor * math.sqrt(self.linearVelocity)*-steeringForce2)
	end
	
	car.steerRight.func = function (self)
		--self.phys:applyTorque( self.linearVelocity*steeringForce)
		self.phys:applyTorque( timeScaleFactor * math.sqrt(self.linearVelocity)*steeringForce2)
	end
	
	car.linearInput = function (self, dir, value)
		self[dir].run = value
	end
	
	car.onFrame = function (self, _dt)
		local timeScale = _dt / targetDT
		print (_dt, timeScale)

		self.linearVelocity = Util.vectorDistance(self.phys:getLinearVelocity())
		self.angularVelocity = self.phys.angularVelocity
		
		for i = 1, #self.moveFuncs do
			if self.moveFuncs[i].run then
				self.moveFuncs[i].func(self)
			end
		end
		self.x, self.y = self.phys.x, self.phys.y
		self.rect.x, self.rect.y = self.x, self.y
		self.rotation = self.phys.rotation
		self.rect.rotation = self.rotation
	end

	return car
end



return Car