local constants = require("constants")
local settings = require("config.settings")
local hover = require("util.hover")

local spaces = {}

local spaceHover = hover.group(
  { background = { height = settings.dimens.graphics.bar.height } },
  { background = { height = settings.dimens.graphics.background.height } }
)

local swapWatcher = sbar.add("item", {
  drawing = false,
  updates = true,
})

local currentWorkspaceWatcher = sbar.add("item", {
  drawing = false,
  updates = true,
})

-- Modify this file with Visual Studio Code - at least vim does have problems with the icons
-- copy "Icons" from the nerd fonts cheat sheet and replace icon and name accordingly below
-- https://www.nerdfonts.com/cheat-sheet
local spaceConfigs <const> = {
  ["1"] = { icon = "󱞁", name = "Notes" },
  ["2"] = { icon = "", name = "Terminal" },
  ["3"] = { icon = "󰖟", name = "Browser" },
  ["4"] = { icon = "4", name = "" },
  -- ["4"] = { icon = "󰖟", name = "Browser" },
  -- ["4"] = { icon = "", name = "AltBrowser" },
  -- ["5"] = { icon = "", name = "Remote" },
  -- ["6"] = { icon = "", name = "Database" },
  ["5"] = { icon = "5", name = "" },
  ["6"] = { icon = "6", name = "" },
  -- ["6"] = { icon = "󰊻", name = "Chat" },
  ["7"] = { icon = "", name = "Music" },
  ["8"] = { icon = "", name = "Chat" },
  ["9"] = { icon = "", name = "Mail" },
  -- ["8"] = { icon = "", name = "Music" },
  -- ["9"] = { icon = "󰌾", name = "Secrets" },
  -- ["10"] = { icon = "", name = "Meeting" },
  ["10"] = { icon = "󰊻", name = "Meeting" },
}

local function selectCurrentWorkspace(focusedWorkspaceName)
  for sid, item in pairs(spaces) do
    if item ~= nil then
      local isSelected = sid == constants.items.SPACES .. "." .. focusedWorkspaceName
      item:set({
        icon = { color = isSelected and settings.colors.bg1 or settings.colors.white },
        label = { color = isSelected and settings.colors.bg1 or settings.colors.white },
        background = { color = isSelected and settings.colors.white or settings.colors.bg1 },
      })
    end
  end

end

local function findAndSelectCurrentWorkspace()
  sbar.exec(constants.aerospace.GET_CURRENT_WORKSPACE, function(focusedWorkspaceOutput)
    local focusedWorkspaceName = focusedWorkspaceOutput:match("[^\r\n]+")
    selectCurrentWorkspace(focusedWorkspaceName)
  end)
end

local function addWorkspaceItem(workspaceName)
  local spaceName = constants.items.SPACES .. "." .. workspaceName
  local spaceConfig = spaceConfigs[workspaceName] or { icon = workspaceName, name = "" }

  spaces[spaceName] = sbar.add("item", spaceName, {
    label = {
      width = 0,
      padding_left = 0,
      string = spaceConfig.name,
    },
    icon = {
      string = spaceConfig.icon or settings.icons.apps["default"], color = settings.colors.white,
    },
    background = {
      color = settings.colors.bg1,
    },
    click_script = "aerospace workspace " .. workspaceName,
  })

  spaceHover.add(spaces[spaceName])

  sbar.add("item", spaceName .. ".padding", {
    width = settings.dimens.padding.label
  })
end

local function createWorkspaces()
  sbar.exec(constants.aerospace.LIST_ALL_WORKSPACES, function(workspacesOutput)
    for workspaceName in workspacesOutput:gmatch("[^\r\n]+") do
      addWorkspaceItem(workspaceName)
    end

    findAndSelectCurrentWorkspace()
  end)
end

swapWatcher:subscribe(constants.events.SWAP_MENU_AND_SPACES, function(env)
  local isShowingSpaces = env.isShowingMenu == "off" and true or false
  sbar.set("/" .. constants.items.SPACES .. "\\..*/", { drawing = isShowingSpaces })
end)

currentWorkspaceWatcher:subscribe(constants.events.AEROSPACE_WORKSPACE_CHANGED, function(env)
  selectCurrentWorkspace(env.FOCUSED_WORKSPACE)
end)

createWorkspaces()
