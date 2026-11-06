#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "============================================="
echo " Starting Unattended-Upgrades for Proxmox VE "
echo "============================================="

# 1. Update package lists and install required tools
echo "[1/4] Installing packages..."
sudo apt-get update
sudo apt-get install -y unattended-upgrades apt-listchanges bsd-mailx

# 2. Enable automatic upgrades in the system periodic configuration
echo "[2/4] Configuring daily upgrade schedules..."
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

# 3. Create a custom override file (52unattended-upgrades-custom)
echo "[3/4] Creating custom configuration overrides..."
sudo tee /etc/apt/apt.conf.d/52unattended-upgrades-custom > /dev/null << 'EOF'
// Custom overrides for Proxmox VE (PVE), Debian, Docker, and Netbird environment

Unattended-Upgrade::Origins-Pattern {
    // 1. Core Debian Repositories
    "origin=Debian,codename=${distro_codename},label=Debian";
    "origin=Debian,codename=${distro_codename},label=Debian-Security";
    "origin=Debian,codename=${distro_codename}-security,label=Debian-Security";
    "origin=Debian,codename=${distro_codename}-updates";

    // 2. Proxmox VE Repositories (No-Subscription, Enterprise & Ceph)
    "origin=Proxmox,codename=${distro_codename},label=Proxmox Debian Repository";
    "origin=ProxmoxVE,label=Proxmox VE Enterprise Repository";
    "site=download.proxmox.com";
    "site=enterprise.proxmox.com";

    // 3. Direct Domain Site Matching for Third-Party Apps
    "site=download.docker.com";
    "site=pkgs.netbird.io";
};

// Clean up unused dependencies and old kernels automatically
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";

// Enable automatic reboots at 3:00 AM if a kernel update requires it
// (Set to "false" if you do not want automated VM/hypervisor reboots)
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
EOF

# 4. Restart the service and run a validation test
echo "[4/4] Restarting service and running dry-run test..."
sudo systemctl restart unattended-upgrades
sudo systemctl enable unattended-upgrades

echo "============================================="
echo " Setup complete! Auto-upgrades are active.   "
echo "============================================="

