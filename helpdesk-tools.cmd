@echo off
set silentMode=false

:: Check for silent mode parameter
for %%x in (%*) do (
    if /i "%%x"=="-s" set silentMode=true
    if /i "%%x"=="--silent" set silentMode=true
)

>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo [Error] Please run as Administrator!
    if not "%silentMode%"=="true" pause
    goto goUac
)

:goAdmin
pushd "%CD%"
CD /D "%~dp0"

:: Define directories
set "workDir=%~dp0"
set "targetDir=%workDir%helpdesk-tools"
set "configDir=%targetDir%\config"
set "manifestDir=%targetDir%\manifest"
set "wingetDir=%manifestDir%\winget"
set "chocoDir=%manifestDir%\choco"
set "moduleDir=%targetDir%\modules"
set "tempDir=%targetDir%\temp"
set "projectManifest=%configDir%\project_manifest.json"

:: Initialize temp directory
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

:: Entry Point
cls
echo ================================================
echo          Welcome to Helpdesk Tools
echo ================================================

:: 1. System Validation and OS Info
echo Checking System Requirements...
call :checkRequirements
if not "%requirementsMet%"=="true" (
    echo [Error] System does not meet requirements. Exiting...
    if not "%silentMode%"=="true" pause
    exit /B 1
)
echo.
ping -n 3 localhost > nul
cls

:: 2. User Agreement
echo Showing User Disclaimer...
call :showDisclaimer || exit /B 1
cls

:: 3. Fetch API, Create Structure, Install Package Managers
echo Setting up Environment (Fetching Files, Package Managers)...
call :setupEnvironment
if "%setupExit%"=="true" (
    echo [Error] Environment setup was not completed. Exiting...
     if not "%silentMode%"=="true" pause
    exit /B 1
)
cls

:: Install Package Managers
call :checkPackageManagers
if "%pmExit%"=="true" (
    echo [Error] Winget or Chocolatey setup was not completed. Exiting...
    if not "%silentMode%"=="true" pause
    exit /B 1
)
goto mainLoop


:: ==================
:: Main Menu and Navigation
:mainLoop
call :mainMenu
goto mainLoop

:mainMenu
cls
echo    ========================================================
echo    [1] Software Deployment                         : Press 1
echo    [2] System Utilities                           : Press 2
echo    [3] Package Management                         : Press 3
echo    [4] Update CMD                                 : Press 4
echo    [5] Exit                                       : Press 5
echo    ========================================================

if "%silentMode%"=="true" (
    echo Running in Silent Mode. Type 5 and Press Enter to Exit
)
choice /N /C 12345 /M "Your choice is: "
echo.

if %errorlevel% == 5 call :clean & goto exit
if %errorlevel% == 4 call :updateCmd & goto mainMenu
if %errorlevel% == 3 goto packageManagementMenu & goto mainMenu
if %errorlevel% == 2 goto utilitiesMenu & goto mainMenu
if %errorlevel% == 1 goto softwareDeploymentMenu & goto mainMenu
goto mainMenu

:: ========================================================
:: Function Definitions
:: ========================================================

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
    echo [Error] Requires Windows 10 1809+ or Windows 11
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

:showDisclaimer
cls
echo IMPORTANT: This script uses Winget and optionally Chocolatey.
echo SECURITY WARNING: Running scripts involves risks.
echo - Script modifications are your responsibility.
echo - This script will install software and change system settings.
echo - The author is not liable for any issues.
echo - No harm is intended by the script author.
echo.

if "%silentMode%"=="true" (
    echo Proceeding with script execution in silent mode as disclaimer is assumed to be accepted.
    exit /B 0
) else (
    choice /C YN /N /M "Do you agree to proceed? (Y/N): "
    if errorlevel 2 (
        echo You chose NOT to proceed. Exiting...
        exit /B 1
    )
    exit /B 0
)

