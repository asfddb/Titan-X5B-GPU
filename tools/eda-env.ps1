# Put the EDA toolchain on PATH for this shell only.
#
#   . .\tools\eda-env.ps1        (note the leading dot -- it must run in *this*
#                                 shell, not a child, or the PATH change is lost)
#
# Everything needed is already installed; it simply is not on PATH, which is
# why `yosys` and `iverilog` appear missing. Nothing here is written to the
# machine -- close the window and it is as if it never ran. That is deliberate:
# a session-scoped change cannot break anything else on the system.

$ossCad  = "C:\eda\oss-cad-suite"
$icarus  = "C:\iverilog"

$added = @()

if (Test-Path "$ossCad\bin") {
    # OSS CAD Suite ships its own environment script; prefer it, because the
    # tools need more than PATH (Python paths, Tcl libraries, ABC's data files).
    if (Test-Path "$ossCad\environment.ps1") {
        . "$ossCad\environment.ps1"
        $added += "oss-cad-suite (via its own environment.ps1)"
    } else {
        $env:PATH = "$ossCad\bin;$env:PATH"
        $added += "oss-cad-suite\bin"
    }
}

# Icarus is a separate install and carries GTKWave with it.
foreach ($p in @("$icarus\bin", "$icarus\gtkwave\bin")) {
    if ((Test-Path $p) -and ($env:PATH -notlike "*$p*")) {
        $env:PATH = "$p;$env:PATH"
        $added += $p
    }
}

if ($added.Count -eq 0) {
    Write-Host "Nothing found. Expected $ossCad or $icarus." -ForegroundColor Red
    return
}

Write-Host ""
Write-Host "EDA toolchain on PATH for this session:" -ForegroundColor Cyan
foreach ($a in $added) { Write-Host "  + $a" }
Write-Host ""

# Version flags are not consistent across these tools -- Icarus wants -V and
# errors on --version, so asking every tool the same way reports false failures.
$versionFlag = @{
    "yosys" = "-V"; "iverilog" = "-V"; "vvp" = "-V"
    "verilator" = "--version"; "gtkwave" = "--version"
    "nextpnr-ice40" = "--version"; "nextpnr-ecp5" = "--version"
}

foreach ($tool in $versionFlag.Keys | Sort-Object) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Host ("  {0,-16} not found" -f $tool) -ForegroundColor DarkGray
        continue
    }
    $version = ""
    try {
        $raw = & $tool $versionFlag[$tool] 2>&1 | Select-Object -First 1
        if ($raw) { $version = ($raw -replace '\s+', ' ').Trim() }
    } catch { }
    Write-Host ("  {0,-16} {1}" -f $tool, $version) -ForegroundColor Green
}
Write-Host ""
