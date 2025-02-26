return {
    "echasnovski/mini.nvim",
    version = false,  -- Use 'false' to always get the latest commit, or pin a specific commit/tag
    config = function()
        local mini = require("mini")

        -- Example of using all modules (you might want to customize this)
        -- NOTE: Not all modules have a setup function. Those that don't
        -- are usually simple functions that are used directly.
        -- Modules that do not have a .setup() function will be loaded but
        -- won't be configured.

        -- Set up modules that have a setup function.
        require("mini.animate").setup() -- Example
        require("mini.basics").setup()  -- Example
        require("mini.bracketed").setup()
        require("mini.clue").setup() -- Example
        require("mini.colors").setup()
        require("mini.comment").setup()
        require("mini.cursorword").setup()
        require("mini.files").setup() -- Example
        require("mini.jump").setup() -- Example
        require("mini.map").setup() -- Example
        require("mini.move").setup()
        require("mini.operators").setup()
        require("mini.pairs").setup() -- Example
        require("mini.pick").setup()
        require("mini.sessions").setup()
        require("mini.surround").setup()
        require("mini.tabline").setup()
        require("mini.trailspace").setup()
        require("mini.ai").setup()

        -- Optionally use modules that don't have a setup:
        -- These usually export simple functions.
        -- local mini_misc = require("mini.misc")
        -- Example usage:
        -- mini_misc.is_string("hello") -- Returns true
        -- ... other functions from mini.misc ...

        -- Similarly for mini.bufremove etc.
        -- You can check the documentation for what functions each modules expose

        -- Example of configuring a module more specifically
        -- require("mini.cursorword").setup({
        --   use_global_status = true,
        --   cursorword_style = "undercurl",
        -- })
        -- End of optional setup
        print("All Mini modules loaded!")

    end,
}
