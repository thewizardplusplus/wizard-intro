local require_paths =
  {"?.lua", "?/init.lua", "vendor/?.lua", "vendor/?/init.lua"}
love.filesystem.setRequirePath(table.concat(require_paths, ";"))

local assertions = require("luatypechecks.assertions")
local checks = require("luatypechecks.checks")
local Size = require("lualife.models.size")
local Point = require("lualife.models.point")
local Field = require("lualife.models.field")
local random = require("lualife.random")
local life = require("lualife.life")
local center = require("center")
local flux = require("flux")
local tick = require("tick")
local SYSLText = require("sysl-text")
local moonshine = require("moonshine")
require("gooi")

local UPDATE_PERIOD = 0.25
local START_DELAY = 1
local MIN_SIDE_CELL_COUNT = love.system.getOS() ~= "Android" and 30 or 25
local FIELD_FILLING = 0.25
local CELL_PADDING = 0.1
local CELL_BORDER = 0.125
-- at least 5 s plus allowance
local FIELD_POPULATING_DURATION = 5.5
local LOGO_PADDING = 0.1
local LOGO_FADDING_START_DELAY = 1
local LOGO_FADDING_FINISH_DELAY = 0.5
local LOGO_FADDING_DURATION_OFF = 1.75
local LOGO_FOREGROUND_AUDIO_VOLUME = 0.625
local LOGO_BACKGROUND_AUDIO_FADDING = 1
local BOX_WIDTH = 1
local BOX_BORDER = love.system.getOS() ~= "Android" and 0.00375 or 0.00625
local BOX_PADDING = love.system.getOS() ~= "Android" and 0.00375 or 0.00625
local BOX_MIN_MARGIN = love.system.getOS() ~= "Android" and 0.00625 or 0.01375
local BOX_MAX_MARGIN = 1.5 * (1 / MIN_SIDE_CELL_COUNT)
local BOX_SHADOW = love.system.getOS() ~= "Android" and 0.00625 or 0.01375
local BOX_MOVING_START_DELAY = 1
local BOX_MOVING_FINISH_DELAY = 1.5
local BOX_TARGET_X = 0.9
local MIN_FONT_SIZE = 10
local MAX_FONT_SIZE = 0.075
local FONT_SEARCH_STEP = 10
local TOTAL_TEXT_VERTICAL_MARGIN = 0.1
local MENU_WIDTH = 0.75
local MENU_HEIGHT = 0.75
local UI_FONT_SIZE = 0.05
local TEXT_INPUT_COUNT = 7

local use_pale_field_mode = false
local use_transparent_field_mode = false
local use_blur_field_mode = false
-- supported effects: boxblur, fastgaussianblur, gaussianblur, glow
local field_blur_effect = "glow"
local show_logo = false
local show_boxes = false
local text_for_boxes = ""

local field
local logo
local boxes
local box_audio
local text_audio
local total_dt
local is_menu
local ui_root_components
local ui_selected_app_mode

local function _is_instance_from_love_2d(value, type_name)
    assertions.is_string(type_name)

    return value ~= nil
        and checks.is_callable(value.typeOf)
        and value:typeOf(type_name)
end

local function _initialize_field(width, height)
    assertions.is_integer(width)
    assertions.is_integer(height)

    local min_dimension = math.min(width, height)
    local max_dimension = math.max(width, height)
    local is_album_orientation = width > height

    local cell_size = math.floor(min_dimension / MIN_SIDE_CELL_COUNT)
    local max_side_cell_count = math.floor(max_dimension / cell_size)

    local min_side_offset = math.floor(
        (min_dimension - MIN_SIDE_CELL_COUNT * cell_size) / 2
    )
    local max_side_offset = math.floor(
        (max_dimension - max_side_cell_count * cell_size) / 2
    )

    local field_size
    local x_offset
    local y_offset
    if is_album_orientation then
        field_size = Size:new(max_side_cell_count, MIN_SIDE_CELL_COUNT)
        x_offset = max_side_offset
        y_offset = min_side_offset
    else
        field_size = Size:new(MIN_SIDE_CELL_COUNT, max_side_cell_count)
        x_offset = min_side_offset
        y_offset = max_side_offset
    end

    local blur_effect = moonshine.chain(
        width,
        height,
        moonshine.effects[field_blur_effect]
    )
    if not use_blur_field_mode then
        blur_effect.disable(
            "boxblur",
            "fastgaussianblur",
            "gaussianblur",
            "glow"
        )
    end

    local inner_field = random.generate(Field:new(field_size), FIELD_FILLING)
    local field = { -- luacheck: no redefined
        inner_field = inner_field,
        cell_size = cell_size,
        x_offset = x_offset,
        y_offset = y_offset,
        blur_effect = blur_effect,
    }

    field.ticker = tick.delay(
        function()
            field.can_be_updated = true
        end,
        START_DELAY
    )
    field.finish_ticker = tick.delay(
        function()
            love.event.quit()
        end,
        START_DELAY + FIELD_POPULATING_DURATION
    )

    return field
