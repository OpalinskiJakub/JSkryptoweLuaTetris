local utils = require("utils")

local game = require("game") 

local menu = {
    options = { "Start New Game", "Load Game", "Exit" },
    selected = 1
}

local loadMenu = {
    options = {},
    selected = 1
}

function menu.getLoadMenu()
    return loadMenu
end



function menu.handleMenuInput(key)
    if key == "up" then
        menu.selected = menu.selected - 1
        if menu.selected < 1 then
            menu.selected = #menu.options
        end
        utils.playSound("menuNavigate")
    elseif key == "down" then
        menu.selected = menu.selected + 1
        if menu.selected > #menu.options then
            menu.selected = 1
        end
        utils.playSound("menuNavigate")
    elseif key == "return" then
        utils.playSound("menuSelect")
        if menu.options[menu.selected] == "Start New Game" then
            game.initialize() -- Wywołanie funkcji inicjalizującej grę
            state = "game" -- Ustawienie stanu gry na "game"
        elseif menu.options[menu.selected] == "Load Game" then
            utils.loadSavedGames(loadMenu)
            state = "loadMenu"
        elseif menu.options[menu.selected] == "Exit" then
            love.event.quit()
        end
    end
end


local tetrominoes = require("pieces")

function menu.handleLoadMenuInput(key)
    if key == "up" then
        loadMenu.selected = loadMenu.selected - 1
        if loadMenu.selected < 1 then
            loadMenu.selected = #loadMenu.options
        end
        utils.playSound("menuNavigate")
    elseif key == "down" then
        loadMenu.selected = loadMenu.selected + 1
        if loadMenu.selected > #loadMenu.options then
            loadMenu.selected = 1
        end
        utils.playSound("menuNavigate")
    elseif key == "return" then
        if #loadMenu.options > 0 then
            utils.playSound("menuSelect")
            utils.loadSelectedGame(loadMenu, require("game"), tetrominoes) -- dodano `tetrominoes`
        end
    elseif key == "escape" then
        utils.playSound("menuSelect")
        state = "menu"
    elseif key == "r" then
        if #loadMenu.options > 0 then
            utils.playSound("menuSelect")
            utils.deleteSelectedSave(loadMenu)
        end
    end
end



function menu.drawMenu()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Tetris - Main Menu", 0, 100, WINDOW_WIDTH, "center")
    for i, option in ipairs(menu.options) do
        if i == menu.selected then
            love.graphics.setColor(1, 1, 0)
        else
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.printf(option, 0, 150 + i * 40, WINDOW_WIDTH, "center")
    end
end

function menu.drawLoadMenu()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Load Saved Game", 0, 50, WINDOW_WIDTH, "center")
    if #loadMenu.options == 0 then
        love.graphics.printf("No saved games found.", 0, 150, WINDOW_WIDTH, "center")
    else
        for i, filename in ipairs(loadMenu.options) do
            if i == loadMenu.selected then
                love.graphics.setColor(1, 1, 0)
            else
                love.graphics.setColor(1, 1, 1)
            end
            love.graphics.printf(filename, 0, 100 + i * 30, WINDOW_WIDTH, "center")
        end
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Press 'Escape' to return to Main Menu", 0, WINDOW_HEIGHT - 50, WINDOW_WIDTH, "center")
    if #loadMenu.options > 0 then
        love.graphics.printf("Press 'R' to delete selected save", 0, WINDOW_HEIGHT - 80, WINDOW_WIDTH, "center")
    end
end

return menu

