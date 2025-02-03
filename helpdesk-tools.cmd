@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: Helpdesk Tools
:: ============================================================

:: ----- Global Settings & Silent Mode Check -----
set "silentMode=false"
for %%x in (%*) do (
    if /i "%%x"=="-s" set "silentMode=true"
    if /i "%%x"=="--silent" set "silentMode=true"
)

:: ----- Check for Administrator Privileges -----
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo [Error] Please run as Administrator!
    if not "%silentMode%"=="true" pause
    goto goUac
)

:goAdmin
pushd "%CD%"
CD /D "%~dp0"

:: ----- Define Directories -----
set "workDir=%~dp0"
set "targetDir=%workDir%helpdesk-tools"
set "configDir=%targetDir%\config"
set "manifestDir=%targetDir%\manifest"
set "wingetDir=%manifestDir%\winget"
set "chocoDir=%manifestDir%\choco"
set "moduleDir=%targetDir%\modules"
:: Temporary folder inside targetDir
set "tempDir=%targetDir%\temp"

:: ----- Setup Log File in targetDir -----
:: Log file is stored in the helpdesk-tools folder as helpdesk-tools.log
set "LOGFILE=%targetDir%\helpdesk-tools.log"
if not exist "%LOGFILE%" (
    echo [%date% %time%] [INFO] Log file created > "%LOGFILE%"
) else (
    echo.>> "%LOGFILE%"
    echo [%date% %time%] [INFO] New session started >> "%LOGFILE%"
)
call :log "[INFO] Starting Helpdesk Tools script"

:: ----- Initialize Directories -----
if not exist "%targetDir%" (
    mkdir "%targetDir%" || (
        echo [ERROR] Failed to create helpdesk-tools directory
        if not "%silentMode%"=="true" pause
        exit /B 1
    )
)
if not exist "%tempDir%" (
    mkdir "%tempDir%" || (
        echo [ERROR] Failed to create temp directory inside helpdesk-tools
        if not "%silentMode%"=="true" pause
        exit /B 1
    )
)

:: ============================================================
:: ENTRY POINT
:: ============================================================
cls
echo ============================================
echo         WELCOME TO HELPDESK TOOLS
echo ============================================
call :log "[INFO] Displayed welcome message"

:: ----- Show Disclaimer if Not in Silent Mode -----
if "%silentMode%"=="true" (
    echo [INFO] Silent mode enabled: skipping disclaimer.
    call :log "[INFO] Silent mode: skipping disclaimer"
) else (
    call :disclaimer
)

:: ----- 1. System Validation & OS Information -----
echo [*] Checking system requirements...
call :checkRequirements
if not "%requirementsMet%"=="true" (
    echo.
    echo [Error] This script cannot run on your system.
    call :log "[ERROR] System requirements not met. Script cannot run."
    if not "%silentMode%"=="true" pause
    exit /B 1
)
ping -n 3 localhost >nul
cls

:: ----- 3. Environment Setup (Download Repo, Create Structure) -----
echo [*] Setting up environment...
call :log "[INFO] Setting up environment"
call :setupEnvironment
if "%setupExit%"=="true" (
    echo [Error] Environment setup failed. Exiting...
    call :log "[ERROR] Environment setup failed."
    if not "%silentMode%"=="true" pause
    exit /B 1
)
cls

:: ----- 4. Package Managers Check & Installation -----
:: In silent mode, auto-install missing package managers.
:: In non-silent mode, prompt the user.
call :checkPackageManagers
if "%pmExit%"=="true" (
    echo [Error] Winget or Chocolatey installation failed. Exiting...
    call :log "[ERROR] Package managers installation failed."
    if not "%silentMode%"=="true" pause
    exit /B 1
)
call :log "[INFO] Package managers check completed"

:: ----- Refresh environment variables after installing package managers -----
::call :refreshEnv

