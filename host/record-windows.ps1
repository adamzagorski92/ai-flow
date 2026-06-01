param(
    [string]$Language = "pl"
)

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$recordDir = Join-Path $projectRoot ".tmp"
$outputFile = Join-Path $recordDir "voice_input.wav"
New-Item -ItemType Directory -Force -Path $recordDir | Out-Null

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Keyboard {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
}
"@

Write-Host "Hold Alt to record. Release to transcribe." -ForegroundColor Yellow

$recording = $false
$process = $null

while ($true) {
    $altState = [Keyboard]::GetAsyncKeyState(0x12)  # VK_MENU = Alt
    $altDown = $altState -band 0x8000

    if ($altDown -and -not $recording) {
        $recording = $true
        Write-Host "Recording..." -ForegroundColor Green
        $process = Start-Process -NoNewWindow -PassThru -FilePath "ffmpeg" -ArgumentList @("-y", "-f", "dshow", "-i", "audio=Microphone", $outputFile)
        Start-Sleep -Milliseconds 200

        if ($process.HasExited) {
            $devices = @("Microphone (Realtek Audio)", "Mikrofon", "Internal Microphone")
            foreach ($dev in $devices) {
                $process = Start-Process -NoNewWindow -PassThru -FilePath "ffmpeg" -ArgumentList @("-y", "-f", "dshow", "-i", "audio=$dev", $outputFile)
                Start-Sleep -Milliseconds 200
                if (-not $process.HasExited) { break }
            }
        }
    }

    if (-not $altDown -and $recording) {
        $recording = $false
        if ($process -and -not $process.HasExited) {
            $process.Kill()
            $process.WaitForExit(3000)
        }
        Write-Host "Transcribing..." -ForegroundColor Green
        break
    }

    Start-Sleep -Milliseconds 50
}

if (-not (Test-Path $outputFile)) {
    Write-Error "No audio recorded."
    exit 1
}

Set-Location $projectRoot
$transcript = & docker compose exec -T workbench whisper-transcribe "/workspace/.tmp/voice_input.wav" $Language 2>$null
Write-Output $transcript
Remove-Item $outputFile -Force -ErrorAction SilentlyContinue
