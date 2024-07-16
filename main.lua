local width
local height

function love.load()
    width = love.graphics.getWidth()
    height = love.graphics.getHeight()
end

function love.draw()
    if width and height then
        love.graphics.line(0, 0, width, height)
        love.graphics.line(0, height, width, 0)
    end
end

function love.resize(new_width, new_height)
    width = new_width
    height = new_height
end
