#!/bin/bash
set -euo pipefail

#===============================================================================
# Linux Szerver – Biztonsági Beállítások
# Debian / Ubuntu – Alapvető VPS hardening
# Készítette: Doky | 2026.08.12
#===============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[*]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warning() { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[✗]${NC} $*"; }

center() {
    local text="$1"
    local width="${2:-46}"
    local visible
    visible=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local len=${#visible}
    local pad=$(( (width - len) / 2 ))
    printf "%${pad}s%b\n" "" "$text"
}

banner() {
    echo -e "${BOLD}${CYAN}"
    echo "=============================================="
    center "Linux Szerver – Biztonsági Beállítások"
    center "Készítette: Doky"
    echo "=============================================="
    echo -e "${NC}"
}

check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        error "A scriptet root jogosultsággal kell futtatni! (sudo $0)"
        exit 1
    fi
}

check_os() {
    if [[ ! -f /etc/os-release ]]; then
        error "Nem található /etc/os-release – ismeretlen rendszer."
        exit 1
    fi
    . /etc/os-release
    if [[ "$ID" != "debian" && "$ID" != "ubuntu" ]]; then
        error "Ez a script csak Debian és Ubuntu rendszereken fut!"
        error "Jelenlegi rendszer: $ID"
        exit 1
    fi
    success "Támogatott operációs rendszer: $ID"
}

confirm() {
    local prompt="$1"
    local answer

    read -r -p "$(echo -e "${CYAN}?${NC} $prompt [i/N]: ")" answer
    answer="${answer:-N}"
    [[ "$answer" =~ ^[iI]$ ]]
}

show_system_info() {
    . /etc/os-release
    echo
    echo -e "${BOLD}Rendszerinformációk:${NC}"
    echo -e "  Operációs rendszer:  ${YELLOW}$PRETTY_NAME${NC}"
    echo -e "  Kernel verzió:       ${YELLOW}$(uname -r)${NC}"
    echo -e "  Architektúra:        ${YELLOW}$(uname -m)${NC}"
    echo -e "  Jelenlegi hosztnév:  ${YELLOW}$(hostname)${NC}"
    echo -e "  Jelenlegi idő:       ${YELLOW}$(date)${NC}"
    echo -e "  Időzóna:             ${YELLOW}$(timedatectl show --property=Timezone --value 2>/dev/null || echo 'N/A')${NC}"
    echo
}

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        success "Biztonsági mentés: $backup"
        echo "$backup"
    fi
}

generate_password() {
    openssl rand -base64 16 | tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' | head -c22
}

#===============================================================================
# FŐ PROGRAM
#===============================================================================

banner

# --- 1. Root + OS ellenőrzés ---
echo
check_root
check_os

# --- 2. Rendszerinformációk ---
show_system_info

# --- Változók a végösszegzéshez ---
CHANGES_HOSTNAME=""
CHANGES_SSH_PORT=""
CHANGES_TIMEZONE=""
CHANGES_APTUPDATED=""
CHANGES_USERCREATED=""
CHANGES_SSHCONFIG=""
CREDENTIALS_FILE=""

# --- 3. Hosztnév beállítása ---
echo
echo -e "${BOLD}${CYAN}═══ Hosztnév beállítása ═══${NC}"
echo -e "  Jelenlegi: ${YELLOW}$(hostname)${NC}"
echo
read -r -p "$(echo -e "${CYAN}Új hosztnév${NC} (Enter = kihagy): ")" NEW_HOSTNAME
if [[ -n "$NEW_HOSTNAME" ]]; then
    hostnamectl set-hostname "$NEW_HOSTNAME"
    success "Hosztnév beállítva: $NEW_HOSTNAME"
    CHANGES_HOSTNAME="$NEW_HOSTNAME"
else
    info "Hosztnév beállítás kihagyva."
fi

