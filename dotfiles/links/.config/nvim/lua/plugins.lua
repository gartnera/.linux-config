return {
  -- Better syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- master is locked to Nvim 0.11; main is the rewrite for 0.12+
    lazy = false, -- main branch does not support lazy-loading
    build = ":TSUpdate",
    config = function()
      -- Install parsers (async; no-op if already present). markdown_inline is
      -- used via injection to highlight code fences inside markdown.
      require("nvim-treesitter").install({
        "lua", "vim", "vimdoc", "bash", "python", "markdown", "markdown_inline",
        -- languages we work in
        "c", "cpp", "go", "gomod", "gosum", "gowork", "proto",
        "typescript", "tsx", "javascript", "json", "yaml",
      })

      -- On main, highlighting/indent are enabled per-buffer, not via setup().
      vim.api.nvim_create_autocmd("FileType", {
        -- filetypes, not parser names: vimdoc->help, bash->sh/bash,
        -- tsx->typescriptreact, jsx handled by the javascript parser
        pattern = {
          "lua", "vim", "help", "sh", "bash", "python", "markdown",
          "c", "cpp", "go", "gomod", "gosum", "gowork", "proto",
          "typescript", "typescriptreact", "javascript", "javascriptreact",
          "json", "yaml",
        },
        callback = function()
          pcall(vim.treesitter.start)
          -- treesitter indentation is experimental; drop this line to fall back
          -- to smartindent if it misbehaves.
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help" })
    end,
  },
  -- shows keymap when leader keys presed
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },
  -- autodetect indent
  { "tpope/vim-sleuth" },
  -- better status bar
  { "nvim-lualine/lualine.nvim", opts = {} },
}
