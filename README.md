# CD/DVD Copy and Audio Ripper Script

A Windows batch script that automatically copies data CDs/DVDs and rips audio CDs to your hard drive.

## Features

- **Auto-detection**: Automatically detects whether a disc is a data CD/DVD or audio CD
- **Data CD/DVD**: Copies all files and folders using robocopy
- **Audio CD**: Rips tracks to WAV format (lossless)
- **Batch processing**: Process multiple discs in a row with auto-eject
- **Smart naming**: Uses volume label as default folder name
- **Duplicate handling**: Auto-appends counter if folder name already exists

## Requirements

### For Data CDs/DVDs
- Windows (built-in tools only)

### For Audio CDs
Choose one of the following:

**Option 1: FFmpeg (Recommended)**
- Download from: https://ffmpeg.org/download.html
- Install to `C:\ffmpeg\` or add to system PATH
- Provides the best audio CD ripping support

**Option 2: Windows Media Player**
- Already included in Windows
- Limited scriptable support for audio CD ripping
- May require manual configuration

**Option 3: Dedicated Ripping Software**
- Exact Audio Copy (EAC)
- dBpoweramp
- CDex

## Usage

1. Run `cd_copy_script.bat`
2. Enter your CD/DVD drive letter (default: F)
3. Enter target folder path (default: H:\cd-dvd)
4. Insert disc and press any key
5. The script will:
   - Detect if it's a data or audio disc
   - Show volume label and contents
   - Prompt for folder name (or use volume label)
   - Copy/rip the disc
   - Auto-eject when complete
6. Insert next disc or type 'quit' to exit

## Audio CD Ripping

When an audio CD is detected:

1. Script attempts to rip using embedded PowerShell commands
2. If that fails, falls back to `rip_audio_cd.ps1` script
3. If FFmpeg is installed, uses it for high-quality ripping
4. Otherwise, creates a track listing file and provides instructions

Output format: `Track_01.wav`, `Track_02.wav`, etc.

## File Structure

```
cd-copy/
├── cd_copy_script.bat       # Main script
├── rip_audio_cd.ps1         # Audio CD ripper helper
└── README.md                # This file
```

## Configuration

Edit these lines in `cd_copy_script.bat` to change defaults:

```batch
REM Line 14: Default CD drive
set "DRIVE_LETTER=F"

REM Line 26: Default target folder
set "TARGET_BASE=H:\cd-dvd"
```

## Installing FFmpeg for Audio CD Ripping

### Method 1: Download Binary
1. Go to https://ffmpeg.org/download.html
2. Download Windows build
3. Extract to `C:\ffmpeg\`
4. Ensure `ffmpeg.exe` is in `C:\ffmpeg\bin\`

### Method 2: Add to PATH
1. Download and extract FFmpeg anywhere
2. Add the `bin` folder to system PATH
3. Restart command prompt

## Troubleshooting

### Audio CD not detected
- Ensure audio CD is fully loaded
- Try a different disc
- Check if CD drive supports digital audio extraction

### Audio CD rip fails
- Install FFmpeg (see above)
- Verify FFmpeg supports libcdio: `ffmpeg -formats | findstr cdda`
- Try using Windows Media Player manually
- Use dedicated ripping software

### Disc won't eject
- May be in use by another program
- Manually eject using hardware button
- Check for errors in output

## Exit Codes

### Batch Script
- `0`: Normal exit
- `8+`: Robocopy error (data CD)

### PowerShell Ripper
- `0`: Success
- `1`: Error (drive not found, disc not ready)
- `2`: Feature not supported, track listing created

## Notes

- WAV files are lossless and large (~10MB per minute of audio)
- Ripping speed depends on CD drive capabilities
- Some copy-protected audio CDs may not rip properly
- Data CDs preserve all file attributes and timestamps

## License

Free to use and modify
