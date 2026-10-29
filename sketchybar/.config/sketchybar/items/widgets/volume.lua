local constants = require("constants")
local settings = require("config.settings")

local currentAudioDevice = "None"

local volumeValue = sbar.add("item", constants.items.VOLUME .. ".value", {
  position = "right",
  label = {
    string = "??%",
    padding_left = 0,
  },
})

local volumeBracket = sbar.add("bracket", constants.items.VOLUME .. ".bracket", { volumeValue.name }, {
  popup = {
    align = "center"
  },
})

local volumeSlider = sbar.add("slider", constants.items.VOLUME .. ".slider", settings.dimens.graphics.popup.width, {
  position = "popup." .. volumeBracket.name,
  click_script = 'osascript -e "set volume output volume $PERCENTAGE"'
})

-- volume_change fires rapidly while adjusting, so only re-query the output
-- device when the cached value is stale.
local DEVICE_CACHE_SECONDS <const> = 5
local cachedDevice = nil
local cachedDeviceAt = 0

local function withOutputDevice(callback)
  if cachedDevice and os.time() - cachedDeviceAt < DEVICE_CACHE_SECONDS then
    callback(cachedDevice)
    return
  end

  sbar.exec("SwitchAudioSource -t output -c", function(result)
    cachedDevice = result:sub(1, -2)
    cachedDeviceAt = os.time()
    callback(cachedDevice)
  end)
end

volumeValue:subscribe("system_woke", function()
  cachedDevice = nil
end)

volumeValue:subscribe("volume_change", function(env)
  local icon = settings.icons.text.volume._0
  local volume = tonumber(env.INFO)

  withOutputDevice(function(currentOutputDevice)
    if currentOutputDevice == "OpenRun by Shokz" then
      icon = ""
    elseif currentOutputDevice:find("Bose 700", 1, true) then
      icon = ""
    elseif currentOutputDevice == "LinkBuds S" then
      icon = ""
    elseif currentOutputDevice:find("AirPods Pro", 1, true) then
      icon = ""
    elseif volume > 60 then
      icon = settings.icons.text.volume._100
    elseif volume > 30 then
      icon = settings.icons.text.volume._66
    elseif volume > 10 then
      icon = settings.icons.text.volume._33
    elseif volume > 0 then
      icon = settings.icons.text.volume._10
    end
    -- end

    local lead = ""
    if volume < 10 then
      lead = "0"
    end

    -- volumeIcon:set({ label = icon })
    volumeSlider:set({ slider = { percentage = volume } })

    local hasVolume = volume ~= 0
    volumeValue:set({
      icon = icon,
      label = {
        string = hasVolume and lead .. volume .. "%" or "",
        padding_right = hasVolume and 8 or 0,
      },
    })
  end)
end)

local function hideVolumeDetails()
  local drawing = volumeBracket:query().popup.drawing == "on"
  if not drawing then return end
  volumeBracket:set({ popup = { drawing = false } })
  sbar.remove("/" .. constants.items.VOLUME .. ".device\\.*/")
end

local function toggleVolumeDetails(env)
  if env.BUTTON == "right" then
    sbar.exec("open /System/Library/PreferencePanes/Sound.prefpane")
    return
  end

  local shouldDraw = volumeBracket:query().popup.drawing == "off"
  if shouldDraw then
    volumeBracket:set({ popup = { drawing = true } })

    -- Requires 'brew install switchaudio-osx'
    sbar.exec("SwitchAudioSource -t output -c", function(result)
      currentAudioDevice = result:sub(1, -2)

      sbar.exec("SwitchAudioSource -a -t output", function(available)
        local current = currentAudioDevice
        local counter = 0

        for device in string.gmatch(available, '[^\r\n]+') do
          local color = settings.colors.grey
          if current == device then
            color = settings.colors.white
          end

          sbar.add("item", constants.items.VOLUME .. ".device." .. counter, {
            position = "popup." .. volumeBracket.name,
            align = "center",
            label = { string = device, color = color },
            click_script = 'SwitchAudioSource -s "' ..
                device ..
                '" && sketchybar --set /' .. constants.items.VOLUME .. '.device\\.*/ label.color=' ..
                settings.colors.grey .. ' --set $NAME label.color=' .. settings.colors.white

          })
          counter = counter + 1
        end
      end)
    end)
  else
    hideVolumeDetails()
  end
end

local function changeVolume(env)
  local delta = env.SCROLL_DELTA
  sbar.exec('osascript -e "set volume output volume (output volume of (get volume settings) + ' .. delta .. ')"')
end

volumeValue:subscribe("mouse.clicked", toggleVolumeDetails)
volumeValue:subscribe("mouse.scrolled", changeVolume)
-- volumeValue:subscribe("mouse.exited.global", hideVolumeDetails)
