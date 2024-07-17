local require_paths =
  {"?.lua", "?/init.lua", "vendor/?.lua", "vendor/?/init.lua"}
love.filesystem.setRequirePath(table.concat(require_paths, ";"))

local Size = require("lualife.models.size")
local Point = require("lualife.models.point")
local Field = require("lualife.models.field")
local random = require("lualife.random")
local life = require("lualife.life")
local center = require("center")

local UPDATE_PERIOD = 0.25
local START_DELAY = 1
local MIN_SIDE_CELL_COUNT = love.system.getOS() ~= "Android" and 30 or 25
local FIELD_FILLING = 0.25
local CELL_PADDING = 0.1
local CELL_BORDER = 0.125
local LOGO_PADDING = 0.1

local width
local height
local field
local cell_size
local logo
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

    local field = random.generate(Field:new(field_size), FIELD_FILLING)
    return field, cell_size
end

function _initialize_logo(width, height, mode)
    local logo
    if mode == "loading" then
        logo = love.graphics.newImage("resources/logo.png")
        center:setupScreen(logo:getPixelWidth(), logo:getPixelHeight())
    elseif mode == "resizing" then
        center:resize(width, height)
    else
        error("unknown mode of the logo initialization: " .. mode)
    end

    local min_dimension = math.min(width, height)
    local logo_padding = min_dimension * LOGO_PADDING
    center:setBorders(logo_padding, logo_padding, logo_padding, logo_padding)
    center:apply()

    return logo
end

function love.load()
    width = love.graphics.getWidth()
    height = love.graphics.getHeight()
    field, cell_size = _initialize_field(width, height)
    logo = _initialize_logo(width, height, "loading")
    total_dt = 0

    love.mouse.setVisible(false)
    love.graphics.setBackgroundColor({0.3, 0.3, 1})
end

function love.update(dt)
    total_dt = total_dt + dt
    if total_dt < START_DELAY then
        return
    end
    if total_dt > UPDATE_PERIOD then
        field = life.populate(field)
        total_dt = total_dt - UPDATE_PERIOD
    end
end

function love.draw()
    field:map(function(point, contains)
        if not contains then
            return
        end

        local x = point.x * cell_size + cell_size / 2
        local y = point.y * cell_size + cell_size / 2
        local radius = (cell_size - cell_size * CELL_PADDING) / 2

        love.graphics.setColor({0.85, 0.85, 0.85})
        love.graphics.circle("fill", x, y, radius)

        love.graphics.setColor({1, 1, 1})
        love.graphics.circle("fill", x, y, radius - cell_size * CELL_BORDER)
    end)

    center:start()
    love.graphics.draw(logo, 0, 0)
    center:finish()
end

function love.resize(new_width, new_height)
    width = new_width
    height = new_height
    field, cell_size = _initialize_field(width, height)
    _initialize_logo(width, height, "resizing")
    total_dt = 0 -- force the start delay
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
