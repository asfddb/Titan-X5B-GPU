$files = Get-ChildItem -Path ..\rtl -Recurse -Filter *.v -Exclude *fpga_top.v | Select-Object -ExpandProperty FullName
$args = @("-g2012", "-I..\rtl", "-o", "sim_top.vvp", "tb_titan_x5_gpu_top.v") + $files
Write-Host "Compiling Verilog files..."
& iverilog @args
if ($LASTEXITCODE -eq 0) {
    Write-Host "Running Simulation..."
    & vvp sim_top.vvp
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Generating Waveform Proof..."
        & python generate_waveform_proof.py
    } else {
        Write-Host "Simulation failed!"
    }
} else {
    Write-Host "Compilation failed!"
}
