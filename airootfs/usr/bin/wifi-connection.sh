#!/bin/bash

# Script to check internet connection and assist with Wi-Fi connection if needed
# For Arch Linux systems with GTK-based GUI interface

# Function to check internet connectivity
check_connection() {
    # Try pinging multiple sites to ensure reliable connection checking
    if ping -c 1 archlinux.org &> /dev/null || ping -c 1 google.com &> /dev/null || ping -c 1 cloudflare.com &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to wait for internet connection
wait_for_connection() {
    local max_attempts=20
    local attempt=1
    local connected=false
    
    if $GUI_AVAILABLE; then
        # Create progress dialog
        (
        while [ $attempt -le $max_attempts ]; do
            echo "# Verifying internet connection... (Attempt $attempt/$max_attempts)"
            echo "$(( (attempt * 100) / max_attempts ))"
            
            if check_connection; then
                connected=true
                break
            fi
            
            attempt=$((attempt + 1))
            sleep 1
        done
        # Ensure 100% is shown briefly before closing
        if $connected; then
            echo "# Connection established!"
            echo "100"
            sleep 1
        fi
        ) | zenity --progress --title="Verifying Connection" --text="Verifying internet connection..." --percentage=0 --auto-close --no-cancel
        
        # Check final result
        if check_connection; then
            zenity --info --title="Connected" --text="Internet connection established successfully!" --timeout=3
            return 0
        else
            zenity --error --title="No Internet" --text="Could not establish internet connection after multiple attempts."
            return 1
        fi
    else
        echo "Verifying internet connection..."
        while [ $attempt -le $max_attempts ]; do
            echo -n "Attempt $attempt/$max_attempts... "
            
            if check_connection; then
                echo "Success!"
                echo "Internet connection established successfully!"
                return 0
            fi
            
            echo "Failed"
            attempt=$((attempt + 1))
            sleep 1
        done
        
        echo "Could not establish internet connection after multiple attempts."
        return 1
    fi
}

# Function to ensure required tools are installed
check_dependencies() {
    # Check if NetworkManager is installed and running
    if ! command -v nmcli &> /dev/null; then
        zenity --error --title="Missing Dependency" --text="NetworkManager (nmcli) is not installed or not in PATH.\n\nPlease install NetworkManager with:\nsudo pacman -S networkmanager\n\nAnd start it with:\nsudo systemctl enable --now NetworkManager" --window-icon=network-wireless
        exit 1
    fi
    
    # Ensure wireless tools are available
    if ! command -v ip &> /dev/null; then
        zenity --error --title="Missing Dependency" --text="'ip' command not found. Please install iproute2 package." --window-icon=network-wireless
        exit 1
    fi
    
    # Check for zenity
    if ! command -v zenity &> /dev/null; then
        echo "Error: zenity is not installed. Installing zenity..."
        if ! sudo pacman -S --noconfirm zenity; then
            echo "Failed to install zenity. Please install it manually with: sudo pacman -S zenity"
            exit 1
        fi
    fi
    
    # Apply dark mode GTK settings
    export GTK_THEME="Adwaita:dark"
    # Alternative dark mode method if the above doesn't work
    export GTK_THEME_VARIANT="dark"
}

# Function to check if wireless interface is available
check_wifi_hardware() {
    if [[ -z $(ip link show | grep -i "wlan\|wifi") ]]; then
        zenity --error --title="No Wi-Fi Hardware" --text="No wireless interface detected on this system."
        exit 1
    fi
    
    # Ensure Wi-Fi is enabled
    if [[ $(nmcli radio wifi) == "disabled" ]]; then
        if zenity --question --title="Wi-Fi Disabled" --text="Wi-Fi is currently disabled. Would you like to enable it?" --ok-label="Enable Wi-Fi" --cancel-label="Exit"; then
            nmcli radio wifi on
            sleep 2
        else
            exit 0
        fi
    fi
}

# Function to connect to WiFi using GUI
connect_to_wifi_gui() {
    # Scan for networks with progress indicator
    (
    echo "# Scanning for available Wi-Fi networks..."
    echo "10"
    nmcli device wifi rescan &> /dev/null
    echo "# Processing network information..."
    echo "50"
    sleep 1
    echo "# Finalizing network list..."
    echo "90"
    sleep 1
    echo "100"
    ) | zenity --progress --pulsate --title="Scanning" --text="Scanning for available Wi-Fi networks..." --auto-close --no-cancel --window-icon=network-wireless
    
    # Build a list of networks for the dropdown
    available_networks=$(nmcli -f SSID,SIGNAL,SECURITY device wifi list | grep -v '^--' | sed '1d' | awk '{print $1 " (" $2 "%, " $3 ")"}')
    
    if [[ -z "$available_networks" ]]; then
        zenity --error --title="No Networks" --text="No Wi-Fi networks found. Please check your Wi-Fi hardware."
        exit 1
    fi
    
    # Format networks for zenity list
    network_list=""
    while IFS= read -r line; do
        network_list+="$line\n"
    done <<< "$available_networks"
    
    # Let user select network from list (dark mode styling)
    selected_network=$(echo -e "$network_list" | zenity --list --title="Available Wi-Fi Networks" --text="Select a network to connect:" --column="Network" --width=400 --height=300 --window-icon=network-wireless)
    
    if [[ -z "$selected_network" ]]; then
        # User cancelled
        zenity --info --title="Cancelled" --text="Wi-Fi connection cancelled." --window-icon=network-wireless
        exit 0
    fi
    
    # Extract SSID from the selection (remove signal and security info)
    selected_ssid=$(echo "$selected_network" | awk '{print $1}')
    
    # Check if network requires a password by looking at its security
    security=$(nmcli -f SSID,SECURITY device wifi list | grep "$selected_ssid" | awk '{$1=""; print $0}' | xargs)
    
    if [[ "$security" == "" || "$security" == "--" ]]; then
        # Open network, no password needed
        zenity --info --title="Connecting" --text="Connecting to open network: $selected_ssid" --timeout=2
        
        if nmcli device wifi connect "$selected_ssid"; then
            zenity --info --title="Connected" --text="Successfully connected to $selected_ssid"
        else
            zenity --error --title="Connection Failed" --text="Failed to connect to $selected_ssid"
        fi
    else
        # Password protected network
        wifi_password=$(zenity --entry --title="Wi-Fi Password" --text="Enter the password for '$selected_ssid':" --hide-text --window-icon=network-wireless)
        
        if [[ -z "$wifi_password" ]]; then
            # User cancelled password entry
            zenity --info --title="Cancelled" --text="Wi-Fi connection cancelled." --window-icon=network-wireless
            exit 0
        fi
        
        (
        echo "# Connecting to: $selected_ssid"
        echo "0"
        sleep 1
        echo "# Authenticating..."
        echo "50"
        ) | zenity --progress --title="Connecting" --text="Connecting to: $selected_ssid" --percentage=0 --auto-close --window-icon=network-wireless
        
        if nmcli device wifi connect "$selected_ssid" password "$wifi_password"; then
            zenity --info --title="Connected" --text="Successfully connected to $selected_ssid"
        else
            if zenity --question --title="Connection Failed" --text="Failed to connect to $selected_ssid. Would you like to try again?" --ok-label="Try Again" --cancel-label="Exit"; then
                connect_to_wifi_gui
            else
                exit 1
            fi
        fi
    fi
}

# Function for command-line interface (fallback)
connect_to_wifi_cli() {
    echo "========================================="
    echo "       Wi-Fi Connection Assistant        "
    echo "========================================="
    
    # Scan for networks
    echo "Scanning for available Wi-Fi networks..."
    nmcli device wifi rescan
    sleep 2
    
    # Display available networks
    echo "Available Wi-Fi networks:"
    nmcli -f SSID,SIGNAL,SECURITY device wifi list | grep -v '^--' | sed '1d' | nl -w2 -s") "
    
    # Let user select network
    echo "Enter the number of the network you wish to connect to (or 'q' to quit):"
    read -r choice
    
    # Check if user wants to quit
    if [[ "$choice" == "q" ]]; then
        echo "Exiting without connecting."
        exit 0
    fi
    
    # Get the SSID based on user's choice
    selected_ssid=$(nmcli -f SSID device wifi list | grep -v '^--' | sed '1d' | sed -n "${choice}p" | xargs)
    
    if [[ -z "$selected_ssid" ]]; then
        echo "Invalid selection. Please try again."
        connect_to_wifi_cli
        return
    fi
    
    # Check if network requires a password
    security=$(nmcli -f SECURITY device wifi list | grep -v '^--' | sed '1d' | sed -n "${choice}p" | xargs)
    
    if [[ "$security" == "" || "$security" == "--" ]]; then
        # Open network, no password needed
        echo "Connecting to open network: $selected_ssid"
        if nmcli device wifi connect "$selected_ssid"; then
            echo "Successfully connected to $selected_ssid"
        else
            echo "Failed to connect to $selected_ssid"
        fi
    else
        # Password protected network
        echo "Network '$selected_ssid' requires a password."
        echo "Enter the password for '$selected_ssid':"
        read -rs wifi_password
        
        echo "Connecting to: $selected_ssid"
        if nmcli device wifi connect "$selected_ssid" password "$wifi_password"; then
            echo "Successfully connected to $selected_ssid"
        else
            echo "Failed to connect to $selected_ssid. Please check the password and try again."
            connect_to_wifi_cli
        fi
    fi
}

# Create desktop shortcut function
create_desktop_shortcut() {
    # Create a desktop entry file
    desktop_file="$HOME/.local/share/applications/wifi-connect.desktop"
    
    # Create the directory if it doesn't exist
    mkdir -p "$HOME/.local/share/applications"
    
    # Create icon directory if it doesn't exist
    mkdir -p "$HOME/.local/share/icons"
    
    # Use network-wireless icon if available or create a simple icon
    if [[ -f "/usr/share/icons/hicolor/scalable/devices/network-wireless.svg" ]]; then
        icon_path="/usr/share/icons/hicolor/scalable/devices/network-wireless.svg"
    else
        # Create a basic icon using echo (this is just a placeholder)
        icon_path="$HOME/.local/share/icons/wifi-connect.png"
        zenity --info --title="Icon" --text="Using system network icon for the desktop shortcut." --timeout=2
    fi
    
    # Write the desktop entry
    cat > "$desktop_file" << EOF
[Desktop Entry]
Name=Wi-Fi Connection Assistant
Comment=Connect to available Wi-Fi networks
Exec=$(readlink -f "$0")
Icon=$icon_path
Terminal=false
Type=Application
Categories=Network;System;
EOF
    
    # Make it executable
    chmod +x "$desktop_file"
    
    zenity --info --title="Desktop Shortcut" --text="Desktop shortcut created successfully!\n\nYou can now find 'Wi-Fi Connection Assistant' in your applications menu."
}

# Main script execution
main() {
    # Check if GUI is available
    if [[ -n "$DISPLAY" ]] && command -v zenity &> /dev/null; then
        GUI_AVAILABLE=true
    else
        GUI_AVAILABLE=false
        echo "GUI not available, using command-line interface."
    fi
    
    # Check dependencies first
    if $GUI_AVAILABLE; then
        check_dependencies
    else
        # CLI version of dependency check
        if ! command -v nmcli &> /dev/null; then
            echo "Error: NetworkManager (nmcli) is not installed or not in PATH."
            echo "Please install NetworkManager with: sudo pacman -S networkmanager"
            echo "And start it with: sudo systemctl enable --now NetworkManager"
            exit 1
        fi
        
        if ! command -v ip &> /dev/null; then
            echo "Error: 'ip' command not found. Please install iproute2 package."
            exit 1
        fi
    fi
    
    # Check if already connected to the internet
    if check_connection; then
        if $GUI_AVAILABLE; then
            zenity --info --title="Connected" --text="Already connected to the internet. No further action needed." --timeout=3
        else
            echo "Already connected to the internet. No further action needed."
        fi
        exit 0
    fi
    
    # Check if wireless hardware is available
    if $GUI_AVAILABLE; then
        check_wifi_hardware
    else
        if [[ -z $(ip link show | grep -i "wlan\|wifi") ]]; then
            echo "No wireless interface detected on this system."
            exit 1
        fi
        
        if [[ $(nmcli radio wifi) == "disabled" ]]; then
            echo "Wi-Fi is currently disabled. Enabling Wi-Fi..."
            nmcli radio wifi on
            sleep 2
        fi
    fi
    
    # Connect to Wi-Fi using appropriate interface
    if $GUI_AVAILABLE; then
        connect_to_wifi_gui
        
        # Ask if the user wants to create a desktop shortcut (only on first run)
        if [[ ! -f "$HOME/.local/share/applications/wifi-connect.desktop" ]]; then
            if zenity --question --title="Create Shortcut" --text="Would you like to create a desktop shortcut for the Wi-Fi Connection Assistant?" --ok-label="Yes" --cancel-label="No"; then
                create_desktop_shortcut
            fi
        fi
    else
        connect_to_wifi_cli
    fi
    
    # Wait for internet connection with progress bar
    if wait_for_connection; then
        # Connection successful, exit with success
        exit 0
    else
        # Connection failed
        if $GUI_AVAILABLE; then
            if zenity --question --title="Retry Connection" --text="Would you like to try connecting to a different network?" --ok-label="Try Again" --cancel-label="Exit"; then
                # User wants to try again
                if $GUI_AVAILABLE; then
                    connect_to_wifi_gui
                    wait_for_connection
                else
                    connect_to_wifi_cli
                    wait_for_connection
                fi
            else
                exit 1
            fi
        else
            echo "Would you like to try connecting to a different network? (y/n)"
            read -r retry
            if [[ "$retry" == "y" ]]; then
                connect_to_wifi_cli
                wait_for_connection
            else
                exit 1
            fi
        fi
    fi
}

# Run the main function
main
