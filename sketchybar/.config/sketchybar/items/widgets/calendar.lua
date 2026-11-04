local constants = require("constants")
local hover = require("util.hover")

local calendar = sbar.add("item", constants.items.CALENDAR, {
  position = "right",
  update_freq = 1,
  icon = { padding_left = 0, padding_right = 0 }
})

calendar:subscribe({ "forced", "routine", "system_woke" }, function(env)
  -- The routine fires every second; only redraw on seconds divisible by 5.
  if env.SENDER == "routine" and tonumber(os.date("%S")) % 5 ~= 0 then return end

  calendar:set({
    label = os.date("%a %d %b, %H:%M:%S"),
  })
end)

local OPEN_OUTLOOK_CALENDAR <const> = table.concat({
  "osascript",
  [[-e 'tell application "Microsoft Outlook"']],
  "-e 'activate'",
  "-e 'set theWindow to first main window'",
  "-e 'set the view of theWindow to calendar view'",
  "-e 'end tell'",
}, " ")

calendar:subscribe("mouse.clicked", function(env)
  sbar.exec(OPEN_OUTLOOK_CALENDAR)
end)

hover.widgets.add(calendar)
