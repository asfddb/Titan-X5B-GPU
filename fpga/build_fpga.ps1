# ============================================================================
# Titan X5-B GPU - Basys 3 FPGA build driver
#
# Usage (from anywhere):
#   powershell -File fpga/build_fpga.ps1            # full Vivado flow -> .bit
#   powershell -File fpga/build_fpga.ps1 -SynthOnly # open-source yosys check
#
# The full bitstream flow requires AMD/Xilinx Vivado (free ML Standard
# edition covers the Basys 3's xc7a35t). If Vivado is not installed, the
# script falls back to a genuine yosys synthesis run inside WSL, which
# verifies synthesizability and reports LUT/FF/BRAM/DSP utilization
# against the xc7a35t budget - but cannot produce a bitstream.
# ============================================================================
param(
    [switch]$SynthOnly
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

function Find-Vivado {
    $cmd = Get-Command vivado -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $roots = @("C:\Xilinx\Vivado", "C:\Xilinx\2*", "D:\Xilinx\Vivado", "E:\Xilinx\Vivado")
    foreach ($root in $roots) {
        $hits = Get-ChildItem -Path "$root\*\bin\vivado.bat" -ErrorAction SilentlyContinue |
                Sort-Object FullName -Descending
        if ($hits) { return $hits[0].FullName }
    }
    return $null
}

if (-not $SynthOnly) {
    $vivado = Find-Vivado
    if ($vivado) {
        Write-Host "Using Vivado: $vivado"
        Write-Host "Running synthesis + place-and-route + bitstream (this can take 30-90 min)..."
        Push-Location $RepoRoot
        try {
            & $vivado -mode batch -source fpga/vivado_build.tcl `
                -journal fpga/build/vivado.jou -log fpga/build/vivado.log
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Vivado flow failed (exit $LASTEXITCODE). See fpga/build/vivado.log"
            }
            Write-Host "Bitstream: fpga/build/titan_x5_basys3.bit"
        } finally {
            Pop-Location
        }
        exit $LASTEXITCODE
    }
    Write-Warning "Vivado not found. Falling back to open-source synthesis check (no bitstream)."
    Write-Warning "Install Vivado ML Standard (free) from https://www.xilinx.com/support/download.html to build the .bit file."
}

# --- Open-source fallback: real yosys synthesis inside WSL -------------------
$wslPath = "/mnt/" + $RepoRoot.Substring(0,1).ToLower() + ($RepoRoot.Substring(2) -replace '\\','/')
Write-Host "Running yosys (WSL) synthesis of titan_x5_fpga_top..."
wsl -d Ubuntu-24.04 -- bash -c "cd '$wslPath' && mkdir -p syn/reports && yosys -q -l syn/reports/fpga_top_synth.log fpga/synth_fpga_top.ys"
if ($LASTEXITCODE -ne 0) {
    Write-Error "yosys synthesis failed. See syn/reports/fpga_top_synth.log"
}
Write-Host "Utilization report: syn/reports/fpga_top_utilization.txt"
Write-Host "xc7a35t budget    : 20,800 LUT / 41,600 FF / 50 BRAM36 / 90 DSP48E1"
