local events <const> = {
  AEROSPACE_WORKSPACE_CHANGED = "aerospace_workspace_changed",
  SWAP_MENU_AND_SPACES = "swap_menu_and_spaces",
  SEND_MESSAGE = "send_message",
  HIDE_MESSAGE = "hide_message",
  POMODORO_TOGGLE = "pomodoro_toggle",
  POMODORO_RESET = "pomodoro_reset",
  POMODORO_SETTINGS = "pomodoro_settings",
}

local items <const> = {
  SPACES = "workspaces",
  MESSAGE = "message",
  VOLUME = "widgets.volume",
  WIFI = "widgets.wifi",
  BATTERY = "widgets.battery",
  CALENDAR = "widgets.calendar",
  POMODORO = "widgets.pomodoro",
}

local aerospace <const> = {
  LIST_ALL_WORKSPACES = "aerospace list-workspaces --all",
  GET_CURRENT_WORKSPACE = "aerospace list-workspaces --focused",
}

return {
  items = items,
  events = events,
  aerospace = aerospace,
}
