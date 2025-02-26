return {
    "echasnovski/mini.nvim",
    version = false, -- Use 'false' to always get the latest commit, or pin a specific commit/tag
    config = function()
        -- Setup each module individually without requiring 'mini' directly.

        -- Modules with setup function
        local status_ok, animate = pcall(require, "mini.animate")
        if status_ok then
            animate.setup()
        end

        local status_ok, basics = pcall(require, "mini.basics")
        if status_ok then
            basics.setup()
        end

        local status_ok, bracketed = pcall(require, "mini.bracketed")
        if status_ok then
            bracketed.setup()
        end
        
        local status_ok, clue = pcall(require, "mini.clue")
        if status_ok then
            clue.setup()
        end

        local status_ok, colors = pcall(require, "mini.colors")
        if status_ok then
            colors.setup()
        end

        local status_ok, comment = pcall(require, "mini.comment")
        if status_ok then
            comment.setup()
        end

        local status_ok, cursorword = pcall(require, "mini.cursorword")
        if status_ok then
            cursorword.setup()
        end

        local status_ok, files = pcall(require, "mini.files")
        if status_ok then
            files.setup()
        end

        local status_ok, jump = pcall(require, "mini.jump")
        if status_ok then
            jump.setup()
        end

        local status_ok, map = pcall(require, "mini.map")
        if status_ok then
            map.setup()
        end

        local status_ok, move = pcall(require, "mini.move")
        if status_ok then
            move.setup()
        end

        local status_ok, operators = pcall(require, "mini.operators")
        if status_ok then
            operators.setup()
        end

        local status_ok, pairs = pcall(require, "mini.pairs")
        if status_ok then
            pairs.setup()
        end

        local status_ok, pick = pcall(require, "mini.pick")
        if status_ok then
            pick.setup()
        end

        local status_ok, sessions = pcall(require, "mini.sessions")
        if status_ok then
            sessions.setup()
        end

        local status_ok, surround = pcall(require, "mini.surround")
        if status_ok then
            surround.setup()
        end

        local status_ok, tabline = pcall(require, "mini.tabline")
        if status_ok then
            tabline.setup()
        end

        local status_ok, trailspace = pcall(require, "mini.trailspace")
        if status_ok then
            trailspace.setup()
        end
        
        local status_ok, ai = pcall(require, "mini.ai")
        if status_ok then
            ai.setup()
        end

        -- Modules without a setup function:
        -- You would access these directly as needed.
        -- Example:
        -- local status_ok, misc = pcall(require, "mini.misc")
        -- if status_ok then
        --     -- use misc.is_string, or other exported functions.
        --     if misc.is_string("hello") then
        --         print("It's a string!")
        --     end
        -- end
        -- You can also add these in the same pattern, like above.
        -- This is for all the other modules without a setup() function.
        print("All Mini modules loaded!")
    end,
}
