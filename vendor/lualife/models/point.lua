---
-- @classmod Point

local middleclass = require("middleclass")
local types = require("lualife.types")
local Stringifiable = require("lualife.models.stringifiable")

local Point = middleclass("Point")
Point:include(Stringifiable)

---
-- @table instance
-- @tfield number x
-- @tfield number y

---
-- @function new
-- @tparam number x
-- @tparam number y
-- @treturn Point
function Point:initialize(x, y)
  assert(types.is_number_with_limits(x))
  assert(types.is_number_with_limits(y))

  self.x = x
  self.y = y
end

---
-- @treturn tab table with instance fields
function Point:__data()
  return {
    x = self.x,
    y = self.y,
  }
end

---
-- @function __tostring
-- @treturn string stringified table with instance fields
-- @see Stringifiable

---
-- @tparam Point point
-- @treturn Point
function Point:translate(point)
  assert(types.is_instance(point, Point))

  return Point:new(self.x + point.x, self.y + point.y)
end

---
-- @tparam number factor
-- @treturn Point
function Point:scale(factor)
  assert(types.is_number_with_limits(factor))

  return Point:new(self.x * factor, self.y * factor)
end

return Point
