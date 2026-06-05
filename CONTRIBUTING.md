# Contributing to Titan X5-B GPU

First off, thank you for considering contributing to the Titan X5-B GPU project! 🎉

## 🛡️ Important: Intellectual Property

This project is licensed under **CERN-OHL-S-2.0** (Strongly Reciprocal). By contributing, you agree that:

- Your contributions will be licensed under the same CERN-OHL-S-2.0 license
- You have the right to submit the contribution
- You understand this is a reciprocal license — any derivative work must remain open

## 🚀 How to Contribute

### Reporting Bugs

1. Check if the issue already exists in the [Issues](https://github.com/asfddb/Titan-X5B-GPU/issues) tab
2. If not, create a new issue with:
   - Description of the bug
   - Steps to reproduce
   - Expected vs actual behavior
   - Your environment (OS, Yosys version, iverilog version)

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Run verification:
   ```powershell
   # Compile
   iverilog -g2012 -I rtl -o tb/test.vvp tb/ultimate_blackwell_tb.v rtl/*.v rtl/**/*.v
   
   # Simulate
   vvp tb/test.vvp
   
   # Ensure "TEST PASSED" appears
   ```
5. Commit with a clear message (`git commit -m "Add: description"`)
6. Push and create a Pull Request

### Code Style

- Use `snake_case` for module and signal names
- Prefix registers with `r_` or use `_q` suffix
- Prefix wires with `w_` or use `_d` suffix
- Always use non-blocking assignments (`<=`) in sequential blocks
- Always use blocking assignments (`=`) in combinational blocks
- Add comments for complex logic
- Keep modules under 500 lines when possible

## 🎯 Priority Areas

We especially need help with:

| Area | Difficulty | Description |
|:---|:---|:---|
| UVM Testbench | 🔴 Hard | SystemVerilog UVM verification environment |
| FPGA Prototype | 🟡 Medium | Port to Xilinx Artix-7 or Lattice ECP5 |
| Power Analysis | 🟡 Medium | OpenSTA-based power estimation |
| Documentation | 🟢 Easy | Improve architecture docs and tutorials |
| Bug Fixes | 🟢 Easy | Fix synthesis warnings and port mismatches |

## 📞 Contact

- **Creator**: Adhiraj
- **GitHub**: [@asfddb](https://github.com/asfddb)
- **Location**: India 🇮🇳

---

*Thank you for helping build the future of open-source silicon!* ⚡
