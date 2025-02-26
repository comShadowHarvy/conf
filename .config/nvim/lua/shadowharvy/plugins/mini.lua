return {
  "echasnovski/mini.nvim",
  version = false, -- Use 'false' to always get the latest commit
  config = function()
    -- Remove this line, as it will cause an error:
    -- local mini = require("mini")
    
    -- Set up modules that have a setup function
    require("mini.animate").setup()
    require("mini.basics").setup()
    require("mini.bracketed").setup()
    require("mini.clue").setup()
    require("mini.colors").setup()
    require("mini.comment").setup()
    require("mini.cursorword").setup()
    require("mini.files").setup()
    require("mini.jump").setup()
    require("mini.map").setup()
    require("mini.move").setup()
    require("mini.operators").setup()
    require("mini.pairs").setup()
    require("mini.pick").setup()
    require("mini.sessions").setup()
    require("mini.surround").setup()
    require("mini.tabline").setup()
    require("mini.trailspace").setup()
    require("mini.ai").setup()
    
    print("All Mini modules loaded!")
  end,
}