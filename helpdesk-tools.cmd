@echo off
:: Helpdesk Tools - Main Orchestrator Script

:: Check if script is running as administrator
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo  Run CMD as Administrator...
    goto goUac
)

:goAdmin
    pushd "%CD%"
    CD /D "%~dp0"

:: Define main directories
set workDir=%~dp0
set configDir=%workDir%config
set manifestDir=%workDir%manifest
set wingetDir=%manifestDir%\winget
set chocoDir=%manifestDir%\choco
set moduleDir=%workDir%modules

:: Define manifest categories
set categories=productivity utilities development

:: Main Entry Point
echo ====================================================
echo          Welcome to Helpdesk Tools Orchestrator
echo ====================================================

:: Validate structure and files
call :validateStructure
if not "%allItemsExist%"=="true" (
    echo Cannot continue. Please ensure all required files and folders are present.
    pause
    exit /B 1
)

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

:: Get single key press
choice /N /C 1234567 /M " Your choice is :"

:: Handle choice
if %ERRORLEVEL% == 7 call :clean && goto exit
if %ERRORLEVEL% == 6 call :updateCmd & goto mainMenu
if %ERRORLEVEL% == 5 goto packageManagementMenu
if %ERRORLEVEL% == 4 goto utilitiesMenu
if %ERRORLEVEL% == 3 goto activeLicensesMenu
if %ERRORLEVEL% == 2 goto officeWindowsMenu
if %ERRORLEVEL% == 1 goto installAioMenu

goto :mainMenu

:: Label for Install All In One Menu
:installAioMenu
call "%moduleDir%\software.cmd"
goto :mainMenu

:: Label for Office Windows Menu
:officeWindowsMenu
call "%moduleDir%\office.cmd"
goto :mainMenu

:: Label for Active Licenses Menu
:activeLicensesMenu
echo Placeholder for Active Licenses
goto :mainMenu

:: Label for Utilities Menu
:utilitiesMenu
call "%moduleDir%\utils.cmd"
goto :mainMenu

:: Label for Package Management Menu
:packageManagementMenu
echo Placeholder for Manage Packages
goto :mainMenu

:: Label to Update CMD
:updateCmd
echo Placeholder for Update Script
goto :mainMenu

:: Label to Validate File and Folder Structure
:validateStructure
echo Validating file and folder structure...

:: Define the array of items to check
set "items="
set "items=%configDir% %manifestDir% %wingetDir% %chocoDir% %moduleDir%"

for %%C in (%categories%) do (
    set "items=%items% %wingetDir%\%%C.yaml"
    set "items=%items% %chocoDir%\%%C.json"
)

set "items=%items% %configDir%\settings.json %workDir%README.md %workDir%.gitignore %workDir%helpdesk-tools.cmd"
set "items=%items% %moduleDir%\software.cmd %moduleDir%\system.cmd %moduleDir%\office.cmd %moduleDir%\utils.cmd"

:: Check if all items exist
set "allItemsExist=true"
for %%I in (%items%) do (
    dir /b "%%~I" > nul 2>&1
    if errorlevel 1 (
        echo Missing: %%~I
        set "allItemsExist=false"
    )
)

:: Output result
if "%allItemsExist%"=="true" (
    echo All required files and folders found.
) else (
    echo Some required files or folders are missing.
)

goto :eof

:exit
cls
echo Exiting Helpdesk Tools. Goodbye!
pause
exit /B 0

:: Go UAC to get Admin privileges
:goUac
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B