# --- 4. SSH port ---
echo
echo -e "${BOLD}${CYAN}═══ SSH port beállítása ═══${NC}"
echo -e "  Jelenlegi port (sshd_config-ból): ${YELLOW}$(grep -E '^Port ' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo '22')${NC}"
echo
while true; do
    read -r -p "$(echo -e "${CYAN}Új SSH port${NC} [22]: ")" NEW_SSH_PORT
    NEW_SSH_PORT="${NEW_SSH_PORT:-22}"
    if [[ "$NEW_SSH_PORT" =~ ^[0-9]+$ ]] && (( NEW_SSH_PORT >= 1024 && NEW_SSH_PORT <= 65535 )) || [[ "$NEW_SSH_PORT" == "22" ]]; then
        break
    fi
    warning "A portnak 22-nek vagy 1024–65535 között kell lennie."
done

if [[ "$NEW_SSH_PORT" != "22" ]]; then
    info "SSH port: $NEW_SSH_PORT"
    CHANGES_SSH_PORT="$NEW_SSH_PORT"
fi

# --- 5. Időzóna ---
echo
echo -e "${BOLD}${CYAN}═══ Időzóna beállítása ═══${NC}"
CURRENT_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null || echo 'UTC')
echo -e "  Jelenlegi: ${YELLOW}$CURRENT_TZ${NC}"
echo
read -r -p "$(echo -e "${CYAN}Időzóna${NC} [$(echo "$CURRENT_TZ")]: ")" NEW_TZ
NEW_TZ="${NEW_TZ:-$CURRENT_TZ}"

if [[ "$NEW_TZ" != "$CURRENT_TZ" ]]; then
    if timedatectl set-timezone "$NEW_TZ" 2>/dev/null; then
        success "Időzóna beállítva: $NEW_TZ"
        CHANGES_TIMEZONE="$NEW_TZ"
    else
        warning "Érvénytelen időzóna: $NEW_TZ – kihagyva."
        info "Ellenőrizd: timedatectl list-timezones"
    fi
else
    info "Időzóna változatlan."
fi
CHANGES_TIMEZONE=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "$CURRENT_TZ")

# --- 6. Új sudo felhasználó ---
echo
echo -e "${BOLD}${CYAN}═══ Új sudo felhasználó létrehozása ═══${NC}"
echo
read -r -p "$(echo -e "${CYAN}Új felhasználónév${NC} (Enter = kihagy): ")" NEW_USER

if [[ -n "$NEW_USER" ]]; then
    if id "$NEW_USER" &>/dev/null; then
        warning "A(z) '$NEW_USER' felhasználó már létezik!"
        if confirm "Mégis folytatod? A sudo és jelszó beállítások módosulhatnak."; then
            info "Folytatás a meglévő felhasználóval."
            USER_EXISTED=1
        else
            info "Felhasználó létrehozás kihagyva."
            NEW_USER=""
        fi
    else
        USER_EXISTED=0
    fi
fi

if [[ -n "$NEW_USER" ]]; then
    RANDOM_PASSWORD=$(generate_password)

    if [[ "$USER_EXISTED" -eq 0 ]]; then
        useradd -m -s /bin/bash "$NEW_USER"
        usermod -aG sudo "$NEW_USER"
        success "Felhasználó létrehozva: $NEW_USER"
    fi

    echo "$NEW_USER:$RANDOM_PASSWORD" | chpasswd
    success "Jelszó beállítva."

    SUDOERS_FILE="/etc/sudoers.d/10-${NEW_USER}-nopasswd"
    echo "${NEW_USER} ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
    chmod 440 "$SUDOERS_FILE"
    success "NOPASSWD sudo beállítva: $SUDOERS_FILE"

    CHANGES_USERCREATED="$NEW_USER"
else
    info "Felhasználó létrehozás kihagyva."
fi

# --- 7. Rendszer frissítése ---
echo
echo -e "${BOLD}${CYAN}═══ Rendszer frissítése ═══${NC}"
info "Frissítés folyamatban..."
if DEBIAN_FRONTEND=noninteractive apt-get -y -qq -o=Dpkg::Use-Pty=0 update >/dev/null 2>&1 && \
   DEBIAN_FRONTEND=noninteractive apt-get -y -qq -o=Dpkg::Use-Pty=0 upgrade >/dev/null 2>&1; then
    success "Rendszer frissítve (apt update + apt upgrade)."
    CHANGES_APTUPDATED="Igen"
