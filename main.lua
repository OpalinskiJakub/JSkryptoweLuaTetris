love.graphics.setDefaultFilter("nearest", "nearest")

WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600
GRID_WIDTH = 10
GRID_HEIGHT = 20
BLOCK_SIZE = 25

game = {}
game.grid = {}
game.currentPiece = nil
game.nextPiece = nil
game.score = 0
game.gameOver = false
game.timer = 0
game.dropInterval = 1

state = "menu"

menu = {
    options = { "Start New Game", "Load Game", "Exit" },
    selected = 1
}

loadMenu = {
    options = {},
    selected = 1
}

tetrominoes = {
    {
        color = {1, 0, 0},
        rotations = {
            { {1,1,1,1} },
            { {1},{1},{1},{1} }
        }
    },
    {
        color = {0,1,0},
        rotations = {
            { {0,1,1},
              {1,1,0} },
            { {1,0},
              {1,1},
              {0,1} }
        }
    },
    {
        color = {0,0,1},
        rotations = {
            { {1,1,0},
              {0,1,1} },
            { {0,1},
              {1,1},
              {1,0} }
        }
    },
    {
        color = {1,1,0},
        rotations = {
            { {1,1},
              {1,1} }
        }
    }
}

function initializeGrid()
    game.grid = {}
    for y = 1, GRID_HEIGHT do
        game.grid[y] = {}
        for x = 1, GRID_WIDTH do
            game.grid[y][x] = {0,0,0}
        end
    end
end

sounds = {}

function love.load()
    love.filesystem.setIdentity("tetris_game")

    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    love.window.setTitle("Tetris in Lua - Love2D")

    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    love.graphics.setFont(love.graphics.newFont(20))

    local function loadSound(name, path)
        local success, sound = pcall(function()
            return love.audio.newSource(path, "static")
        end)
        if success and sound then
            sounds[name] = sound
        else
            print("Ostrzeżenie: Nie można załadować " .. path .. ".")
            sounds[name] = nil
        end
    end

    loadSound("move", "assets/move.wav")
    loadSound("rotate", "assets/rotate.wav")
    loadSound("lock", "assets/lock.wav")
    loadSound("clear", "assets/clear.wav")
    loadSound("gameover", "assets/gameover.wav")
    loadSound("menuNavigate", "assets/menuNavigate.wav")
    loadSound("menuSelect", "assets/menuSelect.wav")

    if not sounds.menuNavigate then
        sounds.menuNavigate = sounds.move
    end
    if not sounds.menuSelect then
        sounds.menuSelect = sounds.rotate
    end

    if not love.filesystem.getInfo("saves", "directory") then
        love.filesystem.createDirectory("saves")
    end

    initializeGrid()
end


function love.keypressed(key)
    if state == "menu" then
        handleMenuInput(key)
    elseif state == "loadMenu" then
        handleLoadMenuInput(key)
    elseif state == "game" then
        handleGameInput(key)
    end
end

function love.update(dt)
    if state == "game" and not game.gameOver then
        game.timer = game.timer + dt
        if game.timer >= game.dropInterval then
            if isValidPosition(game.currentPiece, game.currentPiece.x, game.currentPiece.y +1, game.currentPiece.rotation) then
                game.currentPiece.y = game.currentPiece.y +1
            else
                lockPiece()
                clearLines()
                spawnNewPiece()
            end
            game.timer = 0
        end
    end
end

function love.draw()
    if state == "menu" then
        drawMenu()
    elseif state == "loadMenu" then
        drawLoadMenu()
    elseif state == "game" then
        drawGame()
    end
end

function handleMenuInput(key)
    if key == "up" then
        menu.selected = menu.selected - 1
        if menu.selected < 1 then
            menu.selected = #menu.options
        end
        if sounds.menuNavigate then sounds.menuNavigate:play() end
    elseif key == "down" then
        menu.selected = menu.selected + 1
        if menu.selected > #menu.options then
            menu.selected = 1
        end
        if sounds.menuNavigate then sounds.menuNavigate:play() end
    elseif key == "return" then
        if sounds.menuSelect then sounds.menuSelect:play() end
        if menu.options[menu.selected] == "Start New Game" then
            resetGame()
            state = "game"
        elseif menu.options[menu.selected] == "Load Game" then
            loadSavedGames()
            state = "loadMenu"
        elseif menu.options[menu.selected] == "Exit" then
            love.event.quit()
        end
    end
