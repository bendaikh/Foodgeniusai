Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

Start-Sleep -Seconds 5

$found = $false
$processes = Get-Process | Where-Object {$_.MainWindowTitle -ne ""}

foreach($process in $processes) {
    if($process.MainWindowTitle -like "*Android Emulator*" -or 
       $process.MainWindowTitle -like "*Pixel*" -or
       $process.ProcessName -like "*qemu*") {
        Write-Host "Found emulator: $($process.MainWindowTitle) - $($process.ProcessName)"
        if($process.MainWindowHandle -ne 0) {
            [Win32]::ShowWindow($process.MainWindowHandle, 9)
            [Win32]::SetForegroundWindow($process.MainWindowHandle)
            $found = $true
            Write-Host "Brought emulator window to front"
        }
    }
}

if(-not $found) {
    Write-Host "No emulator window found"
}
