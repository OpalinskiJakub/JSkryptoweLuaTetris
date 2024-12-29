local tetrominoes = require("pieces")
local utils = require("utils")

local game = {}

GRID_WIDTH = 10
GRID_HEIGHT = 20
BLOCK_SIZE = 25

function game.initialize()
    game.grid = {}
    game.currentPiece = nil
    game.nextPiece = nil
    game.score = 0
    game.gameOver = false
    game.timer = 0
    game.dropInterval = 1
    game.initializeGrid()
    game.spawnNewPiece()
end

function game.initializeGrid()
    game.grid = {}
    for y = 1, GRID_HEIGHT do
        game.grid[y] = {}
        for x = 1, GRID_WIDTH do
            game.grid[y][x] = {0, 0, 0}
        end
    end
end

function game.spawnPiece()
    local index = math.random(#tetrominoes)
    local piece = {}
    piece.typeIndex = index
    piece.type = tetrominoes[index]
    piece.rotation = 1
    piece.shape = piece.type.rotations[piece.rotation]
    piece.x = math.floor(GRID_WIDTH / 2) - math.ceil(#piece.shape[1] / 2) + 1
    piece.y = 1
    return piece
end

function game.spawnNewPiece()
    game.currentPiece = game.nextPiece or game.spawnPiece()
    game.nextPiece = game.spawnPiece()
    if not game.isValidPosition(game.currentPiece, game.currentPiece.x, game.currentPiece.y, game.currentPiece.rotation) then
        game.gameOver = true
        utils.playSound("gameover")
    end
end

function game.isValidPosition(piece, x, y, rotation)
    local shape = piece.type.rotations[rotation]
    for i, row in ipairs(shape) do
        for j, cell in ipairs(row) do
            if cell == 1 then
                local newX = x + j
                local newY = y + i
                if newX < 1 or newX > GRID_WIDTH or newY > GRID_HEIGHT then
                    return false
                end
                if newY > 0 then
                    local gridCell = game.grid[newY][newX]
                    if gridCell[1] ~= 0 or gridCell[2] ~= 0 or gridCell[3] ~= 0 then
                        return false
                    end
                end
            end
        end
    end
    return true
end

function game.lockPiece()
    local piece = game.currentPiece
    local shape = piece.shape
    for i, row in ipairs(shape) do
        for j, cell in ipairs(row) do
            if cell == 1 then
                local x = piece.x + j
                local y = piece.y + i
                if y > 0 and y <= GRID_HEIGHT and x > 0 and x <= GRID_WIDTH then
                    game.grid[y][x] = piece.type.color
                end
            end
        end
    end
    utils.playSound("lock")
    game.score = game.score + 2
end

function game.clearLines()
    local linesClearedThisMove = 0
    for y = GRID_HEIGHT, 1, -1 do
        local isFull = true
        for x = 1, GRID_WIDTH do
            if game.grid[y][x][1] == 0 and game.grid[y][x][2] == 0 and game.grid[y][x][3] == 0 then
                isFull = false
                break
            end
        end
        if isFull then
            table.remove(game.grid, y)
            table.insert(game.grid, 1, {})
            for x = 1, GRID_WIDTH do
                game.grid[1][x] = {0, 0, 0}
            end
            linesClearedThisMove = linesClearedThisMove + 1
        end
    end
    if linesClearedThisMove > 0 then
        local pointsPerLine = { [1] = 40, [2] = 100, [3] = 300, [4] = 1200 }
        local points = pointsPerLine[linesClearedThisMove] or 0
        game.score = game.score + points
        utils.playSound("clear")
    end
end

function game.handleGameInput(key)
    if game.gameOver then
        if key == "r" then
            game.initialize()
            state = "game"
        end
        return
    end

    if key == "s" then
        utils.saveAndReturnToMenu(game)
    elseif key == "escape" then
        state = "menu"
    elseif not game.gameOver then
        if key == "left" then
            game.movePiece(-1, 0)
        elseif key == "right" then
            game.movePiece(1, 0)
        elseif key == "down" then
            game.movePiece(0, 1)
        elseif key == "up" then
            game.rotatePiece()
        end
    end
end

function game.movePiece(dx, dy)
    if game.isValidPosition(game.currentPiece, game.currentPiece.x + dx, game.currentPiece.y + dy, game.currentPiece.rotation) then
        game.currentPiece.x = game.currentPiece.x + dx
        game.currentPiece.y = game.currentPiece.y + dy
        utils.playSound("move")
        if dy == 1 then
            game.score = game.score + 1
        end
    end
end

function game.rotatePiece()
    local newRotation = game.currentPiece.rotation + 1
    if newRotation > #game.currentPiece.type.rotations then
        newRotation = 1
    end
    if game.isValidPosition(game.currentPiece, game.currentPiece.x, game.currentPiece.y, newRotation) then
        game.currentPiece.rotation = newRotation
        game.currentPiece.shape = tetrominoes[game.currentPiece.typeIndex].rotations[newRotation]
        utils.playSound("rotate")
    end
end

function game.update(dt)
    if not game.gameOver then
        game.timer = game.timer + dt
        if game.timer >= game.dropInterval then
            if game.isValidPosition(game.currentPiece, game.currentPiece.x, game.currentPiece.y + 1, game.currentPiece.rotation) then
                game.currentPiece.y = game.currentPiece.y + 1
            else
                game.lockPiece()
                game.clearLines()
                game.spawnNewPiece()
            end
            game.timer = 0
        end
    end
end

function game.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 50, 50, GRID_WIDTH * BLOCK_SIZE, GRID_HEIGHT * BLOCK_SIZE)
    for y = 1, GRID_HEIGHT do
        for x = 1, GRID_WIDTH do
            local color = game.grid[y][x]
            if color[1] ~= 0 or color[2] ~= 0 or color[3] ~= 0 then
                love.graphics.setColor(color)
                love.graphics.rectangle("fill", 50 + (x - 1) * BLOCK_SIZE, 50 + (y - 1) * BLOCK_SIZE, BLOCK_SIZE - 1, BLOCK_SIZE - 1)
            end
        end
    end
    if game.currentPiece then
        local piece = game.currentPiece
        local shape = piece.shape
        love.graphics.setColor(piece.type.color)
        for i, row in ipairs(shape) do
            for j, cell in ipairs(row) do
                if cell == 1 then
                    local x = 50 + (piece.x + j - 1) * BLOCK_SIZE
                    local y = 50 + (piece.y + i - 1) * BLOCK_SIZE
                    love.graphics.rectangle("fill", x, y, BLOCK_SIZE - 1, BLOCK_SIZE - 1)
                end
            end
        end
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. game.score, 400, 25)
    love.graphics.print("Press 's' to save and return to menu", 400, 55)
    love.graphics.print("Press 'Escape' to return to menu", 400, 85)
    if game.gameOver then
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("Game Over! Press 'R' to Restart", 50, 300, 300, "center")
    end
end

return game

