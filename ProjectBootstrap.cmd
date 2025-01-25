@echo off
:: Define main directories
set WORKDIR=%~dp0
set CONFIGDIR=%WORKDIR%config
set MODULEDIR=%WORKDIR%modules
set LOGDIR=%WORKDIR%logs
set TEMPDIR=%WORKDIR%temp

:: Create directories if they don't exist
echo Creating directories...
if not exist "%CONFIGDIR%" mkdir "%CONFIGDIR%"
if not exist "%MODULEDIR%" mkdir "%MODULEDIR%"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
if not exist "%TEMPDIR%" mkdir "%TEMPDIR%"

:: Create README.md if it doesn't exist
echo Creating README.md...
if not exist "%WORKDIR%README.md" (
    (
        echo # Helpdesk Tools
        echo A modular CMD-based automation tool for managing software, optimizing systems, and dynamically updating scripts via GitHub.
        echo.
        echo ---
        echo.
        echo ## Features
        echo - Modular CMD scripts for software and system management.
        echo - Support for JSON and YAML-based configurations.
        echo - Integration with tools like Winget, Chocolatey, jq, and yq.
        echo - Detailed logging for traceability and debugging.
        echo - Automatic fetching of updated scripts from GitHub.
        echo.
        echo ---
        echo.
        echo ## Project Structure
        echo ```
        echo Project Root
        echo ├── main.cmd           (Entry point for the project)
        echo ├── config\\            (Stores configuration files)
        echo ├── modules\\           (Modular CMD scripts for task execution)
        echo ├── logs\\              (Stores log files)
        echo ├── temp\\              (Temporary folder for intermediate processing)
        echo ├── README.md          (Project documentation)
        echo └── .gitignore         (Rules to exclude unnecessary files from Git)
        echo ```
        echo.
        echo ---
        echo.
        echo ## Getting Started
        echo 1. Clone the Repository:
        echo    git clone https://github.com/tamld/helpdesk-tools.git
        echo    cd helpdesk-tools
        echo 2. Run the Main Script:
        echo    main.cmd
        echo.
        echo ---
        echo.
        echo ## License
        echo This project is licensed under the MIT License. See the LICENSE file for details.
    ) > "%WORKDIR%README.md"
)

:: Create .gitignore if it doesn't exist
echo Creating .gitignore...
if not exist "%WORKDIR%.gitignore" (
    (
        echo # Ignore log files
        echo logs/
        echo *.log
        echo.
        echo # Ignore temporary files
        echo temp/
        echo *.tmp
        echo.
        echo # Ignore system files
        echo Thumbs.db
        echo .DS_Store
        echo.
        echo # Ignore IDE settings
        echo .vscode/
        echo .idea/
        echo.
    ) > "%WORKDIR%.gitignore"
)

:: Create configuration files if they don't exist
echo Creating configuration files...
if not exist "%CONFIGDIR%\\settings.json" (
    (
        echo {
        echo     "log_level": "debug",
        echo     "github_base_url": "https://raw.githubusercontent.com/<username>/<repo>/main/",
        echo     "files": {
        echo         "main_cmd": "main.cmd",
        echo         "software_module": "modules/software.cmd",
        echo         "system_module": "modules/system.cmd",
        echo         "office_module": "modules/office.cmd",
        echo         "utils_module": "modules/utils.cmd",
        echo         "winget_config": "config/winget.yaml",
        echo         "choco_config": "config/choco.json"
        echo     }
        echo }
    ) > "%CONFIGDIR%\\settings.json"
)

:: Create module scripts if they don't exist
echo Creating module files...
if not exist "%MODULEDIR%\\software.cmd" (
    (
        echo @echo off
        echo REM Software Management Module
        echo :InstallSoftware
        echo     echo Installing software...
        echo     exit /B
        echo :RemoveSoftware
        echo     echo Removing software...
        echo     exit /B
        echo :UpdateSoftware
        echo     echo Updating software...
        echo     exit /B
    ) > "%MODULEDIR%\\software.cmd"
)

if not exist "%MODULEDIR%\\system.cmd" (
    (
        echo @echo off
        echo REM System Utilities Module
        echo :CleanTempFiles
        echo     echo Cleaning temporary files...
        echo     exit /B
        echo :OptimizeSystem
        echo     echo Optimizing system...
        echo     exit /B
        echo :CheckForUpdates
        echo     echo Checking for system updates...
        echo     exit /B
    ) > "%MODULEDIR%\\system.cmd"
)

if not exist "%MODULEDIR%\\office.cmd" (
    (
        echo @echo off
        echo REM Office Management Module
        echo :InstallOffice
        echo     echo Installing Office suite...
        echo     exit /B
        echo :RepairOffice
        echo     echo Repairing Office installation...
        echo     exit /B
        echo :RemoveOffice
        echo     echo Removing Office suite...
        echo     exit /B
    ) > "%MODULEDIR%\\office.cmd"
)

if not exist "%MODULEDIR%\\utils.cmd" (
    (
        echo @echo off
        echo REM Utilities and Helper Module
        echo :CheckAdminRights
        echo     echo Checking for admin rights...
        echo     exit /B
        echo :GenerateLogFile
        echo     echo Generating log file...
        echo     exit /B
        echo :DebugMode
        echo     echo Debug mode enabled...
        echo     exit /B
    ) > "%MODULEDIR%\\utils.cmd"
)

:: Create empty log files if they don't exist
echo Creating empty log files...
if not exist "%LOGDIR%\\software.log" type nul > "%LOGDIR%\\software.log"
if not exist "%LOGDIR%\\system.log" type nul > "%LOGDIR%\\system.log"
if not exist "%LOGDIR%\\office.log" type nul > "%LOGDIR%\\office.log"
if not exist "%LOGDIR%\\debug.log" type nul > "%LOGDIR%\\debug.log"

echo Project structure created successfully!
exit /B
