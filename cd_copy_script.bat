@echo off
setlocal enabledelayedexpansion

REM CD/DVD Copy Script
REM This script copies the contents of a CD/DVD to a named folder

:SETUP
echo ========================================
echo CD/DVD Copy Script
echo ========================================
echo.

REM Prompt for CD/DVD drive letter with default
set "DRIVE_LETTER=F"
set /p DRIVE_LETTER="Enter CD/DVD drive letter [default: F]: "
set "CD_DRIVE=%DRIVE_LETTER%:"

REM Check if drive exists
if not exist %CD_DRIVE%\ (
    echo ERROR: Drive %CD_DRIVE% not found!
    echo.
    goto SETUP
)

REM Prompt for target base folder with default
set "TARGET_BASE=H:\cd-dvd"
set /p TARGET_BASE="Enter target base folder path [default: H:\cd-dvd]: "

REM Remove trailing backslash if present
if "%TARGET_BASE:~-1%"=="\" set "TARGET_BASE=%TARGET_BASE:~0,-1%"

REM Create base folder if it doesn't exist
if not exist "%TARGET_BASE%" (
    echo Creating base folder: %TARGET_BASE%
    mkdir "%TARGET_BASE%"
)

echo.
echo Setup complete!
echo CD/DVD Drive: %CD_DRIVE%
echo Target Folder: %TARGET_BASE%
echo.
pause

:COPY_LOOP
cls
echo ========================================
echo CD/DVD Copy Script
echo ========================================
echo CD/DVD Drive: %CD_DRIVE%
echo Target Folder: %TARGET_BASE%
echo ========================================
echo.

REM List contents of CD/DVD
echo Contents of %CD_DRIVE%:
echo ----------------------------------------
dir %CD_DRIVE%\ /b
echo ----------------------------------------
echo.

REM Get volume label from CD/DVD
for /f "tokens=5*" %%a in ('vol %CD_DRIVE% 2^>nul ^| find "Volume in drive"') do set "VOL_LABEL=%%b"
if "%VOL_LABEL%"=="" set "VOL_LABEL=UNNAMED_DISC"

REM Get folder name from user with volume label as default
echo Volume label: %VOL_LABEL%
set "FOLDER_NAME="
set /p FOLDER_NAME="Enter name for this CD/DVD backup folder [default: %VOL_LABEL%] (or 'quit' to exit): "

REM Check if user wants to quit
if /i "%FOLDER_NAME%"=="quit" (
    echo.
    echo Exiting script...
    goto END
)

REM Use volume label as default if folder name is empty
if "%FOLDER_NAME%"=="" set "FOLDER_NAME=%VOL_LABEL%"

REM Create target folder path
set "TARGET_FOLDER=%TARGET_BASE%\%FOLDER_NAME%"

REM Check if folder already exists
if exist "%TARGET_FOLDER%" (
    echo.
    echo WARNING: Folder "%TARGET_FOLDER%" already exists!
    set /p OVERWRITE="Overwrite? (Y/N): "
    if /i not "!OVERWRITE!"=="Y" (
        echo Skipping...
        echo.
        pause
        goto COPY_LOOP
    )
    echo Removing existing folder...
    rd /s /q "%TARGET_FOLDER%"
)

REM Create target folder
echo.
echo Creating folder: %TARGET_FOLDER%
mkdir "%TARGET_FOLDER%"

REM Copy files using robocopy (more reliable than xcopy)
echo.
echo Copying files from %CD_DRIVE% to %TARGET_FOLDER%...
echo.
robocopy %CD_DRIVE%\ "%TARGET_FOLDER%" /E /COPY:DAT /R:2 /W:5 /V /ETA

REM Check robocopy exit code (0-7 are success, 8+ are errors)
if %ERRORLEVEL% GEQ 8 (
    echo.
    echo ERROR: Copy failed with error code %ERRORLEVEL%
) else (
    echo.
    echo ========================================
    echo Copy completed successfully!
    echo ========================================
    echo Files copied to: %TARGET_FOLDER%
    echo.
    echo Ejecting disc...
    powershell -Command "(New-Object -COMObject Shell.Application).Namespace(17).ParseName('%CD_DRIVE%').InvokeVerb('Eject')"
    echo Disc ejected. Please insert next CD/DVD.
)

echo.
echo Please insert the next CD/DVD or type 'quit' to exit.
echo.
pause

REM Loop back for next CD/DVD
goto COPY_LOOP

:END
echo.
echo Thank you for using CD/DVD Copy Script!
echo.
pause
endlocal
