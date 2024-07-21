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
local SYSLText = require("sysl-text")

local UPDATE_PERIOD = 0.25
local START_DELAY = 1
local FINISH_DELAY = 0.5
local MIN_SIDE_CELL_COUNT = love.system.getOS() ~= "Android" and 30 or 25
local FIELD_FILLING = 0.25
local CELL_PADDING = 0.1
local CELL_BORDER = 0.125
local LOGO_PADDING = 0.1
local LOGO_FADDING_DURATION_ON = 3
local LOGO_FADDING_DURATION_OFF = 2
local LOGO_FADDING_START_DELAY = 1
local BOX_WIDTH = 1
local BOX_BORDER = love.system.getOS() ~= "Android" and 0.00375 or 0.00625
local BOX_PADDING = love.system.getOS() ~= "Android" and 0.00375 or 0.00625
local BOX_MIN_MARGIN = love.system.getOS() ~= "Android" and 0.00625 or 0.01375
local BOX_SHADOW = love.system.getOS() ~= "Android" and 0.00625 or 0.01375
local BOX_MOVING_DURATION = 0.5
local BOX_MOVING_START_DELAY = 1
local BOX_TARGET_X = 0.9
local MIN_FONT_SIZE = 10
local MAX_FONT_SIZE = 0.075
local FONT_SEARCH_STEP = 10

local show_logo = false

local width
local height
local field
local logo
local boxes
local total_dt
-- DEBUGGING START
local debugging_text = [[zero
one
two
three
four
five
six
seven
eight
nine
ten
eleven
twelve
thirteen
fourteen
fifteen
sixteen
seventeen
eighteen
nineteen
twenty]]
-- DEBUGGING END

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

    logo.fadding = flux.to(logo, LOGO_FADDING_DURATION_ON, { opacity = 1 })
        :ease("quadout")
        :delay(START_DELAY + LOGO_FADDING_START_DELAY)
        :after(logo, LOGO_FADDING_DURATION_OFF, { opacity = 0 })
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

function _get_text_size(text, font)
    local text_box = SYSLText.new("left", { font = font })
    text_box:send(text)

    return {
        width = text_box.get.width,
        height = text_box.get.height,
    }
end

function _split_text_to_lines(width, text, font)
    local max_text_width = width - 2 * width * (1 - BOX_TARGET_X)

    local words = {}
    for word in string.gmatch(text, "[^%s]+") do
        table.insert(words, word)
    end

    local lines = {}
    local current_text = ""
    local word_index = 1
    while word_index <= #words do
        local word = words[word_index]

        if current_text ~= "" then
            current_text = current_text .. " "
        end
        local extended_text = current_text .. word

        local text_size = _get_text_size(extended_text, font)
        if text_size.width <= max_text_width then
            current_text = extended_text
            word_index = word_index + 1
        elseif current_text ~= "" then
            table.insert(lines, current_text)
            current_text = ""
        else
            return nil, "font is too large; word: " .. word
        end
    end
    if current_text ~= "" then
        table.insert(lines, current_text)
    end

    return lines
end

