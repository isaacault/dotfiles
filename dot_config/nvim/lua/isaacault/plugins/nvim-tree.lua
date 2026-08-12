-- File explorer + the sidebar cycle:
--   <leader>e steps  none -> file explorer -> p4 CL panel -> none
-- (the p4 CL step is skipped on machines without p4diff.nvim).
local function cycle_sidebar()
  local function has_ft(ft)
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == ft then return true end
    end
    return false
  end
  if has_ft("NvimTree") then
    vim.cmd.NvimTreeClose()
    if vim.fn.exists(":P4") == 2 then
      vim.cmd("P4 cl")
    end
  elseif has_ft("p4diff-panel") then
    require("p4diff.cl").close()
  else
    vim.cmd.NvimTreeOpen()
  end
end

return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>e", cycle_sidebar, desc = "Cycle sidebar: explorer → p4 CL → none" },
    },
    opts = {},
  },
}