:: ============================================================
:: MAIN MENU (Enhanced Interface)
:: ============================================================
:mainLoop
cls
echo ============================================
echo               MAIN MENU
echo ============================================
echo.
echo   [1] Software Deployment
echo   [2] System Utilities
echo   [3] Package Management
echo   [4] Update CMD
echo   [5] Exit
echo.
choice /C 12345 /N /M "Enter your choice: "
echo.
if %errorlevel% == 5 (
    call :log "[INFO] User selected: Exit"
    call :clean 
    goto :exit
)
if %errorlevel% == 4 (
    call :log "[INFO] User selected: Update CMD"
    call :updateCmd 
    goto mainLoop
)
if %errorlevel% == 3 (
    call :log "[INFO] User selected: Package Management"
    goto packageManagementMenu
)
if %errorlevel% == 2 (
    call :log "[INFO] User selected: System Utilities"
    goto utilitiesMenu
)
if %errorlevel% == 1 (
    call :log "[INFO] User selected: Software Deployment"
    goto softwareDeploymentMenu
)
goto mainLoop

:: ============================================================
:: LABEL: Disclaimer
:: Displays the disclaimer and prompts user to confirm.
:: ============================================================
:disclaimer
cls
echo ============================================
echo              DISCLAIMER
echo ============================================
echo.
echo This script is designed to support helpdesk operations by:
echo   - Installing Winget and optionally Chocolatey.
echo   - Modifying system settings to improve configuration.
echo.
echo Please be aware that:
echo   - The script may change system settings and install software packages.
echo   - All modifications are intended solely for helpdesk purposes.
echo   - The full source code is publicly available for review.
echo   - The author does not intend to cause harm, damage, or disrupt normal system operations.
echo   - Use this script only after thorough review and at your own risk.
echo   - The author disclaims any liability for any adverse effects or damages.
echo.
choice /C YN /N /M "Do you agree to proceed? (Y/N): "
if errorlevel 2 (
    echo [*] You chose NOT to proceed. Exiting...
    call :log "[INFO] User declined disclaimer. Exiting."
    exit /B 1
)
cls
exit /B 0

:: ============================================================
:: FUNCTION: Check System Requirements
:: ============================================================
:checkRequirements
cls
echo Checking system requirements...
set "requirementsMet=true"
for /f "tokens=2 delims=," %%A in ('wmic os get Caption /format:csv ^| findstr /v "Caption"') do set "os_caption=%%A"
for /f "tokens=2 delims=," %%A in ('wmic os get BuildNumber /format:csv ^| findstr /v "BuildNumber"') do set "build_number=%%A"
for /f "tokens=2 delims=," %%A in ('wmic os get OSArchitecture /format:csv ^| findstr /v "OSArchitecture"') do set "os_arch=%%A"

echo   OS Caption      : %os_caption%
echo   Build Number    : %build_number%
echo   OS Architecture : %os_arch%

if %build_number% LSS 17763 (
    echo [Error] Requires Windows 10 1809+ or Windows 11.
    set "requirementsMet=false"
)
if /i "%os_arch%"=="ARM64" (
    echo [Error] System architecture is ARM64. Not supported.
    set "requirementsMet=false"
)

if "%requirementsMet%"=="true" (
    echo [OK] System requirements met.
)

exit /B 0

:: ============================================================
:: FUNCTION: Setup Environment (Download Repo & Create Structure)
:: ============================================================
:setupEnvironment
set "setupExit=false"
set "REPO_URL=https://github.com/tamld/helpdesk-tools/archive/refs/heads/main.zip"
set "ZIP_FILE=%tempDir%\repo.zip"
set "EXTRACT_DIR=%tempDir%\repo"

echo [*] Downloading repository ZIP file...
call :log "[INFO] Downloading repository from %REPO_URL%"
powershell -NoProfile -Command ^
    "try { $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%REPO_URL%' -OutFile '%ZIP_FILE%' -ErrorAction Stop; } catch { Write-Host '[ERROR] Failed to download repo ZIP:' $_.Exception.Message; exit 1; }"
if %errorlevel% neq 0 (
    set "setupExit=true"
    call :log "[ERROR] Failed to download repository ZIP file."
    exit /B 1
)

echo [*] Extracting repository ZIP file...
call :log "[INFO] Extracting repository ZIP file"
powershell -NoProfile -Command ^
    "try { Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%EXTRACT_DIR%' -Force -ErrorAction Stop; } catch { Write-Host '[ERROR] Failed to extract repo ZIP:' $_.Exception.Message; exit 1; }"
