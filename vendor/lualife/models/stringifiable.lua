---
-- @classmod Stringifiable

local inspect = require("inspect")
local types = require("lualife.types")

local Stringifiable = {}

---
-- @treturn string stringified result of the __data() metamethod
function Stringifiable:__tostring()
  assert(types.has_metamethod(self, "__data"))

  return inspect(self:__data(), {
    indent = "",
    newline = "",
  })
end

return Stringifiable
