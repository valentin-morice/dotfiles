-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Put Mason's bin dir on PATH up front. Mason itself is lazy-loaded, so tools it
-- manages (tree-sitter, stylua, shfmt) are otherwise invisible until some LSP or
-- :Mason command drags it in -- which makes :TSInstall and :checkhealth fail on a
-- freshly opened editor.
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

-- Disable unused remote-plugin providers. Nothing in this config is written in
-- perl/ruby/python, and leaving them on only buys startup cost and health noise.
-- Drop the relevant line (and `pip install pynvim` / `gem install neovim`) if a
-- plugin ever needs one.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0
