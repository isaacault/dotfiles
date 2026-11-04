local constants = require("constants")
local settings = require("config.settings")
local hover = require("util.hover")

local popupWidth <const> = settings.dimens.graphics.popup.width + 20

-- The Wi-Fi interface isn't always en0 (docks and adapters shift the numbering).
local wifiDevice = "en0"
sbar.exec([[networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/{getline; print $2; exit}']],
  function(device)
    device = device:gsub("%s+", "")
    if device ~= "" then wifiDevice = device end
  end)

local wifi = sbar.add("item", constants.items.WIFI .. ".padding", {
  position = "right",
  label = { drawing = false },
  padding_right = 0,
})

local wifiBracket = sbar.add("bracket", constants.items.WIFI .. ".bracket", {
  wifi.name,
}, {
  popup = { align = "center" }
})

-- Reads the network name with Location Services permission; macOS hides it from
-- plain commands. Built by scripts/build-swift-tools.sh, see wifi-ssid/wifi-ssid.swift.
local ssidHelper = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config"))
  .. "/sketchybar/wifi-ssid/wifi-ssid.app/Contents/MacOS/wifi-ssid"

local ssid = sbar.add("item", {
  align = "center",
  position = "popup." .. wifiBracket.name,
  width = popupWidth,
  height = 16,
  icon = {
    string = settings.icons.text.wifi.router,
    font = {
      style = settings.fonts.styles.bold
    },
  },
  label = {
    font = {
      style = settings.fonts.styles.bold,
      size = settings.dimens.text.label,
    },
    max_chars = 18,
    string = "????????????",
  },
})

local hostname = sbar.add("item", {
  position = "popup." .. wifiBracket.name,
  background = {
    height = 16,
  },
  icon = {
    align = "left",
    string = "Hostname:",
    width = popupWidth / 2,
    font = {
      size = settings.dimens.text.label
    },
  },
  label = {
    max_chars = 20,
    string = "????????????",
    width = popupWidth / 2,
    align = "right",
  }
})

local ip = sbar.add("item", {
  position = "popup." .. wifiBracket.name,
  background = {
    height = 16,
  },
  icon = {
    align = "left",
    string = "IP:",
    width = popupWidth / 2,
    font = {
      size = settings.dimens.text.label
    },
  },
  label = {
    align = "right",
    string = "???.???.???.???",
    width = popupWidth / 2,
  }
})

local router = sbar.add("item", {
  position = "popup." .. wifiBracket.name,
  background = {
    height = 16,
  },
  icon = {
    align = "left",
    string = "Router:",
    width = popupWidth / 2,
    font = {
      size = settings.dimens.text.label
    },
  },
  label = {
    align = "right",
    string = "???.???.???.???",
    width = popupWidth / 2,
  },
})

sbar.add("item", { position = "right", width = settings.dimens.padding.item })

wifi:subscribe({ "wifi_change", "system_woke", "forced" }, function(env)
  wifi:set({
    icon = {
      string = settings.icons.text.wifi.disconnected,
      color = settings.colors.magenta,
    }
  })

  sbar.exec("ipconfig getifaddr " .. wifiDevice, function(ip)
    local ipConnected = not (ip == "")

    local wifiIcon
    local wifiColor

    if ipConnected then
      wifiIcon = settings.icons.text.wifi.connected
      wifiColor = settings.colors.white
    end

    wifi:set({
      icon = {
        string = wifiIcon,
        color = wifiColor,
      }
    })

    -- Give the VPN interface a moment to come up before checking for it.
    sbar.delay(2, function()
      sbar.exec([[scutil --nwi | grep -m1 'utun' | awk '{ print $1 }']], function(vpn)
        local isVPNConnected = not (vpn == "")

        if isVPNConnected then
          wifiIcon = settings.icons.text.wifi.vpn
        end

        wifi:set({
          icon = {
            string = wifiIcon,
          }
        })
      end)
    end)
  end)
end)

local function hideDetails()
  wifiBracket:set({ popup = { drawing = false } })
end

local function toggleDetails()
  local shouldDrawDetails = wifiBracket:query().popup.drawing == "off"

  if shouldDrawDetails then
    wifiBracket:set({ popup = { drawing = true } })
    sbar.exec("networksetup -getcomputername", function(result)
      hostname:set({ label = result })
    end)
    sbar.exec("ipconfig getifaddr " .. wifiDevice, function(result)
      ip:set({ label = result })
    end)
    -- Link state first; the helper then replaces it with the network name.
    -- Until the helper is built and allowed, the row keeps the link state.
    sbar.exec("ipconfig getifaddr " .. wifiDevice, function(result)
      local connected = result:gsub("%s+", "") ~= ""
      ssid:set({ label = connected and "Connected" or "Disconnected" })
      if not connected then return end
      sbar.exec("'" .. ssidHelper .. "' 2>/dev/null", function(name)
        name = name:gsub("%s+$", "")
        if name ~= "" then ssid:set({ label = name }) end
      end)
    end)
    sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'", function(result)
      router:set({ label = result })
    end)
  else
    hideDetails()
  end
end

local function copyLabelToClipboard(env)
  local label = sbar.query(env.NAME).label.value
  local escaped = label:gsub("[\r\n]+$", ""):gsub("'", "'\\''")
  sbar.exec("printf %s '" .. escaped .. "' | pbcopy")
  sbar.set(env.NAME, { label = { string = settings.icons.text.clipboard, align = "center" } })
  sbar.delay(1, function()
    sbar.set(env.NAME, { label = { string = label, align = "right" } })
  end)
end

wifi:subscribe("mouse.clicked", toggleDetails)
hover.widgets.add(wifi)

-- Clicking the status row opens the Wi-Fi settings pane.
ssid:subscribe("mouse.clicked", function()
  hideDetails()
  sbar.exec("open x-apple.systempreferences:com.apple.wifi-settings-extension")
end)
hostname:subscribe("mouse.clicked", copyLabelToClipboard)
ip:subscribe("mouse.clicked", copyLabelToClipboard)
router:subscribe("mouse.clicked", copyLabelToClipboard)
