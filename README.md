# Linux Update Manager

A user-friendly, interactive command-line update manager for Linux systems, written in Lua.

## Features

- Support for multiple package managers (apt, dnf, pacman)
- Clean terminal user interface
- Display of system and update information
- Color-coded output for better readability
- Selective update installation
- Critical updates highlighting

## Prerequisites

- Lua 5.3 or higher
- Root/sudo privileges
- One of the supported package managers:
  - apt (Debian/Ubuntu)
  - dnf (Fedora/RHEL)
  - pacman (Arch Linux)

## Installation

1. First, ensure Lua is installed on your system:

   ```bash
   # Debian/Ubuntu
   sudo apt install lua5.3

   # Fedora
   sudo dnf install lua

   # Arch Linux
   sudo pacman -S lua
   ```

2. Download the update manager:
   ```bash
   wget https://raw.githubusercontent.com/LukasSku/LinuxUpdateManager/refs/heads/main/update_manager.lua
   ```

3. Make it executable:
   ```bash
   chmod +x update_manager.lua
   ```


## Usage

Run the script with sudo privileges:
```bash
sudo ./update_manager.lua
```


### Available Options

1. Check for updates
2. Install all updates
3. Install specific update
4. Show critical updates only
5. Refresh system information
q. Quit
