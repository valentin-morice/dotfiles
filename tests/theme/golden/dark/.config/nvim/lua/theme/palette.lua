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
  background = (1 == 1) and "dark" or "light",

  -- Grounds. bg_alt is the terminal background (alacritty renders it), so the
  -- editor uses it as Normal bg to sit seamlessly in the terminal.
  bg = "#0d0d0d",
  bg_alt = "#141414",
  bg_alt2 = "#1a1a1a",
  bg_sel = "#1c1c1c",
  bg_section = "#202020",
  bg_hover = "#2e2e2e",
  fg = "#ffffff",
  fg_soft = "#d4d4d4",
  muted = "#888888",
  muted_dim = "#6e6e6e",
  muted_warm = "#aaaaaa",
  highlight = "#6c6c6c",

  -- Accents
  accent = "#5294e2",
  accent_text = "#0d0d0d",
  secondary = "#e0a552",
  urgent = "#ff5555",
  urgent_dark = "#900000",
  urgent_text = "#ffffff",

  -- Borders
  border = "#1f1f1f",
  border_med = "#444444",

  -- Terminal ANSI 16 (also the syntax hues: green/magenta/cyan have no
  -- standalone THEME_ key — the ANSI palette is their single source of truth).
  ansi = {
    black = "#1a1a1a",
    red = "#ff5555",
    green = "#6cc08b",
    yellow = "#e0a552",
    blue = "#5294e2",
    magenta = "#b48ead",
    cyan = "#5fb3c4",
    white = "#d4d4d4",
    bright_black = "#888888",
    bright_red = "#ff7b7b",
    bright_green = "#87d0a3",
    bright_yellow = "#ecc07d",
    bright_blue = "#6ba3e8",
    bright_magenta = "#c8a0c8",
    bright_cyan = "#7fc8d6",
    bright_white = "#ffffff",
  },
}
