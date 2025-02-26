return {
    "echasnovski/mini.nvim",
    version = false,  -- Use 'false' to always get the latest commit, or pin a specific commit/tag
    config = function()
      -- Removed require("mini").setup() as mini.nvim does not have a global setup function.
      require("mini.cursorword").setup()
      require("mini.surround").setup()
      require("mini.comment").setup()
      -- Add additional modules as needed.
    end,
  }
