--lines.lua
sndH = require "soundHandler"
sr = 44100 -- sample rate
t = 1/10 -- shortest sound length (in seconds)
l = math.floor(sr*t) -- waveform segment length
c = 1 -- assuming mono is fine
advance = true
testSoundData = love.sound.newSoundData(l, sr, 16, c) -- 16bits for quality
for i=0,l-1 do
	testSoundData:setSample(i, math.sin(2 * math.pi * (i/l))) -- create sine wave that doesn't pop... or at least tries not to.
end -- now you have a sine wave of length l seconds and pitch of t/sr Hz... if i'm not mistaken.
testSound = love.audio.newSource(testSoundData)
ts = sndH.registerSound(testSound)
sndH.setPitch(testSound, 30) -- e.g. if you want 440 Hz, then you need to set this to 440 / (t / sr) or something; not gonna say it's a guarantee that it works if the multiplier is too small or too large; this is kinda a bad way to do all this tbh.
sndH.setLooping(testSound, true )
lines = {}
sortType = 7
--MERGE
accesses = 0
debugText2 = ""
hiddenLines = {}
SORTSPEEDS = {}
SORTSPEEDS[0] = 5000
SORTSPEEDS[1] = 700
SORTSPEEDS[2] = 700
SORTSPEEDS[3] = 4000
SORTSPEEDS[4] = 200
SORTSPEEDS[5] = 5000
SORTSPEEDS[6] = 1000 
SORTSPEEDS[8] = 1000
SORTSPEEDS[7] = 1000
sortSpeeds = {unpack(SORTSPEEDS)} 
sortSpeeds[0] = 4000
loadedFromList = false
originalArray = 0
numIterations = 0
advItterationDT = 0
itterationDT = 0
advDTCounter = 0
accesses = 0
swaps = 0
insertions = 0 -- OwO
bucketLocations = {1}
startTime = 0
totalTime = 0
onDigitValue2 = 12
--HELPERS:
function HSV(h, s, v)
    if s <= 0 then return v,v,v end
    h, s, v = h/256*6, s/255, v/255
    local c = v*s
    local x = (1-math.abs((h%2)-1))*c
    local m,r,g,b = (v-c), 0,0,0
    if h < 1     then r,g,b = c,x,0
    elseif h < 2 then r,g,b = x,c,0
    elseif h < 3 then r,g,b = 0,c,x
    elseif h < 4 then r,g,b = 0,x,c
    elseif h < 5 then r,g,b = x,0,c
    else              r,g,b = c,0,x
    end return (r+m),(g+m),(b+m)
end

linePOStoID = {}

linePOStoID2 = {}
--CONSTANTS:
DS = {}
NUM_LINES = 1024
	-- DS 1 wheel:
	DS[1] = {}
	DS[1].centerX = love.graphics.getWidth()/3.5
	DS[1].centerY = love.graphics.getHeight()/2
	DS[1].radius = 200
	--DS 2 wheel:
	DS[2] = {}
	DS[2].centerX = love.graphics.getWidth()/2
	DS[2].centerY = love.graphics.getHeight()/2
	DS[2].radius = 60


function addLine(id, pos, dstyle, special, secondaryValue)
	local l = {}
	
	l.color = {}
	l.id = id or table.getn(lines)
	l.secondaryValue = secondaryValue or l.id
	l.color.r, l.color.g, l.color.b = HSV((l.id/NUM_LINES)*255, 255, 255)
	l.pos = pos or l.id
	if special then
		l.color.r, l.color.g, l.color.b = 1, 1, 1
	end
	l.dstyle = dstyle or -1
	l.radialX = (math.cos((2*math.pi)*(l.pos/NUM_LINES))*DS[1].radius) + DS[1].centerX
	l.radialY = (math.sin((2*math.pi)*(l.pos/NUM_LINES))*DS[1].radius) + DS[1].centerY
	if l.dstyle == 1 then
		l.draw = function()
			love.graphics.setColor(l.color.r, l.color.g, l.color.b)
			love.graphics.line(DS[1].centerX, DS[1].centerY, l.radialX, l.radialY)
		end
	else
		l.draw = function( dstyle )
			love.graphics.setColor(1, 1, 1, (l.id/NUM_LINES))
			love.graphics.line(DS[1].centerX, DS[1].centerY)
		end
	end

	l.getPos = function()
		return l.pos
	end

	l.setPos = function(newPos)
		-- print("old =  ", l.radialX, l.radialY)
		l.pos = newPos
		local rad = DS[1].radius --+ (math.sqrt(math.abs(l.pos - l.id))*4)
		l.radialX = (math.cos((2*math.pi)*(l.pos/NUM_LINES))*rad) + DS[1].centerX
		l.radialY = (math.sin((2*math.pi)*(l.pos/NUM_LINES))*rad) + DS[1].centerY
		-- print("new =  ", l.radialX, l.radialY)
	end

	l.setID = function(newID, newSecondaryVal)
		l.id = newID
		l.secondaryValue = newSecondaryVal
		l.color.r, l.color.g, l.color.b = HSV((l.id/NUM_LINES)*255, 255, 255)
	end


	l.moveToNewList = function(newPos)
		l.pos = newPos
		local rad = DS[1].radius --+ (math.sqrt(math.abs(l.pos - l.id))*4)
		l.radialX = (math.cos((2*math.pi)*(l.pos/NUM_LINES))*rad) + DS[1].centerX
		l.radialY = (math.sin((2*math.pi)*(l.pos/NUM_LINES))*rad) + DS[1].centerY
	end

	l.getID = function()
		return l.id
	end


	l.getValue = function(targetVal)
		return l.id
	end

	l.getSecondaryValue = function()
		return l.secondaryValue
	end


	return l