end

function handleLoadMenuInput(key)
    if key == "up" then
        loadMenu.selected = loadMenu.selected - 1
        if loadMenu.selected < 1 then
            loadMenu.selected = #loadMenu.options
        end
        if sounds.menuNavigate then sounds.menuNavigate:play() end
    elseif key == "down" then
        loadMenu.selected = loadMenu.selected + 1
        if loadMenu.selected > #loadMenu.options then
            loadMenu.selected = 1
        end
        if sounds.menuNavigate then sounds.menuNavigate:play() end
    elseif key == "return" then
        if #loadMenu.options > 0 then
            if sounds.menuSelect then sounds.menuSelect:play() end
            loadSelectedGame()
        end
    elseif key == "escape" then
        if sounds.menuSelect then sounds.menuSelect:play() end
        state = "menu"
    elseif key == "r" then
        if #loadMenu.options > 0 then
            if sounds.menuSelect then sounds.menuSelect:play() end
            deleteSelectedSave()
        end
    end
end

function handleGameInput(key)
    if key == 's' then
        saveAndReturnToMenu()
    elseif key == 'escape' then
        if sounds.menuSelect then sounds.menuSelect:play() end
        state = "menu"
    elseif key == 'r' and game.gameOver then
        resetGame()
        state = "game"
    elseif not game.gameOver then
        if key == 'left' then
            movePiece(-1, 0)
        elseif key == 'right' then
            movePiece(1, 0)
        elseif key == 'down' then
            movePiece(0, 1)
        elseif key == 'up' then
            rotatePiece()
        end
    end
end

function drawMenu()
    love.graphics.setColor(1,1,1)
    love.graphics.printf("Tetris - Main Menu", 0, 100, WINDOW_WIDTH, "center")
    for i, option in ipairs(menu.options) do
        if i == menu.selected then
            love.graphics.setColor(1, 1, 0)
        else
            love.graphics.setColor(1,1,1)
        end
        love.graphics.printf(option, 0, 150 + i * 40, WINDOW_WIDTH, "center")
    end
end

function drawLoadMenu()
    love.graphics.setColor(1,1,1)
    love.graphics.printf("Load Saved Game", 0, 50, WINDOW_WIDTH, "center")
    if #loadMenu.options == 0 then
        love.graphics.printf("No saved games found.", 0, 150, WINDOW_WIDTH, "center")
    else
        for i, filename in ipairs(loadMenu.options) do
            if i == loadMenu.selected then
                love.graphics.setColor(1, 1, 0)
            else
                love.graphics.setColor(1,1,1)
            end
            love.graphics.printf(filename, 0, 100 + i * 30, WINDOW_WIDTH, "center")
        end
    end
    love.graphics.setColor(1,1,1)
    love.graphics.printf("Press 'Escape' to return to Main Menu", 0, WINDOW_HEIGHT - 50, WINDOW_WIDTH, "center")
    if #loadMenu.options > 0 then
        love.graphics.printf("Press 'R' to delete selected save", 0, WINDOW_HEIGHT - 80, WINDOW_WIDTH, "center")
    end
end

