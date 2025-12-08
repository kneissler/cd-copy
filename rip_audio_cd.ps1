param(
    [Parameter(Mandatory=$true)]
    [string]$CDDrive,

    [Parameter(Mandatory=$true)]
    [string]$TargetFolder
)

# Audio CD Ripper Script
# Rips audio CD tracks to WAV files

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Audio CD Ripper (WAV Format)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CD Drive: $CDDrive" -ForegroundColor White
Write-Host "Target: $TargetFolder" -ForegroundColor White
Write-Host ""

# Ensure target folder exists
if (!(Test-Path $TargetFolder)) {
    New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null
}

# Check for FFmpeg
$ffmpegPath = $null
$ffmpegLocations = @(
    "ffmpeg",
    "C:\ffmpeg\bin\ffmpeg.exe",
    "C:\Program Files\ffmpeg\bin\ffmpeg.exe",
    "$env:ProgramFiles\ffmpeg\bin\ffmpeg.exe"
)

foreach ($location in $ffmpegLocations) {
    try {
        $testResult = Get-Command $location -ErrorAction SilentlyContinue
        if ($testResult) {
            $ffmpegPath = $location
            Write-Host "Found FFmpeg: $ffmpegPath" -ForegroundColor Green
            break
        }
    } catch {
        continue
    }
}

if ($ffmpegPath) {
    Write-Host "Using FFmpeg to rip audio CD..." -ForegroundColor Yellow
    Write-Host ""

    # Use FFmpeg to rip the audio CD
    # Note: This requires FFmpeg built with libcdio support
    $driveIndex = [int][char]$CDDrive.ToUpper()[0] - [int][char]'A'

    Write-Host "Attempting to rip audio CD tracks..." -ForegroundColor Yellow

    # Try to get track information first
    try {
        & $ffmpegPath -f cdda -i "\\.\${CDDrive}:" -t 1 -f null - 2>&1 | Out-Null
        Write-Host "CD audio detected, starting rip..." -ForegroundColor Green
    } catch {
        Write-Host "Warning: Could not verify CD audio. Proceeding anyway..." -ForegroundColor Yellow
    }

    # Rip all tracks
    # FFmpeg will create separate files for each track when using -map
    $outputPattern = Join-Path $TargetFolder "Track_%02d.wav"

    Write-Host "Ripping to: $TargetFolder" -ForegroundColor Cyan
    Write-Host "Output pattern: Track_01.wav, Track_02.wav, etc." -ForegroundColor Cyan
    Write-Host ""

    & $ffmpegPath -f cdda -i "\\.\${CDDrive}:" -map 0 -c:a pcm_s16le "$outputPattern" 2>&1 | ForEach-Object {
        if ($_ -match "time=") {
            Write-Host $_ -ForegroundColor Gray
        }
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Audio CD ripped successfully!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        $wavFiles = Get-ChildItem -Path $TargetFolder -Filter "*.wav"
        Write-Host "Created $($wavFiles.Count) WAV file(s)" -ForegroundColor White
        exit 0
    } else {
        Write-Host ""
        Write-Host "FFmpeg rip failed. Falling back to track listing..." -ForegroundColor Yellow
        # Continue to fallback method below
    }
}

