#!/bin/bash

# =====================================================
# RPM/YUM/DNF Software Management Menu
# Interactive script for Red Hat / RHEL / CentOS / Fedora / Rocky / AlmaLinux systems
# Beginner-friendly with safety checks
# =====================================================

clear

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display welcome banner
show_banner() {
    echo -e "${BLUE}=====================================================${NC}"
    echo -e "${GREEN}       RPM / YUM / DNF Software Management Menu      ${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    echo -e "  Welcome to the Red Hat-based Package Manager Tool"
    echo -e "  This script helps you manage software safely."
    echo -e "  Works on RHEL, CentOS, Rocky, AlmaLinux, Fedora, etc."
    echo -e "${BLUE}=====================================================${NC}"
    echo ""
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root or with sudo.${NC}"
        echo "Please run: sudo $0"
        exit 1
    fi
}

# Function to detect available package managers
detect_package_managers() {
    DNF_AVAILABLE=false
    YUM_AVAILABLE=false
    
    if command -v dnf &> /dev/null; then
        DNF_AVAILABLE=true
    fi
    if command -v yum &> /dev/null; then
        YUM_AVAILABLE=true
    fi
}

# Function to check if a package is installed
check_installed() {
    local pkg=$1
    if rpm -q "$pkg" &> /dev/null; then
        echo -e "${GREEN}✓ Package '$pkg' is already installed.${NC}"
        return 0
    else
        echo -e "${YELLOW}✗ Package '$pkg' is not installed.${NC}"
        return 1
    fi
}

# Main menu function
show_menu() {
    echo -e "${YELLOW}Available Options:${NC}"
    echo "-----------------------------------------------------"
    echo " 1. Check if a package is installed          (rpm -q)"
    echo " 2. Install package using DNF                (dnf install)"
    echo " 3. Remove package using DNF                 (dnf remove)"
    echo " 4. Update all packages using DNF            (dnf update)"
    echo " 5. Search for a package using DNF           (dnf search)"
    echo " 6. List all installed packages (rpm)        (rpm -qa)"
    echo " 7. Show detailed info of a package (rpm)    (rpm -qi)"
    echo " 8. List files installed by a package (rpm)  (rpm -ql)"
    echo " 9. Check which package owns a file (rpm)    (rpm -qf)"
    echo "10. Install local .rpm file                  (rpm -ivh)"
    echo "11. Install package using YUM                (yum install)"
    echo "12. Remove package using YUM                 (yum remove)"
    echo "13. Update all packages using YUM            (yum update)"
    echo "14. Exit"
    echo "-----------------------------------------------------"
}

