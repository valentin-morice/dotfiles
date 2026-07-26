-- graphite — the dotfiles colorscheme, light AND dark. All colours come from
-- the rendered palette (lua/theme/palette.lua, written by theme-render from
-- palettes/{light,dark}.sh); this file only decides how they're applied, so it
-- is theme-agnostic and never edited on a theme switch. Running instances are
-- re-sourced live by theme-render via require("theme").reload().
--
-- Design notes:
--   * Normal is fg_soft on bg_alt — exactly alacritty's primary colours — so
--     the editor sits seamlessly in the terminal. Pure fg is emphasis only.
--   * Floats/popups use bg (the deeper WM ground), chrome (statusline/tabline)
--     too: the editor text plane is bg_alt, everything around it steps back.
--   * Syntax hues are the terminal ANSI palette: keywords blue (== accent),
--     strings green, constants gold, types cyan, special magenta. Both
--     palettes already tuned these per-ground, so light needs no special-casing.
--   * "Pill" = accent bg + accent_text fg, the waybar active-workspace trick.

-- Bootstrap fallback: a fresh clone hasn't run theme-render yet, so the
-- rendered palette may not exist. Mirror palettes/dark.sh (the default theme)
-- rather than erroring out of every nvim start until the first render.
local ok, p = pcall(require, "theme.palette")
if not ok then
  p = {
    background = "dark",
    bg = "#0d0d0d", bg_alt = "#141414", bg_alt2 = "#1a1a1a", bg_sel = "#1c1c1c",
    bg_section = "#202020", bg_hover = "#2e2e2e",
    fg = "#ffffff", fg_soft = "#d4d4d4",
    muted = "#888888", muted_dim = "#6e6e6e", muted_warm = "#aaaaaa", highlight = "#6c6c6c",
    accent = "#5294e2", accent_text = "#0d0d0d", secondary = "#e0a552",
    urgent = "#ff5555", urgent_dark = "#900000", urgent_text = "#ffffff",
    border = "#1f1f1f", border_med = "#444444",
    ansi = {
      black = "#1a1a1a", red = "#ff5555", green = "#6cc08b", yellow = "#e0a552",
      blue = "#5294e2", magenta = "#b48ead", cyan = "#5fb3c4", white = "#d4d4d4",
      bright_black = "#888888", bright_red = "#ff7b7b", bright_green = "#87d0a3",
      bright_yellow = "#ecc07d", bright_blue = "#6ba3e8", bright_magenta = "#c8a0c8",
      bright_cyan = "#7fc8d6", bright_white = "#ffffff",
    },
  }
end

-- Mix hex colours: blend(fg, bg, 0.15) = 15% fg over bg. Used for the soft
-- tinted backgrounds (diff, search, virtual text) the palette has no keys for —
-- deriving them keeps the palette small and the tints correct on both grounds.
local function blend(top, bottom, alpha)
  local tr, tg, tb = top:match("#(%x%x)(%x%x)(%x%x)")
  local br, bg_, bb = bottom:match("#(%x%x)(%x%x)(%x%x)")
  local function mix(a, b)
    return math.floor(tonumber(a, 16) * alpha + tonumber(b, 16) * (1 - alpha) + 0.5)
  end
  return string.format("#%02x%02x%02x", mix(tr, br), mix(tg, bg_), mix(tb, bb))
end

if vim.o.background ~= p.background then
  vim.o.background = p.background -- before colors_name: avoids a re-source loop
end
vim.cmd.highlight("clear")
vim.g.colors_name = "graphite"

local a = p.ansi
-- Derived tints (soft backgrounds on the editor ground)
local sel = blend(p.accent, p.bg_alt, 0.20) -- visual selection: consistent blue wash
local ref = blend(p.accent, p.bg_alt, 0.12) -- LSP references / word under cursor
local add_bg = blend(a.green, p.bg_alt, 0.14)
local del_bg = blend(a.red, p.bg_alt, 0.14)
local chg_bg = blend(a.blue, p.bg_alt, 0.10)
local txt_bg = blend(a.blue, p.bg_alt, 0.28)
local search = blend(p.secondary, p.bg_alt, 0.30)
local faint = blend(p.muted_dim, p.bg_alt, 0.55) -- listchars / eol tildes

