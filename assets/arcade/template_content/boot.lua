require "system"
gpu = system.getDevice("gpu")
speaker = system.getDevice("speaker")
gamepad = system.getDevice("gamepad")

states = {a=false, b=false, x=0, y=0, xlen=0, ylen=0, alen=0, blen=0}
numbers = {}
for i = 0,16 do
    numbers[i] = gpu.loadTGA( io.open( "numbers/".. tostring(i) ..".tga", "rb" ) )
end
base = gpu.loadTGA( io.open( "numbers/base.tga", "rb" ) )

grid = {}
combined = {}

sound0 = {
            waveform = "sawtooth",
            frequency = 70,
            duration = 0.05,
            slide = 100,
        }
sound2 = {
            waveform = "square",
            frequency = 500,
            duration = 0.1
        }

function setStates()
   function calcMod(x)
		if x > 250 then return 2 end
		if x > 80 then return 5 end
		if x > 40 then return 10 end
		return 20
	end
	states.xlen = gamepad.getAxis(0) ~= 0 and states.xlen + 1 or 0
	states.ylen = gamepad.getAxis(1) ~= 0 and states.ylen + 1 or 0
	states.x = (states.xlen % calcMod(states.xlen) == 1) and gamepad.getAxis(0) or 0
	states.y = (states.ylen % calcMod(states.ylen) == 1) and gamepad.getAxis(1) or 0
	states.alen = gamepad.getButton(0) and states.alen + 1 or 0
	states.blen = gamepad.getButton(1) and states.blen + 1 or 0
	states.a = states.alen == 1
	states.b = states.blen == 1
end

function restartGame()
    grid = {{-1,-1,-1,-1},{-1,-1,-1,-1},{-1,-1,-1,-1},{-1,-1,-1,-1}}
    insertRandom()

end

function drawGame(moving, shft, dir)
    gpu.clear()
    if true then
        for x = 1,4 do
            for y = 1,4 do
                if grid[x][y] >= 0 and not moving[4*x+y] then                    
                    gpu.setOffset(16*(x-1),16*(y-1))
                    drawNumber(grid[x][y])
                end
            end
        end
        dx = dir[1]
        dy = dir[2]
        for x = 1,4 do
            for y = 1,4 do
                if moving[4*x+y] then                
                    gpu.setOffset(16*(x-1) + dx*shft,16*(y-1) + dy*shft)
                    drawNumber(grid[x][y])
                end
            end
        end
    end
end

function drawNumber(number)
    if number <= 16 then
        gpu.drawImage(0, 0, numbers[number])
    else
        gpu.drawImage(0, 0, base)
        gpu.drawText(6, 2, tostring(number))
    end
    gpu.drawLine(0,15,15,15,1)
    gpu.drawLine(15,0,15,15,1)
                    
end

function getMoving()
    newGrid = {}
    for x = 1,4 do
        newGrid[x] = {}
        for y = 1,4 do
            newGrid[x][y] = grid[x][y]
        end
    end
    if states.x ~= 0 then states.y = 0 end
    if states.x == 0 and states.y == 0 then
        return {}
    end
    
    if states.x == -1 then
        x1 = 2; x2 = 4; dx = 1
        y1 = 1; y2 = 4; dy = 1
    elseif states.x == 1 then
        x1 = 3; x2 = 1; dx = -1
        y1 = 1; y2 = 4; dy = 1
    elseif states.y == -1 then
        x1 = 1; x2 = 4; dx = 1
        y1 = 2; y2 = 4; dy = 1
    elseif states.y == 1 then
        x1 = 1; x2 = 4; dx = 1
        y1 = 3; y2 = 1; dy = -1
    end
    result = {}
    for x = x1,x2,dx do
        for y = y1,y2,dy do
            if newGrid[x][y] ~= -1 then
                if newGrid[x+states.x][y+states.y] == -1 then
                    newGrid[x+states.x][y+states.y] = newGrid[x][y]
                    newGrid[x][y] = -1
                    result[4*x+y] = true
                elseif newGrid[x][y] == newGrid[x+states.x][y+states.y] then
                    if not (combined[x+4*y] or combined[x+states.x+4*(y+states.y)]) then
                        newGrid[x+states.x][y+states.y] = newGrid[x+states.x][y+states.y] + 1
                        newGrid[x][y] = -1
                        combined[x+states.x+4*(y+states.y)] = true
                    result[4*x+y] = true
                    end             
                end
            end
        end
    end
    return result
end

function tryMove()
    combined = {}
    comb = false
    moved = false
    for i = 1,3 do
        moving = getMoving()
        if next(moving) ~= nil then
            if not comb and next(combined) ~= nil then
                comb = true
                speaker.play(sound2)
            elseif i == 1 then
                speaker.play(sound0)
            end
            moved = true
            for shft = 2,15,2 do
                drawGame(moving, shft, {states.x, states.y})
                system.sleep(0)
            end
            grid = newGrid
        end
    end
    return moved
end

function insertRandom()
    empty = {}
    for i = 1,4 do
        for j = 1,4 do
            if grid[i][j] == -1 then
                empty[#empty+1] = {i,j}
            end
        end
    end
    v = math.random(1, 10)
    v = v==1 and 2 or 1
    c = math.random(1, #empty)
    grid[empty[c][1]][empty[c][2]] = v
    
end

function main()
    math.randomseed( os.time() )
    restartGame()
    screen = game
    while true do
        setStates()
        screen()
        system.sleep(0)
    end
end

function game()
    if states.a then
        restartGame()
    end
    if tryMove() then    
        insertRandom()
    end
    drawGame({}, 0, {states.x, states.y})
end

main()