import sys
import os
import re

def parse_stats(filepath):
    counts = {}
    with open(filepath, 'r') as f:
        lines = f.readlines()
        
    in_stats = False
    for line in lines:
        if "Number of wires:" in line:
            in_stats = True
        
        if in_stats and "$_" in line:
            parts = line.strip().split()
            if len(parts) >= 2:
                gate = parts[0]
                count = int(parts[1])
                counts[gate] = count
    return counts

def generate_svg_pie(counts, output_path):
    # Simple SVG generation since matplotlib might not be available
    total = sum(counts.values())
    if total == 0: return
    
    colors = ['#10B981', '#3B82F6', '#F59E0B', '#EF4444', '#8B5CF6', '#EC4899', '#6366F1']
    
    svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">\n'
    svg += '<rect width="400" height="400" fill="#1F2937" rx="8"/>\n'
    
    # Just draw a text table for now to simulate a chart
    svg += '<text x="20" y="40" font-family="sans-serif" font-size="20" font-weight="bold" fill="#F9FAFB">Gate Distribution</text>\n'
    
    y = 80
    for i, (gate, count) in enumerate(sorted(counts.items(), key=lambda x: x[1], reverse=True)):
        if i > 8: break # limit to top 9
        color = colors[i % len(colors)]
        pct = (count / total) * 100
        svg += f'<rect x="20" y="{y-12}" width="16" height="16" fill="{color}"/>\n'
        svg += f'<text x="45" y="{y}" font-family="monospace" font-size="14" fill="#D1D5DB">{gate}: {count:,} ({pct:.1f}%)</text>\n'
        y += 25
        
    svg += '</svg>'
    
    with open(output_path, 'w') as f:
        f.write(svg)

def main():
    if not os.path.exists('syn/reports/synthesis_stats.txt'):
        print("Stats file not found")
        sys.exit(1)
        
    counts = parse_stats('syn/reports/synthesis_stats.txt')
    os.makedirs('docs/assets', exist_ok=True)
    generate_svg_pie(counts, 'docs/assets/synth_pie.svg')
    print("Generated docs/assets/synth_pie.svg")

if __name__ == "__main__":
    main()
