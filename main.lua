local require_paths =
  {"?.lua", "?/init.lua", "vendor/?.lua", "vendor/?/init.lua"}
love.filesystem.setRequirePath(table.concat(require_paths, ";"))

local Size = require("lualife.models.size")
local Point = require("lualife.models.point")
local Field = require("lualife.models.field")
local random = require("lualife.random")
local life = require("lualife.life")

local UPDATE_PERIOD = 0.25
local MIN_SIDE_CELL_COUNT = love.system.getOS() ~= "Android" and 30 or 25
local FIELD_FILLING = 0.25

local width
local height
local field
local total_dt

function _initialize_field(width, height)
    local min_dimension = math.min(width, height)
    local max_dimension = math.max(width, height)
    local is_album_orientation = width > height

    local cell_size = math.floor(min_dimension / MIN_SIDE_CELL_COUNT)
    local max_side_cell_count = math.floor(max_dimension / cell_size)

    local field_size
    if is_album_orientation then
        field_size = Size:new(max_side_cell_count, MIN_SIDE_CELL_COUNT)
    else
        field_size = Size:new(MIN_SIDE_CELL_COUNT, max_side_cell_count)
    end

    return random.generate(Field:new(field_size), FIELD_FILLING)
end

function love.load()
    width = love.graphics.getWidth()
    height = love.graphics.getHeight()
    field = _initialize_field(width, height)
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
    field = _initialize_field(width, height)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
