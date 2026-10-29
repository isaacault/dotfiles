local constants = require("constants")
local settings = require("config.settings")

local message = sbar.add("item", constants.items.MESSAGE, {
  width = 0,
  position = "center",
  popup = { align = "center" },
  label = {
    padding_left = 0,
    padding_right = 0,
  },
  background = {
    padding_left = 0,
    padding_right = 0,
  }
})

local messagePopup = sbar.add("item", {
  position = "popup." .. message.name,
  width = "dynamic",
  label = {
    padding_right = settings.dimens.padding.label,
    padding_left = settings.dimens.padding.label,
  },
  icon = {
    padding_left = 0,
    padding_right = 0,
  },
})

local function hideMessage()
  message:set({ popup = { drawing = false } })
end

local hideToken = 0

local function showMessage(content, hold)
  hideMessage()

  message:set({ popup = { drawing = true } })
  messagePopup:set({ label = { string = content } })

  -- Only the most recent message's timer may hide the popup.
  hideToken = hideToken + 1
  local token = hideToken

  if not hold then
    sbar.delay(5, function()
      if token ~= hideToken then return end
      hideMessage()
    end)
  end
end

message:subscribe(constants.events.SEND_MESSAGE, function(env)
  local content = env.MESSAGE
  local hold = env.HOLD ~= nil and env.HOLD == "true" or false
  showMessage(content, hold)
end)

message:subscribe(constants.events.HIDE_MESSAGE, hideMessage)
