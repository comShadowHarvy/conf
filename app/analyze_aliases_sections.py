#!/usr/bin/env python3
"""
Analyze .aliases file and categorize sections for modular splitting.
This extends the existing analyze_shell_config.py functionality.
"""

import re
import json
from pathlib import Path
from typing import Dict, List, Tuple, NamedTuple

class Section(NamedTuple):
    name: str
    start_line: int
    end_line: int
    priority: int  # Load order priority (0 = highest)
    depends: List[str]
    load_condition: str
    content: List[str]

def analyze_aliases_file(aliases_path: Path) -> Dict[str, Section]:
    """Analyze .aliases file and return categorized sections."""
    
    with open(aliases_path, 'r') as f:
        lines = f.readlines()
    
    sections = {}
    current_section = None
    section_start = 0
    
    # Section patterns and their mappings
    section_patterns = {
        r'General & Navigation': ('00-core', 0, [], 'always'),
        r'File & Directory Management': ('10-files', 1, [], 'always'),
        r'Yazi File Manager': ('15-yazi', 2, ['yazi'], '(( ${+commands[yazi]} ))'),
        r'System Management': ('20-system', 3, [], 'always'),
        r'Package Management.*CachyOS': ('30-package', 4, ['pacman'], '(( ${+commands[pacman]} || ${+commands[brew]} ))'),
        r'Media & Downloads': ('40-media', 5, ['youtube-dl', 'yt-dlp'], '(( ${+commands[yt-dlp]} || ${+commands[youtube-dl]} ))'),
        r'Git & Development': ('50-git', 6, ['git'], '(( ${+commands[git]} ))'),
        r'Tmux Shortcuts': ('55-tmux', 7, ['tmux'], '(( ${+commands[tmux]} ))'),
        r'Shell, Apps.*Custom Commands': ('60-apps', 8, [], 'always'),
        r'AI/Ollama Tools': ('65-ai', 9, ['ollama'], '(( ${+commands[ollama]} ))'),
        r'Productivity.*Advanced': ('70-productivity', 10, [], 'always'),
        r'Modern CLI Tool Shortcuts': ('75-modern', 11, ['fd', 'rg', 'bat'], 'always'),
        r'CachyOS.*Performance': ('80-performance', 12, [], 'always'),
        r'Enhanced Development': ('85-development', 13, ['nvim'], '(( ${+commands[nvim]} ))'),
        r'Modern File Operations': ('90-operations', 14, [], 'always'),
        r'AUR-Safe.*Aliases': ('95-aur-safe', 15, [], 'always'),
    }
    
    # Find section boundaries
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        
        # Look for section headers
        if line.startswith('#') and any(re.search(pattern, line, re.IGNORECASE) for pattern in section_patterns.keys()):
            # Found a section header
            if current_section:
                # End previous section
                sections[current_section[0]] = Section(
                    name=current_section[0],
                    start_line=section_start,
                    end_line=i-1,
                    priority=current_section[1],
                    depends=current_section[2],
                    load_condition=current_section[3],
                    content=lines[section_start:i]
                )
            
            # Find matching pattern
            for pattern, (name, priority, depends, condition) in section_patterns.items():
                if re.search(pattern, line, re.IGNORECASE):
                    current_section = (name, priority, depends, condition)
                    section_start = i
                    break
        
        i += 1
    
    # Handle final section
    if current_section:
        sections[current_section[0]] = Section(
            name=current_section[0],
            start_line=section_start,
            end_line=len(lines)-1,
            priority=current_section[1],
            depends=current_section[2],
            load_condition=current_section[3],
            content=lines[section_start:]
        )
    
    # Handle content without clear section headers
    if not sections:
        # Fallback: create sections based on content analysis
        sections = analyze_by_content_heuristics(lines)
    
    return sections

def analyze_by_content_heuristics(lines: List[str]) -> Dict[str, Section]:
    """Fallback analysis using content patterns when headers are unclear."""
    
    sections = {}
    current_content = []
    current_name = '00-core'
    start_line = 0
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        # Skip comments and empty lines for analysis
        if not stripped or stripped.startswith('#'):
            current_content.append(line)
            continue
            
        # Heuristics for section detection
        if any(keyword in stripped for keyword in ['git ', 'gh ', 'gst', 'gco']):
            if current_name != '50-git':
                # Switch to git section
                if current_content:
                    sections[current_name] = Section(current_name, start_line, i-1, 0, [], 'always', current_content)
                current_name = '50-git'
                current_content = []
                start_line = i
        elif any(keyword in stripped for keyword in ['pacman', 'paru', 'yay', 'makepkg']):
            if current_name != '30-package':
                if current_content:
                    sections[current_name] = Section(current_name, start_line, i-1, 0, [], 'always', current_content)
                current_name = '30-package'
                current_content = []
                start_line = i
        elif any(keyword in stripped for keyword in ['systemd', 'journal', 'service']):
            if current_name != '20-system':
                if current_content:
                    sections[current_name] = Section(current_name, start_line, i-1, 0, [], 'always', current_content)
                current_name = '20-system'
                current_content = []
                start_line = i
        
        current_content.append(line)
    
    # Add final section
    if current_content:
        sections[current_name] = Section(current_name, start_line, len(lines)-1, 0, [], 'always', current_content)
    
    return sections

def main():
    """Main analysis function."""
    aliases_path = Path('/home/me/git/conf/.aliases')
    
    if not aliases_path.exists():
        print(f"Error: {aliases_path} not found")
        return
    
    print("🔍 Analyzing .aliases file structure...")
    sections = analyze_aliases_file(aliases_path)
    
    # Create output directory
    output_dir = Path('/home/me/git/conf/analysis')
    output_dir.mkdir(exist_ok=True)
    
    # Convert sections to JSON-serializable format
    sections_json = {}
    for name, section in sections.items():
        sections_json[name] = {
            'start_line': section.start_line,
            'end_line': section.end_line,
            'priority': section.priority,
            'depends': section.depends,
            'load_condition': section.load_condition,
            'line_count': len(section.content)
        }
    
    # Write analysis results
    output_file = output_dir / 'aliases_sections.json'
    with open(output_file, 'w') as f:
        json.dump(sections_json, f, indent=2)
    
    print(f"📊 Analysis complete! Found {len(sections)} sections:")
    for name, section in sorted(sections.items(), key=lambda x: x[1].priority):
        line_count = section.end_line - section.start_line + 1
        depends_str = f" (depends: {', '.join(section.depends)})" if section.depends else ""
        print(f"  • {name}: lines {section.start_line}-{section.end_line} ({line_count} lines){depends_str}")
    
    print(f"\n✅ Results saved to: {output_file}")
    
    # Also save the sections object for the splitting phase
    import pickle
    with open(output_dir / 'sections.pkl', 'wb') as f:
        pickle.dump(sections, f)
    
    return sections

if __name__ == '__main__':
    main()