-- stylua: ignore
local groups = {
  -- Editor chrome -----------------------------------------------------------
  Normal          = { fg = p.fg_soft, bg = p.bg_alt },
  NormalNC        = { link = "Normal" },
  NormalFloat     = { fg = p.fg_soft, bg = p.bg },
  FloatBorder     = { fg = p.border_med, bg = p.bg },
  FloatTitle      = { fg = p.accent, bg = p.bg, bold = true },
  WinSeparator    = { fg = p.border_med },
  SignColumn      = { fg = p.muted, bg = "NONE" },
  FoldColumn      = { fg = p.muted_dim },
  Folded          = { fg = p.muted, bg = p.bg_alt2, italic = true },
  LineNr          = { fg = p.muted_dim },
  CursorLineNr    = { fg = p.secondary, bold = true },
  CursorLine      = { bg = p.bg_alt2 },
  CursorColumn    = { bg = p.bg_alt2 },
  ColorColumn     = { bg = p.bg_alt2 },
  Cursor          = { fg = p.bg_alt, bg = p.fg },
  TermCursor      = { fg = p.bg_alt, bg = p.fg },
  Visual          = { bg = sel },
  VisualNOS       = { bg = sel },
  Search          = { fg = p.fg, bg = search },
  CurSearch       = { fg = p.accent_text, bg = p.accent, bold = true },
  IncSearch       = { link = "CurSearch" },
  Substitute      = { fg = p.urgent_text, bg = p.urgent_dark },
  MatchParen      = { bg = p.bg_hover, bold = true },
  StatusLine      = { fg = p.muted, bg = p.bg },
  StatusLineNC    = { fg = p.muted_dim, bg = p.bg },
  TabLine         = { fg = p.muted, bg = p.bg },
  TabLineSel      = { fg = p.fg, bg = p.bg_alt, bold = true },
  TabLineFill     = { bg = p.bg },
  WinBar          = { fg = p.fg_soft, bg = "NONE", bold = true },
  WinBarNC        = { fg = p.muted, bg = "NONE" },
  Pmenu           = { fg = p.fg_soft, bg = p.bg },
  PmenuSel        = { fg = p.accent, bg = p.bg_sel },
  PmenuSbar       = { bg = p.bg_alt2 },
  PmenuThumb      = { bg = p.border_med },
  WildMenu        = { link = "PmenuSel" },
  QuickFixLine    = { bg = p.bg_sel },
  Directory       = { fg = p.accent },
  Title           = { fg = p.accent, bold = true },
  ErrorMsg        = { fg = p.urgent },
  WarningMsg      = { fg = p.secondary },
  MoreMsg         = { fg = p.accent },
  ModeMsg         = { fg = p.muted, bold = true },
  Question        = { fg = p.accent },
  NonText         = { fg = faint },
  Whitespace      = { fg = faint },
  SpecialKey      = { fg = faint },
  EndOfBuffer     = { fg = p.bg_alt }, -- hide the ~ column entirely
  Conceal         = { fg = p.muted },
  SpellBad        = { sp = p.urgent, undercurl = true },
  SpellCap        = { sp = p.secondary, undercurl = true },
  SpellLocal      = { sp = a.cyan, undercurl = true },
  SpellRare       = { sp = a.magenta, undercurl = true },

  -- Diff --------------------------------------------------------------------
  DiffAdd         = { bg = add_bg },
  DiffDelete      = { fg = p.muted_dim, bg = del_bg },
  DiffChange      = { bg = chg_bg },
  DiffText        = { bg = txt_bg },
  diffAdded       = { fg = a.green },
  diffRemoved     = { fg = a.red },
  diffChanged     = { fg = a.blue },
  diffFile        = { fg = p.accent },
  diffLine        = { fg = p.muted },
  Added           = { fg = a.green },
  Removed         = { fg = a.red },
  Changed         = { fg = a.blue },

  -- Syntax ------------------------------------------------------------------
  Comment         = { fg = p.muted, italic = true },
  Constant        = { fg = p.secondary },
  String          = { fg = a.green },
  Character       = { fg = a.green },
  Number          = { fg = p.secondary },
  Float           = { fg = p.secondary },
  Boolean         = { fg = p.secondary },
  Identifier      = { fg = p.fg_soft },
  Function        = { fg = p.fg, bold = true },
  Statement       = { fg = p.accent },
  Conditional     = { fg = p.accent },
  Repeat          = { fg = p.accent },
  Label           = { fg = p.accent },
  Operator        = { fg = p.muted_warm },
  Keyword         = { fg = p.accent },
  Exception       = { fg = p.accent },
  PreProc         = { fg = a.magenta },
  Include         = { fg = p.accent },
  Define          = { fg = a.magenta },
  Macro           = { fg = a.magenta },
  PreCondit       = { fg = a.magenta },
  Type            = { fg = a.cyan },
  StorageClass    = { fg = p.accent },
  Structure       = { fg = a.cyan },
  Typedef         = { fg = a.cyan },
  Special         = { fg = a.magenta },
  SpecialChar     = { fg = a.magenta },
  Tag             = { fg = p.accent },
  Delimiter       = { fg = p.muted_warm },
  SpecialComment  = { fg = p.muted, bold = true },
  Debug           = { fg = p.urgent },
  Underlined      = { underline = true },
  Bold            = { bold = true },
  Italic          = { italic = true },
  Error           = { fg = p.urgent },
  Todo            = { fg = p.accent_text, bg = p.accent, bold = true },

  -- Treesitter --------------------------------------------------------------
  ["@variable"]              = { fg = p.fg_soft },
  ["@variable.builtin"]      = { fg = a.magenta, italic = true }, -- self, this
  ["@variable.parameter"]    = { fg = p.fg_soft, italic = true },
  ["@variable.member"]       = { fg = p.fg_soft },
  ["@property"]              = { fg = p.fg_soft },
  ["@field"]                 = { fg = p.fg_soft },
  ["@constant"]              = { fg = p.secondary },
  ["@constant.builtin"]      = { fg = p.secondary, italic = true },
  ["@constant.macro"]        = { fg = a.magenta },
  ["@module"]                = { fg = p.fg_soft },
  ["@string.regexp"]         = { fg = a.magenta },
  ["@string.escape"]         = { fg = a.magenta },
  ["@string.special.url"]    = { fg = p.accent, underline = true },
  ["@function"]              = { fg = p.fg, bold = true },
  ["@function.call"]         = { fg = p.fg }, -- calls plain, definitions bold
  ["@function.builtin"]      = { fg = p.fg },
  ["@function.macro"]        = { fg = a.magenta }, -- println!, vec!
  ["@constructor"]           = { fg = a.cyan },
  ["@keyword.operator"]      = { fg = p.accent },
  ["@keyword.return"]        = { fg = p.accent, italic = true },
  ["@attribute"]             = { fg = a.magenta }, -- #[derive(...)]
  ["@punctuation.delimiter"] = { fg = p.muted_warm },
  ["@punctuation.bracket"]   = { fg = p.muted_warm },
  ["@punctuation.special"]   = { fg = p.accent },
  ["@tag"]                   = { fg = p.accent },
  ["@tag.attribute"]         = { fg = p.secondary },
  ["@tag.delimiter"]         = { fg = p.muted_warm },
  ["@markup.heading.1"]      = { fg = p.accent, bold = true },
  ["@markup.heading.2"]      = { fg = p.secondary, bold = true },
  ["@markup.heading.3"]      = { fg = p.fg, bold = true },
  ["@markup.heading.4"]      = { fg = p.fg, bold = true },
  ["@markup.heading.5"]      = { fg = p.fg_soft, bold = true },
  ["@markup.heading.6"]      = { fg = p.fg_soft, bold = true },
  ["@markup.strong"]         = { bold = true },
  ["@markup.italic"]         = { italic = true },
  ["@markup.strikethrough"]  = { strikethrough = true },
  ["@markup.link"]           = { fg = p.accent },
  ["@markup.link.url"]       = { fg = p.accent, underline = true },
  ["@markup.link.label"]     = { fg = p.accent },
  ["@markup.raw"]            = { fg = p.muted_warm },
  ["@markup.quote"]          = { fg = p.muted, italic = true },
  ["@markup.list"]           = { fg = p.accent },
  ["@markup.list.checked"]   = { fg = a.green },
  ["@markup.list.unchecked"] = { fg = p.muted },

  -- Diagnostics & LSP -------------------------------------------------------
  DiagnosticError            = { fg = p.urgent },
  DiagnosticWarn             = { fg = p.secondary },
  DiagnosticInfo             = { fg = p.accent },
  DiagnosticHint             = { fg = p.muted },
  DiagnosticOk               = { fg = a.green },
  DiagnosticUnderlineError   = { sp = p.urgent, undercurl = true },
  DiagnosticUnderlineWarn    = { sp = p.secondary, undercurl = true },
  DiagnosticUnderlineInfo    = { sp = p.accent, undercurl = true },
  DiagnosticUnderlineHint    = { sp = p.muted, undercurl = true },
  DiagnosticVirtualTextError = { fg = p.urgent, bg = blend(p.urgent, p.bg_alt, 0.10) },
  DiagnosticVirtualTextWarn  = { fg = p.secondary, bg = blend(p.secondary, p.bg_alt, 0.10) },
  DiagnosticVirtualTextInfo  = { fg = p.accent, bg = blend(p.accent, p.bg_alt, 0.10) },
  DiagnosticVirtualTextHint  = { fg = p.muted, bg = blend(p.muted, p.bg_alt, 0.10) },
  DiagnosticUnnecessary      = { fg = p.muted_dim },
  LspReferenceText           = { bg = ref },
  LspReferenceRead           = { bg = ref },
  LspReferenceWrite          = { bg = ref, underline = true },
  LspInlayHint               = { fg = p.muted_dim, italic = true },
  LspCodeLens                = { fg = p.muted_dim },
  LspSignatureActiveParameter = { fg = p.accent, bold = true },

  -- Plugins: lazy.nvim ------------------------------------------------------
  LazyH1           = { fg = p.accent_text, bg = p.accent, bold = true },
  LazyButton       = { fg = p.fg_soft, bg = p.bg_section },
  LazyButtonActive = { fg = p.accent_text, bg = p.accent, bold = true },
  LazySpecial      = { fg = p.accent },
  LazyProp         = { fg = p.muted },
  LazyReasonPlugin = { fg = p.secondary },
  LazyReasonEvent  = { fg = p.secondary },

  -- Plugins: blink.cmp ------------------------------------------------------
  BlinkCmpMenu           = { link = "Pmenu" },
  BlinkCmpMenuBorder     = { link = "FloatBorder" },
  BlinkCmpMenuSelection  = { link = "PmenuSel" },
  BlinkCmpLabelMatch     = { fg = p.accent, bold = true },
  BlinkCmpLabelDetail    = { fg = p.muted },
  BlinkCmpLabelDescription = { fg = p.muted },
  BlinkCmpSource         = { fg = p.muted_dim },
  BlinkCmpDoc            = { link = "NormalFloat" },
  BlinkCmpDocBorder      = { link = "FloatBorder" },
  BlinkCmpGhostText      = { fg = p.muted_dim, italic = true },

  -- Plugins: snacks ---------------------------------------------------------
  SnacksIndent             = { fg = p.border },
  SnacksIndentScope        = { fg = p.highlight },
  SnacksPickerMatch        = { fg = p.accent, bold = true },
  SnacksPickerDir          = { fg = p.muted },
  SnacksPickerPrompt       = { fg = p.accent, bold = true },
  SnacksPickerTitle        = { link = "FloatTitle" },
  SnacksPickerListCursorLine = { bg = p.bg_sel },
  SnacksDashboardHeader    = { fg = p.accent },
  SnacksDashboardIcon      = { fg = p.accent },
  SnacksDashboardKey       = { fg = p.secondary, bold = true },
  SnacksDashboardDesc      = { fg = p.fg_soft },
  SnacksDashboardSpecial   = { fg = p.secondary },
  SnacksDashboardFooter    = { fg = p.muted },
  SnacksDashboardDir       = { fg = p.muted },
  SnacksNotifierInfo       = { fg = p.fg_soft, bg = p.bg },
  SnacksNotifierWarn       = { fg = p.fg_soft, bg = p.bg },
  SnacksNotifierError      = { fg = p.fg_soft, bg = p.bg },
  SnacksNotifierBorderInfo  = { fg = p.accent, bg = p.bg },
  SnacksNotifierBorderWarn  = { fg = p.secondary, bg = p.bg },
  SnacksNotifierBorderError = { fg = p.urgent, bg = p.bg },
  SnacksNotifierTitleInfo   = { fg = p.accent, bold = true },
  SnacksNotifierTitleWarn   = { fg = p.secondary, bold = true },
  SnacksNotifierTitleError  = { fg = p.urgent, bold = true },
  SnacksNotifierIconInfo    = { fg = p.accent },
  SnacksNotifierIconWarn    = { fg = p.secondary },
  SnacksNotifierIconError   = { fg = p.urgent },

  -- Plugins: noice / which-key / flash --------------------------------------
  NoiceCmdlineIcon        = { fg = p.accent },
  NoiceCmdlinePopupBorder = { fg = p.border_med },
  NoiceCmdlinePopupTitle  = { fg = p.accent, bold = true },
  NoiceVirtualText        = { fg = p.muted_dim },
  WhichKey          = { fg = p.accent, bold = true },
  WhichKeyGroup     = { fg = p.secondary },
  WhichKeyDesc      = { fg = p.fg_soft },
  WhichKeySeparator = { fg = p.muted_dim },
  WhichKeyNormal    = { link = "NormalFloat" },
  FlashLabel        = { fg = p.bg, bg = p.secondary, bold = true },
  FlashMatch        = { bg = sel },
  FlashCurrent      = { fg = p.accent_text, bg = p.accent },
  FlashBackdrop     = { fg = p.muted_dim },

  -- Plugins: gitsigns / trouble / grug-far / todo-comments ------------------
  GitSignsAdd          = { fg = a.green },
  GitSignsChange       = { fg = a.blue },
  GitSignsDelete       = { fg = a.red },
  GitSignsCurrentLineBlame = { fg = p.muted_dim, italic = true },
  TroubleNormal        = { link = "Normal" },
  TroubleCount         = { fg = p.secondary, bold = true },
  GrugFarResultsMatch  = { fg = p.accent_text, bg = p.accent },

  -- Plugins: dap ------------------------------------------------------------
  DapBreakpoint     = { fg = p.urgent },
  DapBreakpointCondition = { fg = p.secondary },
  DapLogPoint       = { fg = p.accent },
  DapStopped        = { fg = a.green },
  DapStoppedLine    = { bg = add_bg },

  -- Plugins: mini.icons — retint the fixed default hues to the palette so
  -- picker/statusline icons carry the same six colours as everything else.
  MiniIconsAzure  = { fg = a.bright_blue },
  MiniIconsBlue   = { fg = a.blue },
  MiniIconsCyan   = { fg = a.cyan },
  MiniIconsGreen  = { fg = a.green },
  MiniIconsGrey   = { fg = p.muted },
  MiniIconsOrange = { fg = p.secondary },
  MiniIconsPurple = { fg = a.magenta },
  MiniIconsRed    = { fg = a.red },
  MiniIconsYellow = { fg = a.yellow },
}

for name, def in pairs(groups) do
  vim.api.nvim_set_hl(0, name, def)
end

-- :terminal — same ANSI 16 the palette gives alacritty.
local term = {
  a.black, a.red, a.green, a.yellow, a.blue, a.magenta, a.cyan, a.white,
  a.bright_black, a.bright_red, a.bright_green, a.bright_yellow,
  a.bright_blue, a.bright_magenta, a.bright_cyan, a.bright_white,
}
for i, c in ipairs(term) do
  vim.g["terminal_color_" .. (i - 1)] = c
end
