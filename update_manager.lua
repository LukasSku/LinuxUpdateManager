#!/usr/bin/env lua

local function execute(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result:gsub("^%s*(.-)%s*$", "%1")
end

local colors = {
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    cyan = "\27[36m",
    magenta = "\27[35m",
    reset = "\27[0m",
    bold = "\27[1m",
    dim = "\27[2m"
}

local function clear_screen()
    os.execute("clear")
end

local function pause(message)
    io.write(colors.yellow .. (message or "Press Enter to continue...") .. colors.reset)
    io.read()
end

local function show_system_info()
    local os_info = execute("cat /etc/os-release")
    local kernel = execute("uname -r")
    local cpu = execute("cat /proc/cpuinfo | grep 'model name' | head -n1"):match("model name%s*:%s*(.*)")
    local uptime = execute("uptime -p")
    
    print(colors.cyan .. colors.bold .. "System Information:" .. colors.reset)
    print(colors.yellow .. "OS:" .. colors.reset .. " " .. (os_info:match('PRETTY_NAME="(.-)"') or "Unknown"))
    print(colors.yellow .. "Kernel:" .. colors.reset .. " " .. kernel)
    print(colors.yellow .. "CPU:" .. colors.reset .. " " .. (cpu or "Unknown"))
    print(colors.yellow .. "Uptime:" .. colors.reset .. " " .. uptime:gsub("up ", ""))
    print("")
end

local function detect_package_manager()
    local apt = execute("which apt")
    if apt ~= "" then return "apt" end
    
    local dnf = execute("which dnf")
    if dnf ~= "" then return "dnf" end
    
    local pacman = execute("which pacman")
    if pacman ~= "" then return "pacman" end
    
    return nil
end

local function check_updates(pkg_manager)
    local updates = {}
    print(colors.blue .. "Checking for updates..." .. colors.reset)
    
    if pkg_manager == "apt" then
        print(colors.dim .. "Running apt update..." .. colors.reset)
        os.execute("apt update >/dev/null 2>&1")
        
        local result = execute("LANG=C apt list --upgradable 2>/dev/null")
        for line in result:gmatch("[^\r\n]+") do
            local pkg = line:match("^([^/]+)")
            local version = line:match("%(.-%)") or line:match("%[.-%]")
            if pkg and version and not line:match("Listing...") then
                local priority = line:match("security") and "critical" or "normal"
                table.insert(updates, {
                    name = pkg,
                    version = version:gsub("[%(%[%]%)]", ""),
                    priority = priority
                })
            end
        end
    
    elseif pkg_manager == "dnf" then
        local result = execute("dnf check-update")
        for line in result:gmatch("[^\r\n]+") do
            local pkg, version = line:match("^(%S+)%s+(%S+)")
            if pkg and version and not line:match("Last metadata") then
                local priority = line:match("security") and "critical" or "normal"
                table.insert(updates, {
                    name = pkg,
                    version = version,
                    priority = priority
                })
            end
        end
    
    elseif pkg_manager == "pacman" then
        os.execute("pacman -Sy >/dev/null 2>&1")
        local result = execute("pacman -Qu")
        for line in result:gmatch("[^\r\n]+") do
            local pkg, version = line:match("^(%S+)%s+(%S+)")
            if pkg and version then
                table.insert(updates, {
                    name = pkg,
                    version = version,
                    priority = "normal"
                })
            end
        end
    end
    
    return updates
end

local function install_updates(pkg_manager, specific_pkg)
    if pkg_manager == "apt" then
        if specific_pkg then
            return os.execute("apt install -y " .. specific_pkg)
        else
            return os.execute("apt upgrade -y")
        end
    elseif pkg_manager == "dnf" then
        if specific_pkg then
            return os.execute("dnf update -y " .. specific_pkg)
        else
            return os.execute("dnf upgrade -y")
        end
    elseif pkg_manager == "pacman" then
        if specific_pkg then
            return os.execute("pacman -S --noconfirm " .. specific_pkg)
        else
            return os.execute("pacman -Syu --noconfirm")
        end
    end
    return false
end

local function draw_ui(updates, pkg_manager)
    clear_screen()
    print(colors.cyan .. colors.bold .. "╔════════════════════════════════════════╗")
    print("║         Linux Update Manager           ║")
    print("╚════════════════════════════════════════╝" .. colors.reset)
    
    show_system_info()
    
    print(colors.dim .. "Package Manager: " .. pkg_manager .. colors.reset)
    print("")
    
    if #updates > 0 then
        print(colors.yellow .. "Available Updates:" .. colors.reset)
        print(string.format("%-4s %-30s %-15s %s", "No.", "Package", "Version", "Priority"))
        print(string.rep("-", 65))
        
        for i, update in ipairs(updates) do
            local priority_color = colors.reset
            if update.priority == "critical" then
                priority_color = colors.red
            elseif update.priority == "high" then
                priority_color = colors.yellow
            end
            
            print(string.format("%-4d %-30s %-15s %s", 
                i, 
                colors.cyan .. update.name .. colors.reset,
                colors.green .. update.version .. colors.reset,
                priority_color .. (update.priority or "normal") .. colors.reset
            ))
        end
        print("")
        print(colors.dim .. "Total updates: " .. #updates .. colors.reset)
    else
        print(colors.green .. "No updates available!" .. colors.reset)
    end
    print("")
    
    print(colors.yellow .. "Available Actions:" .. colors.reset)
    print("1. Check for updates")
    if #updates > 0 then
        print("2. Install all updates")
        print("3. Install specific update")
        print("4. Show critical updates only")
    end
    print("5. Refresh system information")
    print("q. Quit")
    print("")
end

-- Main program
if os.getenv("USER") ~= "root" then
    print(colors.red .. "This program must be run with sudo!" .. colors.reset)
    os.exit(1)
end

local pkg_manager = detect_package_manager()
if not pkg_manager then
    print(colors.red .. "No supported package manager found!" .. colors.reset)
    print("Supported package managers: apt, dnf, pacman")
    os.exit(1)
end

local updates = {}

while true do
    draw_ui(updates, pkg_manager)
    io.write(colors.yellow .. "Choose an option: " .. colors.reset)
    local choice = io.read()
    
    if choice == "1" then
        updates = check_updates(pkg_manager)
    
    elseif choice == "2" and #updates > 0 then
        print(colors.blue .. "Installing all updates..." .. colors.reset)
        if install_updates(pkg_manager) then
            print(colors.green .. "Updates installed successfully!" .. colors.reset)
            updates = check_updates(pkg_manager)
        else
            print(colors.red .. "Error installing updates!" .. colors.reset)
        end
        pause()
    
    elseif choice == "3" and #updates > 0 then
        io.write(colors.yellow .. "Choose update number: " .. colors.reset)
        local update_num = tonumber(io.read())
        if update_num and updates[update_num] then
            print(colors.blue .. "Installing " .. updates[update_num].name .. "..." .. colors.reset)
            if install_updates(pkg_manager, updates[update_num].name) then
                print(colors.green .. "Update installed successfully!" .. colors.reset)
                updates = check_updates(pkg_manager)
            else
                print(colors.red .. "Error installing update!" .. colors.reset)
            end
        else
            print(colors.red .. "Invalid selection!" .. colors.reset)
        end
        pause()
    
    elseif choice == "4" and #updates > 0 then
        local critical_updates = {}
        for _, update in ipairs(updates) do
            if update.priority == "critical" then
                table.insert(critical_updates, update)
            end
        end
        if #critical_updates > 0 then
            print(colors.red .. "\nCritical Updates:" .. colors.reset)
            for i, update in ipairs(critical_updates) do
                print(string.format("%d. %s -> %s", 
                    i, 
                    colors.cyan .. update.name .. colors.reset,
                    colors.red .. update.version .. colors.reset
                ))
            end
        else
            print(colors.green .. "\nNo critical updates found." .. colors.reset)
        end
        pause()
    
    elseif choice == "5" then
        clear_screen()
        show_system_info()
        pause()
    
    elseif choice == "q" then
        clear_screen()
        print(colors.green .. "Exiting..." .. colors.reset)
        os.exit(0)
    end
end
