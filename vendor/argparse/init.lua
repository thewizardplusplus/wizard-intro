-- The MIT License (MIT)
-- Copyright (c) 2013 - 2018 Peter Melnichenko
-- Minimal vendored argparse-compatible subset for wizard-intro CLI options.

local Parser = {}
Parser.__index = Parser

local Option = {}
Option.__index = Option

function Option:description(value)
    self._description = value
    return self
end

function Option:args(value)
    self._args = value
    return self
end

function Option:target(value)
    self._target = value
    return self
end

function Option:default(value)
    self._default = value
    return self
end

function Option:convert(value)
    self._convert = value
    return self
end

function Option:choices(value)
    self._choices = value
    return self
end

function Option:_target_name()
    if self._target then
        return self._target
    end

    local name = self._aliases[#self._aliases]
    name = string.gsub(name, "^%-%-?", "")
    return string.gsub(name, "-", "_")
end

local function _create_option(...)
    return setmetatable({ _aliases = {...}, _args = 1 }, Option)
end

function Parser:option(...)
    local option = _create_option(...)
    table.insert(self._options, option)
    return option
end

function Parser:flag(...)
    local option = _create_option(...)
    option._args = 0
    option._default = false
    table.insert(self._options, option)
    return option
end

function Parser:get_usage()
    local parts = {"Usage:", self._name}
    for _, option in ipairs(self._options) do
        local usage = option._aliases[#option._aliases]
        if option._args ~= 0 then
            usage = usage .. " <value>"
        end
        table.insert(parts, "[" .. usage .. "]")
    end

    return table.concat(parts, " ")
end

function Parser:get_help()
    local lines = {self:get_usage()}
    if self._description then
        table.insert(lines, "")
        table.insert(lines, self._description)
    end

    table.insert(lines, "")
    table.insert(lines, "Options:")
    for _, option in ipairs(self._options) do
        local aliases = table.concat(option._aliases, ", ")
        if option._args ~= 0 then
            aliases = aliases .. " <value>"
        end
        table.insert(lines, string.format("  %-28s %s", aliases, option._description or ""))
    end

    return table.concat(lines, "\n")
end

local function _error(parser, message)
    return false, parser:get_usage() .. "\n\nError: " .. message
end

local function _is_option(value)
    return string.sub(value, 1, 1) == "-"
end

function Parser:pparse(args)
    args = args or {}

    local result = {}
    local by_alias = {}
    for _, option in ipairs(self._options) do
        result[option:_target_name()] = option._default
        for _, alias in ipairs(option._aliases) do
            by_alias[alias] = option
        end
    end

    local index = 1
    while index <= #args do
        local arg = args[index]
        if arg == "--help" or arg == "-h" then
            print(self:get_help())
            os.exit(0)
        end

        local name = arg
        local value
        local equals = string.find(arg, "=", 1, true)
        if equals ~= nil then
            name = string.sub(arg, 1, equals - 1)
            value = string.sub(arg, equals + 1)
        end

        local option = by_alias[name]
        if option == nil then
            return _error(self, "unknown option '" .. name .. "'")
        end

        local target = option:_target_name()
        if option._args == 0 then
            if value ~= nil then
                return _error(self, "option '" .. name .. "' does not take arguments")
            end
            result[target] = true
        else
            if value == nil then
                index = index + 1
                value = args[index]
            end
            if value == nil or _is_option(value) then
                return _error(self, "option '" .. name .. "' requires an argument")
            end
            if option._choices ~= nil then
                local is_valid = false
                for _, choice in ipairs(option._choices) do
                    if value == choice then
                        is_valid = true
                        break
                    end
                end
                if not is_valid then
                    return _error(self, "malformed argument '" .. value .. "'")
                end
            end
            if option._convert ~= nil then
                value = option._convert(value)
            end
            result[target] = value
        end

        index = index + 1
    end

    return true, result
end

local argparse = { version = "0.6.0" }
setmetatable(argparse, {
    __call = function(_, name, description)
        return setmetatable({
            _name = name,
            _description = description,
            _options = {},
        }, Parser)
    end,
})
return argparse
