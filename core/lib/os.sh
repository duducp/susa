#!/usr/bin/env zsh

# Function to get the simplified name of the OS (linux or mac)
# Usage:
#   os_name=$(get_simple_os)
#   echo "$os_name"  # Output: linux or mac
get_simple_os() {
    if is_mac; then
        echo "mac"
    elif is_linux; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Check if running on macOS
# Usage:
#   if is_mac; then
#       echo "Running on macOS"
#   fi
is_mac() {
    [[ "$(uname)" == "Darwin" ]]
}

# Check if running on Linux
# Usage:
#   if is_linux; then
#       echo "Running on Linux"
#   fi
is_linux() {
    [[ "$(uname)" == "Linux" ]]
}

# Check if running on Debian-based distro
# Usage:
#   if is_linux_debian; then
#       echo "Running on Debian-based system"
#   fi
is_linux_debian() {
    if is_linux; then
        local distro=$(get_distro_id)
        [[ "$distro" == "ubuntu" || "$distro" == "debian" || "$distro" == "linuxmint" || "$distro" == "pop" || "$distro" == "elementary" || "$distro" == "zorin" ]] || [[ "$ID_LIKE" == *"debian"* ]]
    else
        return 1
    fi
}

# Check if running on RedHat-based distro
# Usage:
#   if is_linux_redhat; then
#       echo "Running on RedHat-based system"
#   fi
is_linux_redhat() {
    if is_linux; then
        local distro=$(get_distro_id)
        [[ "$distro" == "fedora" || "$distro" == "rhel" || "$distro" == "centos" || "$distro" == "rocky" || "$distro" == "almalinux" || "$distro" == "oracle" || "$distro" == "scientific" || "$distro" == "eurolinux" ]] || [[ "$ID_LIKE" == *"rhel"* || "$ID_LIKE" == *"fedora"* ]]
    else
        return 1
    fi
}

# Check if running on Arch-based distro
# Usage:
#   if is_linux_arch; then
#       echo "Running on Arch-based system"
#   fi
is_linux_arch() {
    if is_linux; then
        local distro=$(get_distro_id)
        [[ "$distro" == "arch" || "$distro" == "manjaro" || "$distro" == "endeavouros" || "$distro" == "garuda" || "$distro" == "artix" || "$distro" == "arcolinux" || "$distro" == "cachyos" ]] || [[ "$ID_LIKE" == *"arch"* ]]
    else
        return 1
    fi
}

# Get the appropriate package manager for Debian-based systems
# Returns: "apt-get" if available, otherwise "apt"
# Usage:
#   pkg_manager=$(get_debian_pkg_manager)
#   sudo $pkg_manager install package
get_debian_pkg_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt-get"
    elif command -v apt &> /dev/null; then
        echo "apt"
    else
        echo "unknown"
    fi
}

# Get the appropriate package manager for RedHat-based systems
# Returns: "dnf" if available, otherwise "yum"
# Usage:
#   pkg_manager=$(get_redhat_pkg_manager)
#   sudo $pkg_manager install package
get_redhat_pkg_manager() {
    if command -v dnf &> /dev/null; then
        echo "dnf"
    else
        echo "yum"
    fi
}

# Get the appropriate package manager for Arch-based systems
# Returns: "pacman"
# Usage:
#   pkg_manager=$(get_arch_pkg_manager)
#   sudo $pkg_manager install package
get_arch_pkg_manager() {
    if command -v pacman &> /dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# Get the Linux distribution ID from /etc/os-release
# Returns: The $ID value (e.g., "ubuntu", "fedora", "arch")
# Usage:
#   distro=$(get_distro_id)
get_distro_id() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}
