local sbarpath = os.getenv("HOME") .. "/.local/share/sketchybar_lua/"

local function exists(file)
  local ok, err, code = os.rename(file, file)
  if not ok then
    if code == 13 then
      return true
    end
  end
  return ok, err
end

-- SbarLua is built by scripts/install-sbarlua.sh (pinned to a Lua 5.4 build),
-- never at bar start: an unpinned build can embed a Lua that doesn't match.
if not exists(sbarpath .. "sketchybar.so") then
  error("SbarLua is not installed: run scripts/install-sbarlua.sh from the dotfiles repo")
end

package.cpath = package.cpath .. ";" .. sbarpath .. "?.so"