function drawGame()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 50, 50, GRID_WIDTH * BLOCK_SIZE, GRID_HEIGHT * BLOCK_SIZE)

    for y = 1, GRID_HEIGHT do
        for x = 1, GRID_WIDTH do
            local color = game.grid[y][x]
            if color[1] ~=0 or color[2] ~=0 or color[3] ~=0 then
                love.graphics.setColor(color)
                love.graphics.rectangle("fill", 50 + (x-1)*BLOCK_SIZE, 50 + (y-1)*BLOCK_SIZE, BLOCK_SIZE-1, BLOCK_SIZE-1)
            end
        end
    end

    if game.currentPiece then
        local piece = game.currentPiece
        local shape = piece.shape
        love.graphics.setColor(piece.type.color)
        for i, row in ipairs(shape) do
            for j, cell in ipairs(row) do
                if cell ==1 then
                    local x = 50 + (piece.x + j -1) * BLOCK_SIZE
                    local y = 50 + (piece.y + i -1) * BLOCK_SIZE
                    love.graphics.rectangle("fill", x, y, BLOCK_SIZE-1, BLOCK_SIZE-1)
                end
            end
        end
    end

    love.graphics.setColor(1,1,1)
    love.graphics.print("Score: " .. game.score, 400, 25)

    love.graphics.print("Press 's' to save and return to menu", 400, 55)

    love.graphics.print("Press 'Escape' to return to menu", 400, 85)

    if game.gameOver then
        love.graphics.setColor(1,0,0)
        love.graphics.printf("Game Over! Press 'R' to Restart", 50, WINDOW_HEIGHT /2 - 10, GRID_WIDTH * BLOCK_SIZE, "center")
    end
end

