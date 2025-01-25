<h1 align="center">📦 Helpdesk Tools</h1>

<p align="center">
  <img src="https://img.shields.io/badge/status-active-brightgreen" alt="Status">
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License">
  <img src="https://img.shields.io/github/downloads/helpdesk-tools/total.svg">
</p>
<p align="center">
  <img src="https://img.shields.io/github/forks/tamld/helpdesk-tools.svg">
  <img src="https://img.shields.io/github/stars/tamld/helpdesk-tools.svg">
  <img src="https://img.shields.io/github/followers/tamld.svg?style=social&label=Follow&maxAge=2592000">
</p>
A collection of robust CMD scripts and configurations for software management, system utilities, and dynamic updates via GitHub.

---

## **Overview**
**Helpdesk Tools** is a modular CMD-based automation tool designed for:
- Managing software installations and updates.
- Optimizing Windows systems.
- Handling Office-related tasks.
- Dynamically fetching updated scripts from GitHub.

---

## **Features**
- Modular CMD scripts for software and system management.
- Support for JSON and YAML-based configurations.
- Integration with tools like Winget, Chocolatey, jq, and yq.
- Detailed logging for traceability and debugging.
- Automatic fetching of updated scripts from GitHub.

---

## **Project Structure**

```powershell
Project Structure:
Project Root
├── main.cmd           (Entry point for the project)
├── config\            (Stores configuration files)
├── modules\           (Modular CMD scripts for task execution)
├── logs\              (Stores log files)
├── temp\              (Temporary folder for intermediate processing)
├── README.md          (Project documentation)
└── .gitignore         (Rules to exclude unnecessary files from Git)
```
### **File Descriptions:**
- **main.cmd**: The entry point for running tasks and initializing the environment.
- **config**\: Contains configuration files for the project:
  - settings.json: Main configuration file for defining project settings.
  - winget.yaml: Defines the apps to be managed using Winget.
  - choco.json: Defines the apps to be managed using Chocolatey.
- **modules**\: Contains modular CMD scripts for specific tasks:
  - software.cmd: For installing, removing, and updating software.
  - system.cmd: For cleaning temp files, optimizing the system, and checking updates.
  - office.cmd: For managing Office installations and repairs.
  - utils.cmd: Contains utility functions like log generation and admin checks.
- **logs**\: Stores logs for debugging and tracing activities.
- **temp**\: Temporary files for intermediate operations.

---

## **Getting Started:**

### 1. Clone the Repository:
To set up the project, clone the repository to your local system:

```powershell
git clone https://github.com/tamld/helpdesk-tools.git
cd helpdesk-tools
```
### 2. Run the Main Script:
Run main.cmd to initialize the environment:
main.cmd

---

## **Usage:**

### Run Tasks:
- Upon running main.cmd, a menu will be displayed allowing you to:
  - Manage software (install, remove, update).
  - Perform system utilities (cleanup, optimization).
  - Handle Office tasks (install, repair, remove).
  - Run utility functions (log generation, admin validation).

### Dynamic Updates:
- The project fetches the latest module and configuration files from GitHub based on URLs in config/settings.json.

---

## License:
This project is licensed under the MIT License. See the LICENSE file for details.

---

## Support:
For issues or feature requests, open a GitHub issue in this repository.
