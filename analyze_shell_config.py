#!/usr/bin/env python3
"""
Shell Configuration Analysis Tool
Analyzes .aliases and .zshrc files for duplicates, conflicts, and issues
"""

import re
import json
from collections import defaultdict
from pathlib import Path

def extract_aliases(file_path):
    """Extract all alias definitions from a shell file"""
    aliases = {}
    functions = {}
    
    with open(file_path, 'r') as f:
        content = f.read()
        lines = content.split('\n')
    
    for i, line in enumerate(lines, 1):
        line = line.strip()
        
        # Skip comments and empty lines
        if not line or line.startswith('#'):
            continue
            
        # Extract alias definitions
        alias_match = re.match(r'alias\s+([^=]+)=(.+)', line)
        if alias_match:
            alias_name = alias_match.group(1).strip()
            alias_value = alias_match.group(2).strip()
            aliases[alias_name] = {
                'value': alias_value,
                'line': i,
                'raw': line
            }
        
        # Extract function definitions
        func_match = re.match(r'([a-zA-Z_][a-zA-Z0-9_-]*)\s*\(\s*\)\s*\{', line)
        if func_match:
            func_name = func_match.group(1)
            functions[func_name] = {
                'line': i,
                'raw': line
            }
    
    return aliases, functions

def find_hardcoded_paths(file_path):
    """Find hardcoded paths that might not exist"""
    issues = []
    
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    for i, line in enumerate(lines, 1):
        # Look for hardcoded /home/me paths
        if '/home/me/' in line and not line.strip().startswith('#'):
            issues.append({
                'type': 'hardcoded_path',
                'line': i,
                'content': line.strip(),
                'issue': 'Hardcoded /home/me path - should use $HOME'
            })
        
        # Look for other potential path issues
        path_patterns = [
            r'/usr/local/bin/[^"\s]+',
            r'/opt/[^"\s/]+/[^"\s]+',
            r'~/development/[^"\s]+',
        ]
        
        for pattern in path_patterns:
            matches = re.finditer(pattern, line)
            for match in matches:
                if not line.strip().startswith('#'):
                    issues.append({
                        'type': 'potential_missing_path',
                        'line': i,
                        'content': line.strip(),
                        'path': match.group(),
                        'issue': f'Potential missing path: {match.group()}'
                    })
    
    return issues

def analyze_files():
    """Main analysis function"""
    aliases_file = Path('.aliases')
    zshrc_file = Path('.zshrc')
    
    print("🔍 Analyzing shell configuration files...")
    
    # Extract aliases and functions
    aliases_aliases, aliases_functions = extract_aliases(aliases_file)
    zshrc_aliases, zshrc_functions = extract_aliases(zshrc_file)
    
    # Find duplicates
    duplicates = []
    all_aliases = {}
    
    # Check for duplicates across files
    for name, info in aliases_aliases.items():
        if name in all_aliases:
            duplicates.append({
                'type': 'alias_duplicate',
                'name': name,
                'files': [all_aliases[name]['file'], f'.aliases:{info["line"]}'],
                'values': [all_aliases[name]['value'], info['value']]
            })
        else:
            all_aliases[name] = {**info, 'file': f'.aliases:{info["line"]}'}
    
    for name, info in zshrc_aliases.items():
        if name in all_aliases:
            duplicates.append({
                'type': 'alias_duplicate',
                'name': name,
                'files': [all_aliases[name]['file'], f'.zshrc:{info["line"]}'],
                'values': [all_aliases[name]['value'], info['value']]
            })
        else:
            all_aliases[name] = {**info, 'file': f'.zshrc:{info["line"]}'}
    
    # Check for function duplicates
    all_functions = {}
    
    for name, info in aliases_functions.items():
        all_functions[name] = {**info, 'file': f'.aliases:{info["line"]}'}
    
    for name, info in zshrc_functions.items():
        if name in all_functions:
            duplicates.append({
                'type': 'function_duplicate',
                'name': name,
                'files': [all_functions[name]['file'], f'.zshrc:{info["line"]}']
            })
        else:
            all_functions[name] = {**info, 'file': f'.zshrc:{info["line"]}'}
    
    # Find hardcoded paths
    aliases_paths = find_hardcoded_paths(aliases_file)
    zshrc_paths = find_hardcoded_paths(zshrc_file)
    
    # Identify conflicting aliases (same command, different implementations)
    conflicts = []
    conflicting_commands = ['cat', 'find', 'ls', 'grep', 'top', 'df', 'du', 'ps']
    
    for cmd in conflicting_commands:
        cmd_aliases = [name for name in all_aliases.keys() if name == cmd]
        if len(cmd_aliases) > 1:
            conflicts.append({
                'command': cmd,
                'aliases': [all_aliases[name] for name in cmd_aliases]
            })
    
    # Generate report
    report = {
        'summary': {
            'total_aliases': len(all_aliases),
            'total_functions': len(all_functions),
            'duplicates': len(duplicates),
            'path_issues': len(aliases_paths + zshrc_paths),
            'conflicts': len(conflicts)
        },
        'duplicates': duplicates,
        'path_issues': aliases_paths + zshrc_paths,
        'conflicts': conflicts,
        'recommendations': []
    }
    
    # Generate recommendations
    if duplicates:
        report['recommendations'].append("Comment out duplicate aliases, keeping the most modern/portable version")
    
    if aliases_paths or zshrc_paths:
        report['recommendations'].append("Replace hardcoded paths with $HOME and XDG variables")
    
    if conflicts:
        report['recommendations'].append("Resolve conflicting command aliases by using conditional checks")
    
    return report

if __name__ == "__main__":
    report = analyze_files()
    
    # Save detailed report
    with open('analysis_report.json', 'w') as f:
        json.dump(report, f, indent=2)
    
    # Print summary
    print(f"\n📊 Analysis Summary:")
    print(f"  • Total aliases: {report['summary']['total_aliases']}")
    print(f"  • Total functions: {report['summary']['total_functions']}")
    print(f"  • Duplicates found: {report['summary']['duplicates']}")
    print(f"  • Path issues: {report['summary']['path_issues']}")
    print(f"  • Conflicts: {report['summary']['conflicts']}")
    
    if report['duplicates']:
        print(f"\n🔄 Duplicates:")
        for dup in report['duplicates'][:5]:  # Show first 5
            print(f"  • {dup['name']} ({dup['type']})")
    
    if report['path_issues']:
        print(f"\n📁 Path Issues:")
        for issue in report['path_issues'][:3]:  # Show first 3
            print(f"  • Line {issue['line']}: {issue['issue']}")
    
    print(f"\n💡 Recommendations:")
    for rec in report['recommendations']:
        print(f"  • {rec}")
    
    print(f"\n📄 Full report saved to: analysis_report.json")