end

local function _reset_field(field) -- luacheck: no redefined
    assertions.is_table_or_nil(field)

    if not field then
        return
    end

    field.ticker:stop()
    field.finish_ticker:stop()
end

local function _initialize_logo(width, height, prev_logo)
    assertions.is_integer(width)
    assertions.is_integer(height)
    assertions.is_table_or_nil(prev_logo)

    local logo = prev_logo -- luacheck: no redefined
    if not logo then
        logo = { opacity = 0 }

        logo.image = love.graphics.newImage("resources/logo.png")
        center:setupScreen(
            logo.image:getPixelWidth(),
            logo.image:getPixelHeight()
        )

        logo.foreground_audio = love.audio.newSource(
            "resources/BRAAAM/BRAAAM.wav",
            "static"
        )
        logo.foreground_audio:setVolume(LOGO_FOREGROUND_AUDIO_VOLUME)

        logo.background_audio = love.audio.newSource(
            "resources/4BarLoop/4BarLoop.wav",
            "static"
        )
        logo.background_audio:setLooping(true)

        logo.audios = {logo.foreground_audio, logo.background_audio}
    else
        center:resize(width, height)
    end

    local min_dimension = math.min(width, height)
    local logo_padding = min_dimension * LOGO_PADDING
    center:setBorders(logo_padding, logo_padding, logo_padding, logo_padding)
    center:apply()

    local fadding_duration_on = logo.foreground_audio:getDuration()
    logo.fadding_in = flux.to(logo, fadding_duration_on, { opacity = 1 })
        :ease("quadout")
        :delay(START_DELAY + LOGO_FADDING_START_DELAY)
        :onstart(function()
            love.audio.play(logo.audios)
        end)
        :oncomplete(function()
            logo.foreground_audio:stop()
        end)

    logo.fadding_out = logo.fadding_in
        :after(logo, LOGO_FADDING_DURATION_OFF, { opacity = 0 })
        :ease("quadin")
        :onupdate(function()
            local background_audio_volume = math.min(
                logo.opacity * LOGO_BACKGROUND_AUDIO_FADDING,
                1
            )
            logo.background_audio:setVolume(background_audio_volume)
        end)
        :oncomplete(function()
            logo.ticker = tick.delay(
                function()
                    love.event.quit()
                end,
                LOGO_FADDING_FINISH_DELAY
            )

            logo.background_audio:stop()
        end)

    return logo
end

local function _reset_audios(audios)
    assertions.is_sequence_or_nil(audios, function(value)
        return _is_instance_from_love_2d(value, "Source")
    end)

    for _, audio in ipairs(audios) do
        audio:stop()
        audio:seek(0)
    end
end

local function _reset_logo(logo) -- luacheck: no redefined
    assertions.is_table_or_nil(logo)

    if not logo then
        return
    end

    logo.opacity = 0

    logo.fadding_in:stop()
    logo.fadding_out:stop()
    if logo.ticker then
        logo.ticker:stop()
    end

    _reset_audios(logo.audios)
end

local function _get_text_size(text, font)
    assertions.is_string(text)
    assertions.is_true(_is_instance_from_love_2d(font, "Font"))

    local text_box = SYSLText.new("left", { font = font })
    text_box:send(text)

    return {
        width = text_box.get.width,
        height = text_box.get.height,
    }
end

