local utils = {}

local sounds = {}

function utils.loadSounds()
    local function loadSound(name, path)
        local success, sound = pcall(function()
            return love.audio.newSource(path, "static")
        end)
        if success and sound then
            sounds[name] = sound
        end
    end

    loadSound("move", "assets/move.wav")
    loadSound("rotate", "assets/rotate.wav")
    loadSound("lock", "assets/lock.wav")
    loadSound("clear", "assets/clear.wav")
    loadSound("gameover", "assets/gameover.wav")
    loadSound("menuNavigate", "assets/menuNavigate.wav")
    loadSound("menuSelect", "assets/menuSelect.wav")
end

function utils.playSound(name)
    if sounds[name] then
        sounds[name]:play()
    end
end

function utils.saveAndReturnToMenu(gameState)
    if not love.filesystem.getInfo("saves", "directory") then
        love.filesystem.createDirectory("saves")
    end
    local filename = "saves/save_" .. os.date("%Y%m%d_%H%M%S") .. ".lua"
    local saveData = {
        grid = gameState.grid,
        currentPiece = {
            typeIndex = gameState.currentPiece.typeIndex,
            rotation = gameState.currentPiece.rotation,
            x = gameState.currentPiece.x,
            y = gameState.currentPiece.y
        },
        nextPiece = {
            typeIndex = gameState.nextPiece.typeIndex,
            rotation = gameState.nextPiece.rotation,
            x = gameState.nextPiece.x,
            y = gameState.nextPiece.y
        },
        score = gameState.score,
        gameOver = gameState.gameOver
    }
    local serialized = utils.serialize(saveData)
    love.filesystem.write(filename, serialized)
    state = "menu"
end

function utils.loadSavedGames(loadMenu)
    loadMenu.options = {}
    local files = love.filesystem.getDirectoryItems("saves")
    for _, file in ipairs(files) do
        if file:match("%.lua$") then
            table.insert(loadMenu.options, file)
        end
    end
    loadMenu.selected = 1
end

function utils.loadSelectedGame(loadMenu, gameState, tetrominoes)
    if loadMenu.options[loadMenu.selected] then
        local filename = "saves/" .. loadMenu.options[loadMenu.selected]
        local serialized = love.filesystem.read(filename)
        local saveData = utils.deserialize(serialized)
        if saveData then
            gameState.grid = saveData.grid
            gameState.currentPiece = utils.restorePiece(saveData.currentPiece, tetrominoes)
            gameState.nextPiece = utils.restorePiece(saveData.nextPiece, tetrominoes)
            gameState.score = saveData.score or 0
            gameState.gameOver = saveData.gameOver or false
            state = "game"
        end
    end
end



function utils.deleteSelectedSave(loadMenu)
    local filename = "saves/" .. loadMenu.options[loadMenu.selected]
    if love.filesystem.getInfo(filename) then
        love.filesystem.remove(filename)
        utils.loadSavedGames(loadMenu)
    end
end

function utils.serialize(tbl)
    local serialized = "{"
    for k, v in pairs(tbl) do
        if type(k) == "string" then
            k = '"' .. k .. '"'
        end
        serialized = serialized .. "[" .. k .. "]="
        if type(v) == "table" then
            serialized = serialized .. utils.serialize(v)
        elseif type(v) == "number" then
            serialized = serialized .. v
        elseif type(v) == "string" then
            serialized = serialized .. '"' .. v .. '"'
        elseif type(v) == "boolean" then
            serialized = serialized .. tostring(v)
        else
            serialized = serialized .. "nil"
        end
        serialized = serialized .. ","
    end
    serialized = serialized .. "}"
    return serialized
end

function utils.deserialize(str)
    local func, err = load("return " .. str)
    if not func then return nil end
    return func()
end

function utils.restorePiece(pieceData, tetrominoes)
    local piece = {}
    piece.typeIndex = pieceData.typeIndex
    piece.type = tetrominoes[piece.typeIndex]
    piece.rotation = pieceData.rotation
    piece.shape = tetrominoes[piece.typeIndex].rotations[piece.rotation]
    piece.x = pieceData.x
    piece.y = pieceData.y
    return piece
end


return utils

