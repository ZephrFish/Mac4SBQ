#!/usr/bin/env bash
# @decision: Central visual layer for all user-facing output. Centralizing colors/print here
# means the other lib files stay focused on logic and a future maintainer only needs to
# touch one file to change the entire look of the setup script.

# ---- Colors ----
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

_STEP_NUM=0
_TOTAL_STEPS=5

# ---- Core print functions ----
step() {
    echo -e "  ${CYAN}->${RESET} $*"
    echo "[STEP] $*" >> "${MACBEQUICK_LOG:-/dev/null}"
}

ok() {
    echo -e "  ${GREEN}[OK]${RESET} $*"
    echo "[OK] $*" >> "${MACBEQUICK_LOG:-/dev/null}"
}

skip() {
    echo -e "  ${DIM}[SKIP] $*${RESET}"
    echo "[SKIP] $*" >> "${MACBEQUICK_LOG:-/dev/null}"
}

warn() {
    echo -e "  ${YELLOW}[WARN]${RESET} $*"
    echo "[WARN] $*" >> "${MACBEQUICK_LOG:-/dev/null}"
}

fail() {
    echo -e "\n  ${RED}[FAIL]${RESET} $*" >&2
    echo "[FAIL] $*" >> "${MACBEQUICK_LOG:-/dev/null}"
    exit 1
}

section_header() {
    (( _STEP_NUM++ )) || true
    local title="$1"
    local label="[${_STEP_NUM}/${_TOTAL_STEPS}] ${title}"
    local line
    line="$(printf '=%.0s' $(seq 1 ${#label}))"
    echo ""
    echo -e "${BOLD}${WHITE}${line}${RESET}"
    echo -e "${BOLD}${WHITE}${label}${RESET}"
    echo -e "${BOLD}${WHITE}${line}${RESET}"
    echo ""
    echo "=== ${label} ===" >> "${MACBEQUICK_LOG:-/dev/null}"
}

# ---- Welcome banner ----
show_welcome_banner() {
    clear
    echo -e "${BOLD}${CYAN}"
    cat << 'EOF'
  _ __ ___   __ _  ___| |__   ___| |__   __ _ _   _(_) ___| | __
 | '_ ` _ \ / _` |/ __| '_ \ / _ \ '_ \ / _` | | | | |/ __| |/ /
 | | | | | | (_| | (__| |_) |  __/ | | | (_| | |_| | | (__|   <
 |_| |_| |_|\__,_|\___|_.__/ \___|_| |_|\__, |\__,_|_|\___|_|\_\
                                            |_|
EOF
    echo -e "${RESET}"
    echo -e "${BOLD}Welcome! This script will set up your Mac for coding.${RESET}"
    echo ""
    echo "  It will install and configure:"
    echo "    • Signal, Discord, Tailscale, iTerm2, VS Code"
    echo "    • A powerful terminal with a beautiful prompt"
    echo "    • Essential coding tools and VS Code extensions"
    echo ""
    echo -e "  ${DIM}Takes about 10-15 minutes. Safe to re-run — skips what's already done.${RESET}"
    echo ""
    ask_continue "Ready to go?"
}

show_finish_message() {
    echo ""
    echo -e "${BOLD}${GREEN}========================================${RESET}"
    echo -e "${BOLD}${GREEN}  All done! Your Mac is set up.         ${RESET}"
    echo -e "${BOLD}${GREEN}========================================${RESET}"
    echo ""
    echo -e "  ${BOLD}Next:${RESET} Close this terminal and open ${BOLD}iTerm2${RESET}"
    echo -e "  to see your new prompt and all the goodies."
    echo ""
    echo -e "  Full setup log: ${DIM}${MACBEQUICK_LOG}${RESET}"
    echo ""
}

# ---- Interactive prompt ----
ask_continue() {
    local question="${1:-Continue?}"
    echo -ne "  ${BOLD}${question}${RESET} ${DIM}[Y/n]${RESET} "
    read -r answer
    case "${answer}" in
        [Nn]*) echo "Exiting. Run setup.sh again whenever you're ready."; exit 0 ;;
        *) return 0 ;;
    esac
}

# ---- Spinner: animates while a background pid runs ----
spinner() {
    local pid="$1"
    local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 "${pid}" 2>/dev/null; do
        local c="${chars:$((i % ${#chars})):1}"
        echo -ne "  ${CYAN}${c}${RESET}\r"
        sleep 0.1
        (( i++ )) || true
    done
    echo -ne "    \r"
}
