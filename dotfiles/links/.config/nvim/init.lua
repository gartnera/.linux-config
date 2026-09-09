-- UI
vim.opt.number = true            -- line numbers
vim.opt.cursorline = true        -- highlight current line
vim.opt.termguicolors = false     -- 24-bit color (turn off if matching terminal palette)
vim.opt.scrolloff = 8            -- keep 8 lines visible above/below cursor
vim.opt.wrap = false

-- Indentation
vim.opt.expandtab = true         -- spaces instead of tabs
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.smartindent = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true         -- case-sensitive only if you type a capital
vim.opt.incsearch = true
vim.opt.hlsearch = true

-- Behavior
vim.opt.mouse = ""               -- mouse disabled entirely
vim.opt.undofile = true          -- persistent undo across sessions
vim.opt.swapfile = false
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.updatetime = 250

-- Clear search highlight with Esc
vim.keymap.set("n", "<Esc>", ":nohlsearch<CR>", { silent = true })

-- leader is space key
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set("n", "<Space>", "<Nop>", { silent = true })

-- ── Bootstrap lazy.nvim ──────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ── Plugins (loaded from lua/plugins.lua) ────────────────
require("lazy").setup(require("plugins"), {
  install = { colorscheme = { "default" } },
})