# Function to perform actions
perform_action() {
    local choice=$1
    
    case $choice in
        1)  # Check if package is installed
            echo -e "${BLUE}Check if package is installed${NC}"
            read -p "Enter package name: " pkg
            if [[ -z "$pkg" ]]; then
                echo -e "${RED}Error: Package name cannot be empty.${NC}"
                return
            fi
            check_installed "$pkg"
            ;;
            
        2)  # Install using DNF
            echo -e "${BLUE}Install package using DNF${NC}"
            if ! $DNF_AVAILABLE; then
                echo -e "${RED}DNF is not available on this system.${NC}"
                return
            fi
            read -p "Enter package name to install: " pkg
            if [[ -z "$pkg" ]]; then
                echo -e "${RED}Error: Package name cannot be empty.${NC}"
                return
            fi
            check_installed "$pkg"
            if [[ $? -eq 0 ]]; then
                read -p "Do you still want to reinstall? (y/n): " confirm
                [[ "$confirm" != "y" && "$confirm" != "Y" ]] && return
            fi
            echo -e "${YELLOW}Running: dnf install $pkg -y${NC}"
            dnf install "$pkg" -y
            ;;
            
        3)  # Remove using DNF
            echo -e "${BLUE}Remove package using DNF${NC}"
            if ! $DNF_AVAILABLE; then
                echo -e "${RED}DNF is not available on this system.${NC}"
                return
            fi
            read -p "Enter package name to remove: " pkg
            if [[ -z "$pkg" ]]; then
                echo -e "${RED}Error: Package name cannot be empty.${NC}"
                return
            fi
            check_installed "$pkg"
            if [[ $? -ne 0 ]]; then
                echo -e "${YELLOW}Package is not installed. Nothing to remove.${NC}"
                return
            fi
            read -p "Are you sure you want to remove '$pkg'? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                echo -e "${YELLOW}Running: dnf remove $pkg -y${NC}"
                dnf remove "$pkg" -y
            fi
            ;;
            
        4)  # Update all using DNF
            echo -e "${BLUE}Update all packages using DNF${NC}"
            if ! $DNF_AVAILABLE; then
                echo -e "${RED}DNF is not available on this system.${NC}"
                return
            fi
            read -p "Proceed with full system update? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                echo -e "${YELLOW}Running: dnf update -y${NC}"
                dnf update -y
            fi
            ;;
            
        5)  # Search using DNF
            echo -e "${BLUE}Search for package using DNF${NC}"
            if ! $DNF_AVAILABLE; then
                echo -e "${RED}DNF is not available on this system.${NC}"
                return
            fi
            read -p "Enter search keyword: " keyword
            if [[ -z "$keyword" ]]; then
                echo -e "${RED}Error: Keyword cannot be empty.${NC}"
                return
            fi
            echo -e "${YELLOW}Running: dnf search $keyword${NC}"
            dnf search "$keyword"
            ;;
            
        6)  # List installed packages using rpm
            echo -e "${BLUE}Listing all installed packages (rpm -qa)${NC}"
            echo -e "${YELLOW}Running: rpm -qa | less${NC}"
            rpm -qa | less
            ;;
            
        7)  # Show package info
            echo -e "${BLUE}Show package information${NC}"
            read -p "Enter package name: " pkg
            if [[ -z "$pkg" ]]; then
                echo -e "${RED}Error: Package name cannot be empty.${NC}"
                return
            fi
            echo -e "${YELLOW}Running: rpm -qi $pkg${NC}"
            rpm -qi "$pkg" 2>/dev/null || echo -e "${RED}Package '$pkg' is not installed.${NC}"
            ;;
            
        8)  # List files of a package
            echo -e "${BLUE}List files installed by a package${NC}"
            read -p "Enter package name: " pkg
            if [[ -z "$pkg" ]]; then
                echo -e "${RED}Error: Package name cannot be empty.${NC}"
                return
            fi
            echo -e "${YELLOW}Running: rpm -ql $pkg${NC}"
            rpm -ql "$pkg" 2>/dev/null || echo -e "${RED}Package '$pkg' is not installed.${NC}"
            ;;
            
        9)  # Check file ownership
            echo -e "${BLUE}Check which package owns a file${NC}"
            read -p "Enter full path to file: " filepath
            if [[ -z "$filepath" ]]; then
                echo -e "${RED}Error: File path cannot be empty.${NC}"
                return
            fi
            if [[ ! -e "$filepath" ]]; then
                echo -e "${RED}Error: File '$filepath' does not exist.${NC}"
                return
            fi
            echo -e "${YELLOW}Running: rpm -qf $filepath${NC}"
            rpm -qf "$filepath" 2>/dev/null || echo -e "${RED}No package owns this file.${NC}"
            ;;
            
        10) # Install local RPM file
            echo -e "${BLUE}Install local .rpm file${NC}"
            read -p "Enter full path to .rpm file: " rpmfile
            if [[ -z "$rpmfile" ]]; then
                echo -e "${RED}Error: File path cannot be empty.${NC}"
                return
            fi
            if [[ ! -f "$rpmfile" ]]; then
                echo -e "${RED}Error: File '$rpmfile' not found.${NC}"
                return
            fi
            echo -e "${YELLOW}Running: rpm -ivh $rpmfile${NC}"
            rpm -ivh "$rpmfile"
            ;;
            
        11) # Install using YUM
            echo -e "${BLUE}Install package using YUM${NC}"
            if ! $YUM_AVAILABLE; then
                echo -e "${RED}YUM is not available on this system.${NC}"
                return
            fi
            read -p "Enter package name: " pkg
            if [[ -z "$pkg" ]]; then
                echo -e "${RED}Error: Package name cannot be empty.${NC}"
                return
            fi
            check_installed "$pkg"
            if [[ $? -eq 0 ]]; then
                read -p "Package already installed. Reinstall? (y/n): " confirm
                [[ "$confirm" != "y" && "$confirm" != "Y" ]] && return
            fi
            echo -e "${YELLOW}Running: yum install $pkg -y${NC}"
            yum install "$pkg" -y
            ;;
            
        12) # Remove using YUM
            echo -e "${BLUE}Remove package using YUM${NC}"
            if ! $YUM_AVAILABLE; then
                echo -e "${RED}YUM is not available on this system.${NC}"
                return
            fi
            read -p "Enter package name: " pkg
            if [[ -z "$pkg" ]]; then
                echo -e "${RED}Error: Package name cannot be empty.${NC}"
                return
            fi
            check_installed "$pkg"
            if [[ $? -ne 0 ]]; then
                echo -e "${YELLOW}Package not installed.${NC}"
                return
            fi
            read -p "Confirm removal of '$pkg'? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                echo -e "${YELLOW}Running: yum remove $pkg -y${NC}"
                yum remove "$pkg" -y
            fi
            ;;
            
        13) # Update using YUM
            echo -e "${BLUE}Update all packages using YUM${NC}"
            if ! $YUM_AVAILABLE; then
                echo -e "${RED}YUM is not available on this system.${NC}"
                return
            fi
            read -p "Proceed with full system update? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                echo -e "${YELLOW}Running: yum update -y${NC}"
                yum update -y
            fi
            ;;
            
        14) # Exit
            echo -e "${GREEN}Thank you for using RPM/YUM/DNF Management Menu!${NC}"
            echo "Goodbye 👋"
            exit 0
            ;;
            
        *) 
            echo -e "${RED}Invalid option selected.${NC}"
            ;;
    esac
}

# Main program
main() {
    check_root
    detect_package_managers
    
    while true; do
        clear
        show_banner
        
        if $DNF_AVAILABLE; then
            echo -e "${GREEN}✓ DNF is available (recommended)${NC}"
        else
            echo -e "${YELLOW}⚠ DNF is not available${NC}"
        fi
        
        if $YUM_AVAILABLE; then
            echo -e "${GREEN}✓ YUM is available${NC}"
        fi
        echo ""
        
        show_menu
        
        echo ""
        read -p "Enter your choice (1-14): " choice
        
        perform_action "$choice"
        
        echo ""
        read -p "Press Enter to continue..." 
    done
}

# Start the script
main
