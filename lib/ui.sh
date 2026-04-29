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

# ---- Optional prompt (returns 1 if user says no, never exits) ----
ask_optional() {
    local question="${1:-Continue?}"
    echo -ne "  ${BOLD}${question}${RESET} ${DIM}[Y/n]${RESET} "
    read -r answer
    case "${answer}" in
        [Nn]*) return 1 ;;
        *) return 0 ;;
    esac
}

# ---- Interactive app-selection toggle menu (Ninite-style with categories) ----
# Usage: app_selection_menu "CATEGORY:Name" "cask_id|Display Name|description" ...
# Result: global SELECTED_APPS array is populated with chosen cask IDs.
# All apps are ON by default (opt-out). Non-interactive stdin selects all.
# CATEGORY: sentinel lines are displayed as section headers; they never appear in
# SELECTED_APPS and are skipped when assigning toggle indices.
#
# @decision DEC-UI-APPSEL-001
# @title Ninite-style opt-out app-selection menu with category sections
# @status accepted
# @rationale An opt-out model (all apps selected by default) gives a frictionless
#   first-run experience — the user just presses Enter to install everything.
#   CATEGORY: sentinels group apps visually like Ninite.com, making it easier to
#   spot what to skip. The toggle index is built from app-only entries so that
#   "5" always toggles the 5th app regardless of how many category headers precede it.
#   Piped / non-interactive runs (CI, tests) skip the menu and select all apps,
#   ensuring the installer stays scriptable without special flags.
app_selection_menu() {
    local -a all_entries=("$@")

    # Build flat app-only list, preserving order
    local -a app_entries=()
    local -a app_selected=()
    for entry in "${all_entries[@]}"; do
        [[ "${entry}" == CATEGORY:* ]] && continue
        app_entries+=("${entry}")
        app_selected+=(1)
    done
    local app_count=${#app_entries[@]}

    # Non-interactive fallback: select all
    if [[ ! -t 0 ]]; then
        SELECTED_APPS=()
        for entry in "${app_entries[@]}"; do
            SELECTED_APPS+=("${entry%%|*}")
        done
        return 0
    fi

    while true; do
        echo ""
        echo -e "  ${BOLD}Select apps to install${RESET} ${DIM}— number to toggle · 'all' · 'none' · Enter to confirm${RESET}"
        echo ""

        local app_idx=0
        for entry in "${all_entries[@]}"; do
            if [[ "${entry}" == CATEGORY:* ]]; then
                local cat="${entry#CATEGORY:}"
                echo -e "\n  ${BOLD}${WHITE}${cat}${RESET}"
            else
                local rest="${entry#*|}"
                local display="${rest%%|*}"; local desc="${rest#*|}"
                local mark
                [[ ${app_selected[app_idx]} -eq 1 ]] \
                    && mark="${GREEN}[✓]${RESET}" \
                    || mark="${DIM}[ ]${RESET}"
                printf "  %b %-3s %-26s %s\n" \
                    "${mark}" "$((app_idx+1))." "${display}" "${desc}"
                (( app_idx++ )) || true
            fi
        done

        echo ""
        echo -ne "  ${DIM}>${RESET} "
        read -r choice

        case "${choice}" in
            ""|done) break ;;
            all)  for (( i=0; i<app_count; i++ )); do app_selected[i]=1; done ;;
            none) for (( i=0; i<app_count; i++ )); do app_selected[i]=0; done ;;
            *)
                if [[ "${choice}" =~ ^[0-9]+$ ]]; then
                    local idx=$(( choice - 1 ))
                    if (( idx >= 0 && idx < app_count )); then
                        app_selected[idx]=$(( 1 - app_selected[idx] ))
                    fi
                fi ;;
        esac
    done

    SELECTED_APPS=()
    for (( i=0; i<app_count; i++ )); do
        [[ ${app_selected[i]} -eq 1 ]] && SELECTED_APPS+=("${app_entries[i]%%|*}")
    done
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