try {
    # Create Windows Media Player COM object
    Write-Host "Initializing Windows Media Player..." -ForegroundColor Yellow
    $wmp = New-Object -ComObject WMPlayer.OCX

    # Get the CD drive
    $cdromCount = $wmp.cdromCollection.count
    Write-Host "Found $cdromCount CD/DVD drive(s)" -ForegroundColor White

    if ($cdromCount -eq 0) {
        Write-Host "ERROR: No CD/DVD drives found!" -ForegroundColor Red
        exit 1
    }

    # Find the correct CD drive
    $cdrom = $null
    for ($i = 0; $i -lt $cdromCount; $i++) {
        $drive = $wmp.cdromCollection.item($i)
        if ($drive.driveSpecifier -eq $CDDrive) {
            $cdrom = $drive
            break
        }
    }

    if ($null -eq $cdrom) {
        # If exact match not found, use first drive
        $cdrom = $wmp.cdromCollection.item(0)
        Write-Host "Using first available drive: $($cdrom.driveSpecifier)" -ForegroundColor Yellow
    }

    # Get the playlist (audio tracks)
    $playlist = $cdrom.Playlist

    if ($null -eq $playlist) {
        Write-Host "ERROR: No audio CD detected or disc not ready!" -ForegroundColor Red
        Write-Host "Please ensure an audio CD is inserted in the drive." -ForegroundColor Yellow
        exit 1
    }

    $trackCount = $playlist.count

    if ($trackCount -eq 0) {
        Write-Host "ERROR: No audio tracks found on disc!" -ForegroundColor Red
        Write-Host "This may be a data disc, not an audio CD." -ForegroundColor Yellow
        exit 1
    }

    Write-Host "Found $trackCount audio track(s)" -ForegroundColor Green
    Write-Host ""

    # Configure Windows Media Player for ripping
    Write-Host "Configuring rip settings..." -ForegroundColor Yellow

    # Set rip format to WAV
    # Note: WMP COM interface has limited direct ripping control
    # We'll use an alternative approach with MCI (Media Control Interface)

    Write-Host "Starting audio extraction..." -ForegroundColor Yellow
    Write-Host ""

    # Alternative: Use MCI to extract digital audio
    Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class MCI {
    [DllImport("winmm.dll")]
    public static extern int mciSendString(string command, StringBuilder returnValue, int returnLength, IntPtr hwndCallback);
}
"@

    # Open the CD audio device
    $result = [MCI]::mciSendString("open cdaudio alias cd wait shareable", $null, 0, [IntPtr]::Zero)

    if ($result -ne 0) {
        Write-Host "ERROR: Failed to open CD audio device (Error code: $result)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Alternative: Using Windows Media Player track information..." -ForegroundColor Yellow

        # Fallback: Just list the tracks
        for ($i = 0; $i -lt $trackCount; $i++) {
            $track = $playlist.item($i)
            $trackNum = ($i + 1).ToString("00")
            $trackName = $track.name
            if ([string]::IsNullOrEmpty($trackName)) {
                $trackName = "Track_$trackNum"
            }

            Write-Host "Track $trackNum`: $trackName" -ForegroundColor Cyan
            Write-Host "  Duration: $($track.duration) seconds" -ForegroundColor Gray
        }

        Write-Host ""
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host "NOTICE: Direct audio CD ripping requires additional configuration" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To rip audio CDs to WAV, please use one of these methods:" -ForegroundColor White
        Write-Host ""
        Write-Host "1. Windows Media Player:" -ForegroundColor Cyan
        Write-Host "   - Open Windows Media Player" -ForegroundColor Gray
        Write-Host "   - Go to Rip settings > Format > WAV (Lossless)" -ForegroundColor Gray
        Write-Host "   - Insert audio CD and click 'Rip CD'" -ForegroundColor Gray
        Write-Host ""
        Write-Host "2. Install FFmpeg with libcdio:" -ForegroundColor Cyan
        Write-Host "   - Download from: https://ffmpeg.org/" -ForegroundColor Gray
        Write-Host "   - Use command: ffmpeg -f cdda -i $CDDrive -c:a pcm_s16le output.wav" -ForegroundColor Gray
        Write-Host ""
        Write-Host "3. Use dedicated CD ripper software:" -ForegroundColor Cyan
        Write-Host "   - Exact Audio Copy (EAC)" -ForegroundColor Gray
        Write-Host "   - dBpoweramp" -ForegroundColor Gray
        Write-Host "   - CDex" -ForegroundColor Gray
        Write-Host ""

        # Clean up
        [MCI]::mciSendString("close cd", $null, 0, [IntPtr]::Zero)
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wmp) | Out-Null

        # Create a text file with track listing
        $trackListFile = Join-Path $TargetFolder "track_list.txt"
        "Audio CD Track Listing" | Out-File -FilePath $trackListFile -Encoding UTF8
        "=" * 50 | Out-File -FilePath $trackListFile -Append -Encoding UTF8
        "CD Drive: $CDDrive" | Out-File -FilePath $trackListFile -Append -Encoding UTF8
        "Track Count: $trackCount" | Out-File -FilePath $trackListFile -Append -Encoding UTF8
        "" | Out-File -FilePath $trackListFile -Append -Encoding UTF8

        for ($i = 0; $i -lt $trackCount; $i++) {
            $track = $playlist.item($i)
            $trackNum = ($i + 1).ToString("00")
            $trackName = $track.name
            if ([string]::IsNullOrEmpty($trackName)) {
                $trackName = "Track_$trackNum"
            }
            "Track $trackNum`: $trackName ($($track.duration) seconds)" | Out-File -FilePath $trackListFile -Append -Encoding UTF8
        }

        Write-Host "Track listing saved to: $trackListFile" -ForegroundColor Green
        Write-Host ""

        exit 2  # Exit code 2 indicates feature not fully supported
    }

    # Get number of tracks from MCI
    $sb = New-Object System.Text.StringBuilder 255
    [MCI]::mciSendString("status cd number of tracks", $sb, 255, [IntPtr]::Zero)
    $mciTrackCount = [int]$sb.ToString()

    Write-Host "MCI reports $mciTrackCount tracks" -ForegroundColor White

    # Set time format to milliseconds
    [MCI]::mciSendString("set cd time format milliseconds", $null, 0, [IntPtr]::Zero)

    # Note: Actual digital audio extraction via MCI requires additional
    # low-level implementation that's beyond simple scripting

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Advanced audio extraction requires external tools" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow

    # Clean up
    [MCI]::mciSendString("close cd", $null, 0, [IntPtr]::Zero)
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wmp) | Out-Null

    exit 2

} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.Exception.StackTrace -ForegroundColor DarkGray

    if ($null -ne $wmp) {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wmp) | Out-Null
    }

    exit 1
}
