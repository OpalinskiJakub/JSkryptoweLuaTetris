local menu = require("menu")
local game = require("game")
local utils = require("utils")

love.graphics.setDefaultFilter("nearest", "nearest")

WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600

state = "menu"

function love.load()
    love.filesystem.setIdentity("tetris_game")
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    love.window.setTitle("Tetris in Lua - Love2D")
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    love.graphics.setFont(love.graphics.newFont(20))
    utils.loadSounds()
    game.initialize()
end

function love.keypressed(key)
    if state == "menu" then
        menu.handleMenuInput(key)
    elseif state == "loadMenu" then
        local loadMenu = menu.getLoadMenu()
        menu.handleLoadMenuInput(key)
    elseif state == "game" then
        game.handleGameInput(key)
    end
end

function love.update(dt)
    if state == "game" then
        game.update(dt)
    end
end

function love.draw()
    if state == "menu" then
        menu.drawMenu()
    elseif state == "loadMenu" then
        menu.drawLoadMenu()
    elseif state == "game" then
        game.draw()
    end
end