else
    warning "A rendszerfrissítés sikertelen (hálózati hiba vagy dpkg lock?)"
    warning "A többi beállítás érvényben maradt."
fi

# --- 8. Midnight Commander ---
echo
echo -e "${BOLD}${CYAN}═══ Fájlkezelő telepítése ═══${NC}"
if confirm "Midnight Commander telepítése?"; then
    if apt install -y -qq mc 2>/dev/null; then
        success "Midnight Commander telepítve."
    else
        warning "Midnight Commander telepítése sikertelen."
    fi
else
    info "Midnight Commander telepítés kihagyva."
fi

# --- 9. SSH konfiguráció ---
echo
echo -e "${BOLD}${CYAN}═══ SSH konfiguráció ═══${NC}"

SSHD_DROPIN_DIR="/etc/ssh/sshd_config.d"
SSHD_DROPIN_FILE="${SSHD_DROPIN_DIR}/99-vps-setup.conf"

mkdir -p "$SSHD_DROPIN_DIR"

if [[ -f "$SSHD_DROPIN_FILE" ]]; then
    backup_file "$SSHD_DROPIN_FILE"
fi

echo "PermitRootLogin no" > "$SSHD_DROPIN_FILE"
success "Root SSH bejelentkezés: tiltva (PermitRootLogin no)"

if [[ -n "$CHANGES_SSH_PORT" && "$CHANGES_SSH_PORT" != "22" ]]; then
    echo "Port $CHANGES_SSH_PORT" >> "$SSHD_DROPIN_FILE"
    success "SSH port beállítva: $CHANGES_SSH_PORT"
fi

echo
info "SSH konfiguráció ellenőrzése (sshd -t)..."
if sshd -t; then
    success "SSH konfiguráció szintaktikailag rendben."
    systemctl restart sshd
    success "SSH szolgáltatás újraindítva."
    CHANGES_SSHCONFIG="Igen"
else
    rm -f "$SSHD_DROPIN_FILE"
    error "SSH konfiguráció hibás! A 99-vps-setup.conf törölve."
    error "Az eredeti beállítások változatlanok."
    CHANGES_SSHCONFIG="HIBA!"
fi

