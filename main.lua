-- That wierd sweeping winning animation
-- Stats!
-- Setting Board size and # of mines 
--		(Resize window to fit new board. Max size based on highest resolution?)
--		New Button with lil arrow to the right. New button will make new game with same size and mines
--		lil arrow will give options

TileSize = 32

Animation = require("lib.animation")

Fonts = {
    numbers = love.graphics.newImageFont("gfx/numbers.png", "12345678f"),
    timer = love.graphics.newImageFont("gfx/timer.png", "1234567890 abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ[].:"),
}

function love.load()
    modes = love.graphics.getModes()
    table.sort(modes, function(a, b) return a.width > b.width end)   -- sort from smallest to largest
    maxWidth = modes[1].width
    maxHeight = modes[1].height
    math.randomseed( os.time() ); math.random(); math.random(); math.random()
	MINES = 40
	WIDTH = 16
	HEIGHT = 16
    loadLevel(WIDTH, HEIGHT, MINES, -1, -1)
    generated = false
    DEBUG = false
    timer = 0
	gameOver = false
	gameWon = false
	dcWait = 1
    hintDuration = 1
    hintTimer = 0
    hint = false
    lastHint = nil
    hintSquare = nil
    boom = nil
end

function love.update(dt)
    if boom ~= nil then boom:update(dt) end
    if gameOver or gameWon then
        if love.keyboard.isDown(" ") then
            gameOver = false
			gameWon = false
            love.load()
        end
        return
    end
    DEBUG = love.keyboard.isDown("tab")
    if generated then
        timer = timer + dt
    end
	if doubleClick ~= nil then
		dcTimer = dcTimer + dt
		if dcTimer >= dcWait then
			doubleClick = nil
			dcTimer = 0
		end
	end
    if hint then
        hintTimer = hintTimer + dt
        if hintTimer >= hintDuration then
            hint = false
        end
    end
end

function love.keyreleased(key, unicode)
    if key == "f2" then 
        love.load()
    end
    if key == "h" then
        showHint()
    end
end

function love.mousereleased(x, y, key)
	if gameOver or gameWon then return end
    local i = x - (love.graphics.getWidth() - (levelWidth * TileSize)) / 2
    i = math.floor(i / TileSize) + 1
    local j = y - (((love.graphics.getHeight() - (levelHeight * TileSize)) / 2) - 32)
    j = math.floor(j / TileSize) + 1
    if i >= 1 and i <= levelWidth and j >= 1 and j <= levelHeight then
        if key == "r" and not revealed[j][i] then
            flags[j][i] = not flags[j][i]
			if flags[j][i] then
				minesToFind = minesToFind - 1
			else
				minesToFind = minesToFind + 1
			end
        elseif key == "l" then
            if not generated then
                loadLevel(WIDTH, HEIGHT, MINES, i, j)
                generated = true
				reveal(i, j)
			elseif revealed[j][i] and numbers[j][i] >= 1 then
				if doubleClick ~= nil and dcTimer <= dcWait and doubleClick.x == i and doubleClick.y == j then
					if flagsAround(i, j) >= numbers[j][i] then
						reveal(i-1, j-1)
						reveal(i, j-1)
						reveal(i+1, j-1)
						reveal(i-1, j)
						reveal(i+1, j)
						reveal(i-1, j+1)
						reveal(i, j+1)
						reveal(i+1, j+1)
						doubleClick = nil
					end
				else
					doubleClick = {
						x = i, y = j
					}
					dcTimer = 0
				end
			else
				reveal(i, j)
            end
        end
    end
	if hasWon() then
		gameWon = true
	end
end

function loadLevel(w, h, n, x, y)
	levelMines = n
	minesToFind = levelMines
    if x == -1 then 
        n = 0
    end
    levelWidth = w
    levelHeight = h
    local m = 0
    seed = math.floor(math.random() * 100000)
    math.randomseed(seed)
    mines = {}
    flags = {}
    revealed = {}
    for j = 1, h do
        mines[j] = {}
        flags[j] = {}
        revealed[j] = {}
        for i = 1, w do
            mines[j][i] = false
            flags[j][i] = false
            revealed[j][i] = false
        end
    end
    while m < n do
        local rand = math.random(w*h) - 1
        local i = (rand % w) + 1
        local j = (math.floor(rand / w)) + 1
        if mines[j][i] == false and math.abs(x-i) + math.abs(y-j) > 2 then
            mines[j][i] = true
            m = m + 1
        end
    end
    assert(m == n, "ERROR WRONG NUMBER OF MINES")
    numbers = {}
    for j = 1, h do
        numbers[j] = {}
        for i = 1, w do
            numbers[j][i] = minesAround(i, j)
        end
    end
