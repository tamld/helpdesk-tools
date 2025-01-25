@echo off
:: ========================================================
:: Helpdesk Tools - Full Script with Integrated Package Management and OS Info
:: ========================================================

:: --------------------------
:: Check Administrator Rights
:: --------------------------
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo [Error] Please run as Administrator!
    pause
    goto goUac
)

:goAdmin
pushd "%CD%"
CD /D "%~dp0"

:: Define directories
set "workDir=%~dp0"
set "configDir=%workDir%config"
set "manifestDir=%workDir%manifest"
set "wingetDir=%manifestDir%\winget"
set "chocoDir=%manifestDir%\choco"
set "moduleDir=%workDir%modules"
set "tempDir=%workDir%temp"

:: Initialize temp directory
if not exist "%tempDir%" (
    mkdir "%tempDir%" || (
        echo [ERROR] Failed to create temp directory
        pause
        exit /B 1
    )
)

:: Entry Point
cls
echo ================================================
echo          Welcome to Helpdesk Tools
echo ================================================

:: 1. System Validation and OS Info
call :checkRequirements
if not "%requirementsMet%"=="true" (
    echo [Error] System does not meet requirements. Exiting...
    exit /B 1
)

:: 2. User Agreement
call :showDisclaimer || exit /B 1

:: 3. Initialize Package Managers (Winget/Chocolatey)
call :checkPackageManagers
if "%pmExit%"=="true" (
    echo [Error] Winget or Chocolatey setup was not completed. Exiting...
    exit /B 1
)

:: 4. Validate structure and files
call :validateStructure || exit /B 1

:: ==================
:: Main Menu
:mainMenu
cls
echo    ========================================================
echo    [1] Install All In One Online                  : Press 1
echo    [2] Windows Office Utilities                   : Press 2
echo    [3] Active Licenses                            : Press 3
echo    [4] Utilities                                  : Press 4
echo    [5] Package Management                         : Press 5
echo    [6] Update CMD                                 : Press 6
echo    [7] Exit                                       : Press 7
echo    ========================================================

choice /N /C 1234567 /M "Your choice is :"
echo.

if %ERRORLEVEL% == 7 call :clean & exit /B 0
if %ERRORLEVEL% == 6 call :updateCmd & goto mainMenu
if %ERRORLEVEL% == 5 goto packageManagementMenu
if %ERRORLEVEL% == 4 goto utilitiesMenu
if %ERRORLEVEL% == 3 goto activeLicensesMenu
if %ERRORLEVEL% == 2 goto officeWindowsMenu
if %ERRORLEVEL% == 1 goto installAioMenu

goto :mainMenu

:: ========================================================
:: Function Definitions
:: ========================================================

:checkRequirements
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
exit /B 0

:showDisclaimer
echo IMPORTANT: This script relies on Winget for core functionality.
echo Winget is a native app on Windows 11 but may not be installed on Windows 10.
echo Chocolatey is an optional package manager that can enhance the script's capabilities.
echo.
echo SECURITY WARNING: Please be aware of the security implications of running scripts.
echo The script owner is not responsible for any damage or issues caused by modified or edited scripts.
echo.
echo By proceeding, you acknowledge that you understand the following:
echo - You are aware that this script will execute code to fine-tune, optimize, and install software on your system.
echo - The script author has no intent to attack, harm, or damage your system.
echo.
choice /C YN /N /M "Do you agree to proceed with this script? (Y/N): "
if errorlevel 2 (
    echo You chose NOT to proceed. Exiting...
    exit /B 1
)
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
    echo Winget is required for core functionality.
    choice /C YN /N /M "Do you want to install Winget? (Y/N): "
    if errorlevel 2 (
        echo [Error] Winget is not installed. Cannot proceed.
        set "pmExit=true"
        exit /B 1
    ) else (
        call :installXamlFramework || goto wingetInstallError
        call :installWinget || exit /B 1
    )
)

:: Check for Chocolatey
where choco > nul 2>&1
if %ERRORLEVEL%==0 (
    echo Chocolatey is found on this system.
    set "chocoInstalled=true"
) else (
    echo Chocolatey is optional but recommended for additional features.
    choice /C YN /N /M "Do you want to install Chocolatey? (Y/N): "
    if errorlevel 2 (
        echo Skipping Chocolatey installation.
    ) else (
        call :installChoco
    )
)
exit /B 0

:installXamlFramework
echo Checking Microsoft.UI.Xaml requirements...
where winget >nul 2>&1 && exit /B 0

:: Get latest stable version
echo Fetching latest Microsoft.UI.Xaml version...
for /f "delims=" %%v in ('powershell -NoProfile -Command "(Invoke-RestMethod 'https://api.nuget.org/v3-flatcontainer/microsoft.ui.xaml/index.json').versions | Where-Object { $_ -match '^\d+\.\d+\.\d+$' } | Sort-Object -Descending | Select-Object -First 1"') do set "XAML_VERSION=%%v"

if "%XAML_VERSION%"=="" (
    echo [Error] Failed to fetch Microsoft.UI.Xaml version.
    exit /B 1
)

echo Latest stable version: %XAML_VERSION%

:: Download and install
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
exit /B 0

:installWinget
echo Installing Winget...
set "wingetBundle=%tempDir%\winget.msixbundle"
powershell -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile '%wingetBundle%'"
powershell -Command "Add-AppxPackage -Path '%wingetBundle%' -ForceApplicationShutdown"
del /q "%wingetBundle%" 2>nul
where winget >nul 2>&1 || (
    echo [Error] Failed to install Winget.
    exit /B 1
)
exit /B 0

:installChoco
echo Installing Chocolatey...
powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" >nul
where choco >nul 2>&1 || (
    echo [Warning] Chocolatey installation failed.
    exit /B 0
)
exit /B 0

:validateStructure
echo Validating directory structure...
set "errorFlag=0"
set "items=%configDir% %manifestDir% %wingetDir% %chocoDir% %moduleDir%"
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

:fullDeploymentMenu
call "%moduleDir%\software.cmd"
pause
goto mainMenu

:officeWindowsMenu
call "%moduleDir%\office.cmd"
pause
goto mainMenu

:utilitiesMenu
call "%moduleDir%\utils.cmd"
pause
goto mainMenu

:packageManagementMenu
echo Package management console
pause
goto mainMenu

:updateCmd
echo Placeholder for Update Script
pause
goto mainMenu

:exit
cls
echo Exiting Helpdesk Tools. Goodbye!
pause
exit /B 0