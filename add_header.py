import os

HEADER = """// ============================================================================
// Copyright (c) 2026 Adhiraj / [Your LLP]
// 
// This file is part of the Titan X5-B GPU project.
// 
// Dual-licensed under CERN-OHL-S-2.0 AND Commercial License.
// See LICENSE and COMMERCIAL.md for details.
// ============================================================================
"""

def process_dir(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.v') or file.endswith('.sv'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                if not content.startswith("// ================================"):
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(HEADER + content)
                    print(f"Added header to {filepath}")

if __name__ == "__main__":
    process_dir("rtl")
    process_dir("tb")
    process_dir("fpga")
