#!/usr/bin/env python3
"""
Split .aliases file into modular alias files based on the analysis results.
"""

import json
from pathlib import Path
from typing import Dict, List

def create_module_header(name: str, load_condition: str, depends: List[str]) -> str:
    """Generate standardized header for each module."""
    module_name = name.replace('00-', '').replace('10-', '').replace('20-', '').replace('30-', '').replace('40-', '').replace('50-', '').replace('55-', '').replace('60-', '').replace('65-', '').replace('70-', '').replace('75-', '').replace('80-', '').replace('85-', '').replace('90-', '').replace('95-', '')
    depends_str = f"# Depends: {', '.join(depends)}" if depends else "# Depends: none"
    load_when = "always" if load_condition == 'always' else f"conditional ({load_condition})"
    
    return f"""# ------------------------------------------------------------------
# Module: {module_name}
# Loaded when: {load_when}
{depends_str}
# ------------------------------------------------------------------

"""

def process_content(content: List[str], is_first_module: bool = False) -> str:
    """Process module content, removing header from first module."""
    processed_lines = []
    skip_header = is_first_module
    header_lines = 0
    
    for line in content:
        # Skip the original file header for the first module only
        if skip_header and line.strip().startswith('#') and header_lines < 15:
            header_lines += 1
            if 'Enhanced Shell Aliases' in line or 'CachyOS Linux Optimized' in line or '============' in line:
                continue
        else:
            skip_header = False
            
        processed_lines.append(line)
    
    # Ensure content ends cleanly
    processed_content = ''.join(processed_lines).rstrip() + '\n\n'
    
    # Add return 0 for source error detection
    processed_content += "# Module loaded successfully\nreturn 0\n"
    
    return processed_content

def main():
    """Main splitting function."""
    
    # Load the analysis results from JSON and original file
    analysis_dir = Path('/home/me/git/conf/analysis')
    sections_json_file = analysis_dir / 'aliases_sections.json'
    aliases_file = Path('/home/me/git/conf/.aliases')
    
    if not sections_json_file.exists():
        print("❌ Error: aliases_sections.json not found. Run analyze_aliases_sections.py first.")
        return
    
    # Load section metadata
    with open(sections_json_file, 'r') as f:
        sections_meta = json.load(f)
    
    # Load original aliases file
    with open(aliases_file, 'r') as f:
        all_lines = f.readlines()
    
    # Reconstruct sections with content
    sections = {}
    for name, meta in sections_meta.items():
        start = meta['start_line']
        end = meta['end_line']
        sections[name] = {
            'priority': meta['priority'],
            'depends': meta['depends'],
            'load_condition': meta['load_condition'],
            'content': all_lines[start:end+1]
        }
    
    print("🔧 Splitting .aliases into modular files...")
    
    aliases_dir = Path('/home/me/git/conf/aliases.d')
    aliases_dir.mkdir(exist_ok=True)
    
    # Sort sections by priority for processing
    sorted_sections = sorted(sections.items(), key=lambda x: x[1]['priority'])
    
    for i, (name, section) in enumerate(sorted_sections):
        module_file = aliases_dir / f"{name}.aliases"
        
        print(f"  📄 Creating {module_file.name} ({len(section['content'])} lines)")
        
        # Create module header
        header = create_module_header(name, section['load_condition'], section['depends'])
        
        # Process content
        is_first = (i == 0)  # First module gets special header treatment
        content = process_content(section['content'], is_first)
        
        # Write module file
        with open(module_file, 'w') as f:
            f.write(header)
            f.write(content)
        
        # Make executable
        module_file.chmod(0o755)
    
    print(f"\n✅ Split complete! Created {len(sections)} module files in aliases.d/")
    
    # Show summary
    total_lines = sum(len(section['content']) for section in sections.values())
    print(f"📊 Total lines processed: {total_lines}")
    print("\n📁 Module files created:")
    for module_file in sorted(aliases_dir.glob("*.aliases")):
        size = module_file.stat().st_size
        print(f"   • {module_file.name} ({size} bytes)")

if __name__ == '__main__':
    main()