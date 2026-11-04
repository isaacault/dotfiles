-- Hover highlight shared by a group of items. Every render writes the full
-- hover state of every member, so a mouse event that is missed or arrives out
-- of order can never leave an item stuck in the hovered state.
local settings = require("config.settings")

local hover = {}

function hover.group(active, inactive)
  local members = {}
  local hovered = nil

  local function setHovered(item)
    if hovered == item then return end
    hovered = item

    sbar.animate("tanh", 3, function()
      for member in pairs(members) do
        member:set(member == hovered and active or inactive)
      end
    end)
  end

  return {
    add = function(item)
      members[item] = true
      item:subscribe("mouse.entered", function() setHovered(item) end)
      item:subscribe("mouse.exited", function()
        if hovered == item then setHovered(nil) end
      end)
      item:subscribe("mouse.exited.global", function() setHovered(nil) end)
    end,
  }
end

-- Right-hand widgets get a faint highlight behind them.
hover.widgets = hover.group(
  { background = { drawing = true, color = settings.colors.with_alpha(settings.colors.white, 0.12) } },
  { background = { drawing = true, color = settings.colors.transparent } }
)

return hover
