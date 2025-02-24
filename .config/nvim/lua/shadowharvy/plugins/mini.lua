return {
  "echasnovski/mini.nvim",
  --event = { "BufReadPre", "BufNewFile" },
  version = "false", -- Use for stability; omit to use `main` branch for the latest features
  config = function()
    require("mini").setup()
  end,
}