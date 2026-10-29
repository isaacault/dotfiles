local constants = require("constants")
local settings = require("config.settings")

local ICONS <const> = {
  idle = settings.icons.text.pomodoro.focus,
  focus = settings.icons.text.pomodoro.focus,
  short = settings.icons.text.pomodoro.short_break,
  long = settings.icons.text.pomodoro.long_break,
}
local COLORS <const> = {
  idle = settings.colors.white,
  focus = settings.colors.white,
  short = settings.colors.cyan,
  long = settings.colors.cyan,
}
-- Abandoned focus sessions shorter than this are treated as accidental taps.
local MIN_LOGGED_SECONDS <const> = 60

local STATE_DIR <const> = os.getenv("HOME") .. "/.local/state/sketchybar"
local STATE_FILE <const> = STATE_DIR .. "/pomodoro"
local CONF_FILE <const> = STATE_DIR .. "/pomodoro.conf"
local LOG_FILE <const> = STATE_DIR .. "/pomodoro.log"
local PANEL <const> = os.getenv("HOME") .. "/.config/sketchybar/pomodoro/pomodoro-panel"
os.execute("mkdir -p '" .. STATE_DIR .. "'")

sbar.add("event", constants.events.POMODORO_TOGGLE)
sbar.add("event", constants.events.POMODORO_RESET)
sbar.add("event", constants.events.POMODORO_SETTINGS)

-- The panel (pomodoro/pomodoro-panel) writes CONF_FILE; keep defaults in sync
-- with pomodoro/panel.html.
local conf = {
  focus_min = 25,
  short_min = 5,
  long_min = 15,
  sessions_per_long = 4,
  goal = 8,
  chime = true,
  invert = true,
  banner = true,
}

local function loadConf()
  local f = io.open(CONF_FILE, "r")
  if not f then return end
  for line in f:lines() do
    local k, v = line:match("^([%w_]+)=(%S+)$")
    if k and conf[k] ~= nil then
      if type(conf[k]) == "boolean" then
        conf[k] = v == "true"
      elseif tonumber(v) and tonumber(v) > 0 then
        conf[k] = tonumber(v)
      end
    end
  end
  f:close()
end

local function durationOf(phase)
  if phase == "focus" then return conf.focus_min * 60 end
  if phase == "short" then return conf.short_min * 60 end
  return conf.long_min * 60
end

local function today() return os.date("%Y-%m-%d") end

-- The countdown is derived from an end timestamp rather than decremented, so
-- it stays correct across sleep and bar reloads.
local state = {
  phase = "idle", -- idle | focus | short | long
  running = false,
  endsAt = 0,     -- valid while running
  remaining = 0,  -- valid while paused
  planned = 0,    -- full length of the current phase, for logging
  count = 0,      -- focus sessions completed today
  day = today(),
  alert = false,  -- phase finished and not yet acknowledged
}

local function save()
  local f = io.open(STATE_FILE, "w")
  if not f then return end
  f:write(string.format("%s %s %d %d %d %d %s %s\n", state.phase, tostring(state.running),
    state.endsAt, state.remaining, state.planned, state.count, state.day, tostring(state.alert)))
  f:close()
end

local function loadState()
  local f = io.open(STATE_FILE, "r")
  if not f then return end
  local line = f:read("l")
  f:close()
  local phase, running, endsAt, remaining, planned, count, day, alert =
      (line or ""):match("^(%a+) (%a+) (%d+) (%d+) (%d+) (%d+) (%S+) (%a+)$")
  if not phase or day ~= today() then return end -- old format or new day: start fresh
  state.phase, state.running, state.alert = phase, running == "true", alert == "true"
  state.endsAt, state.remaining, state.planned = tonumber(endsAt), tonumber(remaining), tonumber(planned)
  state.count = tonumber(count)
end

-- One line per focus session: epoch, status, planned seconds, focused seconds.
local function logSession(status, plannedSeconds, focusedSeconds)
  local f = io.open(LOG_FILE, "a")
  if not f then return end
  f:write(string.format("%d %s %d %d\n", os.time(), status, plannedSeconds, focusedSeconds))
  f:close()
