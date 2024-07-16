---
-- @classmod PlacedField

local middleclass = require("middleclass")
local types = require("lualife.types")
local Stringifiable = require("lualife.models.stringifiable")
local Size = require("lualife.models.size")
local Point = require("lualife.models.point")
local Field = require("lualife.models.field")

local PlacedField = middleclass("PlacedField", Field)
PlacedField:include(Stringifiable)

---
-- @table instance
-- @tfield Size size
-- @tfield Point offset
-- @tfield tab _cells
--   map[string, bool]; key - stringified Point, value - always true

---
-- @function place
-- @static
-- @tparam Field field
-- @tparam[opt=(0 0)] Point offset
-- @treturn PlacedField
function PlacedField.static.place(field, offset)
  offset = offset or Point:new(0, 0)

  assert(types.is_instance(field, Field))
  assert(types.is_instance(offset, Point))

  local placed_field = PlacedField:new(field.size, offset)
  placed_field._cells = field._cells

  return placed_field
end

---
-- @function new
-- @tparam Size size
-- @tparam[opt=(0 0)] Point offset
-- @treturn PlacedField
function PlacedField:initialize(size, offset)
  offset = offset or Point:new(0, 0)

  assert(types.is_instance(size, Size))
  assert(types.is_instance(offset, Point))

  Field.initialize(self, size)

  self.offset = offset
end

---
-- @treturn tab table with instance fields
function PlacedField:__data()
  local data = Field.__data(self)
  data.offset = self.offset:__data()

  return data
end

---
-- @function __tostring
-- @treturn string stringified table with instance fields
-- @see Stringifiable

---
-- @function count
-- @treturn int [0, self.size.width * self.size.height]

---
-- @tparam Point point
-- @treturn bool
function PlacedField:contains(point)
  assert(types.is_instance(point, Point))

  local local_point = self:_to_local(point)
  return Field.contains(self, local_point)
end

---
-- @tparam PlacedField other
-- @treturn bool
function PlacedField:fits(other)
  assert(types.is_instance(other, PlacedField))

  local offsets_difference = self.offset:translate(other:_inverted_offset())
  return self.size:_fits(other.size, offsets_difference)
end

---
-- @tparam Point point
function PlacedField:set(point)
  assert(types.is_instance(point, Point))

  local local_point = self:_to_local(point)
  Field.set(self, local_point)
end

---
-- @tparam func mapper func(point: Point, contains: bool): bool
-- @treturn PlacedField
function PlacedField:map(mapper)
  assert(types.is_callable(mapper))

  local field = Field.map(self, function(point)
    local global_point = self:_to_global(point)
    local contains = self:contains(global_point)
    return mapper(global_point, contains)
  end)
  return PlacedField.place(field, self.offset)
end

---
-- @treturn Point
function PlacedField:_inverted_offset()
  return self.offset:scale(-1)
end

---
-- @tparam Point point
-- @treturn Point
function PlacedField:_to_local(point)
  assert(types.is_instance(point, Point))

  return point:translate(self:_inverted_offset())
end

---
-- @tparam Point point
-- @treturn Point
function PlacedField:_to_global(point)
  assert(types.is_instance(point, Point))

  return point:translate(self.offset)
end

return PlacedField
