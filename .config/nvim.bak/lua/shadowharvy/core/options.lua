local opt = vim.opt -- Shorthand for vim.opt, used to set options.
local o = vim.o   -- Shorthand for vim.o, an older way to set options. It's recommended to use `opt`.
local g = vim.g   -- Shorthand for vim.g, used to set global variables.

-- Merge existing options
vim.cmd("let g:netrw_liststyle = 3") -- Sets the list style of netrw (Neovim's built-in file explorer) to a tree-like view.

opt.relativenumber = true -- Shows relative line numbers, making it easier to navigate with j and k.
opt.number = true           -- Shows absolute line numbers.

-- tabs & indentation
opt.tabstop = 2       -- Sets the number of spaces a tab character represents.
opt.shiftwidth = 2    -- Sets the number of spaces used for auto-indentation.
opt.expandtab = true  -- Converts tabs to spaces.
opt.autoindent = true -- Copies the indentation from the previous line when starting a new line.

opt.wrap = true       -- Enables line wrapping.

-- search settings
opt.ignorecase = true -- Makes searches case-insensitive.
opt.smartcase = true  -- Makes searches case-sensitive if you include uppercase letters.

opt.cursorline = true -- Highlights the line where the cursor is.

opt.termguicolors = true -- Enables true color support in the terminal.
opt.background = "dark"  -- Sets the background color to dark, affecting colorschemes.
opt.signcolumn = "yes"  -- Always shows the sign column, preventing text from shifting.

opt.backspace = "indent,eol,start" -- Allows backspace to delete indent, end-of-line characters, and characters at the start of insert mode.

opt.clipboard:append("unnamedplus") -- Uses the system clipboard as the default register.

opt.splitright = true -- Splits new vertical windows to the right.
opt.splitbelow = true -- Splits new horizontal windows to the bottom.

opt.swapfile = false -- Disables the creation of swap files.

-- Merge new options
o.laststatus = 3       -- Always shows the statusline, even with only one window.
o.showmode = false      -- Hides the mode indicator (e.g., -- INSERT --).

o.clipboard = "unnamedplus" -- Already set, no conflict
o.cursorline = true     -- Already set, no conflict
o.cursorlineopt = "number" -- Highlights the line number along with the cursor line.

-- Indenting (already set, but verify consistency)
o.expandtab = true  -- Already set, no conflict
o.shiftwidth = 2   -- Already set, no conflict
o.smartindent = true -- Enables smart indentation, automatically adjusting indentation based on context.
o.tabstop = 2       -- Already set, no conflict
o.softtabstop = 2    -- Sets the number of spaces used for backspacing over tabs.

opt.fillchars = { eob = " " } -- Sets the fill character for the end-of-buffer to a space.
o.ignorecase = true -- Already set, no conflict
o.smartcase = true  -- Already set, no conflict
o.mouse = "a"       -- Enables mouse support in all modes.

-- Numbers (already set, but verify consistency)
o.number = true      -- Already set, no conflict
o.numberwidth = 2   -- Sets the width of the line number column to 2 characters.
o.ruler = false      -- Disables the ruler at the bottom of the window.

-- disable nvim intro
opt.shortmess:append "sI" -- Suppresses the startup message and intro screen.

o.signcolumn = "yes"  -- Already set, no conflict
o.splitbelow = true -- Already set, no conflict
o.splitright = true -- Already set, no conflict
o.timeoutlen = 400 -- Sets the timeout for key sequences to 400 milliseconds.
o.undofile = true   -- Enables persistent undo.

-- interval for writing swap file to disk, also used by gitsigns
o.updatetime = 250 -- Sets the interval for writing swap files and updating signs to 250 milliseconds.

-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
opt.whichwrap:append "<>[]hl" -- Allows cursor movement across line boundaries with h, l, and arrow keys.

-- disable some default providers
g.loaded_node_provider = 0    -- Disables the Node.js provider.
g.loaded_python3_provider = 0 -- Disables the Python 3 provider.
g.loaded_perl_provider = 0    -- Disables the Perl provider.
g.loaded_ruby_provider = 0    -- Disables the Ruby provider.

-- add binaries installed by mason.nvim to path
local is_windows = vim.fn.has "win32" ~= 0 -- Checks if the operating system is Windows.
local sep = is_windows and "\\" or "/" -- Sets the path separator based on the operating system.
local delim = is_windows and ";" or ":" -- Sets the path delimiter based on the operating system.
vim.env.PATH = table.concat({ vim.fn.stdpath "data", "mason", "bin" }, sep) .. delim .. vim.env.PATH -- Appends the Mason binary directory to the system PATH.
