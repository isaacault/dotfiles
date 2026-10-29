local constants = require("constants")

local notification_center = sbar.add("item", constants.items.NOTIFICATIONS, {
  position = "right",
  update_freq = 60,
  icon = { 
    padding_left = 0,
    padding_right = 0,
    string = "󰎟",}
})

notification_center:subscribe({ "forced", "routine", "system_woke" }, function(env)
  notification_center:set({
    label = os.date("%a %d %b, %H:%M:%S"),
  })
end)

notification_center:subscribe("mouse.clicked", function(env)
  -- I don't know how to split this across lines and have it still work.
  sbar.exec("osascript -e 'tell application \"Microsoft Outlook\"' -e 'activate' -e 'set theWindow to first main window' -e 'set the view of theWindow to calendar view' -e 'end tell'")
end)
