local Bezier = require("lib.bezier")

local TrackBuilder = {}

local drawMesh = false
local drawProcess = false
local trackGroup

local boolChance = function(chance)
	if math.random() > chance/100 then return true else return false end
end
local invertChance = function(chance)
	if math.random() > chance/100 then return 1 else return -1 end
end

local checkLineIntercept = function(x1start, y1start, x1end, y1end, x2start, y2start, x2end, y2end, _extraCheck) --extra check is for track generation, not adjusting track lines
	local extraCheck; if _extraCheck == false then extraCheck = false else extraCheck = true end 
	
	local x1min, x1max, y1min, y1max = math.min(x1start, x1end), math.max(x1start, x1end), math.min(y1start, y1end), math.max(y1start, y1end)
	local x2min, x2max, y2min, y2max = math.min(x2start, x2end), math.max(x2start, x2end), math.min(y2start, y2end), math.max(y2start, y2end)
	if x1min > x2max or x1max < x2min or y1min > y2max or y1max < y2min then
		return false
	else
		local slope1, slope2 = (y1end-y1start)/(x1end-x1start), (y2end-y2start)/(x2end-x2start)
		if slope1 == slope2 then
			return false
		else
			local interceptX, interceptY = 0, 0
			if slope1 == math.huge then
				interceptX = x1start
				interceptY = slope2*(interceptX-x2start) + y2start
			elseif slope2 == math.huge then
				interceptX = x2start
				interceptY = slope1*(interceptX-x1start) + y1start
			else
				interceptX = (y2start-y1start+slope1*x1start-slope2*x2start)/(slope1-slope2)
				interceptY = slope1*(interceptX-x1start) + y1start
			end
			if extraCheck then
				if interceptX >= x1min and interceptX <= x1max and interceptX >= x2min and interceptX <= x2max and interceptY >= y1min and interceptY <= y1max and interceptY >= y2min and interceptY <= y2max then
					--add extra check to make sure intercept is not near the start or end of either line
					local x1dist, x2dist = math.abs(interceptX-x1start), math.abs(interceptX-x1end)
					local y1dist, y2dist = math.abs(interceptY-y1start), math.abs(interceptY-y1end)
					local x1diff, x2diff = math.abs(x1end-x1start), math.abs(x2end-x2start)
					local y1diff, y2diff = math.abs(y1end-y1start), math.abs(y2end-y2start)
					local x1diff2, x2diff2 = math.abs(x1end-x2start), math.abs(x2end-x1start)
					local y1diff2, y2diff2 = math.abs(y1end-y2start), math.abs(y2end-y1start)
					local margin = 40
					if x1dist > x1diff/margin and x1dist > x2diff/margin and x2dist > x1diff2/margin and x2dist > x2diff2/margin and y1dist > y1diff/margin and y1dist > y2diff/margin and y2dist > y1diff2/margin and y2dist > y2diff2/margin then
						print("Intercept at "..interceptX..", "..interceptY)
						return interceptX, interceptY
					end
				else
					return false
				end
			else
				print("Intercept at "..interceptX..", "..interceptY)
				return interceptX, interceptY
			end
		end
	end
	return false
end

local checkIntercepts = function(_trackLines)
	local trackLines = _trackLines
	for i = 1, #trackLines do
		for i2 = 1, #trackLines do
			if i == i2 then
				--skip checking self
			else
				local l1, l2 = trackLines[i], trackLines[i2]
				if checkLineIntercept(l1.startX, l1.startY, l1.endX, l1.endY, l2.startX, l2.startY, l2.endX, l2.endY) then
					print("Intercept between line "..i.." and line "..i2)
					return true
				end
			end
		end
	end
	print("no intersecting lines found")
	return false
end


