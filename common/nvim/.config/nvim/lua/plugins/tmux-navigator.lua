-- nvim half of christoomey/vim-tmux-navigator (the tmux half is a TPM plugin in
-- ~/.tmux.conf): C-h/j/k/l move between nvim splits and, at the edge of the
-- editor, on into the neighbouring tmux pane. Loaded on the keys only.
return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Window left (tmux-aware)" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Window down (tmux-aware)" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Window up (tmux-aware)" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Window right (tmux-aware)" },
      { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Previous window (tmux-aware)" },
    },
  },
}