if %errorlevel% neq 0 (
    set "setupExit=true"
    call :log "[ERROR] Failed to extract repository ZIP file."
    del "%ZIP_FILE%"
    exit /B 1
)

:: Move extracted content to targetDir and remove temporary folders
for /d %%d in ("%EXTRACT_DIR%\helpdesk-tools-main\*") do move "%%d" "%targetDir%" >nul
for %%f in ("%EXTRACT_DIR%\helpdesk-tools-main\*") do move "%%f" "%targetDir%" >nul
rd /s /q "%EXTRACT_DIR%\helpdesk-tools-main"
rd /s /q "%EXTRACT_DIR%"
del "%ZIP_FILE%"
call :log "[INFO] Environment setup completed"
exit /B 0

:: ============================================================
:: FUNCTION: Check & Install Package Managers
:: ============================================================
:checkPackageManagers
set "pmExit=false"
set "wingetInstalled=false"
set "chocoInstalled=false"

:: Check for Winget
where winget >nul 2>&1
if %ERRORLEVEL%==0 (
    echo [*] Winget is installed.
    set "wingetInstalled=true"
    call :log "[INFO] Winget is already installed."
) else (
    cls
    echo [*] Winget is required.
    if "%silentMode%"=="true" (
        echo [*] Silent mode: auto installing Winget.
        call :log "[INFO] Silent mode: auto installing Winget."
        call :installWinget
    ) else (
        choice /C YN /N /M "Install Winget? (Y/N): "
        if errorlevel 2 (
            echo [Error] Winget is not installed. Exiting.
            call :log "[ERROR] User declined Winget installation. Exiting."
            set "pmExit=true"
            exit /B 1
        ) else (
            call :installWinget
        )
    )
)

:: Check for Chocolatey
where choco >nul 2>&1
if %ERRORLEVEL%==0 (
    echo [*] Chocolatey is installed.
    set "chocoInstalled=true"
    call :log "[INFO] Chocolatey is already installed."
) else (
    if "%silentMode%"=="true" (
        echo [*] Silent mode: auto installing Chocolatey.
        call :log "[INFO] Silent mode: auto installing Chocolatey."
        call :installChoco
    ) else (
        echo [*] Chocolatey is optional.
        choice /C YN /N /M "Install Chocolatey? (Y/N): "
        if errorlevel 2 (
            echo [*] Skipping Chocolatey installation.
            call :log "[INFO] User skipped Chocolatey installation."
        ) else (
            call :installChoco
        )
    )
)
exit /B 0

:: ============================================================
:: FUNCTION: Install Winget (Dependencies & Core) from GitHub
:: ============================================================
:installWinget
echo [*] Fetching latest Winget release information from GitHub...
call :log "[INFO] Fetching latest Winget release information from GitHub"
set "GITHUB_API_URL=https://api.github.com/repos/microsoft/winget-cli/releases/latest"

:: Get the MSIXBUNDLE File URL
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command " (Invoke-RestMethod -Uri '%GITHUB_API_URL%' -Headers @{ 'User-Agent'='winget-installer' }).assets | Where-Object { $_.name -like 'Microsoft.DesktopAppInstaller_*.msixbundle' } | Select-Object -First 1 -ExpandProperty browser_download_url"`) do (
    set "MSIXBUNDLE_URL=%%i"
)

:: Get the DesktopAppInstaller_Dependencies.zip File URL
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command " (Invoke-RestMethod -Uri '%GITHUB_API_URL%' -Headers @{ 'User-Agent'='winget-installer' }).assets | Where-Object { $_.name -eq 'DesktopAppInstaller_Dependencies.zip' } | Select-Object -First 1 -ExpandProperty browser_download_url"`) do (
    set "DEP_ZIP_URL=%%i"
)

echo.
echo [*] Detected Assets:
echo     Dependencies ZIP: %DEP_ZIP_URL%
echo     Main Package: %MSIXBUNDLE_URL%
echo.
call :log "[INFO] Detected Winget assets: Main Package: %MSIXBUNDLE_URL%, Dependencies: %DEP_ZIP_URL%"