local generateTrack = function()

	local trackBends = math.random(16, 18) --working 16-18
	local bendMinAngle, bendMaxAngle = 30, 90 --30-90
	local bendMinLength, bendMaxLength = 40, 80 --40-80
	local trackStraights = math.random(1, 6) --1-6
	local straghtMinLength, straightMaxLength = 160, 240 --80-240

	local totalAngle = 360 --if positive, clockwise, if negative, counter-clockwise


	local remainingAngle = totalAngle
	local remainingSegments = trackBends + trackStraights
	local remainingStraights = trackStraights
	local remainingBends = trackBends

	local makeTrackSegment = function(segType, additionalAngle)
		local trackSegment = {segType = segType}
		if segType == "straight" then
			trackSegment.length = math.random(straghtMinLength, straightMaxLength)
			trackSegment.angle = additionalAngle or 0
		elseif segType == "bend" then
			trackSegment.angle = math.random(bendMinAngle, bendMaxAngle)*invertChance(50) + (additionalAngle or 0)
			trackSegment.length = math.random(bendMinLength, bendMaxLength)
		end
		return trackSegment
	end

	local track = {}
	for i = 1, trackBends + trackStraights do
		if i == 1 then
			track[1] = makeTrackSegment("straight", remainingAngle/remainingSegments)
		else
			if (boolChance(remainingSegments/remainingStraights*10) and remainingStraights > 0 and track[i-1].segType ~= "straight") or remainingBends == 0 then
				track[i] = makeTrackSegment("straight", remainingAngle/remainingSegments)
			else
				track[i] = makeTrackSegment("bend", remainingAngle/remainingSegments)
			end
		end
		if track[i].segType == "straight" then remainingStraights = remainingStraights - 1
		elseif track[i].segType == "bend" then remainingBends = remainingBends - 1 end
		remainingAngle = remainingAngle - track[i].angle
		remainingSegments = remainingSegments - 1
	end

	--print(json.prettify(track))

	local trackPointX, trackPointY = 0, 0
	local trackLines = {}
	local cumulativeAngle = 0
	for i = 1, #track do
		local trackSegment = track[i]
		local lineData = {}
		lineData.startX, lineData.startY = trackPointX, trackPointY
		cumulativeAngle = cumulativeAngle + trackSegment.angle
		lineData.endX, lineData.endY = trackPointX + trackSegment.length*math.cos(math.rad(cumulativeAngle)), trackPointY + trackSegment.length*math.sin(math.rad(cumulativeAngle))
		trackLines[i] = lineData
		trackPointX, trackPointY = lineData.endX, lineData.endY
	end
	local trackStartPoint = {x = trackLines[1].startX, y = trackLines[1].startY}
	local trackEndPoint = {x = trackLines[#trackLines].endX, y = trackLines[#trackLines].endY}
	local deltaX, deltaY = trackEndPoint.x - trackStartPoint.x, trackEndPoint.y - trackStartPoint.y
	local segmentDeltaX, segmentDeltaY = deltaX/#trackLines, deltaY/#trackLines
	for i = 1, #trackLines do
		local lineData = trackLines[i]
		lineData.startX, lineData.startY = lineData.startX - segmentDeltaX*(i-1), lineData.startY - segmentDeltaY*(i-1)
		lineData.endX, lineData.endY = lineData.endX - segmentDeltaX*i, lineData.endY - segmentDeltaY*i
	end

	local checkPointDistance = function()
		for i = 1, #trackLines do
			for i2 = 1, #trackLines do
				if i == i2 then
					--skip checking self
				else
					local l1, l2 = trackLines[i], trackLines[i2]
					local dist = math.sqrt((l1.startX-l2.startX)^2 + (l1.startY-l2.startY)^2)
					if dist < 40 then
						print("Distance between line "..i.." and line "..i2.." is "..dist)
						return true
					end
				end
			end
		end
		print("no close lines found")
		return false
	end

	if checkIntercepts(trackLines) or checkPointDistance() then
		return nil
	else
		return trackLines
	end
end

local function widenTrack(trackLines, trackWidth)
	local trackInner = {}
	local trackOuter = {}
	for i = 1, #trackLines do
		local lineData = trackLines[i]
		local innerData, outerData = {}, {}
		local lineAngle = math.atan2(lineData.endY-lineData.startY, lineData.endX-lineData.startX)
		local lineNormalAngle = lineAngle + math.pi/2
		local lineNormalX, lineNormalY = math.cos(lineNormalAngle), math.sin(lineNormalAngle)
		
		local adjustLine = function(_lineData, nx, ny, w) --moves the line by its width based on its tangent
			local sx, sy, ex, ey = _lineData.startX, _lineData.startY, _lineData.endX, _lineData.endY
			local sx2, sy2, ex2, ey2 = sx + nx*w, sy + ny*w, ex + nx*w, ey + ny*w
			return sx2, sy2, ex2, ey2
		end
		innerData.startX, innerData.startY, innerData.endX, innerData.endY = adjustLine(lineData, lineNormalX, lineNormalY, trackWidth/2)
		outerData.startX, outerData.startY, outerData.endX, outerData.endY = adjustLine(lineData, lineNormalX, lineNormalY, -trackWidth/2)

		local extendLine = function(_lineData, _lineData2) --if points don't meet, extend both lines until they meet
			--double the length of both lines, then find the intercept, then set the start and end of both lines to the intercept
			local sx, sy, ex, ey = _lineData.startX, _lineData.startY, _lineData.endX, _lineData.endY
			local sx2, sy2, ex2, ey2 = _lineData2.startX, _lineData2.startY, _lineData2.endX, _lineData2.endY
			local doubleLength = function(x1, y1, x2, y2)
				local dx, dy = x2-x1, y2-y1
				return x1 - dx, y1 - dy, x2 + dx, y2 + dy
			end
			sx, sy, ex, ey = doubleLength(sx, sy, ex, ey)
			sx2, sy2, ex2, ey2 = doubleLength(sx2, sy2, ex2, ey2)
			local interX, interY = checkLineIntercept(sx, sy, ex, ey, sx2, sy2, ex2, ey2, false)
			if interX then
				print("extended lines meet at "..interX..", "..interY)
				_lineData.endX, _lineData.endY = interX, interY
				_lineData2.startX, _lineData2.startY = interX, interY
			else
				print("extended lines do not meet")
			end
		end

		local checkOverlap = function(_lineData, _lineData2) --checks for overlaps between two lines and adjusts them if necessary
			local sx, sy, ex, ey = _lineData.startX, _lineData.startY, _lineData.endX, _lineData.endY
			local sx2, sy2, ex2, ey2 = _lineData2.startX, _lineData2.startY, _lineData2.endX, _lineData2.endY
			local interX, interY = checkLineIntercept(sx, sy, ex, ey, sx2, sy2, ex2, ey2, false)
			if interX then
				print("found intercept, adjust line points")
				_lineData.endX, _lineData.endY = interX, interY
				_lineData2.startX, _lineData2.startY = interX, interY
			else
				print("no intercept found, extend lines")
				extendLine(_lineData, _lineData2)
			end
		end
		if i > 1 then
			checkOverlap(trackInner[i-1], innerData)
			checkOverlap(trackOuter[i-1], outerData)
			if i == #trackLines then
			print("check last line and first")
			checkOverlap(innerData, trackInner[1] )
			checkOverlap(outerData, trackOuter[1] )
			end
		end

		trackInner[i] = innerData
		trackOuter[i] = outerData
	end
	return trackInner, trackOuter
end

local trackShapeInner, trackShapeOuter = {}, {}

local function makeTrackShape(trackLines) --takes track lineData and converts to shape of x, y co-ordinates to be fed into bezier chain module
	local shape = {}

	for i = 1, #trackLines do --we want to go from the midpoint, to the midpoint of the next line, using the end points of the current line as the control points
		local sx, sy = trackLines[i].startX, trackLines[i].startY
		local ex, ey = trackLines[i].endX, trackLines[i].endY
		local mx, my = sx+(ex-sx)/2, sy+(ey-sy)/2
		local nextPoint
		if trackLines[i+1] then
			nextPoint = trackLines[i+1]
		else --if we're at the end of the track, use the first point as the next point
			nextPoint = trackLines[1]
		end
		local nextMx, nextMy = nextPoint.startX+(nextPoint.endX-nextPoint.startX)/2, nextPoint.startY+(nextPoint.endY-nextPoint.startY)/2
		shape[#shape+1] = {sx = mx, sy = my, cx = ex, cy = ey, ex = nextMx, ey = nextMy}
	end

	return shape
end

TrackBuilder.BuildTrack = function(attempts, group, _drawMesh, _drawProcess)
	trackGroup = group or display.getCurrentStage()
	drawMesh = _drawMesh or false
	drawProcess = _drawProcess or false
	attempts = attempts or 50000

	local trackMesh
	for i = 1, attempts do
		local trackLines = generateTrack()
		if trackLines then
			local innerTrackLines, outerTrackLines = widenTrack(trackLines, 15)
			
			if checkIntercepts(innerTrackLines) then
				print("intercepts found on innerTrackLines, try again")
			else
				if drawProcess == true then
					for i2 = 1, #trackLines do
						local inner, outer = innerTrackLines[i2], outerTrackLines[i2]
						local lineData = trackLines[i2]
						inner.line = display.newLine(trackGroup, inner.startX, inner.startY, inner.endX, inner.endY)
						inner.line.strokeWidth = 2
						inner.line.alpha = 0.3
						inner.line:setStrokeColor(1, 0, 0)
						outer.line = display.newLine(trackGroup, outer.startX, outer.startY, outer.endX, outer.endY)
						outer.line.strokeWidth = 2
						outer.line.alpha = 0.3
						outer.line:setStrokeColor(0, 0, 1)
						lineData.lineObj = display.newLine(trackGroup, lineData.startX, lineData.startY, lineData.endX, lineData.endY)
						lineData.lineObj.strokeWidth = 2
						lineData.lineObj.alpha = 0.3					
					end
				end

				trackShapeInner = makeTrackShape(innerTrackLines)
				trackShapeOuter = makeTrackShape(outerTrackLines)
				print(#trackShapeInner, #trackShapeOuter)

				local innerChain = Bezier.makeChain2(trackShapeInner, 10, false, trackGroup)
				local outerChain = Bezier.makeChain2(trackShapeOuter, 10, false, trackGroup)

				local finalTrack
				local allVertices = {}
				local centerPoint = {}
				-- mesh method
				for i = 1, #innerChain.curvePoints-1 do
					local point1 = innerChain.curvePoints[i]
					local point2 = outerChain.curvePoints[i]
					local point3 = innerChain.curvePoints[i+1]
					local point4 = outerChain.curvePoints[i+1]
					--centerPoint = {x = (point1.x + point2.x + point3.x + point4.x)/4, y = (point1.y + point2.y + point3.y + point4.y)/4}
					local vertices = {point1.x, point1.y, point2.x, point2.y, point3.x, point3.y, point4.x, point4.y}
					for i2 = 1, #vertices do
						allVertices[#allVertices+1] = vertices[i2]
					end
				end
				trackMesh = display.newMesh(trackGroup, 0, 0, {mode = "strip", vertices = allVertices})
				--trackMesh:translate( trackMesh.path:getVertexOffset() )
				trackMesh.vertices = allVertices
				if drawMesh ~= true then
					trackMesh.isVisible = false
				end
				break
			end
		else
			print("unable to generate track")
		end
	end
	return trackMesh
end

return TrackBuilder