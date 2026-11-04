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

local function isdir(path)
  return exists(path .. "/")
end

if not isdir(sbarpath) then
  os.execute(
    'tmp=$(mktemp -d) && git clone --depth 1 https://github.com/FelixKratz/SbarLua.git "$tmp" && (cd "$tmp" && make install); rm -rf "$tmp"'
  )
end

package.cpath = package.cpath .. ";" .. sbarpath .. "?.so"
