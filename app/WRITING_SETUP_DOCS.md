# Novel Writing Environment Setup

This is your complete guide to the novel writing environment setup. Everything has been configured for distraction-free, productive writing with modern tools.

## 🚀 Quick Start

### 1. Install Required Packages

First, install the document conversion tools:

```bash
sudo pacman -S pandoc wkhtmltopdf texlive-core languagetool vale --needed
```

### 2. Create Your First Novel Project

```bash
init_novel.sh "My Amazing Novel"
cd my_amazing_novel
```

### 3. Start Writing

```bash
# Create your first chapter
new_chapter.sh "Chapter 1: The Beginning"

# Check word count anytime
make wordcount

# Generate PDF when ready
make pdf
```

## 📁 Project Structure

When you create a new novel project, you get this structure:

```
my_amazing_novel/
├── chapters/           # Your main manuscript chapters
├── drafts/            # Working drafts and experiments
├── notes/             # Character notes, world building, plots
├── research/          # Reference materials
├── output/            # Generated PDFs, DOCX, HTML files
├── scripts/           # Automation scripts (auto-generated)
├── templates/         # Document templates
├── .backup/           # Automatic backups
├── README.md          # Project information and progress
├── Makefile          # Build commands
└── .gitignore        # Git ignore rules
```

## 🛠️ Available Commands

### Project Management

- `init_novel.sh "Title"` - Create a new novel project
- `new_chapter.sh "Chapter Title"` - Create a new chapter with template
- `wc.sh` - Accurate word count for current project
- `backup.sh` - Create timestamped backup of your project

### Document Generation

- `make wordcount` - Show detailed word count breakdown
- `make pdf` - Generate PDF manuscript
- `make docx` - Generate Word document
- `make html` - Generate HTML version
- `make clean` - Remove generated files

### Backup and Safety

- `make backup` - Quick backup
- `backup.sh --include-git` - Backup with full git history
- `backup.sh --compress-only` - Create compressed archive only

## 🎯 Neovim Writing Features

### Zen Mode for Distraction-Free Writing

- `<leader>zz` - Toggle Zen Mode (fullscreen, minimal UI)
- `<leader>zw` - Toggle Zen Mode + Twilight (dims inactive text)
- `<leader>zt` - Toggle Twilight only

### Markdown Writing Shortcuts

When editing `.md` files:

- `<leader>mb` - **Bold** current word
- `<leader>mi` - *Italic* current word
- `<leader>m1` to `<leader>m4` - Create headers (# ## ### ####)
- `<leader>mw` - Show word count for current file

### Visual Selection Shortcuts

- `<leader>mb` - **Bold** selected text
- `<leader>mi` - *Italic* selected text

### Navigation for Long Documents

- `j/k` - Move by display lines (not actual lines)
- `0/$` - Go to start/end of display line
- `zM` - Fold all sections
- `zR` - Unfold all sections

### ASCII Diagrams and Planning

- `<leader>zv` - Toggle Venn mode for drawing character charts, plot diagrams
- `<leader>zc` - Open calendar for scheduling

## 📊 Word Count and Progress Tracking

### Built-in Word Count

The setup includes multiple ways to track your progress:

1. **Live count in statusline** (when editing markdown files)
2. **Detailed project analysis**: `make wordcount` or `wc.sh`
3. **Progress toward goals** (set in README.md)

### Setting Up Goals

Edit your project's `README.md` and set:

```markdown
- **Target Length:** 80000 words
- **Daily goal:** 500 words
```

The word count scripts will automatically calculate your progress percentage.

## 🔧 Advanced Features

### Auto-save

Your writing is automatically saved:
- When you leave insert mode
- When text changes (after 135ms delay)
- Only for markdown/text files

### Spell Check

Automatic spell checking is enabled for all writing files:
- Red underlines for misspelled words
- `z=` to see spelling suggestions
- `zg` to add word to dictionary
- `zw` to mark word as wrong

### Grammar and Style (Optional)

If you installed `vale` and `languagetool`:

- Grammar checking integrated with Neovim
- Style suggestions for better prose
- Configurable rules for fiction writing

## 🔄 Daily Workflow

### Recommended Daily Routine

1. **Start your writing session**:
   ```bash
   cd my_novel_project
   nvim chapters/current_chapter.md
   ```

2. **Enter focus mode**:
   - Press `<leader>zw` for distraction-free writing

3. **Write your daily goal**:
   - Word count shows live in status bar
   - Use `<leader>mw` to check progress

4. **Track progress**:
   ```bash
   make wordcount  # See detailed breakdown
   git add .
   git commit -m "Daily writing: added XXX words"
   ```

5. **Backup regularly**:
   ```bash
   make backup  # Quick backup
   ```

### Weekly Tasks

- `make pdf` - Generate a PDF to review your progress
- `backup.sh --include-git --compress-only` - Create comprehensive backup
- Review and update your notes and character development

## 🎨 Customization

### Zen Mode Settings

Edit `~/.config/nvim/lua/plugins/writing.lua` to customize:
- Window width (default: 80 columns)
- Background dimming
- Which UI elements to hide

### Adding New Document Templates

Create templates in your project's `templates/` directory:
- `chapter_template.md` - Custom chapter format
- `character_sheet.md` - Character development template
- `scene_outline.md` - Scene planning template

## 🔍 Troubleshooting

### Word Count Issues

If word counts seem inaccurate:
```bash
# Install pandoc for accurate counting
sudo pacman -S pandoc

# Test word count
wc.sh chapters/chapter_01.md
```

### Neovim Plugin Issues

If writing plugins don't load:
```bash
# Update plugins
nvim --headless "+Lazy! sync" +qa

# Check for errors
nvim --headless "+checkhealth" +qa
```

### Git Integration

If git commands fail in project:
```bash
# Initialize git repository
git init
git add .
git commit -m "Initial commit"
```

## 📚 Additional Resources

### Writing Productivity Tips

1. **Set daily word count goals** and track them
2. **Use Zen mode** to eliminate distractions
3. **Write first, edit later** - don't get stuck on perfection
4. **Backup regularly** - your work is precious
5. **Use chapter templates** to maintain consistency

### Keyboard Shortcuts Summary

| Shortcut | Action |
|----------|--------|
| `<leader>zw` | Zen + Twilight mode |
| `<leader>zz` | Zen mode only |
| `<leader>mb` | Bold word/selection |
| `<leader>mi` | Italic word/selection |
| `<leader>m1-4` | Insert header |
| `<leader>mw` | Word count |
| `<leader>zv` | ASCII diagram mode |
| `<leader>zc` | Calendar |

### File Organization Tips

- **chapters/**: Number your chapters (01_chapter_name.md)
- **notes/**: Separate files for characters, world-building, plot
- **research/**: PDFs, images, reference materials
- **drafts/**: Experimental scenes, alternate versions

---

## 🎉 You're All Set!

Your complete novel writing environment is now ready. Start with:

```bash
init_novel.sh "Your Novel Title"
```

Happy writing! 📝✨