local function _split_text_to_lines(width, height, text, font)
    assertions.is_integer(width)
    assertions.is_integer(height)
    assertions.is_string(text)
    assertions.is_true(_is_instance_from_love_2d(font, "Font"))

    local min_dimension = math.min(width, height)

    local box_border = min_dimension * BOX_BORDER
    local box_padding = min_dimension * BOX_PADDING

    local max_text_width = width
        - 2 * width * (1 - BOX_TARGET_X)
        - 2 * box_border
        - 2 * box_padding

    local words = {}
    for word in string.gmatch(text, "[^%s]+") do
        table.insert(words, word)
    end

    local lines = {}
    local current_text = ""
    local word_index = 1
    while word_index <= #words do
        local word = words[word_index]
        local extended_text = current_text
            .. (current_text ~= "" and " " or "")
            .. word

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

local function _find_largest_font_size(
    width,
    height,
    text,
    min_font_size,
    font_search_step
)
    assertions.is_integer(width)
    assertions.is_integer(height)
    assertions.is_string(text)
    assertions.is_integer(min_font_size)
    assertions.is_integer(font_search_step)

    local min_dimension = math.min(width, height)

    local box_border = min_dimension * BOX_BORDER
    local box_padding = min_dimension * BOX_PADDING
    local box_min_margin = min_dimension * BOX_MIN_MARGIN
    local box_shadow = min_dimension * BOX_SHADOW

    local total_text_vertical_margin = height * TOTAL_TEXT_VERTICAL_MARGIN
    local max_total_box_height = height - 2 * total_text_vertical_margin
    local max_font_size = math.floor(height * MAX_FONT_SIZE)

    local prev_font_size
    local font_size = min_font_size
    while font_size <= max_font_size do
        local font = love.graphics.newFont(
            "resources/Roboto/Roboto-Bold.ttf",
            font_size
        )
        local lines, err = _split_text_to_lines(width, height, text, font)
        if err ~= nil then
            if not prev_font_size then
                return nil,
                    "text is too large: "
                    .. "unable to split the text to lines: "
                    .. err
            end

            return prev_font_size
        end

        local total_box_height = 0
        for _, line in ipairs(lines) do
            local text_size = _get_text_size(line, font)
            local box_height = text_size.height
                + 2 * box_border
                + 2 * box_padding
            total_box_height = total_box_height + box_height + box_shadow
        end
        if total_box_height > max_total_box_height then
            if not prev_font_size then
                return nil,
                    "text is too large: "
                    .. "the total text height is greater than its maximum"
            end

            return prev_font_size
        end

        if #lines > 1 then
            local box_margin = (max_total_box_height - total_box_height)
                / (#lines - 1)
            if box_margin < box_min_margin then
                if not prev_font_size then
                    return nil,
                        "text is too large: "
                        .. "the box margin is less than its minimum"
                end

                return prev_font_size
            end
        end

        prev_font_size = font_size
        font_size = font_size + font_search_step
    end
    if not prev_font_size then
        return nil,
            "text is too large: "
            .. "the result font size is greater than its maximum"
    end

    return prev_font_size
end

local function _find_largest_font_size_ex(width, height, text)
    assertions.is_integer(width)
    assertions.is_integer(height)
    assertions.is_string(text)

    local font_size, err = _find_largest_font_size(
        width,
        height,
        text,
        MIN_FONT_SIZE,
        FONT_SEARCH_STEP
    )
    if err ~= nil then
        return nil, "unable to find the largest font size: " .. err
    end

    font_size, err = _find_largest_font_size(width, height, text, font_size, 1)
    if err ~= nil then
        return nil,
            "unable to find the largest font size (for the second time): "
            .. err
    end

    return font_size
end

local function _initialize_box(
    width,
    height,
    text,
    font,
    kind,
    box_y,
    moving_delay
)
    assertions.is_integer(width)
    assertions.is_integer(height)
    assertions.is_string(text)
    assertions.is_true(_is_instance_from_love_2d(font, "Font"))
    assertions.is_enumeration(kind, {"left", "right"})
    assertions.is_number(box_y)
    assertions.is_number(moving_delay)

    local min_dimension = math.min(width, height)

    local box_width = width * BOX_WIDTH
    local box_border = min_dimension * BOX_BORDER
    local box_padding = min_dimension * BOX_PADDING
    local box_shadow = min_dimension * BOX_SHADOW

    local min_text_x = width * (1 - BOX_TARGET_X) + box_border + box_padding
    local max_text_width = width
        - 2 * width * (1 - BOX_TARGET_X)
        - 2 * box_border
        - 2 * box_padding

    local box_x
    local box_target_x
    if kind == "left" then
        box_x = -box_width
        box_target_x = box_x + width * BOX_TARGET_X
    else
        box_x = width + box_shadow
        box_target_x = box_x - width * BOX_TARGET_X - box_shadow
    end

    local text_size = _get_text_size(text, font)
    local box_height = text_size.height + 2 * box_border + 2 * box_padding
    local text_x = min_text_x + (max_text_width - text_size.width) / 2

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

    local moving_duration = box_audio:getDuration()
    box.start_moving = function()
        box.moving = flux.to(box, moving_duration, { x = box_target_x })
            :delay(moving_delay)
            :ease("cubicout")
            :onstart(function()
                box_audio:play()
            end)
            :oncomplete(function()
                _reset_audios({box_audio})

                text_box:send(text)
                box.is_text_sent = true

                text_audio:play()
            end)
    end

    return box
end

local function _initialize_boxes(width, height, text)
    assertions.is_integer(width)
    assertions.is_integer(height)
    assertions.is_string(text)

    local min_dimension = math.min(width, height)

    local box_border = min_dimension * BOX_BORDER
    local box_padding = min_dimension * BOX_PADDING
    local box_max_margin = min_dimension * BOX_MAX_MARGIN
    local box_shadow = min_dimension * BOX_SHADOW

    local total_text_vertical_margin = height * TOTAL_TEXT_VERTICAL_MARGIN
    local max_total_box_height = height - 2 * total_text_vertical_margin

    local font_size, err = _find_largest_font_size_ex(width, height, text)
    if err ~= nil then
        return nil, "unable to find the largest font size: " .. err
    end

    local font = love.graphics.newFont(
        "resources/Roboto/Roboto-Bold.ttf",
        font_size
    )
    local lines, err = _split_text_to_lines( -- luacheck: no redefined
        width,
        height,
        text,
        font
    )
    if err ~= nil then
        return nil, "unable to split the text to lines: " .. err
    end

    local total_box_height = 0
    for _, line in ipairs(lines) do
        local text_size = _get_text_size(line, font)
        local box_height = text_size.height + 2 * box_border + 2 * box_padding
        total_box_height = total_box_height + box_height + box_shadow
    end

    local box_margin = 0
    if #lines > 1 then
        box_margin = (max_total_box_height - total_box_height) / (#lines - 1)
        if box_margin > box_max_margin then
            box_margin = box_max_margin
        end
    end

    local final_total_box_height = total_box_height + box_margin * (#lines - 1)
    local min_box_y = total_text_vertical_margin
        + (max_total_box_height - final_total_box_height) / 2

    local boxes = {} -- luacheck: no redefined
    local box_kind = "left"
    local box_y = min_box_y
    local box_above
    for index, line in ipairs(lines) do
        local moving_delay = index == 1
            and START_DELAY + BOX_MOVING_START_DELAY
            or 0
        local box = _initialize_box(
            width,
            height,
            line,
            font,
            box_kind,
            box_y,
            moving_delay
        )
        if index == 1 then
            box.start_moving()
        else
            box_above.on_text_end = function()
                box.start_moving()
            end
        end

        if index == #lines then
            box.on_text_end = function()
                box.ticker = tick.delay(
                    function()
                        love.event.quit()
                    end,
                    BOX_MOVING_FINISH_DELAY
                )
            end
        end

        table.insert(boxes, box)

        box_kind = box_kind == "left" and "right" or "left"
        box_y = box_y + box.height + box_shadow + box_margin
        box_above = box
    end

    return boxes
end

local function _reset_boxes(boxes) -- luacheck: no redefined
    assertions.is_sequence_or_nil(boxes, checks.is_table)

    if not boxes then
        return
    end

    _reset_audios({box_audio, text_audio})

    for _, box in ipairs(boxes) do
        if box.moving then
            box.moving:stop()
        end
        if box.ticker then
            box.ticker:stop()
        end
    end
end

local function _initialize_scene()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    field = _initialize_field(width, height)

    if show_logo then
        field.finish_ticker:stop()

        logo = _initialize_logo(width, height, logo)
    end

    if show_boxes then
        field.finish_ticker:stop()

        local local_boxes, err = _initialize_boxes(
            width,
            height,
            text_for_boxes
        )
        if err ~= nil then
            error("unable to initialize the boxes: " .. err)
        end

        boxes = local_boxes
    end

    total_dt = 0

    love.mouse.setVisible(false)
    love.graphics.setBackgroundColor({0.3, 0.3, 1})
end

local function _reset_scene()
    _reset_field(field)
    _reset_logo(logo)
    _reset_boxes(boxes)
end

local function _press_gooi_component(component)
    local x = component.x + component.w / 2
    local y = component.y + component.h / 2
    gooi.pressed(component.id, x, y)
    gooi.released(component.id, x, y)
end

local function _get_visible_gooi_components_by_type(component_type)
    local visible_components = {}
    for _ , component in ipairs(gooi.getByType(component_type)) do
        if component.visible then
            table.insert(visible_components, component)
        end
    end

    return visible_components
end

local function _get_start_button()
    local visible_buttons = _get_visible_gooi_components_by_type("button")
    return #visible_buttons == 1 and visible_buttons[1] or nil
end

local function _get_text_from_text_inputs()
    local visible_text_inputs = _get_visible_gooi_components_by_type("text")
    table.sort(visible_text_inputs, function(component_one, component_two)
        return component_one.id < component_two.id
    end)

    local text = ""
    for _, text_input in ipairs(visible_text_inputs) do
        local text_part = text_input:getText()
        if text_part ~= "" then
            text = text .. (text ~= "" and " " or "") .. text_part
        end
    end

    return text
end

local function _initialize_ui(width, height, prev_ui_root_components)
    assertions.is_integer(width)
    assertions.is_integer(height)
    assertions.is_sequence_or_nil(prev_ui_root_components, checks.is_table)

    if prev_ui_root_components then
        for _, ui_root_component in ipairs(prev_ui_root_components) do
            gooi.removeComponent(ui_root_component)
        end
    end

    local min_dimension = math.min(width, height)

    local menu_width = width * MENU_WIDTH
    local menu_height = height * MENU_HEIGHT
    local ui_font_size = min_dimension * UI_FONT_SIZE

    -- Backspace doesn't work on Android without it
    gooi.desktopMode()

    local ui_font = love.graphics.newFont(
        "resources/Roboto/Roboto-Regular.ttf",
        ui_font_size
    )
    gooi.setStyle({
        font = ui_font,
    })

    local ui_root_components = {} -- luacheck: no redefined

    local main_menu_grid = gooi.newPanel({
        x = (width - menu_width) / 2,
        y = (height - menu_height) / 2,
        w = menu_width,
        h = menu_height,
        layout = "grid 3x1",
        group = "main-menu",
    })
    main_menu_grid:add(
        gooi
            .newButton({ text = "Background" })
            :onRelease(function()
                ui_selected_app_mode = "background"

                gooi.setGroupVisible("main-menu", false)
                gooi.setGroupVisible("field-settings", true)
            end),
        gooi
            .newButton({ text = "Logo" })
            :onRelease(function()
                ui_selected_app_mode = "logo"

                gooi.setGroupVisible("main-menu", false)
                gooi.setGroupVisible("field-settings", true)
            end),
        gooi
            .newButton({ text = "Text rectangles" })
            :onRelease(function()
                ui_selected_app_mode = "text-rectangles"

                gooi.setGroupVisible("main-menu", false)
                gooi.setGroupVisible("field-settings", true)
            end)
    )
    table.insert(ui_root_components, main_menu_grid)

    local boxblur_effect_check = gooi.newRadio({
        text = "> Box",
        radioGroup = "field-effect",
    })
    boxblur_effect_check:setEnabled(false)

    local fastgaussianblur_effect_check = gooi.newRadio({
        text = "> Fast Gaussian",
        radioGroup = "field-effect",
    })
    fastgaussianblur_effect_check:setEnabled(false)

    local gaussianblur_effect_check = gooi.newRadio({
        text = "> Gaussian",
        radioGroup = "field-effect",
    })
    gaussianblur_effect_check:setEnabled(false)

    local glow_effect_check = gooi.newRadio({
        text = "> Glow",
        radioGroup = "field-effect",
    })
    glow_effect_check:setEnabled(false)

    if field_blur_effect == "boxblur" then
        boxblur_effect_check:select()
    elseif field_blur_effect == "fastgaussianblur" then
        fastgaussianblur_effect_check:select()
    elseif field_blur_effect == "gaussianblur" then
        gaussianblur_effect_check:select()
    else
        glow_effect_check:select()
    end

    local pale_mode_check = gooi.newCheck({ text = "Pale" })
    local transparent_mode_check = gooi.newCheck({ text = "Transparent" })
    local blur_mode_check = gooi.newCheck({ text = "Blur" })
    blur_mode_check:onRelease(function()
        local is_checked = blur_mode_check.checked
        boxblur_effect_check:setEnabled(is_checked)
        fastgaussianblur_effect_check:setEnabled(is_checked)
        gaussianblur_effect_check:setEnabled(is_checked)
        glow_effect_check:setEnabled(is_checked)
    end)

    local text_for_boxes_inputs = {}
    for _ = 1, TEXT_INPUT_COUNT do
        local text_for_boxes_input = gooi.newText({ text = "" })
        table.insert(text_for_boxes_inputs, text_for_boxes_input)
    end

    local field_settings_grid = gooi.newPanel({
        x = (width - menu_width) / 2,
        y = (height - menu_height) / 2,
        w = menu_width,
        h = menu_height,
        layout = "grid 9x1",
        group = "field-settings",
    })
    field_settings_grid:setRowspan(8, 1, 2)
    field_settings_grid:add(
        pale_mode_check,
        transparent_mode_check,
        blur_mode_check,
        boxblur_effect_check,
        fastgaussianblur_effect_check,
        gaussianblur_effect_check,
        glow_effect_check,
        gooi
            .newButton({ text = "Start" })
            :onRelease(function()
                use_pale_field_mode = pale_mode_check.checked
                use_transparent_field_mode = transparent_mode_check.checked
                use_blur_field_mode = blur_mode_check.checked

                if boxblur_effect_check.selected then
                    field_blur_effect = "boxblur"
                elseif fastgaussianblur_effect_check.selected then
                    field_blur_effect = "fastgaussianblur"
                elseif gaussianblur_effect_check.selected then
                    field_blur_effect = "gaussianblur"
                else
                    field_blur_effect = "glow"
                end

                gooi.setGroupVisible("field-settings", false)

                if ui_selected_app_mode == "text-rectangles" then
                    gooi.setGroupVisible("boxes-settings", true)
                    _press_gooi_component(text_for_boxes_inputs[1])
                    return
                end

                show_logo = ui_selected_app_mode == "logo"
                is_menu = false

                _initialize_scene()
            end)
    )
    gooi.setGroupVisible("field-settings", false)
    table.insert(ui_root_components, field_settings_grid)

    local boxes_settings_grid = gooi.newPanel({
        x = (width - menu_width) / 2,
        y = (height - menu_height) / 2,
        w = menu_width,
        h = menu_height,
        layout = string.format("grid %dx1", TEXT_INPUT_COUNT + 2),
        group = "boxes-settings",
    })
    boxes_settings_grid:setRowspan(TEXT_INPUT_COUNT + 1, 1, 2)
    for _, text_for_boxes_input in ipairs(text_for_boxes_inputs) do
        boxes_settings_grid:add(text_for_boxes_input)
    end
    boxes_settings_grid:add(
        gooi
            .newButton({ text = "Start" })
            :onRelease(function()
                show_boxes = true
                text_for_boxes = _get_text_from_text_inputs()
                is_menu = false

                gooi.setGroupVisible("boxes-settings", false)
                _initialize_scene()
            end)
    )
    gooi.setGroupVisible("boxes-settings", false)
    table.insert(ui_root_components, boxes_settings_grid)

    love.mouse.setVisible(true)
    love.graphics.setBackgroundColor({0.1, 0.1, 0.1})

    return ui_root_components
end

function love.load()
    math.randomseed(os.time())

    box_audio = love.audio.newSource("resources/SlideOut.mp3", "static")
    text_audio = love.audio.newSource("resources/Typing.mp3", "static")

    ui_root_components = _initialize_ui(
        love.graphics.getWidth(),
        love.graphics.getHeight()
    )
    is_menu = true
end

function love.update(dt)
    assertions.is_number(dt)

    if is_menu then
        gooi.update(dt)
        return
    end

    total_dt = total_dt + dt
    -- cannot use the `tick.recur()` function for this
    -- due to a slowdown on Android
    if total_dt > UPDATE_PERIOD then
        if field.can_be_updated then
            field.inner_field = life.populate(field.inner_field)
        end

        total_dt = total_dt - UPDATE_PERIOD
    end

    if show_boxes then
        for _, box in ipairs(boxes) do
            box.text_box:update(dt)

            if box.is_text_sent
                and box.text_box:is_finished()
                and box.on_text_end then
                _reset_audios({text_audio})

                box.on_text_end()
                box.on_text_end = nil
            end
        end
    end

    flux.update(dt)
    tick.update(dt)
end

function love.draw()
    if is_menu then
        gooi.draw()
        return
    end

    -- reset the foreground color for the blur effect;
    -- it's relevant for the following effects:
    -- boxblur, fastgaussianblur, and gaussianblur
    love.graphics.setColor({1, 1, 1})
    field.blur_effect.draw(function()
        field.inner_field:map(function(point, contains)
            assertions.is_instance(point, Point)
            assertions.is_boolean(contains)

            if not contains then
                return
            end

            local x = point.x * field.cell_size
                + field.cell_size / 2
                + field.x_offset
            local y = point.y * field.cell_size
                + field.cell_size / 2
                + field.y_offset
            local radius = (field.cell_size - field.cell_size * CELL_PADDING)
                / 2
            local opacity = use_transparent_field_mode and 0.5 or 1

            love.graphics.setColor({0.85, 0.85, 0.85, opacity})
            love.graphics.circle("fill", x, y, radius)

            love.graphics.setColor({1, 1, 1, opacity})
            love.graphics.circle(
                "fill",
                x,
                y,
                radius - field.cell_size * CELL_BORDER
            )
        end)
    end)
    if use_pale_field_mode then
        love.graphics.setColor({1, 1, 1, 0.5})
        love.graphics.rectangle(
            "fill",
            0,
            0,
            love.graphics.getWidth(),
            love.graphics.getHeight()
        )
    end

    if show_logo then
        center:start()
        love.graphics.setColor({1, 1, 1, logo.opacity})
        love.graphics.draw(logo.image, 0, 0)
        center:finish()
    end

    if show_boxes then
        for _, box in ipairs(boxes) do
            love.graphics.setColor({0.2, 0.2, 0.2})
            love.graphics.rectangle(
                "fill",
                box.x - box.shadow,
                box.y + box.shadow,
                box.width,
                box.height
            )
            love.graphics.setColor({0.2, 0.83, 0.2})
            love.graphics.rectangle("fill", box.x, box.y, box.width, box.height)
            love.graphics.setColor({0.3, 1, 0.3})
            love.graphics.rectangle(
                "fill",
                box.x + box.border,
                box.y + box.border,
                box.width - 2 * box.border,
                box.height - 2 * box.border
            )

            box.text_box:draw(box.text_x, box.y + box.border + box.padding)
        end
    end
end

function love.resize(width, height)
    assertions.is_integer(width)
    assertions.is_integer(height)

    _reset_scene()

    ui_root_components = _initialize_ui(width, height, ui_root_components)
    is_menu = true
end

function love.keypressed(key, scancode)
    assertions.is_string(key)
    assertions.is_string(scancode)

    if key == "escape" then
        love.event.quit()
    elseif key == "return" then
        local start_button = _get_start_button()
        if start_button then
            _press_gooi_component(start_button)
        end
    elseif key == "tab" then
        local visible_text_inputs = _get_visible_gooi_components_by_type("text")
        table.sort(visible_text_inputs, function(component_one, component_two)
            return component_one.id < component_two.id
        end)

        local focused_index = -1
        for index, text_input in ipairs(visible_text_inputs) do
            if text_input.hasFocus then
                focused_index = index
                break
            end
        end

        if focused_index ~= -1 then
            local next_index = focused_index
            if love.keyboard.isDown("lshift")
                or love.keyboard.isDown("rshift") then
                next_index = math.max(next_index - 1, 1)
            else
                next_index = math.min(next_index + 1, #visible_text_inputs)
            end

            _press_gooi_component(visible_text_inputs[next_index])
        end
    end

    gooi.keypressed(key, scancode)
end

function love.keyreleased(key, scancode)
    assertions.is_string(key)
    assertions.is_string(scancode)

    gooi.keyreleased(key, scancode)
end

function love.textinput(text)
    assertions.is_string(text)

    gooi.textinput(text)
end

function love.mousepressed()
    gooi.pressed()
end

function love.mousereleased()
    gooi.released()
end