end

local pomodoro = sbar.add("item", constants.items.POMODORO, {
  position = "right",
  update_freq = 0,
  icon = { string = ICONS.idle },
  label = { string = "", padding_left = 0 },
})

local function secondsLeft()
  if state.running then return math.max(0, state.endsAt - os.time()) end
  return state.remaining
end

local function rollDay()
  if state.day ~= today() then state.day, state.count = today(), 0 end
end

local function render()
  rollDay()
  local icon = ICONS[state.phase]
  local color = COLORS[state.phase]
  local label = ""

  if state.phase ~= "idle" then
    local left = secondsLeft()
    label = string.format("%02d:%02d", left // 60, left % 60)
    label = label .. "  " .. state.count .. "/" .. conf.goal
    if not state.running and not state.alert then icon = settings.icons.text.pomodoro.paused end
  end

  local alerting = state.alert and conf.invert
  if alerting then
    label = (state.phase == "focus" and "Focus" or "Break") .. " ready · click"
  end

  pomodoro:set({
    update_freq = state.running and 1 or 0,
    background = {
      drawing = alerting,
      color = settings.colors.white,
    },
    icon = { string = icon, color = alerting and settings.colors.black or color },
    label = { string = label, color = alerting and settings.colors.black or settings.colors.white },
  })
end

local function notify(text)
  if conf.chime then sbar.exec("afplay /System/Library/Sounds/Glass.aiff") end
  if conf.banner then
    sbar.exec(string.format("osascript -e 'display notification \"%s\" with title \"Pomodoro\"'", text))
  end
end

-- Moves to the next phase and waits for the user to start it.
local function finishPhase()
  rollDay()
  if state.phase == "focus" then
    state.count = state.count + 1
    logSession("done", state.planned, state.planned)
    state.phase = state.count % conf.sessions_per_long == 0 and "long" or "short"
    notify(string.format("Focus session %d/%d done. Time for a break.", state.count, conf.goal))
  else
    state.phase = "focus"
    notify("Break over. Ready to focus?")
  end
  state.running = false
  state.planned = durationOf(state.phase)
  state.remaining = state.planned
  state.alert = true
  save()
  render()
end

local function startPhase(phase)
  state.phase = phase
  state.planned = durationOf(phase)
  state.running = true
  state.endsAt = os.time() + state.planned
  state.remaining = 0
  state.alert = false
end

local function toggle()
  if state.phase == "idle" then
    startPhase("focus")
  elseif state.alert then
    -- Acknowledge the alert and start the phase that is waiting.
    state.running, state.alert = true, false
    state.endsAt = os.time() + state.remaining
  elseif state.running then
    state.remaining = secondsLeft()
    state.running = false
  else
    state.running, state.endsAt = true, os.time() + state.remaining
  end
  save()
  render()
end

local function reset()
  if state.phase == "focus" and not state.alert then
    local focused = state.planned - secondsLeft()
    if focused >= MIN_LOGGED_SECONDS then logSession("partial", state.planned, focused) end
  end
  state.phase, state.running, state.alert = "idle", false, false
  state.endsAt, state.remaining, state.planned = 0, 0, 0
  save()
  render()
end

local function openPanel()
  sbar.exec("pkill -x pomodoro-panel || '" .. PANEL .. "'")
end

pomodoro:subscribe({ "routine", "forced", "system_woke" }, function()
  if state.running and secondsLeft() == 0 then
    finishPhase()
  else
    render()
  end
end)

pomodoro:subscribe(constants.events.POMODORO_TOGGLE, toggle)
pomodoro:subscribe(constants.events.POMODORO_RESET, reset)
pomodoro:subscribe(constants.events.POMODORO_SETTINGS, function()
  loadConf()
  render()
end)
pomodoro:subscribe("mouse.clicked", function(env)
  if env.BUTTON == "right" then
    reset()
  elseif env.BUTTON == "other" then
    openPanel()
  else
    toggle()
  end
end)

loadConf()
loadState()
if state.running and secondsLeft() == 0 then finishPhase() else render() end