end



function generate(numLines, ds, special)
	NUM_LINES = numLines
	for i = 0, #SORTSPEEDS do
		sortSpeeds[i] = math.floor((SORTSPEEDS[i]/1000)*NUM_LINES)
	end
	if special ~= nil then
		DS[ds] = special
	end
	lines = {}
	lines[-1] =  addLine(-1, -1, ds, true)
	for i = 1, NUM_LINES do
		table.insert(lines, addLine(i, i, ds))
	end
end




function generateFromList(arr, ds, special)
	loadedFromList = true
	sortSpeeds = {}
	
	originalArray = {unpack(arr)}
	sortedArr = {unpack(arr)}
	table.sort(sortedArr)
	NUM_LINES = table.getn(arr)
	lineSpecial = nil
	if special ~= nil then
		if special.style ~= nil then
			DS[ds] = special.style
		end
		if special.lines ~= nil then
			lineSpecial = special.lines
		end
	end

	

	hashTable = {}
	hashIndex = 0
	for i= 1, #arr do
		for j= 1, #sortedArr do
			if sortedArr[j] == arr[i] then
				table.insert(hashTable, j)
				sortedArr[j] = -1
				break

			end
		end
		
		-- print(i, hashTable[i])
	end

	
	lines = {}
	lines[-1] =  addLine(-1, -1, ds, true)
	linesSorted = {}
	-- for i= 1, #sortedArr do
	-- 	lines[i] = {}
	-- end
	linePOStoID = {}
	for i = 1, #arr do
		table.insert(lines, addLine(i, hashTable[i], ds, lineSpecial, arr[i]))
		-- print(i, hashTable[i])
		-- print("line #" .. tostring(lines[i].getPos()) .. ": ", lines[i].getID(), lines[i].getPos(), lines[i].getSecondaryValue())
		-- table.insert(linesSorted, hashTable[arr[i]])
		hiddenLines[i] = 0
		linePOStoID[lines[i].getPos()] = lines[i].getID()
	end
	NUM_LINES = table.getn(lines)
	quickSortInit(1, NUM_LINES)
	if NUM_LINES >= 1000 then
		love.graphics.setLineWidth( 1)
	end
	-- print("\n--------------------------\n")
	for i = 0, #SORTSPEEDS do
		sortSpeeds[i] = math.floor((SORTSPEEDS[i]/1000)*NUM_LINES)
	end
	setSort(sortType)
end


function reload()
	generateFromList({unpack(originalArray)}, 1)
	quickSortInit(1, NUM_LINES)
	startTime = love.timer.getTime()
	setSort(sortType)
end
function shuffle()
	local tbl = lines
  	for i = #tbl, 2, -1 do
    	local j = math.random(i)
    	local tI = tbl[i].pos
    	tbl[i].setPos(tbl[j].pos)
    	tbl[j].setPos(tI)
  	end
  	for i = 1, #tbl do
  		hiddenLines[i] = 0
  		linePOStoID[tbl[i].getPos()] = tbl[i].getID() 
  	end
	quickSortInit(1, NUM_LINES)
	startTime = love.timer.getTime()
	setSort(sortType)

end
function shuffle2()
	local tbl = lines
  	for i = #tbl, 2, -1 do
    	local j = math.random(i)
    	local tI = tbl[i].pos
    	tbl[i].setPos(tbl[j].pos)
    	tbl[j].setPos(tI)
  	end
  	for i = 1, #tbl do
  		hiddenLines[i] = 0
  		linePOStoID[tbl[i].getPos()] = tbl[i].getID() 
  	end

end
function drawLines()
	for i = 1, NUM_LINES do
		lines[i].draw()
	end
end

-- function sortPass(sortAlgo)
-- 	sortAlgo(lines)
-- end

function isSorted()
	for i = 1, NUM_LINES do
		if lines[i].id ~= lines[i].pos then
				return false
		end
	end
	return true
end





---------------------------SORTER--------------------------------------------------

passesPerSecond = 700
onPos = 1
numPasses = 0
storePasses = 0