# --- 10. Credentials mentése ---
echo
echo -e "${BOLD}${CYAN}═══ Belépési adatok mentése ═══${NC}"
if [[ -n "$NEW_USER" ]] && [[ -n "${RANDOM_PASSWORD:-}" ]]; then
    CREDENTIALS_FILE="/root/${NEW_USER}_credentials.txt"
    CRED_TITLE="Belépési adatok"
    CRED_DATE="Generálva: $(date '+%Y-%m-%d %H:%M')"
    CRED_WIDTH=40
    TITLE_PAD=$(( (CRED_WIDTH - ${#CRED_TITLE}) / 2 ))
    DATE_PAD=$(( (CRED_WIDTH - ${#CRED_DATE}) / 2 ))

    {
        echo "========================================"
        printf "%${TITLE_PAD}s%s\n" "" "$CRED_TITLE"
        printf "%${DATE_PAD}s%s\n" "" "$CRED_DATE"
        echo "========================================"
        echo
        echo "Szerver hosztnév:  ${CHANGES_HOSTNAME:-$(hostname)}"
        echo "Rendszer:          $(. /etc/os-release && echo "$PRETTY_NAME")"
        echo "Kernel:            $(uname -r)"
        echo
        echo "Felhasználónév:    $NEW_USER"
        echo "Jelszó:            $RANDOM_PASSWORD"
        echo "Sudo:              NOPASSWD (jelszó nélküli)"
        echo "SSH port:          ${CHANGES_SSH_PORT:-22}"
        echo
        echo "FONTOS! Őrizd meg biztonságosan ezeket az adatokat."
        echo "Változtass jelszót az első bejelentkezés után!"
        echo
    } > "$CREDENTIALS_FILE"

    chmod 600 "$CREDENTIALS_FILE"
    success "Belépési adatok mentve: $CREDENTIALS_FILE"
else
    if [[ -n "$NEW_USER" ]]; then
        warning "Nem található generált jelszó – a credentials fájl nem jött létre."
    else
        info "Nem történt felhasználó létrehozás – credentials fájl kihagyva."
    fi
fi

# --- 11. Részletes összegzés ---
echo
echo -e "${BOLD}${CYAN}"
echo "========================================"
center "RÉSZLETES ÖSSZEGZÉS" 40
echo "========================================"
echo -e "${NC}"

echo -e "  ${BOLD}Rendszer információ:${NC}"
echo -e "    OS:                  $(. /etc/os-release && echo "$PRETTY_NAME")"
echo -e "    Kernel:              $(uname -r)"
echo -e "    Hosztnév:            ${CHANGES_HOSTNAME:-$(hostname)}"
echo -e "    Időzóna:             ${CHANGES_TIMEZONE}"

echo
echo -e "  ${BOLD}Rendszer állapot:${NC}"
if [[ -n "$CHANGES_APTUPDATED" ]]; then
    echo -e "    ${GREEN}[✓]${NC} Rendszer frissítve (apt update + upgrade)"
else
    echo -e "    ${YELLOW}[!]${NC} Rendszer nincs frissítve"
fi

echo
echo -e "  ${BOLD}Felhasználó:${NC}"
if [[ -n "$CHANGES_USERCREATED" ]]; then
    echo -e "    ${GREEN}[✓]${NC} Felhasználónév:     $CHANGES_USERCREATED"
    echo -e "    ${GREEN}[✓]${NC} Sudo:               NOPASSWD (jelszó nélküli)"
    echo -e "    ${GREEN}[✓]${NC} Credentials fájl:   $CREDENTIALS_FILE"
else
    echo -e "    ${YELLOW}[!]${NC} Nem történt felhasználó létrehozás"
fi

echo
echo -e "  ${BOLD}SSH:${NC}"
if [[ -n "$CHANGES_SSHCONFIG" && "$CHANGES_SSHCONFIG" == "Igen" ]]; then
    echo -e "    ${GREEN}[✓]${NC} Root SSH bejelentkezés: tiltva"
    echo -e "    ${GREEN}[✓]${NC} SSH port:              ${CHANGES_SSH_PORT:-22}"
else
    echo -e "    ${YELLOW}[!]${NC} SSH konfiguráció nem módosult"
fi

# --- 12. Figyelmeztetések ---
echo
echo -e "${BOLD}${YELLOW}========================================"
center "FIGYELEM!" 40
echo -e "========================================${NC}"

if [[ -n "$CHANGES_SSH_PORT" && "$CHANGES_SSH_PORT" != "22" ]]; then
    echo -e "  ${RED}►${NC} Az SSH port megváltozott: ${BOLD}$CHANGES_SSH_PORT${NC}"
    echo -e "  ${RED}►${NC} Kapcsolódáshoz használd: ${BOLD}ssh -p $CHANGES_SSH_PORT felhasznalo@szerver${NC}"
fi

if [[ -n "$CHANGES_SSHCONFIG" && "$CHANGES_SSHCONFIG" == "Igen" ]]; then
    echo -e "  ${RED}►${NC} Nyiss egy ${BOLD}ÚJ SSH MUNKAMENETET${NC} mielőtt kilépsz!"
    echo -e "  ${RED}►${NC} Teszteld, hogy tudsz-e csatlakozni az új beállításokkal!"
fi

if [[ -z "$CHANGES_USERCREATED" ]]; then
    echo -e "  ${RED}►${NC} Nem hoztál létre új felhasználót – ha elrontod az SSH konfigot,"
    echo -e "       előfordulhat, hogy nem tudsz majd belépni!"
fi

echo
echo -e "${CYAN}Kész – a szerver alapvető biztonsági beállításai elvégezve.${NC}"
echo
