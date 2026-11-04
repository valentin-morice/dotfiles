-- The lang.clangd extra would have Mason download its own clangd. Use the one
-- from pacman's `clang` package instead, so it updates with the rest of the system.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = { mason = false },
      },
    },
  },
}