onDigit = 0
currentListPos = 1
onDigitValue = 0
function setSort(n)
		numIterations = 0
		advItterationDT = 0
		itterationDT = 0
		advDTCounter = 0
		accesses = 0
		swaps = 0
		insertions = 0
		sortType = n
		passesPerSecond = sortSpeeds[sortType]
		onPos = 1

		if sortType == 0 then
			sortText1 = "Sort Type: Bubble"
			sortText0 = "Passes Per Second: ".. passesPerSecond
		elseif sortType == 1 then
			sortText1 = "Sort Type: Quick Sort"
			sortText0 = "Passes Per Second: ".. passesPerSecond
		elseif sortType == 2 then
			sortText1 = "Sort Type: Radix Sort"
			sortText0 = "Passes Per Second: ".. passesPerSecond
			onDigit = 0
			currentListPos = 1
			onDigitValue = 0
		elseif sortType == 3 then
			sortText1 = "Sort Type: Cocktail Shaker"
			sortText0 = "Passes Per Second: ".. passesPerSecond
			dir = 1
			onPos = 1
		elseif sortType == 4 then
			sortText1 = "Sort Type: Merge"
			sortText0 = "Passes Per Second: ".. passesPerSecond
			dir = 1
			onPos = 1
			msLeft = 0
			msRight = 0
			msMiddle = 0
			msL = {}
			msR = {}
			msWidth = 0
			msN = 0

			msN1 = 0
			msN2 = 0
			msState = 0
			msState2 = 0
			msState3 = 0
			msLastPos = 0
			linePos = 1
		elseif sortType == 5 then
			sortText1 = "Sort Type: Insertion"
			sortText0 = "Passes Per Second: ".. passesPerSecond
			dir = 1
			onPos = 1
			max = NUM_LINES
		elseif sortType == 8 then
			sortText1 = "Sort Type: BOGO"
			sortText0 = "Passes Per Second: ".. passesPerSecond
		elseif sortType == 7 then
			sortText1 = "Sort Type: Counting Sort"
			sortText0 = "Passes Per Second: ".. passesPerSecond
			B = {}
			C = {}
			csStep = 0
			onPos = 0
			k = NUM_LINES
		elseif sortType == 6 then
			bucketLocations = {1}
			sortText1 = "Sort Type: Bucket"
			sortText0 = "Passes Per Second: ".. passesPerSecond
			maxDigit = math.floor(math.log10(NUM_LINES))-1
			currentListPos2 = 1
			dir = 1
			onDigitValue2 = 0
			bucketsortStep = 0
			onDigit2 = math.floor(math.log10(NUM_LINES))-1
		end
		
		-- print(onDigitValue2)
		startTime = love.timer.getTime()
end
setSort(sortType)
function sortingUpdate(dt)
	numPasses = math.floor(passesPerSecond *dt)
	if numPasses == 0 then
		-- numPasses = 0
		storePasses = storePasses + (passesPerSecond *dt)
		numPasses = math.floor(storePasses)
		if numPasses >= 1 then 
			storePasses = 0
		end

	end

	for passN = 1, numPasses do
		if not isSorted() then
			if passN == 1 then
				timeA = love.timer.getTime()
				sortLines()
				timeB = love.timer.getTime()
				itterationDT = timeB-timeA
				advItterationDT = advItterationDT + itterationDT
				advDTCounter = advDTCounter + 1
			else
				sortLines()
			end
			numIterations = numIterations + 1
		end
	end
	
	sortText2 = "Iterations = " .. numIterations.. " len(A) = " .. NUM_LINES
	sortText3 = string.format("Iteration DT =  %.1e", advItterationDT/advDTCounter)
	sortText4 = "Swaps = " .. swaps .. " Insertions = " .. insertions
	now = love.timer.getTime()
	sortText4 = "Accesses = " .. accesses .. string.format("Total Time = %.3f", now-startTime)
	if isSorted() then
		print("\n\n\n\n--------------------------------------\n\n\n\n\n")
		for i = 1, NUM_LINES do
			print(lines[linePOStoID[i]].getSecondaryValue())
		end
		if loadedFromList then
			reload()
		else
			shuffle()
		end
		if advance then
			local n = sortType + 1
			n = n%9
			setSort(n)
		else
			setSort(sortType)
		end
	end

end