:setupEnvironment
set "setupExit=false"
set "REPO_URL=https://github.com/tamld/helpdesk-tools/archive/refs/heads/main.zip"
set "ZIP_FILE=%temp%\repo.zip"
set "EXTRACT_DIR=%tempDir%\repo"

:: Create temp directory
if not exist "%tempDir%" (
    mkdir "%tempDir%" || (
        echo [ERROR] Failed to create temp directory
        if not "%silentMode%"=="true" pause
        set "setupExit=true"
        exit /B 1
    )
)

:: Delete old content
echo Deleting old content from target directory...
if exist "%targetDir%" (
    for /f "delims=" %%i in ('dir /b /ad "%targetDir%"') do (
        rd /s /q "%targetDir%\%%i"
    )
     for /f "delims=" %%i in ('dir /b "%targetDir%"') do (
       if not "%%i"=="temp" if not "%%i"=="helpdesk-tools.cmd" del /f /q "%targetDir%\%%i"
    )
)

:: Download ZIP file with try-catch
echo [1/2] Downloading repository ZIP file...
powershell -NoProfile -Command ^
    "try { " ^
    "   $ProgressPreference='SilentlyContinue'; " ^
    "   Invoke-WebRequest -Uri '%REPO_URL%' -OutFile '%ZIP_FILE%' -ErrorAction Stop; " ^
    "} catch { " ^
    "   Write-Host '[ERROR] Failed to download repository ZIP file: ' $_.Exception.Message; " ^
    "   exit 1; " ^
    "}"
if %errorlevel% neq 0 (
    set "setupExit=true"
    exit /B 1
)

:: Extract ZIP file with try-catch
echo [2/2] Extracting repository ZIP file...
powershell -NoProfile -Command ^
    "try { " ^
    "   Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%EXTRACT_DIR%' -Force -ErrorAction Stop; " ^
    "} catch { " ^
     "   Write-Host '[ERROR] Failed to extract repository ZIP file: ' $_.Exception.Message; " ^
    "   exit 1; " ^
    "}"
if %errorlevel% neq 0 (
    set "setupExit=true"
    del "%ZIP_FILE%"
    exit /B 1
)

:: Delete the zip file
del "%ZIP_FILE%"

:: Move extracted content to target dir
for /d %%d in ("%EXTRACT_DIR%\helpdesk-tools-main\*") do move "%%d" "%targetDir%" >nul
for %%f in ("%EXTRACT_DIR%\helpdesk-tools-main\*") do move "%%f" "%targetDir%" >nul
rd /s /q "%EXTRACT_DIR%\helpdesk-tools-main"

:: Create project_manifest.json
echo Creating project_manifest.json...
powershell -NoProfile -Command ^
    "$manifest = @{ 'downloaded_at' = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ');};" ^
    "$manifest | ConvertTo-Json -Depth 4 | Out-File '%projectManifest%' -Encoding UTF8;"

exit /B 0


:checkPackageManagers
set "pmExit=false"
set "wingetInstalled=false"
set "chocoInstalled=false"

:: Check for Winget
where winget > nul 2>&1
if %ERRORLEVEL%==0 (
    echo Winget is found on this system.
    set "wingetInstalled=true"
) else (
	cls
    echo Winget is required for core functionality.
    if "%silentMode%"=="true" (
        echo Silent mode: Proceeding with Winget installation.
        call :installWinget  :: Directly call installWinget which now includes XAML
    ) else (
        choice /C YN /N /M "Do you want to install Winget? Press N to exit script (Y/N): "
        if errorlevel 2 (
            echo [Error] Winget is not installed. Cannot proceed.
            set "pmExit=true"
            exit /B 1
        ) else (
            call :installWinget  :: Directly call installWinget which now includes XAML
        )
    )
)

