-- In your plugins.lua or init.lua where you define your plugins
return {
  {
    "github/copilot.vim",
    lazy = false, -- Make sure Copilot starts with Neovim
    config = function()
      -- Basic configuration
      vim.g.copilot_no_tab_map = true -- Disable tab mapping
      vim.g.copilot_assume_mapped = true
      vim.g.copilot_tab_fallback = ""

      -- Set up custom keymapping (optional)
      vim.api.nvim_set_keymap("i", "<C-j>", 'copilot#Accept("<CR>")', { silent = true, expr = true })

      -- Additional configuration options
      -- vim.g.copilot_filetypes = { ["*"] = true } -- Enable for all filetypes
      -- vim.g.copilot_filetypes = { ["markdown"] = false } -- Disable for markdown
    end,
  },
}