function sortingDraw()
	local x1 =  (math.cos((2*math.pi)*(onPos/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerX
	local y1 = (math.sin((2*math.pi)*(onPos/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerY
	local x2 =  (math.cos((2*math.pi)*(onPos/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerX
	local y2 = (math.sin((2*math.pi)*(onPos/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerY

	love.graphics.setColor(1, 1, 1)
	love.graphics.line(x1, y1, x2, y2)

	if sortType == 0 then
		sortText1 = "Sort Type: Bubble"
	elseif sortType == 1 then
		local a1 =  (math.cos((2*math.pi)*(qsX/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerX
		local b1 = (math.sin((2*math.pi)*(qsX/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerY
		local a2 =  (math.cos((2*math.pi)*(qsX/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerX
		local b2 = (math.sin((2*math.pi)*(qsX/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerY

		love.graphics.setColor(1, .5, .5)
		love.graphics.line(a1, b1, a2, b2)
	elseif sortType == 2 then
		local a1 =  (math.cos((2*math.pi)*(currentListPos/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerX
		local b1 = (math.sin((2*math.pi)*(currentListPos/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerY
		local a2 =  (math.cos((2*math.pi)*(currentListPos/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerX
		local b2 = (math.sin((2*math.pi)*(currentListPos/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerY

		love.graphics.setColor(1, .5, .5)
		love.graphics.line(a1, b1, a2, b2)
	elseif sortType == 3 then
		sortText1 = "Sort Type: Cocktail Shaker"

	elseif sortType == 4 then
		
		
		local a1 =  (math.cos((2*math.pi)*(msLeft/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerX
		local b1 = (math.sin((2*math.pi)*(msLeft/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerY
		local a2 =  (math.cos((2*math.pi)*(msLeft/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerX
		local b2 = (math.sin((2*math.pi)*(msLeft/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerY

		love.graphics.setColor(1, .5, .5)
		love.graphics.line(a1, b1, a2, b2)
		local c1 =  (math.cos((2*math.pi)*(msRight/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerX
		local d1 = (math.sin((2*math.pi)*(msRight/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerY
		local c2 =  (math.cos((2*math.pi)*(msRight/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerX
		local d2 = (math.sin((2*math.pi)*(msRight/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerY

		love.graphics.setColor(.5, 1, .5)
		love.graphics.line(c1, d1, c2, d2)
		local e1 =  (math.cos((2*math.pi)*(msMiddle/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerX
		local f1 = (math.sin((2*math.pi)*(msMiddle/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerY
		local e2 =  (math.cos((2*math.pi)*(msMiddle/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerX
		local f2 = (math.sin((2*math.pi)*(msMiddle/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerY

		love.graphics.setColor(1, .5, .5)
		love.graphics.line(e1, f1, e2, f2)
	else
		
		
		local a1 =  (math.cos((2*math.pi)*(linePos/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerX
		local b1 = (math.sin((2*math.pi)*(linePos/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerY
		local a2 =  (math.cos((2*math.pi)*(linePos/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerX
		local b2 = (math.sin((2*math.pi)*(linePos/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerY

		love.graphics.setColor(1, .5, .5)
		love.graphics.line(a1, b1, a2, b2)
	end
	-- x1 =  (math.cos((2*math.pi)*(qsP/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerX
	-- y1 = (math.sin((2*math.pi)*(qsP/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerY
	-- x2 =  (math.cos((2*math.pi)*(qsP/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerX
	-- y2 = (math.sin((2*math.pi)*(qsP/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerY

	-- love.graphics.setColor(1, 1, .6)
	-- love.graphics.line(x1, y1, x2, y2)

	-- x1 =  (math.cos((2*math.pi)*(qsH/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerX
	-- y1 = (math.sin((2*math.pi)*(qsH/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerY
	-- x2 =  (math.cos((2*math.pi)*(qsH/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerX
	-- y2 = (math.sin((2*math.pi)*(qsH/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerY

	-- love.graphics.setColor(0.6, 1, .6)
	-- love.graphics.line(x1, y1, x2, y2)

	-- x1 =  (math.cos((2*math.pi)*(qsL/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerX
	-- y1 = (math.sin((2*math.pi)*(qsL/NUM_LINES))*(DS[1].radius+5)) + DS[1].centerY
	-- x2 =  (math.cos((2*math.pi)*(qsL/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerX
	-- y2 = (math.sin((2*math.pi)*(qsL/NUM_LINES))*(DS[1].radius+25)) + DS[1].centerY

	-- love.graphics.setColor(1, 0.6, .6)
	-- love.graphics.line(x1, y1, x2, y2)



end


function sortLines()
	if sortType == 0 then
		bubbleSort()
	elseif sortType == 1 then
		quickSort()
	elseif sortType == 2 then
		radixSort()
	elseif sortType == 3 then
		cocktailShakerSort()
	
	elseif sortType == 4 then
		mergeSort()
		-- tester = 0
		-- solveMergeSort(1, NUM_LINES)
		-- tester = 1
	elseif sortType == 5 then
		insertionSort()
		linePos = max
	
	elseif sortType == 6 then
		bucketSort()
	elseif sortType == 7 then
		countingSort()
	else
		-- solveMergeSort(1, NUM_LINES)
		-- tester = 1
		bogoSort()
	end
end


phase = 0

--helperFunctions

function swapLines(p1, p2)
		local pos1 = p1 or onPos
		local pos2 = p2 or onPos+1
		local a, b = lines[linePOStoID[pos1]].getID(), lines[linePOStoID[pos2]].getID()
		-- print("SWAP:")
		-- print("A:", pos1, a, lines[a].getSecondaryValue())
		-- print("B:", pos2, b, lines[b].getSecondaryValue())
		lines[linePOStoID[pos1]].setPos(pos2)
		lines[linePOStoID[pos2]].setPos(pos1)
		linePOStoID[pos1] = b
		linePOStoID[pos2] = a
		-- print("A:", lines[linePOStoID[pos1]].getPos(), lines[linePOStoID[pos1]].getID(), lines[linePOStoID[pos1]].getSecondaryValue())
		-- print("B:", lines[linePOStoID[pos2]].getPos(), lines[linePOStoID[pos2]].getID(), lines[linePOStoID[pos2]].getSecondaryValue())
		sndH.setPitch(testSound, 12 + b*0.05)
		swaps= swaps + 1
end


function bubbleSort()
	if onPos < NUM_LINES then
		if valAt(onPos) > valAt(onPos+1) then
			swapLines()
		end 
		onPos = onPos +1
	else
		onPos = 1
	end

end


function cocktailShakerSort()
	if onPos < NUM_LINES and onPos >=1 then
		if valAt(onPos) > valAt(onPos+1) then
			swapLines()
		end 
		onPos = onPos +dir
	else
		dir = dir*-1
		onPos = onPos +dir
	end

end

function bogoSort()
	shuffle2()
	sndH.setPitch(testSound, 12 + lines[linePOStoID[1]].getID()*0.05)
end


function radixSort_A()
	if onPos <= NUM_LINES then
		valAtPos = valAt(onPos)
		if valAtPos == -1 then
			onPos = onPos + 1
			return 1
		end
		origValue = valAtPos
		valAtPos = math.floor(valAtPos/(10^onDigit))
		lastDigit = valAtPos%10
		
		if origValue < 10^onDigit then
			lastDigit = 0
		end
		if  lastDigit == onDigitValue then

			moveToNewList(onPos)
			insertions = insertions +1

			-- if onPos == currentListPos then
			-- 	currentListPos = currentListPos + 1
			-- else
			-- 	swapLines(currentListPos, onPos)
			-- 	currentListPos= currentListPos + 1
			-- end
			-- debugText2 = valAtPos .. ", " .. 10^onDigit .. " " .. onDigitValue .. " = " .. lastDigit
		end
		debugText2 = valAtPos .. ", " .. 10^onDigit .. " " .. onDigitValue .. " = " .. lastDigit
		onPos = onPos+1
	else
		if onDigitValue == 9 then
			for rr = 1, NUM_LINES do
				linePOStoID[rr] = linePOStoID2[rr]
				hiddenLines[rr] = 0
			end
			linePOStoID2 = {}
			onPos = 1
			onDigitValue = 0
			onDigit = onDigit + 1
			currentListPos = 1
		else

			onPos = 1
			onDigitValue = onDigitValue + 1

		end
	end

end

function bucketSort()
	-- if onDigit2 < maxDigit-1 then return false end
	if bucketsortStep == 2 then
		cocktailShakerSort()
		return 1
	end
	if onPos <= NUM_LINES then
		valAtPos = valAt(onPos)
		if valAtPos == -1 then
			onPos = onPos + 1
			return 1
		end
		origValue = valAtPos
		valAtPos = math.floor(valAtPos/(10^onDigit2))
		first = valAtPos%10
		
		if origValue < 10^onDigit2 then
			first = 0
		end
		if  first == onDigitValue2 then
			if bucketsortStep == 1 then
				insertAt(onPos, bucketLocations[inBucket] + currentListPos2)
			else
				insertAt(onPos, currentListPos2)
			end

			-- if onPos == currentListPos2 then
			currentListPos2 = currentListPos2 + 1
			-- else
				-- swapLines(currentListPos2, onPos)
			
			-- end
			-- debugText2 = valAtPos .. ", " .. 10^onDigit .. " " .. onDigitValue2 .. " = " .. first
		end
		if bucketsortStep == 1 then
			if onPos >= bucketLocations[inBucket+1] then
				if onDigitValue2 == 10 then 
					onDigitValue2 = 0
					inBucket = inBucket + 1
					currentListPos2 = 0
					if inBucket >= 10 then
						passesPerSecond = (SORTSPEEDS[3]/1000)*NUM_LINES
						bucketsortStep = bucketsortStep + 1
						onDigitValue2 = 0
					end
				else
					onPos = bucketLocations[inBucket]
					onDigitValue2 = onDigitValue2 + 1
					linePos = bucketLocations[inBucket]
				end
			end
		end
		debugText2 = valAtPos .. ", " .. 10^onDigit .. " " .. onDigitValue2 .. " = " .. first
		onPos = onPos+1
	else
		if onDigitValue2 == 10 then
			onPos = 1
			onDigitValue2 = 0
			onDigit2 = onDigit2 - 1
			currentListPos2 = 1
			bucketsortStep = bucketsortStep + 1
			inBucket = 1
			-- solveMergeSort(1, NUM_LINES)
			-- print()

		else
			
			onPos = currentListPos2
			-- print(onPos-1)
			table.insert(bucketLocations, onPos-1)
			onDigitValue2 = onDigitValue2 + 1
			linePos = bucketLocations[onDigitValue2+1]
		end
	end

end



function radixSort()
	if onPos <= NUM_LINES then
		valAtPos = valAt(onPos)
		origValue = valAtPos
		valAtPos = math.floor(valAtPos/(2^onDigit))
		lastDigit = valAtPos%2
		
		if origValue < 2^onDigit then
			lastDigit = 0
		end
		sortText6 = "0"
		if  lastDigit == 0 then

			insertAt(onPos, currentListPos)

			-- if onPos == currentListPos then
			currentListPos = currentListPos + 1
			-- else
				-- swapLines(currentListPos, onPos)
			
			-- end
			-- debugText2 = valAtPos .. ", " .. 10^onDigit .. " " .. onDigitValue .. " = " .. lastDigit
		end
		sortText6 = sortText6 .. ", " .. onPos .. ", " .. currentListPos
		debugText2 = valAtPos .. ", " .. 2^onDigit .. " " .. onDigitValue .. " = " .. lastDigit
		onPos = onPos+1
	else
		
			onPos = 1
			onDigitValue = 0
			onDigit = onDigit + 1
			currentListPos = 1

	end

end






function valAt(n)
	if hiddenLines[n] == -1 then
		return -1
	end
	accesses = accesses + 1
	-- print("valAt", n, lines[linePOStoID[n]].getID())
	-- print(n)
	return lines[linePOStoID[n]].getID()

end

function moveToNewList(oldIndex)
	sndH.setPitch(testSound, 12 + lines[linePOStoID[oldIndex]].getID()*0.05)
	dest = (table.getn(linePOStoID2)+1)
	lines[linePOStoID[oldIndex]].setPos(table.getn(linePOStoID2)+1)
	linePOStoID2[dest] = linePOStoID[oldIndex]

	-- linePOStoID[oldIndex] = -1
	hiddenLines[oldIndex] = -1

end





qsH = h
qsL = l
qsP = 0
qsI = 0
qsJ = 0
qsX = 0
qsSize = 0
qsTop = 0
qsPhase = 0




function partition()
    -- qsJ = onPos
    -- print(qsJ)
    if qsJ  < qsH then
        if  valAt(qsJ) <= qsX then
  
            -- increment index of smaller element
            qsI = qsI + 1
            swapLines(qsI, qsJ)
            -- arr[i], arr[j] = arr[j], arr[i]
  		end
  		qsJ = qsJ + 1
  		onPos = qsJ
  	else
    	swapLines(qsI+1, qsH)
    	qsPhase = 2
    	-- print("thing")
    	qsP = qsI+1
    end
    
end

function quickSortInit(l, h)
	qsH = h or NUM_LINES
	qsL = l or 1
	size = NUM_LINES
	stack = {}
	for i = 1, size do
		table.insert(stack, 0)
	end

	qsTop = 0
	qsTop = qsTop + 1
	stack[qsTop] = qsL
	qsTop = qsTop + 1
	stack[qsTop]  = qsH
	
	qsPhase = 0
	--Keep popping from stack while is not empty

end

function quickSort()
	if qsPhase == 0 then
		-- print(qsTop, stack[qsTop], qsTop-1, stack[qsTop-1])
		qsH = stack[qsTop]
		qsTop = qsTop - 1
		
		qsL = stack[qsTop]
		qsTop = qsTop -1
		qsI = (qsL - 1)
		qsX = valAt(qsH)
	   	qsJ = qsL
	   	qsPhase = 1
	elseif qsPhase == 1 then
		partition()
		-- onPos = onPos + 1
	else

	    --If there are elements on left side of pivot,
	    -- then push left side to stack
		if qsP-1 > qsL then
			-- print("left")
			qsTop = qsTop + 1
	        stack[qsTop] = qsL
	        qsTop = qsTop + 1
	        stack[qsTop] = qsP - 1
	    end

	    -- If there are elements on right side of pivot,
	    -- then push right side to stack
	    if qsP + 1 < qsH then
	    	-- print("right")
	        qsTop = qsTop + 1
	        stack[qsTop] = qsP + 1
	        qsTop = qsTop + 1
	        stack[qsTop] = qsH
	    end
		qsPhase = 0
	end
end

largest = 1
largestVal = -99999999999999999999999999
max = NUM_LINES
function insertionSort()
	if onPos <= max then
		local v = valAt(onPos)
		if largestVal < v then
			largest = onPos
			largestVal = v
		end
		onPos = onPos + 1
	else
		insertAt(largest, max)
		sndH.setPitch(testSound, 12 + largest*0.05)
		largest = 1
		largestVal = -99999999999999999999999999
		onPos = 1
		max = max -1
	end
end


function insertAt(p1, p2)
	local pos1 = p1 or onPos
	local pos2 = p2 or 1
	local a, b = linePOStoID[pos1], linePOStoID[pos2]
	-- print(pos1, pos2, a, b)
	
	if pos1 ~= pos2 then
		table.remove(linePOStoID, pos1)
		table.insert(linePOStoID, pos2, a)
		insertions = insertions +1
	else
		return false
	end
	for i = 1, NUM_LINES do
		lines[linePOStoID[i]].setPos(i)
	end
	sndH.setPitch(testSound, 12 + a*0.05)
end

msLeft = 0
msRight = 0
msMiddle = 0
msL = {}
msR = {}
msWidth = 0
msN = 0

msN1 = 0
msN2 = 0
msState = 0
msState2 = 0
msState3 = 0
msLastPos = 0
linePos = 1
-- FIRST 4 STATES ARE STANDARD MERGE
function merge()
	if msState2 == 0 then
		msN1 = msMiddle - msLeft+1
	    msN2 = msRight - msMiddle 
	    msL = {}
	    msR = {}
	    -- for i = 1, n1 do msL.insert(0) end
	    -- for i = 1, n2 do msR.insert(0) end
	    msLastPos = onPos
	    onPos = 1
	    msOnPos2 = 1
	    msOnPos3 = 1
	    msState2 = 1
	end
	if msState2 == 1 then
		if onPos <= msN1 then
			msL[onPos] = valAt(msLeft+onPos-1)
			
		else

			msState2 = 2
			onPos = 0
		end
		onPos = onPos + 1
	elseif msState2 == 2 then
		if onPos <= msN2 then
			-- print(onPos, msN2)
			msR[onPos] = valAt(msMiddle + onPos)
		else
			msState2 = 3
			onPos = 0
			msOnPos2 = 1
			msOnPos3 = msLeft
			msL[msN1+1] = 9999999999999999999999
			msR[msN2+1] = 9999999999999999999999
		end
		onPos = onPos + 1
	elseif msState2 == 3 then


		-- if onPos-1 < msN1 and msOnPos2-1 < msN2 then
		if msOnPos3 <= msRight then
	        if msL[onPos] <= msR[msOnPos2] then
	            -- lines[linePOStoID[msOnPos3]].setPos(msL[onPos])
	            linePOStoID[msOnPos3] = msL[onPos]
	            onPos = onPos + 1
	        else
	        	linePOStoID[msOnPos3] = msR[msOnPos2]
	        	-- lines[linePOStoID[msOnPos3]].setPos(msR[msOnPos2])
	            -- linePOStoID[msOnPos3] = msL[msOnPos2]
	            msOnPos2 = msOnPos2 + 1
    		end
    		msOnPos3 = msOnPos3 + 1
    	else
    		for i = msOnPos3, msRight do
				lines[linePOStoID[i]].setPos(i)
			end
    		msState2 = 4
    		onPos = 1
    		msOnPos2 = 1
		    msOnPos3 = 1
		    msOnPos3 = msLeft
    	end
	elseif msState2 == 4 then
		if msOnPos3 <= msRight then
	        lines[linePOStoID[msOnPos3]].setPos(msL[onPos])
	        onPos = onPos + 1
	        msOnPos3 = msOnPos3 + 1
	        linePos = msOnPos3
	    else
    		msState2 = 5
    	end
	elseif msState2 == 5 then
		if msOnPos2-1 < msN2 then
	        lines[linePOStoID[msOnPos3]].setPos(msR[msOnPos2])
	        msOnPos2 = msOnPos2 + 1
	        msOnPos3 = msOnPos3 + 1
 
	    else
    		msState2 = 6
    	end
	elseif msState2 == 6 then
		msState = 3
		-- print(msLeft, msMiddle, msRight)
		table.insert(msStack, 0)
	end





end



function mergeSort()
	sortText1 = "Sort Type: Merge" .. msState .. ", " .. msState2
	sortText0 = "Left:" .. msLeft .. ", Mid: " .. msMiddle .. ", Right: " .. msRight

	sndH.setPitch(testSound, 12 + valAt(math.min(msLeft+1, NUM_LINES))*0.05)
	if msState == 0 then
		msWidth = 1   
    	msN = NUM_LINES
    	msState = 1
    	msState3 = 1
	elseif msState == 1 then
		if msWidth < msN-1 then
			msLeft = 1
			msState = 2
			currentLeft = 1
		else
			-- print( "\n\n\n\n--------------------------------------------------")
			-- for i = 1, NUM_LINES do
			-- 	print(i)
			-- -- 	print(linePOStoID[i], lines[linePOStoID].getID(), lines[linePOStoID].getPos())
			-- end
			-- print( "\n\n\n\n--------------------------------------------------")

			return true
		end
	elseif msState == 2 then
		if currentLeft < msN then
			msLeft = currentLeft
			msRight = math.min(msLeft+(msWidth*2)-1, msN)
			-- msMiddle = math.floor((msLeft+msRight)/2)
			msMiddle = currentLeft + msWidth-1
			onPos = msMiddle
			if msMiddle > msN then        
			    msMiddle = msRight-(msN%msWidth)
               -- print(msLeft, msRight, msWidth, msMiddle) 
            end
            msState = 4
            msState2 = 0
            currentLeft = currentLeft + 2*msWidth
		else
			msWidth = msWidth*2
			msState = 1
		end
	elseif msState == 3 then
		msLeft = msLeft + msWidth*2
		msState = 2
	else
		-- print("L:", msLeft, "M:", msMiddle, "R:", msRight)
		merge2(msLeft, msMiddle, msRight)
		
	end

end


msStack = {}
table.insert(msStack, NUM_LINES)
table.insert(msStack, 1)
table.insert(msStack, 0)

msTop = 1
merging = false

function mergeSort_B()
	if not merging then
		local msState = msStack[msTop]
		msTop = msTop -1
		if msState == 0 then

			local l = msStack[msTop]
			msTop = msTop-1
			local r = msStack[msTop]
			msTop = msTop-1

			local m = math.floor((l +(r-1))/2)
			
			if r > l then 
				table.insert(msStack, r)
				table.insert(msStack, m+1)
				table.insert(msStack, 1)


				table.insert(msStack, m)
				table.insert(msStack, l)
				table.insert(msStack, 1)
				msTop = msTop + 6
			end
		elseif msState == 1 then

			local l = msStack[msTop]
			msTop = msTop-1
			local r = msStack[msTop]
			msTop = msTop-1

			local m = math.floor((l +(r-1))/2)
			
			if r > l then 
				table.insert(msStack, r)
				table.insert(msStack, m+1)
				table.insert(msStack, 2)


				table.insert(msStack, m)
				table.insert(msStack, l)
				table.insert(msStack, 2)
				msTop = msTop + 6
			end


		elseif msState == 2 then
			local l = msStack[msTop]
			msTop = msTop-1
			local r = msStack[msTop]
			msTop = msTop-1
			merging = true
			msLeft = l
			msRight = r
			msMiddle = m
		elseif msState == 3 then
			
		end
	else
		merge()
	end

end








tester = 0

function solveMergeSort(l, r)
	if tester == 0 then
		if l < r then
			local m = math.floor((l + (r-1))/2)
			solveMergeSort(l, m)
			solveMergeSort(m+1, r)
			merge2(l, m, r)
		end
	else
		--stub
	end
end


function merge2(p, q, r)
	n1 = q-p +1
	n2 = r - q
	L = {}
	for i= 1, n1 do
		-- print(n1, p, q, r)
		L[i] =  valAt(p+i-1)
	end
	R ={}
	for j= 1, n2 do
		R[j] =  valAt(q+j)
	end
	L[n1+1] = 9999999999999999999999
	R[n2+1] = 9999999999999999999999
	i = 1
	j = 1
	linePos = q 
	for k = p, r do
		if L[i] < R[j] then
			-- linePOStoID[k] = L[i]
			lines[L[i]].setPos(k)
			i = i + 1
		else
			lines[R[j]].setPos(k)
			-- linePOStoID[k] = R[j]
			j = j + 1
		end
	end
	for i = 1, NUM_LINES do
		linePOStoID[lines[i].getPos()] = lines[i].getID()
		-- lines[linePOStoID[i]].setPos(i)
	end
	tester = 1
	msState = 3

end

function merge3(p, q, r)
	n1 = q-p +1
	n2 = r - q
	L = {}
	for i= 1, n1 do
		L[i] =  valAt(p+i-1)
	end
	R ={}
	for j= 1, n2 do
		R[j] =  valAt(q+j)
	end
	L[n1+1] = 9999999999999999999999
	R[n2+1] = 9999999999999999999999
	i = 1
	j = 1
	linePos = q 
	for k = p, r do
		if L[i] <= R[j] then
			linePOStoID[k] = L[i]
			i = i + 1
		else
			linePOStoID[k] = R[j]
			j = j + 1
		end
	end
	for i = 1, NUM_LINES do
		lines[linePOStoID[i]].setPos(i)
	end
	tester = 1

end

function countingSort()
	if csStep == 0 then
		if onPos <= k then
			C[onPos] = 0
		else
			onPos = 0
			csStep = 1
		end

	elseif csStep == 1 then
		if onPos <=NUM_LINES then
			C[linePOStoID[onPos]] = C[linePOStoID[onPos]] + 1 
		else
			onPos = 0
			csStep = 2
		end
	elseif csStep == 2 then
		if onPos <= k then
			C[onPos] = C[onPos] + C[onPos-1] 
		else
			onPos = NUM_LINES
			csStep = 3
		end
	elseif csStep == 3 then
		-- for i = 1, NUM_LINES do
		-- 	-- print(C[i])
		-- end
		-- print(onPos)
		if onPos >= 1 then
			-- print(onPos)
			local j = linePOStoID[onPos]
			if j == nil then print("WHAT THE FUCKKKK", onPos) end
			B[C[j]] = j
			C[j] = C[j] - 1
		else
			onPos = 1
			csStep = 4
			passesPerSecond = (500/1000)*NUM_LINES
		end
		onPos = onPos -1
	else
		if onPos <= NUM_LINES then
			lines[onPos].setPos(B[onPos])
		end

	end
	if csStep ~= 3 then
		onPos = onPos + 1
	end
end

function onAlgo()
	return sortType
end


function setAlgo(n)
	sortType = n
end

function setList(arr)

end