:: Check for Chocolatey
where choco > nul 2>&1
if %ERRORLEVEL%==0 (
    echo Chocolatey is found on this system.
    set "chocoInstalled=true"
) else (
  if "%silentMode%"=="true" (
       echo Chocolatey is not found on this system.
        echo Silent mode: Proceeding with Chocolatey installation.
        call :installChoco
     ) else (
        echo Chocolatey is optional but recommended for additional features.
        choice /C YN /N /M "Do you want to install Chocolatey? Press N to exit script (Y/N): "
        if errorlevel 2 (
            echo Skipping Chocolatey installation.
        ) else (
            call :installChoco
        )
    )
)
exit /B 0


:installWinget
echo Installing Winget and required components...

:: Install XAML Framework
echo Checking Microsoft.UI.Xaml requirements...
where winget >nul 2>&1 && goto installWingetCore  :: If winget exists, skip XAML install

:: Get latest stable version
echo Fetching latest Microsoft.UI.Xaml version...
for /f "delims=" %%v in ('powershell -NoProfile -Command "(Invoke-RestMethod 'https://api.nuget.org/v3-flatcontainer/microsoft.ui.xaml/index.json').versions | Where-Object { $_ -match '^\d+\.\d+\.\d+$' } | Sort-Object -Descending | Select-Object -First 1"') do set "XAML_VERSION=%%v"

if "%XAML_VERSION%"=="" (
    echo [Error] Failed to fetch Microsoft.UI.Xaml version.
    exit /B 1
)

echo Latest stable version: %XAML_VERSION%

:: Download and install XAML
set "xamlUrl=https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/%XAML_VERSION%"
set "xamlPackage=%tempDir%\xaml.zip"

echo Downloading Microsoft.UI.Xaml...
powershell -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%xamlUrl%' -OutFile '%xamlPackage%'"

echo Extracting package...
powershell -Command "Expand-Archive -Path '%xamlPackage%' -DestinationPath '%tempDir%\xaml' -Force"

set "arch=x64"
if "%PROCESSOR_ARCHITECTURE%"=="x86" set "arch=x86"
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "arch=arm64"

echo Installing Microsoft.UI.Xaml for %arch% architecture...
powershell -Command "Add-AppxPackage -Path '%tempDir%\xaml\tools\AppX\%arch%\Release\Microsoft.UI.Xaml.2.8.appx'"
del /q "%xamlPackage%" 2>nul
:: End XAML Installation

:installWingetCore
echo Installing Winget...
set "wingetBundle=%tempDir%\winget.msixbundle"
powershell -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile '%wingetBundle%'"
powershell -Command "Add-AppxPackage -Path '%wingetBundle%' -ForceApplicationShutdown"
set "PATH=%PATH%;%LOCALAPPDATA%\Microsoft\WindowsApps"
del /q "%wingetBundle%" 2>nul
rd /q /s %tempDir%\xaml
where winget >nul 2>&1 || (
    echo [Error] Failed to install Winget.
    exit /B 1
)
exit /B 0

:installChoco
echo Installing Chocolatey...
::powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" >nul
powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
set "PATH=%PATH%;C:\ProgramData\chocolatey\bin"
where choco >nul 2>&1 || (
    echo [Warning] Chocolatey installation failed.
    exit /B 0
)
exit /B 0

:validateStructure
echo Validating directory structure...
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
    exit /B 1
)
exit /B 0

:clean
echo Cleaning temporary files...
if exist "%tempDir%" rd /s /q "%tempDir%" >nul
if exist "%tempDir%\xaml" rd /s /q "%tempDir%\xaml" >nul
echo Temporary files removed
exit /B 0

:goUac
echo Elevating privileges...
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "cmd.exe", "/c %~s0 %*", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
del "%temp%\getadmin.vbs"
exit /B

:: ========================================================
:: MENU HANDLERS
:: ========================================================

:softwareDeploymentMenu
call "%moduleDir%\software.cmd"
goto mainMenu

:utilitiesMenu
call "%moduleDir%\utils.cmd"
goto mainMenu

:packageManagementMenu
echo Package management console
goto mainMenu

:updateCmd
echo Placeholder for Update Script
goto mainMenu

:exit
cls
echo Exiting Helpdesk Tools. Goodbye!
exit /B 0