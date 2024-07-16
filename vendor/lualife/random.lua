---
-- @module random

local types = require("lualife.types")
local Field = require("lualife.models.field")

local random = {}

---
-- @tparam Field sample
-- @tparam[opt=0.5] number filling [0, 1]
-- @treturn Field
function random.generate(sample, filling)
  filling = filling or 0.5

  assert(types.is_instance(sample, Field))
  assert(types.is_number_with_limits(filling, 0, 1))

  return sample:map(function()
    return math.random() < filling
  end)
end

---
-- @tparam Field sample
-- @tparam[opt=0.5] number filling [0, 1]
-- @tparam[optchain=0] int minimal_count
--   [0, sample.size.width * sample.size.height]
-- @tparam[optchain=math.huge] int maximal_count [minimal_count, ∞)
-- @treturn Field
function random.generate_with_limits(
  sample,
  filling,
  minimal_count,
  maximal_count
)
  filling = filling or 0.5
  minimal_count = minimal_count or 0
  maximal_count = maximal_count or math.huge

  assert(types.is_instance(sample, Field))
  assert(types.is_number_with_limits(filling, 0, 1))
  assert(types.is_number_with_limits(
    minimal_count,
    0,
    sample.size.width * sample.size.height
  ))
  assert(types.is_number_with_limits(maximal_count, minimal_count))

  local field
  repeat
    field = random.generate(sample, filling)
  until field:count() >= minimal_count and field:count() <= maximal_count

  return field
end

return random
