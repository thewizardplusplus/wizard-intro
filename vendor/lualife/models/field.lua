---
-- @classmod Field

local middleclass = require("middleclass")
local types = require("lualife.types")
local Stringifiable = require("lualife.models.stringifiable")
local Size = require("lualife.models.size")
local Point = require("lualife.models.point")

local Field = middleclass("Field")
Field:include(Stringifiable)

---
-- @table instance
-- @tfield Size size
-- @tfield tab _cells
--   map[string, bool]; key - stringified Point, value - always true

---
-- @function new
-- @tparam Size size
-- @treturn Field
function Field:initialize(size)
  assert(types.is_instance(size, Size))

  self.size = size
  self._cells = {}
end

---
-- @treturn tab table with instance fields
function Field:__data()
  local cells = {}
  self:map(function(point, contains)
    if contains then
      table.insert(cells, point:__data())
    end
  end)

  return {
    size = self.size:__data(),
    cells = cells,
  }
end

---
-- @function __tostring
-- @treturn string stringified table with instance fields
-- @see Stringifiable

---
-- @treturn int [0, self.size.width * self.size.height]
function Field:count()
  local count = 0
  for _ in pairs(self._cells) do
    count = count + 1
  end

  return count
end

---
-- @tparam Point point
-- @treturn bool
function Field:contains(point)
  assert(types.is_instance(point, Point))

  return self.size:_contains(point)
    and types.to_boolean(self._cells[tostring(point)])
end

---
-- @tparam Field other
-- @treturn bool
function Field:fits(other)
  assert(types.is_instance(other, Field))

  return self.size:_fits(other.size)
end

---
-- @tparam Point point
function Field:set(point)
  assert(types.is_instance(point, Point))

  if self.size:_contains(point) then
    self._cells[tostring(point)] = true
  end
end

---
-- @tparam func mapper func(point: Point, contains: bool): bool
-- @treturn Field
function Field:map(mapper)
  assert(types.is_callable(mapper))

  local field = Field:new(self.size)
  for y = 0, self.size.height - 1 do
    for x = 0, self.size.width - 1 do
      local point = Point:new(x, y)
      local contains = self:contains(point)
      if mapper(point, contains) then
        field:set(point)
      end
    end
  end

  return field
end

return Field
