local Bezier = {}

	Bezier.makeCurve = function(x1, y1, cx1, cy1, x2, y2, cx2, cy2, steps, _drawLines, _drawHandles, _interactable, _parent)

		local drawLines; if _drawLines == false then drawLines = false else drawLines = true end
		local interactable = _interactable or false
		local drawHandles = _drawHandles or false
		local parent = _parent or display.currentStage
		
		local function makePoint(x, y, cx, cy) --constructs a "point" in the curve, used for start and end points
			local point = {origin = {x=0, y=0}, control = {x=0, y=0}}
			point.origin.x, point.origin.y = x, y
			point.control.x, point.control.y = cx, cy
			return point
		end
		local curve = { steps = steps, curvePoints = {}} -- construct the curve object
		curve.parent = parent --store the curves parent object to access for drawing
		
		curve.startPoint = makePoint(x1, y1, cx1, cy1) --store the origin and control co-ords of the start point
		curve.endPoint = makePoint(x2, y2, cx2, cy2) --store the origin and control co-ords of the end point

		curve.setStartPointOrigin = function (x, y) --set the origin of the start point
			curve.startPoint.origin.x, curve.startPoint.origin.y = x, y
			curve.curvePoints = curve:createPoints() --recreate the curvePoints table
		end
		curve.setStartPointControl = function (x, y) --set the control of the start point
			curve.startPoint.control.x, curve.startPoint.control.y = x, y
			curve.curvePoints = curve:createPoints() --recreate the curvePoints table
		end
		curve.setEndPointOrigin = function (x, y) --set the origin of the end point
			curve.endPoint.origin.x, curve.endPoint.origin.y = x, y
			curve.curvePoints = curve:createPoints() --recreate the curvePoints table
		end
		curve.setEndPointControl = function (x, y) --set the control of the end point
			curve.endPoint.control.x, curve.endPoint.control.y = x, y
			curve.curvePoints = curve:createPoints() --recreate the curvePoints table
		end

		curve.getTangentAtIndex = function(self, index)
			local tangentDeltaX = self.curvePoints[index].x - self.curvePoints[index+1].x
			local tangentDeltaY = self.curvePoints[index].y - self.curvePoints[index+1].y
			local tangent = {x = 0, y = 0}
			local tangentLen = math.sqrt(tangentDeltaX^2 + tangentDeltaY^2)
			tangent.x, tangent.y = tangentDeltaX/tangentLen, tangentDeltaY/tangentLen
			return tangent
		end

		curve.getEndTangent = function(self)
			local t = self:getTangentAtIndex(#self.curvePoints-1)
			t.x, t.y = t.x * -1, t.y * -1
			return t
		end

		curve.getStartTangent = function(self)
			return self:getTangentAtIndex(1)
		end
		
		curve.createPoints = function(self) -- creates the points in the curve and stores them in the curvePoints table
			local curvePoints = {} --create a table to store the points in

			local startPoint = self.startPoint --deconstruct the start and end points for readability and performance (less table lookups during math loop)
			local endPoint = self.endPoint
			local so, sc = startPoint.origin, startPoint.control
			local eo, ec = endPoint.origin, endPoint.control
			local sox, soy, scx, scy = so.x, so.y, sc.x, sc.y
			local eox, eoy, ecx, ecy = eo.x, eo.y, ec.x, ec.y

			local step = 1/steps --used in the maths for the bezier curve
			curvePoints[1] = startPoint.origin --set the initial point to the start point
			for i = 1, self.steps do
				local point = {x = 0, y = 0}
				local t = i*step --readability
				point.x = (1-t)^3*sox + 3*(1-t)^2*t*scx + 3*(1-t)*t^2*ecx + t^3*eox --maths for the bezier curve
				point.y = (1-t)^3*soy + 3*(1-t)^2*t*scy + 3*(1-t)*t^2*ecy + t^3*eoy
				curvePoints[i+1] = point
			end
			return curvePoints
		end

		curve.drawLines = function(self) --draws the points in the curve
			parent = self.parent
			local curvePoints = self.curvePoints
			local curveLines = {}
			for i = 1, #curvePoints-1 do
				local point, nextPoint = curvePoints[i], curvePoints[i+1]
				curveLines[i]= display.newLine(parent, point.x, point.y, nextPoint.x, nextPoint.y)
			end
			if self.curveLines  then
				if #self.curveLines > 0 then
					for i = 1, #self.curveLines do
						self.curveLines[i]:removeSelf()
					end
				end
			end
			self.curveLines = curveLines
		end

		curve.drawHandles = function(self) --draw the handles to manipulate the curve
			parent = self.parent
			local so, sc = self.startPoint.origin, self.startPoint.control
			local eo, ec = self.endPoint.origin, self.endPoint.control
			local curveHandles = {}
			local function makeHandles (ox, oy, cx, cy)
				local handles = {}
				local function drawCircle(x, y, t)
					local handleCircle = display.newCircle(parent, x, y, 10)
					handleCircle.curve = curve
					handleCircle.t = t
					if t == "control" then
						handleCircle:setFillColor(0)
						handleCircle:setStrokeColor(0, 0, 1)
						handleCircle.strokeWidth = 1
					else
						handleCircle:setFillColor(0, 0, 1)
					end
					function handleCircle:touch(event)
						if ( event.phase == "began" ) then print(self.t.." handle touched")
						elseif ( event.phase == "moved" ) then self.x, self.y = event.x, event.y; self.updateFunc(event.x, event.y); handleCircle.curve:drawLines()
						elseif ( event.phase == "ended" ) then print (self.t.." handle released")
						end
						return true
					end
					if (interactable) then
						handleCircle:addEventListener( "touch", handleCircle )
					end
					return handleCircle
				end

				handles.control = drawCircle(cx, cy, "control")
				handles.origin = drawCircle(ox, oy, "origin")
				return handles
			end
			curveHandles.startPoint = makeHandles(so.x, so.y, sc.x, sc.y)
			curveHandles.endPoint = makeHandles(eo.x, eo.y, ec.x, ec.y)
			curveHandles.startPoint.control.updateFunc = self.setStartPointControl
			curveHandles.startPoint.origin.updateFunc = self.setStartPointOrigin
			curveHandles.endPoint.control.updateFunc = self.setEndPointControl
			curveHandles.endPoint.control:setStrokeColor(1, 0, 0)
			curveHandles.endPoint.origin.updateFunc = self.setEndPointOrigin
			curveHandles.endPoint.origin:setFillColor(1, 0, 0)

			self.curveHandles = curveHandles
		end

		curve.removeSelf = function(self)
			curve.curvePoints = nil
			if self.curveLines then
				if #self.curveLines > 0 then
					for i = 1, #self.curveLines do
						self.curveLines[i]:removeSelf()
					end
				end
			end
			if self.curveHandles then
				if self.curveHandles.startPoint then
					if self.curveHandles.startPoint.control then
						self.curveHandles.startPoint.control:removeSelf()
					end
					if self.curveHandles.startPoint.origin then
						self.curveHandles.startPoint.origin:removeSelf()
					end
				end
				if self.curveHandles.endPoint then
					if self.curveHandles.endPoint.control then
						self.curveHandles.endPoint.control:removeSelf()
					end
					if self.curveHandles.endPoint.origin then
						self.curveHandles.endPoint.origin:removeSelf()
					end
				end
			end
		end

		curve.curvePoints = curve:createPoints() --initialise the curvePoints table and set it upon making the curve
		if drawLines then curve:drawLines() end
		if drawHandles then curve:drawHandles() end
		
		print("curve created between startPoint: "..x1..", "..y1.."; "..x2..", "..y2 )
		print("curve points: "..#curve.curvePoints)
		return curve
	end

	Bezier.makeChain2 = function(shape, steps, _drawLines, _parent) --shapes need to have 3 values, vector of start, end and control, defined as sx, sy, ex, ey, cx, cy
		local drawLines; if _drawLines == false then drawLines = false else drawLines = true end
		local chain = {}
		local parent = _parent or display.currentStage
		
		local chainPointCount = 0
		local newChainPoints = {}
		local chainCurves = {}

		local addChainPoint = function( sx, sy, ex, ey, cx, cy )
			chainCurves[#chainCurves+1] = Bezier.makeCurve(	sx, sy, cx, cy, ex, ey, cx, cy, steps, drawLines, false, false, parent)
		end
		
		for i = 1, #shape do
				addChainPoint(shape[i].sx, shape[i].sy, shape[i].ex, shape[i].ey, shape[i].cx, shape[i].cy)
		end

		chain.curvePoints = {}
		for i = 1, #chainCurves do
			for j = 1, #chainCurves[i].curvePoints do
				chain.curvePoints[#chain.curvePoints+1] = chainCurves[i].curvePoints[j]
			end
		end

		return chain
	end

	Bezier.makeChain = function(shape, steps, _drawLines, _parent)
		local drawLines; if _drawLines == false then drawLines = false else drawLines = true end
		local chain = {}
		local parent = _parent or display.currentStage
		
		local chainPointCount = 0
		local newChainPoints = {}
		local chainCurves = {}

		local addChainPoint = function( x, y, closeChain )
			chainPointCount = chainPointCount + 1
			local currentPoint = {x = x, y = y}
			local previousPoint = newChainPoints[#newChainPoints]
			newChainPoints[#newChainPoints+1] = currentPoint

			if chainPointCount == 4 then
				chainCurves[#chainCurves+1] = Bezier.makeCurve(	newChainPoints[#newChainPoints-2].x, newChainPoints[#newChainPoints-2].y, previousPoint.x, previousPoint.y,
																currentPoint.x, currentPoint.y, previousPoint.x, previousPoint.y,
																steps, drawLines, false, false, parent)
			end
			if chainPointCount > 4 then

				local tangent = chainCurves[#chainCurves]:getEndTangent()
				local deltaX, deltaY = currentPoint.x - previousPoint.x, currentPoint.y - previousPoint.y
				local halfDeltaLen = math.abs(math.sqrt(deltaX^2 + deltaY^2)) / 2
				local tPos = {x = tangent.x * halfDeltaLen + previousPoint.x, y = tangent.y * halfDeltaLen + previousPoint.y}
				if closeChain then
					local startTangent = chainCurves[1]:getStartTangent()
					local startDeltaX, startDeltaY = currentPoint.x - previousPoint.x, currentPoint.y - previousPoint.y
					local startHalfDeltaLen = math.abs(math.sqrt(startDeltaX^2 + startDeltaY^2)) / 2
					local startTPos = {x = startTangent.x * startHalfDeltaLen + currentPoint.x, y = startTangent.y * startHalfDeltaLen + currentPoint.y}
					chainCurves[#chainCurves+1] = Bezier.makeCurve(	previousPoint.x, previousPoint.y, tPos.x, tPos.y,
																	currentPoint.x, currentPoint.y, startTPos.x, startTPos.y,
																	steps, drawLines, false, false, parent)
				else
				chainCurves[#chainCurves+1] = Bezier.makeCurve(	previousPoint.x, previousPoint.y, tPos.x, tPos.y,
																currentPoint.x, currentPoint.y, tPos.x, tPos.y,
																steps, drawLines, false, false, parent)
				end
			end
		end

		for i = 1, #shape do
			print("adding chain point "..i..": "..shape[i].x..", "..shape[i].y)
			if i < #shape then
				addChainPoint(shape[i].x, shape[i].y, false)
			else
				addChainPoint(shape[i].x, shape[i].y, true)
			end
		end

		chain.curvePoints = {}
		for i = 1, #chainCurves do
			for j = 1, #chainCurves[i].curvePoints do
				chain.curvePoints[#chain.curvePoints+1] = chainCurves[i].curvePoints[j]
			end
		end

		return chain
	end

return Bezier