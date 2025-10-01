# --- OS Detection and Repository Setup ---
log_step "Detecting OS and Setting up Open5GS Repository"
OS_ID=""
OS_VERSION_ID=""
if [ -f /etc/os-release ]; then
    source /etc/os-release
    OS_ID="$ID"
    OS_VERSION_ID="$VERSION_ID"
else
    log_error "Could not determine OS type (/etc/os-release not found)"; exit 1;
fi
if [[ "$OS_ID" == "ubuntu" ]]; then
    OS_VERSION_MAJOR=$(echo "$OS_VERSION_ID" | cut -d'.' -f1)
    if [[ "$OS_VERSION_MAJOR" == "24" ]]; then
        log_info "Detected Ubuntu $OS_VERSION_ID LTS. Adding Open5GS PPA..."
        apt-get update -y >/dev/null 2>&1 || log_warn "apt update failed (continuing...)"
        apt-get install -y software-properties-common || { log_error "Failed to install software-properties-common"; exit 1; }
        add-apt-repository -y ppa:open5gs/latest || { log_error "Failed to add Open5GS PPA"; exit 1; }
    else
        log_error "Unsupported Ubuntu version: $OS_VERSION_ID. Only 24.04 LTS is supported by this script."
        exit 1
    fi
elif [[ "$OS_ID" == "debian" ]]; then
    if [[ "$OS_VERSION_ID" == "12" ]]; then
        log_info "Detected Debian $OS_VERSION_ID. Adding Open5GS repository..."
        apt-get update -y >/dev/null 2>&1 || log_warn "apt update failed (continuing...)"
        apt-get install -y wget gnupg curl || { log_error "Failed to install prerequisite packages (wget, gnupg, curl)"; exit 1; }
        mkdir -p /etc/apt/keyrings
        
        # --- CORREÇÃO DA CHAVE GPG ---
        log_info "Installing Open5GS repository with local GPG key..."
        
        # Criar o arquivo da chave GPG manualmente
        cat > /tmp/open5gs-key.gpg << 'EOF'
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.5 (GNU/Linux)

mQENBFyXC1QBCACtYMjUVxsS3orVeB2a1uQfPxxCpXHCC9f32HqdWUs+TpqIgENL
D7+pkKLl3CQyyKegr0SFmXfN4TFAID9AAb6LTFCyVsTTZzgynWHIF5dnNflJ3c3j
QGDFL8HXMETzfutLnGcPvhbgHp3GxRYBh8X2A6UgBxrOWm7pjRu94NXyRPQJKlle
Om7EUBBhKMDidhWLyXOEhIF+Mqjf4S8/gMdCitNCEVQkkMmqUBxwBe7vHQhZn4Qc
YvZQ1PGjQrNc4cJQwqt4phSbm+WHY9Fk30ZM/tu6fzqu87miADI8HkUcIy1pHCIr
e0Lp+9AGqvGJ2SbTE/nvJMNxq4OE0BBUJOPrABEBAAG0OmhvbWU6YWNldGNvbSBP
QlMgUHJvamVjdCA8aG9tZTphY2V0Y29tQGJ1aWxkLm9wZW5zdXNlLm9yZz6JAT4E
EwEIACgFAmSx0FECGwMFCQw5dP0GCwkIBwMCBhUIAgkKCwQWAgMBAh4BAheAAAoJ
EP5/QvJ2zuDmkiIH/A/nx9cxpLZsKd7zmDqjy/EwB7AyZrsF5Hc0NMorj2vrVU+J
eAydHsX1as6o13EXJ/k0gpa7rB7s07xczTN5ZIy/S37NAyHHWmd+UPHIYKa9abed
80zbulQe/dLJp9pdxTzxFt1DwtJckTKaHCajhAEiqTABVBYIz8kEtc9clIW4lLYz
woMhd66+ATB7MhvyfcR3kxErgkLNw/Pn8P9xTLLnE75GDd2und4Hj2Ji38YOgNG3
t+Tp3ypK2kVuzHan/FZY2yZlS87SwUoQl73fUra1DA5OhN+rcPPEeOtg/HAHKW9B
IHXth25e4pjxgrGA8kNwkH6OCrlfCtDGx40fNDyIRgQTEQIABgUCXJcLVAAKCRA7
MBG3a51lIyaWAJ9wyjrzgQhWjd0Tu6/6x317rneKYgCfS8Q8EmQ2NZcf7Wf6cvUz
rYjHjVo=
=QLhs
-----END PGP PUBLIC KEY BLOCK-----
EOF

        # Instalar a chave
        gpg --dearmor /tmp/open5gs-key.gpg > /etc/apt/keyrings/open5gs.gpg
        if [ $? -ne 0 ]; then 
            log_error "Failed to process Open5GS GPG key"
            # Fallback: tentar método alternativo
            log_info "Trying alternative GPG key method..."
            wget -qO - http://download.opensuse.org/repositories/home:/acetcom:/open5gs:/latest/Debian_12/Release.key | gpg --dearmor > /etc/apt/keyrings/open5gs.gpg 2>/dev/null || {
                log_error "All GPG key methods failed"
                exit 1
            }
        fi
        
        # Adicionar repositório
        echo "deb [signed-by=/etc/apt/keyrings/open5gs.gpg] http://download.opensuse.org/repositories/home:/acetcom:/open5gs:/latest/Debian_12/ ./" > /etc/apt/sources.list.d/open5gs.list
        if [ $? -ne 0 ]; then log_error "Failed to write Open5GS sources list"; exit 1; fi
        
        # Limpar arquivo temporário
        rm -f /tmp/open5gs-key.gpg
        log_info "Open5GS repository configured with local GPG key"
        # --- FIM DA CORREÇÃO ---
        
    else
        log_error "Unsupported Debian version: $OS_VERSION_ID. Only Debian 12 is supported by this script."
        exit 1
    fi
else
    log_error "Unsupported OS: $OS_ID"; exit 1;
fi
log_info "Repository setup complete."

# --- Package Installation ---
log_step "Updating Package Lists"
apt-get update || { log_error "Failed to update package lists"; exit 1; }
log_info "Package lists updated."

log_step "Installing Open5GS Packages (Excluding WebUI)"
apt-get install -y open5gs-amf open5gs-ausf open5gs-hss open5gs-mme open5gs-nrf open5gs-nssf open5gs-pcf open5gs-smf open5gs-sgwc open5gs-sgwu open5gs-udr open5gs-upf open5gs-udm open5gs-pcrf || { log_error "Failed to install Open5GS component packages"; exit 1; }
dpkg -s open5gs-mme &> /dev/null || { log_error "open5gs-mme package not found after install attempt."; exit 1; }
dpkg -s open5gs-pcrf &> /dev/null || { log_error "open5gs-pcrf package not found after install attempt."; exit 1; }
log_info "Open5GS core packages (including PCRF) installed."

log_step "Installing Required Utilities (iptables, persistence tools)"
apt-get install -y iptables iptables-persistent yq || { log_error "Failed to install required utilities (iptables, iptables-persistent, yq)"; exit 1; }
if ! command -v iptables &> /dev/null; then log_error "iptables command not found after installation attempt."; exit 1; fi
if ! command -v yq &> /dev/null; then log_error "yq command not found after installation attempt."; exit 1; fi
log_info "Required base utilities are installed."
