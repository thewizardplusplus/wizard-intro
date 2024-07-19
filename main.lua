local require_paths =
  {"?.lua", "?/init.lua", "vendor/?.lua", "vendor/?/init.lua"}
love.filesystem.setRequirePath(table.concat(require_paths, ";"))

local Size = require("lualife.models.size")
local Point = require("lualife.models.point")
local Field = require("lualife.models.field")
local random = require("lualife.random")
local life = require("lualife.life")
local center = require("center")
local flux = require("flux")
local tick = require("tick")

local UPDATE_PERIOD = 0.25
local START_DELAY = 1
local FINISH_DELAY = 1
local MIN_SIDE_CELL_COUNT = love.system.getOS() ~= "Android" and 30 or 25
local FIELD_FILLING = 0.25
local CELL_PADDING = 0.1
local CELL_BORDER = 0.125
local LOGO_PADDING = 0.1
local LOGO_FADDING_DURATION = 2

local width
local height
local field
local logo
local total_dt

function _initialize_field(width, height, prev_field)
    if prev_field then
        prev_field.ticker:stop()
    end

    local min_dimension = math.min(width, height)
    local max_dimension = math.max(width, height)
    local is_album_orientation = width > height

    local cell_size = math.floor(min_dimension / MIN_SIDE_CELL_COUNT)
    local max_side_cell_count = math.floor(max_dimension / cell_size)

    local min_side_offset = math.floor((min_dimension - MIN_SIDE_CELL_COUNT * cell_size) / 2)
    local max_side_offset = math.floor((max_dimension - max_side_cell_count * cell_size) / 2)

    local field_size
    local x_offset = 0
    local y_offset = 0
    if is_album_orientation then
        field_size = Size:new(max_side_cell_count, MIN_SIDE_CELL_COUNT)
        x_offset = max_side_offset
        y_offset = min_side_offset
    else
        field_size = Size:new(MIN_SIDE_CELL_COUNT, max_side_cell_count)
        x_offset = min_side_offset
        y_offset = max_side_offset
    end

    local inner_field = random.generate(Field:new(field_size), FIELD_FILLING)
    local field = {
        inner_field = inner_field,
        cell_size = cell_size,
        x_offset = x_offset,
        y_offset = y_offset,
    }

    field.ticker = tick.delay(
        function()
            field.can_be_updated = true
        end,
        START_DELAY
    )

    return field
end

function _initialize_logo(width, height, mode, prev_logo)
    local logo = prev_logo
    if not logo then
        logo = { opacity = 0 }
    else
        logo.opacity = 0
        logo.fadding:stop()
        if logo.ticker then
            logo.ticker:stop()
        end
    end

    if mode == "loading" then
        logo.image = love.graphics.newImage("resources/logo.png")
        center:setupScreen(logo.image:getPixelWidth(), logo.image:getPixelHeight())
    elseif mode == "resizing" then
        center:resize(width, height)
    else
        error("unknown mode of the logo initialization: " .. mode)
    end

    local min_dimension = math.min(width, height)
    local logo_padding = min_dimension * LOGO_PADDING
    center:setBorders(logo_padding, logo_padding, logo_padding, logo_padding)
    center:apply()

    logo.fadding = flux.to(logo, LOGO_FADDING_DURATION, { opacity = 1 })
        :ease("cubicout")
        :delay(START_DELAY)
        :after(logo, LOGO_FADDING_DURATION, { opacity = 0 })
        :oncomplete(function()
            logo.ticker = tick.delay(
                function()
                    love.event.quit()
                end,
                FINISH_DELAY
            )
        end)

    return logo
end

function love.load()
    width = love.graphics.getWidth()
    height = love.graphics.getHeight()
    field = _initialize_field(width, height)
    logo = _initialize_logo(width, height, "loading")
    total_dt = 0

    love.mouse.setVisible(false)
    love.graphics.setBackgroundColor({0.3, 0.3, 1})
end

function love.update(dt)
    total_dt = total_dt + dt
    -- cannot use the `tick.recur()` function for this due to a slowdown on Android
    if total_dt > UPDATE_PERIOD then
        if field.can_be_updated then
            field.inner_field = life.populate(field.inner_field)
        end

        total_dt = total_dt - UPDATE_PERIOD
    end

    flux.update(dt)
    tick.update(dt)
end

function love.draw()
    field.inner_field:map(function(point, contains)
        if not contains then
            return
        end

        local x = point.x * field.cell_size + field.cell_size / 2 + field.x_offset
        local y = point.y * field.cell_size + field.cell_size / 2 + field.y_offset
        local radius = (field.cell_size - field.cell_size * CELL_PADDING) / 2

        love.graphics.setColor({0.85, 0.85, 0.85})
        love.graphics.circle("fill", x, y, radius)

        love.graphics.setColor({1, 1, 1})
        love.graphics.circle("fill", x, y, radius - field.cell_size * CELL_BORDER)
    end)

    center:start()
    love.graphics.setColor({1, 1, 1, logo.opacity})
    love.graphics.draw(logo.image, 0, 0)
    center:finish()
end

function love.resize(new_width, new_height)
    width = new_width
    height = new_height
    field = _initialize_field(width, height, field)
    _initialize_logo(width, height, "resizing", logo)
    total_dt = 0
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