function spawnPiece()
    local index = math.random(#tetrominoes)
    local piece = {}
    piece.typeIndex = index
    piece.type = tetrominoes[index]
    piece.rotation = 1
    piece.shape = piece.type.rotations[piece.rotation]
    piece.x = math.floor(GRID_WIDTH / 2) - math.ceil(#piece.shape[1]/2) +1
    piece.y = 1
    print("New piece spawned: Color (" .. table.concat(piece.type.color, ",") .. ")")
    return piece
end

function spawnNewPiece()
    game.currentPiece = game.nextPiece or spawnPiece()
    game.nextPiece = spawnPiece()
    if not isValidPosition(game.currentPiece, game.currentPiece.x, game.currentPiece.y, game.currentPiece.rotation) then
        game.gameOver = true
        if sounds.gameover then sounds.gameover:play() end
        print("Game Over!")
    end
end

function resetGame()
    initializeGrid()
    game.currentPiece = spawnPiece()
    game.nextPiece = spawnPiece()
    game.score = 0
    game.gameOver = false
    game.timer = 0
    state = "game"
    print("Game reset. Score: " .. game.score)
end

function movePiece(dx, dy)
    if isValidPosition(game.currentPiece, game.currentPiece.x + dx, game.currentPiece.y + dy, game.currentPiece.rotation) then
        game.currentPiece.x = game.currentPiece.x + dx
        game.currentPiece.y = game.currentPiece.y + dy
        if sounds.move then 
            sounds.move:play() 
            print("Dźwięk ruchu odtworzony.")
        else
            print("Dźwięk ruchu nie jest załadowany.")
        end
        print("Przesunięto klocek o (" .. dx .. ", " .. dy .. ")")
        
        -- Aktualizacja wyniku tylko przy ruchu w dół
        if dy == 1 then
            game.score = game.score + 1
            print("Aktualny wynik: " .. game.score)
        end
    else
        print("Nie można przesunąć klocka o (" .. dx .. ", " .. dy .. ")")
    end
end

function rotatePiece()
    local newRotation = game.currentPiece.rotation + 1
    if newRotation > #game.currentPiece.type.rotations then
        newRotation = 1
    end

    -- Sprawdź, czy rotacja jest możliwa
    if isValidPosition(game.currentPiece, game.currentPiece.x, game.currentPiece.y, newRotation) then
        game.currentPiece.rotation = newRotation
        game.currentPiece.shape = tetrominoes[game.currentPiece.typeIndex].rotations[newRotation]
        if sounds.rotate then 
            sounds.rotate:play() 
        end
        print("Obrócono klocek. Nowa rotacja: " .. newRotation)
    else
        print("Nie można obrócić klocka do rotacji: " .. newRotation)
    end
end


function isValidPosition(piece, x, y, rotation)
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

function lockPiece()
    local piece = game.currentPiece
    local shape = piece.shape
    for i, row in ipairs(shape) do
        for j, cell in ipairs(row) do
            if cell == 1 then
                local x = piece.x + j
                local y = piece.y + i
                if y > 0 and y <= GRID_HEIGHT and x > 0 and x <= GRID_WIDTH then
                    game.grid[y][x] = piece.type.color
                    print("Wypełniono komórkę (" .. x .. ", " .. y .. ") kolorem (" .. table.concat(game.grid[y][x], ",") .. ")")
                else
                    print("Poza granicami podczas blokowania klocka na (" .. x .. ", " .. y .. ")")
                end
            end
        end
    end
    if sounds.lock then 
        sounds.lock:play() 
        print("Dźwięk blokowania odtworzony.")
    else
        print("Dźwięk blokowania nie jest załadowany.")
    end
    print("Klocek zablokowany na pozycji (" .. piece.x .. ", " .. piece.y .. ")")
    
    -- Aktualizacja wyniku przy blokowaniu klocka
    game.score = game.score + 2
    print("Aktualny wynik: " .. game.score)
    
    printGrid()
end

function clearLines()
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
                game.grid[1][x] = {0,0,0}
            end
            linesClearedThisMove = linesClearedThisMove +1
            print("Linia " .. y .. " została wyczyszczona.")
        end
    end

    if linesClearedThisMove >0 then
        local pointsPerLine = { [1] = 40, [2] = 100, [3] = 300, [4] = 1200 }
        local points = pointsPerLine[linesClearedThisMove] or 0

        game.score = game.score + points
        if sounds.clear then 
            sounds.clear:play() 
            print("Dźwięk wyczyszczenia linii odtworzony.")
        else
            print("Dźwięk wyczyszczenia linii nie jest załadowany.")
        end

        print("Wyczyszczono " .. linesClearedThisMove .. " linii. Zdobyto " .. points .. " punktów. Całkowity wynik: " .. game.score)
    else
        print("Nie wyczyszczono żadnych linii.")
    end
end

function getSavePath(filename)
    -- Katalog `saves` w domyślnym katalogu Love2D
    local basePath = "saves"
    if filename then
        -- Zwróć pełną ścieżkę do pliku
        return basePath .. "/" .. filename
    else
        -- Zwróć tylko ścieżkę katalogu
        return basePath
    end
end


function saveAndReturnToMenu()
    -- Upewnij się, że katalog `saves` istnieje
    local saveDir = getSavePath()
    if not love.filesystem.getInfo(saveDir, "directory") then
        love.filesystem.createDirectory(saveDir)
    end

    -- Konstrukcja nazwy pliku
    local filename = "save_" .. os.date("%Y%m%d_%H%M%S") .. ".lua"
    local filePath = getSavePath(filename)

    -- Dane do zapisania
    local saveData = {
        grid = game.grid,
        currentPiece = {
            typeIndex = game.currentPiece.typeIndex,
            rotation = game.currentPiece.rotation,
            x = game.currentPiece.x,
            y = game.currentPiece.y
        },
        nextPiece = {
            typeIndex = game.nextPiece.typeIndex,
            rotation = game.nextPiece.rotation,
            x = game.nextPiece.x,
            y = game.nextPiece.y
        },
        score = game.score,
        gameOver = game.gameOver
    }

    -- Serializacja i zapis
    local serialized = serialize(saveData)
    local success, err = love.filesystem.write(filePath, serialized)
    if success then
        print("Gra została zapisana w katalogu: " .. love.filesystem.getSaveDirectory() .. "/" .. filePath)
    else
        print("Nie udało się zapisać gry: " .. (err or "nieznany błąd"))
    end

    state = "menu"
end



function saveGame(filename)
    local saveData = {
        grid = game.grid,
        currentPiece = {
            typeIndex = game.currentPiece.typeIndex,
            rotation = game.currentPiece.rotation,
            x = game.currentPiece.x,
            y = game.currentPiece.y
        },
        nextPiece = {
            typeIndex = game.nextPiece.typeIndex,
            rotation = game.nextPiece.rotation,
            x = game.nextPiece.x,
            y = game.nextPiece.y
        },
        score = game.score,
        gameOver = game.gameOver
    }

    local serialized = serialize(saveData)
    love.filesystem.write("saves/" .. filename, serialized)
    print("Gra zapisana jako " .. filename)
end

function loadGame(filename)
    local filePath = getSavePath(filename)

    if love.filesystem.getInfo(filePath) then
        -- Odczyt i deserializacja danych
        local serialized = love.filesystem.read(filePath)
        local saveData = deserialize(serialized)

        if saveData then
            -- Przywróć stan gry
            game.grid = saveData.grid
            game.currentPiece = restorePiece(saveData.currentPiece)
            game.nextPiece = restorePiece(saveData.nextPiece)
            game.score = saveData.score or 0
            game.gameOver = saveData.gameOver or false
            state = "game"
            print("Gra została załadowana z pliku: " .. filePath)
        else
            print("Nie udało się wczytać danych z pliku: " .. filePath)
        end
    else
        print("Plik zapisu nie istnieje: " .. filePath)
    end
end


function restorePiece(pieceData)
    local typeIndex = pieceData.typeIndex
    local piece = {}
    piece.typeIndex = typeIndex
    piece.type = tetrominoes[typeIndex]
    piece.rotation = pieceData.rotation
    piece.shape = tetrominoes[typeIndex].rotations[pieceData.rotation]
    piece.x = pieceData.x
    piece.y = pieceData.y
    return piece
end



function loadSavedGames()
    loadMenu.options = {}

    local saveDir = getSavePath()
    if not love.filesystem.getInfo(saveDir, "directory") then
        print("Katalog `saves` nie istnieje. Brak zapisanych gier.")
        return
    end

    -- Pobierz pliki z katalogu `saves`
    local files = love.filesystem.getDirectoryItems(saveDir)
    for _, file in ipairs(files) do
        if file:match("%.lua$") then
            table.insert(loadMenu.options, file)
        end
    end

    loadMenu.selected = 1

    if #loadMenu.options == 0 then
        print("Nie znaleziono żadnych zapisanych gier.")
    else
        print("Znaleziono " .. #loadMenu.options .. " zapisanych gier.")
    end
end


function loadSelectedGame()
    if loadMenu.options[loadMenu.selected] then
        local filename = loadMenu.options[loadMenu.selected]
        loadGame(filename)
    end
end


function deleteSelectedSave()
    local filename = "saves/" .. loadMenu.options[loadMenu.selected]
    if love.filesystem.getInfo(filename) then
        love.filesystem.remove(filename)
        print("Usunięto plik zapisu: " .. filename)
        loadSavedGames()
    else
        print("Plik zapisu nie został znaleziony: " .. filename)
    end
end

function serialize(tbl)
    local serialized = "{"
    for k, v in pairs(tbl) do
        if type(k) == "string" then
            k = '"' .. k .. '"'
        end
        serialized = serialized .. "[" .. k .. "]="
        if type(v) == "table" then
            serialized = serialized .. serialize(v)
        elseif type(v) == "number" then
            serialized = serialized .. v
        elseif type(v) == "string" then
            serialized = serialized .. '"' .. v .. '"'
        elseif type(v) == "boolean" then
            serialized = serialized .. tostring(v)
        else
            serialized = serialized .. 'nil'
        end
        serialized = serialized .. ","
    end
    serialized = serialized .. "}"
    return serialized
end

function deserialize(str)
    local func, err = load("return " .. str)
    if not func then
        print("Błąd deserializacji:", err)
        return nil
    end
    return func()
end

function printGrid()
    for y = 1, GRID_HEIGHT do
        local row = ""
        for x = 1, GRID_WIDTH do
            if game.grid[y][x][1] ~= 0 or game.grid[y][x][2] ~= 0 or game.grid[y][x][3] ~= 0 then
                row = row .. "X "
            else
                row = row .. ". "
            end
        end
        print(row)
    end
    print("--------------------")
end