:: Define local filenames & folders in %tempDir%
set "MSIXBUNDLE_FILE=%tempDir%\Microsoft.DesktopAppInstaller.msixbundle"
set "DEP_ZIP_FILE=%tempDir%\DesktopAppInstaller_Dependencies.zip"
set "DEP_FOLDER=%tempDir%\DesktopAppInstaller_Dependencies"

:: Download files using Start-BitsTransfer
echo [*] Downloading Winget package...
call :log "[INFO] Downloading Winget package..."
powershell -NoProfile -Command "Start-BitsTransfer -Source \"%MSIXBUNDLE_URL%\" -Destination \"%MSIXBUNDLE_FILE%\""
echo [*] Downloading dependencies ZIP file...
call :log "[INFO] Downloading dependencies ZIP file..."
powershell -NoProfile -Command "Start-BitsTransfer -Source \"%DEP_ZIP_URL%\" -Destination \"%DEP_ZIP_FILE%\""

:: Extract Dependencies ZIP
echo [*] Extracting dependencies...
call :log "[INFO] Extracting dependencies..."
powershell -NoProfile -Command "Expand-Archive -Path '%DEP_ZIP_FILE%' -DestinationPath '%DEP_FOLDER%' -Force"

:: Determine System Architecture
set "arch=x64"
if /I "%PROCESSOR_ARCHITECTURE%"=="x86" set "arch=x86"
if /I "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "arch=x64"
if /I "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "arch=arm64"
echo [*] Detected Architecture: %arch%
call :log "[INFO] Detected architecture: %arch%"

:: Install Dependency Packages (.appx files)
echo [*] Installing dependency packages...
for /r "%DEP_FOLDER%\%arch%" %%f in (*.appx) do (
    echo  Installing: %%f
    powershell -NoProfile -Command "Add-AppxPackage -Path '%%~f'"
)

:: Install the Main Winget Package
echo [*] Installing Winget package...
powershell -NoProfile -Command "Add-AppxPackage -Path '%MSIXBUNDLE_FILE%'"

:: Cleanup downloaded files & folders from %tempDir%
echo [*] Cleaning up Winget installer files...
if exist "%MSIXBUNDLE_FILE%" del /f /q "%MSIXBUNDLE_FILE%"
if exist "%DEP_ZIP_FILE%" del /f /q "%DEP_ZIP_FILE%"
if exist "%DEP_FOLDER%" rd /s /q "%DEP_FOLDER%"
call :log "[INFO] Winget installation completed"
exit /B 0

:: ============================================================
:: FUNCTION: Install Chocolatey
:: ============================================================
:installChoco
echo [*] Checking if Chocolatey is installed...
call :log "[INFO] Checking if Chocolatey is installed"

:: Check if Chocolatey is installed by verifying the existence of choco.exe
if exist "C:\ProgramData\chocolatey\bin\choco.exe" (
    echo [*] Chocolatey is already installed. Skipping installation.
    call :log "[INFO] Chocolatey is already installed. Skipping installation."
    goto :eof
)

echo [*] Installing Chocolatey...
:: Run the Chocolatey installation script via PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"

:: Verify the installation by checking for choco.exe
if exist "C:\ProgramData\chocolatey\bin\choco.exe" (
    echo [*] Chocolatey installation completed successfully.
    call :log "[INFO] Chocolatey installation completed successfully."
    set "PATH=%PATH%;C:\ProgramData\chocolatey\bin"
    goto :eof
) else (
    echo [Warning] Chocolatey installation failed.
    call :log "[WARNING] Chocolatey installation failed."
    exit /B 1
)

exit /B 0

:: ============================================================
:: FUNCTION: Validate Directory Structure
:: ============================================================
:validateStructure
echo [*] Validating directory structure...
set "errorFlag=0"
set "items=%configDir% %manifestDir% %wingetDir% %chocoDir% %moduleDir%"
set "categories=software office utils"
for %%C in (%categories%) do (
    set "items=%items% %wingetDir%\%%C.yaml"
    set "items=%items% %chocoDir%\%%C.json"
)
for %%I in (%items%) do (
    if not exist "%%~I" (
        echo [Missing] %%~I
        set "errorFlag=1"
    )
)
if %errorFlag%==1 (
    echo [Error] Directory structure is invalid.
    call :log "[ERROR] Directory structure is invalid."
    exit /B 1
)
call :log "[INFO] Directory structure validated successfully"
exit /B 0