function _find_largest_font_size(width, height, text, min_font_size, font_search_step)
    local min_dimension = math.min(width, height)

    local box_border = min_dimension * BOX_BORDER
    local box_padding = min_dimension * BOX_PADDING
    local box_min_margin = min_dimension * BOX_MIN_MARGIN
    local box_shadow = min_dimension * BOX_SHADOW

    local max_total_box_height = height - 2 * box_min_margin
    local max_font_size = math.floor(height * MAX_FONT_SIZE)

    local prev_font_size
    local font_size = min_font_size
    while font_size < max_font_size do
        local font = love.graphics.newFont("resources/Roboto/Roboto-Bold.ttf", font_size)
        local lines, err = _split_text_to_lines(width, text, font)
        if err ~= nil then
            if not prev_font_size then
                return nil, "text is too large: unable to split the text to lines: " .. err
            end

            return prev_font_size
        end

        local total_box_height = 0
        for _, line in ipairs(lines) do
            local text_size = _get_text_size(line, font)
            local box_height = text_size.height + 2 * box_border + 2 * box_padding
            total_box_height = total_box_height + box_height + box_shadow
        end
        if total_box_height > max_total_box_height then
            if not prev_font_size then
                return nil, "text is too large: the total text height is greater than its maximum"
            end

            return prev_font_size
        end

        local box_margin = (max_total_box_height - total_box_height) / (#lines - 1)
        if box_margin < box_min_margin then
            if not prev_font_size then
                return nil, "text is too large: the box margin is less than its minimum"
            end

            return prev_font_size
        end

        prev_font_size = font_size
        font_size = font_size + font_search_step
    end
    if not prev_font_size then
        return nil, "text is too large: the result font size is greater than its maximum"
    end

    return prev_font_size
end

function _find_largest_font_size_ex(width, height, text)
    local font_size, err = _find_largest_font_size(width, height, text, MIN_FONT_SIZE, FONT_SEARCH_STEP)
    if err ~= nil then
        return nil, "unable to find the largest font size: " .. err
    end

    font_size, err = _find_largest_font_size(width, height, text, font_size, 1)
    if err ~= nil then
        return nil, "unable to find the largest font size (for the second time): " .. err
    end

    return font_size
end

function _initialize_box(width, height, text, font, kind, box_y, box_above)
    local min_dimension = math.min(width, height)

    local box_width = width * BOX_WIDTH
    local box_border = min_dimension * BOX_BORDER
    local box_padding = min_dimension * BOX_PADDING
    local box_shadow = min_dimension * BOX_SHADOW
    local text_x = width * (1 - BOX_TARGET_X)

    local box_x
    local box_target_x
    if kind == "left" then
        box_x = -box_width
        box_target_x = box_x + width * BOX_TARGET_X
    elseif kind == "right" then
        box_x = width + box_shadow
        box_target_x = box_x - width * BOX_TARGET_X - box_shadow
    else
        error("unknown kind of the box: " .. kind)
    end

    local text_size = _get_text_size(text, font)
    local box_height = text_size.height + 2 * box_border + 2 * box_padding

    local text_box = SYSLText.new("left", {
        font = font,
        color = {0.2, 0.2, 0.2},
    })

    local box = {
        x = box_x,
        y = box_y,
        width = box_width,
        height = box_height,
        border = box_border,
        padding = box_padding,
        shadow = box_shadow,
        text_box = text_box,
        text_x = text_x,
    }

    if not box_above then
        box.moving = flux.to(box, BOX_MOVING_DURATION, { x = box_target_x })
            :delay(START_DELAY + BOX_MOVING_START_DELAY)
    else
        box.moving = box_above.moving:after(box, BOX_MOVING_DURATION, { x = box_target_x })
    end
    box.moving
        :ease("cubicout")
        :oncomplete(function()
            text_box:send(text)
        end)

    return box
end

function _initialize_boxes(width, height, text, prev_boxes)
    if prev_boxes then
        for _, prev_box in ipairs(prev_boxes) do
            prev_box.moving:stop()
        end
    end

    local min_dimension = math.min(width, height)

    local box_border = min_dimension * BOX_BORDER
    local box_padding = min_dimension * BOX_PADDING
    local box_min_margin = min_dimension * BOX_MIN_MARGIN
    local box_shadow = min_dimension * BOX_SHADOW

    local max_total_box_height = height - 2 * box_min_margin

    local font_size, err = _find_largest_font_size_ex(width, height, text)
    if err ~= nil then
        return nil, "unable to find the largest font size: " .. err
    end

    local font = love.graphics.newFont("resources/Roboto/Roboto-Bold.ttf", font_size)
    local lines, err = _split_text_to_lines(width, text, font)
    if err ~= nil then
        return nil, "unable to split the text to lines: " .. err
    end

    local total_box_height = 0
    for _, line in ipairs(lines) do
        local text_size = _get_text_size(line, font)
        local box_height = text_size.height + 2 * box_border + 2 * box_padding
        total_box_height = total_box_height + box_height + box_shadow
    end

    local box_margin = (max_total_box_height - total_box_height) / (#lines - 1)

    local boxes = {}
    local box_kind = "left"
    local box_y = box_min_margin
    local box_above
    for _, line in ipairs(lines) do
        local box = _initialize_box(width, height, line, font, box_kind, box_y, box_above)
        table.insert(boxes, box)

        box_kind = box_kind == "left" and "right" or "left"
        box_y = box_y + box.height + box_shadow + box_margin
        box_above = box
    end

    return boxes
end

function love.load()
    width = love.graphics.getWidth()
    height = love.graphics.getHeight()
    field = _initialize_field(width, height)
    if show_logo then
        logo = _initialize_logo(width, height, "loading")
    end
    total_dt = 0

    local local_boxes, err = _initialize_boxes(width, height, debugging_text)
    if err ~= nil then
        error("unable to initialize the boxes: " .. err)
    end
    boxes = local_boxes

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

    for _, box in ipairs(boxes) do
        box.text_box:update(dt)
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

    if show_logo then
        center:start()
        love.graphics.setColor({1, 1, 1, logo.opacity})
        love.graphics.draw(logo.image, 0, 0)
        center:finish()
    end

    for _, box in ipairs(boxes) do
        love.graphics.setColor({0.2, 0.2, 0.2})
        love.graphics.rectangle("fill", box.x - box.shadow, box.y + box.shadow, box.width, box.height)
        love.graphics.setColor({0.2, 0.83, 0.2})
        love.graphics.rectangle("fill", box.x, box.y, box.width, box.height)
        love.graphics.setColor({0.3, 1, 0.3})
        love.graphics.rectangle("fill", box.x + box.border, box.y + box.border, box.width - 2 * box.border, box.height - 2 * box.border)

        box.text_box:draw(box.text_x + box.border + box.padding, box.y + box.border + box.padding)
    end
end

function love.resize(new_width, new_height)
    width = new_width
    height = new_height
    field = _initialize_field(width, height, field)
    if show_logo then
        _initialize_logo(width, height, "resizing", logo)
    end
    total_dt = 0

    local local_boxes, err = _initialize_boxes(width, height, debugging_text)
    if err ~= nil then
        error("unable to initialize the boxes: " .. err)
    end
    boxes = local_boxes
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
