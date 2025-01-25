@echo off
:: Define main directories
set WORKDIR=%~dp0
set CONFIGDIR=%WORKDIR%config
set MANIFESTDIR=%WORKDIR%manifest
set WINGETDIR=%MANIFESTDIR%\winget
set CHOCODIR=%MANIFESTDIR%\choco
set MODULEDIR=%WORKDIR%modules
set LOGDIR=%WORKDIR%logs
set TEMPDIR=%WORKDIR%temp
set PICTURESDIR=%WORKDIR%pictures

:: Define manifest categories
set CATEGORIES=productivity utilities development

:: Create directories if they don't exist
echo Creating directories...
if not exist "%CONFIGDIR%" mkdir "%CONFIGDIR%"
if not exist "%MANIFESTDIR%" mkdir "%MANIFESTDIR%"
if not exist "%WINGETDIR%" mkdir "%WINGETDIR%"
if not exist "%CHOCODIR%" mkdir "%CHOCODIR%"
if not exist "%MODULEDIR%" mkdir "%MODULEDIR%"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
if not exist "%TEMPDIR%" mkdir "%TEMPDIR%"
if not exist "%PICTURESDIR%" mkdir "%PICTURESDIR%"

:: Create Winget manifests by category
echo Creating Winget manifests...
for %%C in (%CATEGORIES%) do (
    if not exist "%WINGETDIR%\%%C.yaml" (
        (
            echo # Winget Manifest for %%C
            echo apps:
            echo   - id: Example.App1
            echo     name: Example Application 1
            echo   - id: Example.App2
            echo     name: Example Application 2
        ) > "%WINGETDIR%\%%C.yaml"
    )
)

:: Create Chocolatey manifests by category
echo Creating Chocolatey manifests...
for %%C in (%CATEGORIES%) do (
    if not exist "%CHOCODIR%\%%C.json" (
        (
            echo {
            echo     "apps": [
            echo         { "id": "exampleapp1", "name": "Example Application 1" },
            echo         { "id": "exampleapp2", "name": "Example Application 2" }
            echo     ]
            echo }
        ) > "%CHOCODIR%\%%C.json"
    )
)

:: Create config files
echo Creating configuration files...
if not exist "%CONFIGDIR%\settings.json" (
    (
        echo {
        echo     "log_level": "debug",
        echo     "github_base_url": "https://github.com/tamld/helpdesk-tools",
        echo     "manifest_dir": "%MANIFESTDIR%",
        echo     "files": {
        echo         "main_cmd": "helpdesk-tools.cmd",
        echo         "winget_manifests": "%WINGETDIR%",
        echo         "choco_manifests": "%CHOCODIR%"
        echo     }
        echo }
    ) > "%CONFIGDIR%\settings.json"
)

:: Create empty log files
echo Creating log files...
if not exist "%LOGDIR%\software.log" type nul > "%LOGDIR%\software.log"
if not exist "%LOGDIR%\system.log" type nul > "%LOGDIR%\system.log"
if not exist "%LOGDIR%\office.log" type nul > "%LOGDIR%\office.log"
if not exist "%LOGDIR%\debug.log" type nul > "%LOGDIR%\debug.log"

:: Create README.md if it doesn't exist
echo Creating README.md...
if not exist "%WORKDIR%README.md" (
    (
        echo # Helpdesk Tools
        echo A modular CMD-based automation tool for managing software, optimizing systems, and dynamically updating scripts via GitHub.
        echo.
        echo ---
        echo ## Project Structure
        echo The following folders and files are automatically generated to initialize the project.
        echo - `config`: Stores configuration files such as settings, network, and app manifests.
        echo - `manifest`: Contains Winget and Chocolatey manifests organized by category.
        echo - `modules`: Modular scripts for task execution.
        echo - `logs`: Log files for debugging and monitoring.
        echo - `temp`: Temporary files for intermediate processes.
        echo - `pictures`: Images or logs for documentation purposes.
    ) > "%WORKDIR%README.md"
)

:: Create .gitignore if it doesn't exist
echo Creating .gitignore...
if not exist "%WORKDIR%.gitignore" (
    (
        echo logs/
        echo temp/
        echo Thumbs.db
        echo .DS_Store
        echo .vscode/
        echo .idea/
    ) > "%WORKDIR%.gitignore"
)

:: Create main orchestrator script
echo Creating helpdesk-tools.cmd...
if not exist "%WORKDIR%helpdesk-tools.cmd" (
    (
        echo @echo off
        echo REM Helpdesk Tools - Main Orchestrator Script
        echo echo ====================================================
        echo echo          Welcome to Helpdesk Tools Orchestrator
        echo echo ====================================================
        echo echo [1] Install Applications
        echo echo [2] Manage Office Utilities
        echo echo [3] Perform System Utilities
        echo echo [4] View Logs
        echo echo [5] Manage Packages (Winget/Chocolatey)
        echo echo [6] Update Script
        echo echo [7] Exit
        echo echo ====================================================
        echo set /p choice="Enter your choice: "
        echo if "%choice%"=="1" echo Placeholder for Install Applications
        echo if "%choice%"=="2" echo Placeholder for Manage Office Utilities
        echo if "%choice%"=="3" echo Placeholder for Perform System Utilities
        echo if "%choice%"=="4" echo Placeholder for View Logs
        echo if "%choice%"=="5" echo Placeholder for Manage Packages
        echo if "%choice%"=="6" echo Placeholder for Update Script
        echo if "%choice%"=="7" exit
        echo echo Invalid choice. Please try again.
        echo pause
    ) > "%WORKDIR%helpdesk-tools.cmd"
)

:: Create module scripts if they don't exist
echo Creating module scripts...
if not exist "%MODULEDIR%\software.cmd" (
    (
        echo @echo off
        echo REM Software Management Module
        echo :InstallSoftware
        echo     echo Installing software...
        echo     exit /B
    ) > "%MODULEDIR%\software.cmd"
)

if not exist "%MODULEDIR%\system.cmd" (
    (
        echo @echo off
        echo REM System Utilities Module
        echo :CleanTempFiles
        echo     echo Cleaning temporary files...
        echo     exit /B
    ) > "%MODULEDIR%\system.cmd"
)

if not exist "%MODULEDIR%\office.cmd" (
    (
        echo @echo off
        echo REM Office Management Module
        echo :InstallOffice
        echo     echo Installing Office Suite...
        echo     exit /B
    ) > "%MODULEDIR%\office.cmd"
)

if not exist "%MODULEDIR%\utils.cmd" (
    (
        echo @echo off
        echo REM Utility Module
        echo :Debug
        echo     echo Debugging tools...
        echo     exit /B
    ) > "%MODULEDIR%\utils.cmd"
)

echo Project structure created successfully!
exit /B