:: ============================================================
:: FUNCTION: Clean Temporary Files
:: ============================================================
:clean
echo [*] Cleaning temporary files...
if exist "%tempDir%" rd /s /q "%tempDir%" >nul
echo [*] Temporary files removed.
call :log "[INFO] Cleaned temporary files."
exit /B 0

:: ============================================================
:: FUNCTION: Elevate Privileges (UAC)
:: ============================================================
:goUac
echo [*] Elevating privileges...
echo Set UAC = CreateObject^("Shell.Application"^) > "%tempDir%\getadmin.vbs"
echo UAC.ShellExecute "cmd.exe", "/c %~s0 %*", "", "runas", 1 >> "%tempDir%\getadmin.vbs"
"%tempDir%\getadmin.vbs"
del "%tempDir%\getadmin.vbs"
exit /B

:: ============================================================
:: MENU HANDLERS
:: ============================================================
:softwareDeploymentMenu
call :log "[INFO] Entering Software Deployment Menu"
call "%moduleDir%\software.cmd"
goto mainLoop

:utilitiesMenu
call :log "[INFO] Entering System Utilities Menu"
call "%moduleDir%\utils.cmd"
goto mainLoop

:packageManagementMenu
echo [*] Package Management Console
call :log "[INFO] Entering Package Management Menu"
goto mainLoop

:updateCmd
echo [*] Placeholder for Update Script
call :log "[INFO] Update CMD selected (placeholder)"
goto mainLoop

:exit
cls
echo [*] Exiting Helpdesk Tools. Goodbye!
call :log "[INFO] Exiting Helpdesk Tools."
exit

:: ============================================================
:: FUNCTION: Log Message with Timestamp
:: Usage: call :log "Your message here"
:: ============================================================
:log
setlocal EnableDelayedExpansion
set "msg=%*"
echo %date% %time% - !msg! >> "%LOGFILE%"
endlocal & exit /B 0

:: ============================================================
:: LABEL: refreshEnv
:: Refresh environment variables from registry and update current CMD session.
:: Temporary files are stored in %tempDir%.
:: ============================================================
:refreshEnv
setlocal EnableDelayedExpansion

echo Refreshing environment variables from registry. Please wait...

:: --- Begin: Inline functions from RefreshEnv.cmd ---
:: Function: SetFromReg
:SetFromReg
    "%WinDir%\System32\Reg" QUERY "%~1" /v "%~2" > "%tempDir%\_envset.tmp" 2>NUL
    for /f "usebackq skip=2 tokens=2,*" %%A in ("%tempDir%\_envset.tmp") do (
        set "%%~3=%%B"
    )
    goto :EOF

:: Function: GetRegEnv
:GetRegEnv
    "%WinDir%\System32\Reg" QUERY "%~1" > "%tempDir%\_envget.tmp"
    for /f "usebackq skip=2" %%A in ("%tempDir%\_envget.tmp") do (
        if /I not "%%~A"=="Path" (
            call :SetFromReg "%~1" "%%~A" "%%~A"
        )
    )
    goto :EOF
:: --- End: Inline functions ---

:: Create a temporary batch file with environment variable settings in %tempDir%
>"%tempDir%\_env.cmd" echo @echo off
call :GetRegEnv "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" >> "%tempDir%\_env.cmd"
call :GetRegEnv "HKCU\Environment" >> "%tempDir%\_env.cmd"

:: Special handling for PATH: combine system and user PATH
call :SetFromReg "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" Path Path_HKLM >> "%tempDir%\_env.cmd"
call :SetFromReg "HKCU\Environment" Path Path_HKCU >> "%tempDir%\_env.cmd"
>> "%tempDir%\_env.cmd" echo set "Path=%%Path_HKLM%%;%%Path_HKCU%%"

:: Cleanup temporary files used for registry query
del /f /q "%tempDir%\_envset.tmp" 2>nul
del /f /q "%tempDir%\_envget.tmp" 2>nul

:: Apply the environment variable changes
call "%tempDir%\_env.cmd"
del /f /q "%tempDir%\_env.cmd" 2>nul

echo Environment variables refreshed.
endlocal & goto :EOF
