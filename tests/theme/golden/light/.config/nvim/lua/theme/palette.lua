-- nvim palette — RENDERED by theme-render from this template into
-- ~/.config/nvim/lua/theme/palette.lua. Do NOT edit the generated file; edit
-- the palette (palettes/{light,dark}.sh) for colours or the colorscheme
-- (colors/graphite.lua in the nvim package) for how they're applied.
--
-- One adaptive colorscheme consumes this: the light/dark split lives entirely
-- in the palette values, plus the `background` flag below (derived from the
-- same prefer-dark key GTK uses). Running instances re-source this live via
-- theme-render's RPC push (see the nvim block in theme-render).
return {
  background = (0 == 1) and "dark" or "light",

  -- Grounds. bg_alt is the terminal background (alacritty renders it), so the
  -- editor uses it as Normal bg to sit seamlessly in the terminal.
  bg = "#f4f6f8",
  bg_alt = "#e9eef2",
  bg_alt2 = "#e4e9ee",
  bg_sel = "#d4e2ee",
  bg_section = "#e9eef2",
  bg_hover = "#dde2e7",
  fg = "#1d2329",
  fg_soft = "#333b42",
  muted = "#6b7680",
  muted_dim = "#9aa4ad",
  muted_warm = "#8b939b",
  highlight = "#9aa4ad",

  -- Accents
  accent = "#2f6fb3",
  accent_text = "#f4f6f8",
  secondary = "#b5790a",
  urgent = "#c8332b",
  urgent_dark = "#9e2820",
  urgent_text = "#f4f6f8",

  -- Borders
  border = "#d3dae0",
  border_med = "#c2cad1",

  -- Terminal ANSI 16 (also the syntax hues: green/magenta/cyan have no
  -- standalone THEME_ key — the ANSI palette is their single source of truth).
  ansi = {
    black = "#1d2329",
    red = "#c8332b",
    green = "#2f7d4f",
    yellow = "#b5790a",
    blue = "#2f6fb3",
    magenta = "#8b4f9e",
    cyan = "#2b8a92",
    white = "#e9eef2",
    bright_black = "#6b7680",
    bright_red = "#9e2820",
    bright_green = "#246b41",
    bright_yellow = "#946309",
    bright_blue = "#265d99",
    bright_magenta = "#74448a",
    bright_cyan = "#237076",
    bright_white = "#ffffff",
  },
}
