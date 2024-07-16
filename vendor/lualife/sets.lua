---
-- @module sets

local types = require("lualife.types")
local Field = require("lualife.models.field")

local sets = {}

---
-- @tparam Field base
-- @tparam Field additional
-- @treturn Field
function sets.union(base, additional)
  assert(types.is_instance(base, Field))
  assert(types.is_instance(additional, Field))

  return base:map(function(point, contains)
    return contains or additional:contains(point)
  end)
end

---
-- @tparam Field base
-- @tparam Field additional
-- @treturn Field
function sets.complement(base, additional)
  assert(types.is_instance(base, Field))
  assert(types.is_instance(additional, Field))

  return base:map(function(point, contains)
    return contains and not additional:contains(point)
  end)
end

---
-- @tparam Field base
-- @tparam Field additional
-- @treturn Field
function sets.intersection(base, additional)
  assert(types.is_instance(base, Field))
  assert(types.is_instance(additional, Field))

  return base:map(function(point, contains)
    return contains and additional:contains(point)
  end)
end

return sets
