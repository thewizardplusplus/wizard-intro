---
-- @module matrix

local types = require("lualife.types")
local Point = require("lualife.models.point")
local Field = require("lualife.models.field")

local matrix = {}

---
-- @tparam Field field
-- @treturn Field
function matrix.rotate(field)
  assert(types.is_instance(field, Field))
  assert(field.size.width == field.size.height)

  -- make an empty field copy (i.e. without cells)
  -- and detect the field offset
  local offset = nil
  local rotated_field = field:map(function(point)
    if not offset then
      offset = point
    end

    return false
  end)

  local last_index = field.size.width - 1
  for x = 0, field.size.width / 2 - 1 do
    for y = x, last_index - x - 1 do
      local top_left = Point:new(x, y):translate(offset)
      local top_right = Point:new(last_index - y, x):translate(offset)
      local bottom_left = Point:new(y, last_index - x):translate(offset)
      local bottom_right = Point
        :new(last_index - x, last_index - y)
        :translate(offset)

      if field:contains(bottom_left) then
        rotated_field:set(top_left)
      end
      if field:contains(bottom_right) then
        rotated_field:set(bottom_left)
      end
      if field:contains(top_right) then
        rotated_field:set(bottom_right)
      end
      if field:contains(top_left) then
        rotated_field:set(top_right)
      end
    end
  end

  if field.size.width % 2 ~= 0 then
    local x = math.floor(field.size.width / 2)
    local center = Point:new(x, x):translate(offset)
    if field:contains(center) then
      rotated_field:set(center)
    end
  end

  return rotated_field
end

return matrix
