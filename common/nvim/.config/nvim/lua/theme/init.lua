-- Live theme reload, called by theme-render over RPC on every running instance
-- (nvim --server $XDG_RUNTIME_DIR/nvim.<pid>.0 --remote-expr
-- 'v:lua.require("theme").reload()') — the same pattern as zathura's D-Bus
-- SourceConfig push. Drops the cached rendered palette and re-applies the
-- colorscheme; lualine re-reads its theme on the ColorScheme autocmd.
--
-- This module's namesake directory also holds palette.lua, the theme-render
-- OUTPUT (gitignored) — everything committed about theming lives in
-- colors/graphite.lua and the theme package's template.
local M = {}

function M.reload()
  package.loaded["theme.palette"] = nil
  package.loaded["lualine.themes.graphite"] = nil
  if vim.g.colors_name == "graphite" then
    -- Deferred: --remote-expr evaluates synchronously inside the RPC request,
    -- where a full highlight rebuild + redraw doesn't belong.
    vim.schedule(function()
      vim.cmd.colorscheme("graphite")
    end)
  end
  return "" -- --remote-expr prints the result; return something empty
end

return M
