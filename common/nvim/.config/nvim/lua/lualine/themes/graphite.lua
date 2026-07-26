-- lualine theme for graphite. Found automatically: LazyVim leaves lualine's
-- theme on "auto", which resolves lualine.themes.<g:colors_name> from the rtp.
-- Same palette source (and bootstrap situation) as colors/graphite.lua, but no
-- fallback table here: pre-first-render the colorscheme already fell back to
-- its embedded dark palette, so lualine just mirrors whatever it can — and
-- auto-derives from highlight groups if this require fails.
local ok, p = pcall(require, "theme.palette")
if not ok then
  return require("lualine.themes.auto")
end

-- Mode pill: mode-hue bg + accent_text fg — the waybar active-workspace trick.
-- accent_text flips polarity per palette (near-black on dark's bright hues,
-- near-white on light's deepened ones), so one key serves every mode colour.
local function pill(color)
  return {
    a = { fg = p.accent_text, bg = color, gui = "bold" },
    b = { fg = p.fg_soft, bg = p.bg_section },
    c = { fg = p.muted, bg = p.bg },
  }
end

local theme = {
  normal = pill(p.accent),
  insert = pill(p.ansi.green),
  visual = pill(p.secondary),
  replace = pill(p.urgent),
  command = pill(p.ansi.cyan),
  terminal = pill(p.ansi.magenta),
  inactive = {
    a = { fg = p.muted_dim, bg = p.bg },
    b = { fg = p.muted_dim, bg = p.bg },
    c = { fg = p.muted_dim, bg = p.bg },
  },
}

return theme
