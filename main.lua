local require_paths =
  {"?.lua", "?/init.lua", "vendor/?.lua", "vendor/?/init.lua"}
love.filesystem.setRequirePath(table.concat(require_paths, ";"))

local Size = require("lualife.models.size")
local Point = require("lualife.models.point")
local Field = require("lualife.models.field")
local random = require("lualife.random")
local life = require("lualife.life")

local UPDATE_PERIOD = 0.25

local width
local height
local field
local total_dt

function love.load()
    width = love.graphics.getWidth()
    height = love.graphics.getHeight()
    field = random.generate(Field:new(Size:new(25, 20)), 0.5)
    total_dt = 0
end

function love.update(dt)
    total_dt = total_dt + dt
    if total_dt > UPDATE_PERIOD then
        field = life.populate(field)
        total_dt = total_dt - UPDATE_PERIOD
    end
end

function love.draw()
    local field_as_string = ""
    field:map(function(point, contains)
        field_as_string = field_as_string .. "\t" .. (contains and "O" or "..")
        if point.x == field.size.width - 1 then
            field_as_string = field_as_string .. "\n"
        end
    end)

    love.graphics.print(field_as_string, 10, 10)
end

function love.resize(new_width, new_height)
    width = new_width
    height = new_height
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
