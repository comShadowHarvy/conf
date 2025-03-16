vim.g.mapleader = " " -- Sets the leader key to space. The leader key is used in combination with other keys to trigger custom commands.

local keymap = vim.keymap -- For conciseness, creates a shorter alias for `vim.keymap`.
local map = vim.keymap.set -- Even shorter alias for vim.keymap.set

-- Insert mode mappings
map("i", "<C-b>", "<ESC>^i", { desc = "Move to beginning of line" }) -- Moves the cursor to the beginning of the line in insert mode.
map("i", "<C-e>", "<End>", { desc = "Move to end of line" }) -- Moves the cursor to the end of the line in insert mode.
map("i", "<C-h>", "<Left>", { desc = "Move left" }) -- Moves the cursor one character to the left in insert mode.
map("i", "<C-l>", "<Right>", { desc = "Move right" }) -- Moves the cursor one character to the right in insert mode.
map("i", "<C-j>", "<Down>", { desc = "Move down" }) -- Moves the cursor down one line in insert mode.
map("i", "<C-k>", "<Up>", { desc = "Move up" }) -- Moves the cursor up one line in insert mode.
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" }) -- Exits insert mode by pressing 'j' then 'k' quickly.

-- Normal mode mappings
map("n", "<C-h>", "<C-w>h", { desc = "Switch window left" }) -- Switches focus to the window on the left.
map("n", "<C-l>", "<C-w>l", { desc = "Switch window right" }) -- Switches focus to the window on the right.
map("n", "<C-j>", "<C-w>j", { desc = "Switch window down" }) -- Switches focus to the window below.
map("n", "<C-k>", "<C-w>k", { desc = "Switch window up" }) -- Switches focus to the window above.

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" }) -- Clears search highlights.
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "General clear highlights" }) -- General clear highlights (same as above, but uses <Esc> as the keybind instead of <leader>nh).

map("n", "<C-s>", "<cmd>w<CR>", { desc = "General save file" }) -- Saves the current file.
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "General copy whole file" }) -- Copies the entire content of the current file to the system clipboard.

keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- Increments the number under the cursor.
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- Decrements the number under the cursor.

keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- Splits the current window vertically.
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- Splits the current window horizontally.
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- Makes all split windows equal in size.
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- Closes the current split window.

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- Opens a new tab.
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- Closes the current tab.
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) -- Navigates to the next tab.
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) -- Navigates to the previous tab.
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) -- Moves the current buffer to a new tab.

map("n", "<leader>n", "<cmd>set nu!<CR>", { desc = "Toggle line number" }) -- Toggles line numbers.
map("n", "<leader>rn", "<cmd>set rnu!<CR>", { desc = "Toggle relative number" }) -- Toggles relative line numbers.
map("n", "<leader>ch", "<cmd>NvCheatsheet<CR>", { desc = "Toggle nvcheatsheet" }) -- Toggles the NvCheatsheet plugin.

map("n", "<leader>fm", function()
require("conform").format { lsp_fallback = true }
end, { desc = "General format file" }) -- Formats the current file using the 'conform' plugin.

-- Global LSP mappings
map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "LSP diagnostic loclist" }) -- Opens the location list with LSP diagnostics.

-- Tabufline
map("n", "<leader>b", "<cmd>enew<CR>", { desc = "Buffer new" }) -- Creates a new, empty buffer.

map("n", "<tab>", function()
require("nvchad.tabufline").next()
end, { desc = "Buffer goto next" }) -- Navigates to the next buffer using the 'nvchad.tabufline' plugin.

map("n", "<S-tab>", function()
require("nvchad.tabufline").prev()
end, { desc = "Buffer goto prev" }) -- Navigates to the previous buffer using the 'nvchad.tabufline' plugin.

map("n", "<leader>x", function()
require("nvchad.tabufline").close_buffer()
end, { desc = "Buffer close" }) -- Closes the current buffer using the 'nvchad.tabufline' plugin.

-- Comment
map("n", "<leader>/", "gcc", { desc = "Toggle comment", remap = true }) -- Toggles comments on the current line.
map("v", "<leader>/", "gc", { desc = "Toggle comment", remap = true }) -- Toggles comments on the selected lines in visual mode.

-- Nvimtree
map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "Nvimtree toggle window" }) -- Toggles the NvimTree file explorer.
map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "Nvimtree focus window" }) -- Gives focus to the NvimTree window.

-- Telescope
map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "Telescope live grep" }) -- Opens Telescope to search for a string in the project.
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Telescope find buffers" }) -- Opens Telescope to list open buffers.
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Telescope help page" }) -- Opens Telescope to search for help topics.
map("n", "<leader>ma", "<cmd>Telescope marks<CR>", { desc = "Telescope find marks" }) -- Opens Telescope to list marks.
map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", { desc = "Telescope find oldfiles" }) -- Opens Telescope to list recently opened files.
map("n", "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "Telescope find in current buffer" }) -- Opens Telescope to search within the current buffer.
map("n", "<leader>cm", "<cmd>Telescope git_commits<CR>", { desc = "Telescope git commits" }) -- Opens Telescope to list Git commits.
map("n", "<leader>gt", "<cmd>Telescope git_status<CR>", { desc = "Telescope git status" }) -- Opens Telescope to show the Git status.
map("n", "<leader>pt", "<cmd>Telescope terms<CR>", { desc = "Telescope pick hidden term" }) -- Opens Telescope to pick a hidden terminal.

map("n", "<leader>th", function()
require("nvchad.themes").open()
end, { desc = "Telescope nvchad themes" }) -- Opens Telescope to select an NvChad theme.

map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Telescope find files" }) -- Opens Telescope to find files in the project.
map(
    "n",
    "<leader>fa",
    "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
    { desc = "Telescope find all files" }
) -- Opens Telescope to find all files in the project, including hidden and ignored files.

-- Terminal
map("t", "<C-x>", "<C-\\><C-N>", { desc = "Terminal escape terminal mode" }) -- Exits terminal mode.

-- New terminals
map("n", "<leader>h", function()
require("nvchad.term").new { pos = "sp" }
end, { desc = "Terminal new horizontal term" }) -- Opens a new terminal in a horizontal split.

map("n", "<leader>v", function()
require("nvchad.term").new { pos = "vsp" }
end, { desc = "Terminal new vertical term" }) -- Opens a new terminal in a vertical split.

-- Toggleable terminals
map({ "n", "t" }, "<A-v>", function()
require("nvchad.term").toggle { pos = "vsp", id = "vtoggleTerm" }
end, { desc = "Terminal toggleable vertical term" }) -- Toggles a vertical terminal.

map({ "n", "t" }, "<A-h>", function()
require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm" }
end, { desc = "Terminal toggleable horizontal term" }) -- Toggles a horizontal terminal.

map({ "n", "t" }, "<A-i>", function()
require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "Terminal toggle floating term" }) -- Toggles a floating terminal.

-- WhichKey
map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "WhichKey all keymaps" }) -- Opens WhichKey to show all keymaps.

map("n", "<leader>wk", function()
vim.cmd("WhichKey " .. vim.fn.input "WhichKey: ")
end, { desc = "WhichKey query lookup" }) -- Opens WhichKey to search for a specific keymap.