end

function showHint()
    hint = true
    hintTimer = 0
    local hintOptions = {}
    for j, row in pairs(mines) do
        for i, _ in pairs(row) do
			-- If we've not double clicked on this square even though we've found all the mines around it
			if ( revealed[j][i] and numbers[j][i] > 0 and flagsAround(i, j) == numbers[j][i] and revealedAround(i, j) + flagsAround(i, j) < 8 )
			-- If we've not seen the only x places mines could be around this square
			or ( revealed[j][i] and numbers[j][i] > 0 and (8 - revealedAround(i, j) == numbers[j][i] ) and revealedAround(i, j) + flagsAround(i, j) < 8 ) then
                hintOptions[#hintOptions+1] = {i,j}
            end
        end
    end
    if #hintOptions == 0 then
        hintSquare = nil
    else
        lastHint = lastHint or math.random(#hintOptions)
        local i = 1 + lastHint % #hintOptions
        hintSquare = {
            x = hintOptions[i][1],
            y = hintOptions[i][2],
        }
        lastHint = i
    end
end

function reveal(i, j)
    if i < 1 or j < 1 or i > levelWidth or j > levelHeight then return end
    if revealed[j][i] then return end
	if flags[j][i] then return end
	if mines[j][i] then 
        gameOver = true
        boom = Animation.new( (i-1)*TileSize, (j-1)*TileSize, 0.1, "boom.png", 5, 2 )
        boom.offset.x = (192 - TileSize) / 2
        boom.offset.y = (192 - TileSize) / 2
        boom.loop = false
        return
    end
    revealed[j][i] = true
    if numbers[j][i] == 0 then
        reveal(i-1, j-1)
        reveal(i, j-1)
        reveal(i+1, j-1)
        reveal(i-1, j)
        reveal(i+1, j)
        reveal(i-1, j+1)
        reveal(i, j+1)
        reveal(i+1, j+1)
    end
end

function hasWon()
	local r = 0
	for j = 1, levelHeight do
		for i = 1, levelWidth do
			if revealed[j][i] then r = r + 1 end
		end
	end
	return (levelWidth * levelHeight) - r == levelMines
end

function minesAround(x, y)
    local n = 0
    if mines[y-1] ~= nil then
        if mines[y-1][x-1] then n = n + 1 end
        if mines[y-1][x] then n = n + 1 end
        if mines[y-1][x+1] then n = n + 1 end
    end
    if mines[y][x-1] then n = n + 1 end
    if mines[y][x+1] then n = n + 1 end
    if mines[y+1] ~= nil then
        if mines[y+1][x-1] then n = n + 1 end
        if mines[y+1][x] then n = n + 1 end
        if mines[y+1][x+1] then n = n + 1 end
    end
    return n
end

function flagsAround(x, y)
	local n = 0
	if flags[y-1] ~= nil then
        if flags[y-1][x-1] then n = n + 1 end
        if flags[y-1][x] then n = n + 1 end
        if flags[y-1][x+1] then n = n + 1 end
    end
    if flags[y][x-1] then n = n + 1 end
    if flags[y][x+1] then n = n + 1 end
    if flags[y+1] ~= nil then
        if flags[y+1][x-1] then n = n + 1 end
        if flags[y+1][x] then n = n + 1 end
        if flags[y+1][x+1] then n = n + 1 end
    end
    return n
end

function revealedAround(x, y)
    local n = 0
	if revealed[y-1] ~= nil then
        if not (revealed[y-1][x-1] == false) then n = n + 1 end
        if not (revealed[y-1][x] == false) then n = n + 1 end
        if not (revealed[y-1][x+1] == false) then n = n + 1 end
    else
        n = n + 3
    end
    if not (revealed[y][x-1] == false) then n = n + 1 end
    if not (revealed[y][x+1] == false) then n = n + 1 end
    if revealed[y+1] ~= nil then
        if not (revealed[y+1][x-1] == false) then n = n + 1 end
        if not (revealed[y+1][x] == false) then n = n + 1 end
        if not (revealed[y+1][x+1] == false) then n = n + 1 end
    else
        n = n + 3
    end
    return n
end

function getTime(t)
    local s = math.floor(t % 60)
    local m = math.floor(t / 60) % (60*60)
    local h = math.floor(t / (60*60))
    if s < 10 then
        s = "0" .. tostring(s)
    else
        s = tostring(s)
    end
    if m < 10 then
        m = "0" .. tostring(m)
    else
        m = tostring(m)
    end
    return tostring(h) .. ":" .. m .. ":" .. s
end

function love.draw()
    local x = (love.graphics.getWidth() - (levelWidth * TileSize)) / 2
    local y = ((love.graphics.getHeight() - (levelHeight * TileSize)) / 2) - 32
	---[[ -- DEBUGGING
	if DEBUG then
		local mx, my = love.mouse.getPosition()
		mx = math.floor( (mx - x) / TileSize ) + 1
		my = math.floor( (my - y) / TileSize ) + 1
		if mines[my] ~= nil and mines[my][mx] ~= nil then
			love.graphics.setFont(Fonts.timer)
			love.graphics.print(mx .. ", " .. my, 672, 0)
			love.graphics.print("mine? " .. tostring(mines[my][mx]), 672, 32)
			love.graphics.print("flag? " .. tostring(flags[my][mx]), 672, 64)
			love.graphics.print("n = " .. tostring(numbers[my][mx]), 672, 96)
			love.graphics.print("adjM = " .. tostring(minesAround(mx, my)), 672, 128)
			love.graphics.print("adjF = " .. tostring(flagsAround(mx, my)), 672, 160)
			love.graphics.print("adjR = " .. tostring(revealedAround(mx, my)), 672, 192)
		end
	end
	--]]
    love.graphics.translate(x, y)
    for j, row in pairs(mines) do
        for i, mine in pairs(row) do
            if revealed[j][i] then
                love.graphics.setColor(128, 128, 128)
            else
                love.graphics.setColor(96, 96, 96)
            end
            love.graphics.rectangle("fill", (i-1)*TileSize, (j-1)*TileSize, TileSize, TileSize)
            love.graphics.setColor(32, 32, 32)
            love.graphics.rectangle("line", (i-1)*TileSize, (j-1)*TileSize, TileSize, TileSize)
            if (DEBUG or gameOver or gameWon) and mine then
                love.graphics.circle("line", (i-0.5)*TileSize, (j-0.5)*TileSize, 4)
            elseif DEBUG then
                love.graphics.setColor(255, 255, 255)
                love.graphics.setFont(Fonts.numbers)
                love.graphics.printf(numbers[j][i], (i-1)*TileSize, (j-0.9)*TileSize, TileSize, "center")
            end
            if revealed[j][i] then
                love.graphics.setColor(255, 255, 255)
                love.graphics.setFont(Fonts.numbers)
                love.graphics.printf(numbers[j][i], (i-1)*TileSize, (j-0.9)*TileSize, TileSize, "center")
			elseif flags[j][i] then
				love.graphics.setColor(255, 255, 255)
                love.graphics.setFont(Fonts.numbers)
				love.graphics.printf("f", (i-1)*TileSize, (j-0.9)*TileSize, TileSize, "center")
            end
        end
    end
    if hint and hintSquare ~= nil then
        love.graphics.setColor(255, 32, 32)
        local i = hintSquare.x
        local j = hintSquare.y
        love.graphics.rectangle("line", (i-1)*TileSize, (j-1)*TileSize, TileSize, TileSize)
    end
    if boom ~= nil then
        love.graphics.setColor(255, 255, 255)
        boom:draw()
    end
    love.graphics.translate(-x, -y)
    love.graphics.setColor(240, 240, 240)
    love.graphics.setFont(Fonts.timer)
    love.graphics.print(minesToFind, x + 32, (love.graphics.getHeight() + (levelHeight * TileSize)) / 2)
	local t = getTime(timer)
    love.graphics.print(t, love.graphics.getWidth() - x - 32, (love.graphics.getHeight() + (levelHeight * TileSize)) / 2)
    if hint and hintSquare == nil then
        love.graphics.printf("No hint is available", 0, 256, love.graphics.getWidth(), "center")
    end
    if DEBUG then
        love.graphics.print(seed, 0, 0)
    end
    if (gameOver and boom.finished) or gameWon then
        love.graphics.setColor(0, 0, 0, 128)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(255, 255, 255)
		if gameOver then
			love.graphics.printf("GAME OVER", 0, 64, love.graphics.getWidth(), "center")
		elseif gameWon then
			love.graphics.printf("CONGRATULATIONS", 0, 64, love.graphics.getWidth(), "center")
		end
        local t = getTime(timer)
		love.graphics.printf("Your time was " .. t, 0, 240, love.graphics.getWidth(), "center")
        love.graphics.printf("Press [Space] to Continue", 0, 480, love.graphics.getWidth(), "center")
    end
end