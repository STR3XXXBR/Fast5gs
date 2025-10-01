#!/bin/bash

# Source logging functions
if [ -f "./scripts/install_open5gs__presetup.sh" ]; then
    source ./scripts/install_open5gs__presetup.sh
else
    log_step() { echo ">>> Step: $1"; }
    log_info() { echo "[INFO] $1"; }
    log_warn() { echo "[WARN] $1"; }
    log_error() { echo "[ERROR] $1"; }
fi

# --- OS Detection and Repository Setup ---
log_step "Detecting OS and Setting up Open5GS Repository"

if [ -f /etc/os-release ]; then
    source /etc/os-release
else
    log_error "Could not determine OS type"; exit 1;
fi

if [[ "$ID" == "debian" && "$VERSION_ID" == "12" ]]; then
    log_info "Detected Debian 12. Setting up Open5GS repository..."
    
    # Limpar configurações anteriores
    rm -f /etc/apt/sources.list.d/open5gs.list
    rm -f /etc/apt/trusted.gpg.d/open5gs.gpg
    
    # CONFIGURAÇÃO CORRETA: trusted=yes para ignorar GPG
    echo "deb [trusted=yes] http://download.opensuse.org/repositories/home:/acetcom:/open5gs:/latest/Debian_12/ ./" > /etc/apt/sources.list.d/open5gs.list
    
    log_info "Open5GS repository configured (GPG verification bypassed)"
    
else
    log_error "Unsupported OS: Only Debian 12 is supported"
    exit 1
fi

# --- Package Installation ---
log_step "Updating Package Lists"
apt-get update || { log_error "Failed to update package lists"; exit 1; }
log_info "Package lists updated successfully"

log_step "Installing Open5GS Core Packages"
apt-get install -y open5gs-mme open5gs-hss open5gs-sgwc open5gs-sgwu open5gs-pcrf open5gs-amf open5gs-smf open5gs-udm open5gs-udr open5gs-ausf open5gs-nrf open5gs-nssf open5gs-pcf open5gs-upf || {
    log_error "Failed to install Open5GS packages"
    exit 1
}

log_step "Installing Utilities"
apt-get install -y iptables iptables-persistent

log_info "Open5GS installation completed successfully"
exit 0
