#!/usr/bin/env bash
# @decision: Guard-rail checks run before any installation. Fail loudly with actionable
# messages rather than silently installing into a broken environment. Xcode CLT and
# Homebrew are bootstrapped here so every downstream lib can assume both exist.

check_prereqs() {
    if [[ ${DRY_RUN:-0} -eq 1 ]]; then
        step "[DRY RUN] Would check macOS version, disk space, network, Xcode CLT, and Homebrew"
        return 0
    fi

    step "Checking macOS version..."
    if [[ "$(uname)" != "Darwin" ]]; then
        fail "This script only runs on macOS."
    fi
    local major
    major="$(sw_vers -productVersion | cut -d. -f1)"
    if [[ "${major}" -lt 12 ]]; then
        fail "macOS 12 (Monterey) or newer is required. You have: $(sw_vers -productVersion)"
    fi
    ok "macOS $(sw_vers -productVersion)"

    step "Checking available disk space..."
    local free_kb
    free_kb="$(df -k / | awk 'NR==2 {print $4}')"
    local free_gb=$(( free_kb / 1024 / 1024 ))
    if [[ "${free_gb}" -lt 5 ]]; then
        fail "Need at least 5 GB free. You have ~${free_gb} GB. Free up space and try again."
    fi
    ok "Disk space: ~${free_gb} GB free"

    step "Checking network connectivity..."
    if ! curl -s --max-time 5 https://github.com > /dev/null 2>&1; then
        fail "Cannot reach github.com. Check your internet connection and try again."
    fi
    ok "Network reachable"

    _ensure_xcode_clt
    _ensure_homebrew
}

_ensure_xcode_clt() {
    step "Checking Xcode Command Line Tools..."
    if xcode-select -p &>/dev/null; then
        skip "Xcode CLT already installed at $(xcode-select -p)"
        return 0
    fi

    echo ""
    echo -e "  ${BOLD}Xcode Command Line Tools are required.${RESET}"
    echo "  These provide git, compilers, and build tools that Homebrew needs."
    echo "  You do NOT need the full Xcode IDE — just the Command Line Tools."
    echo ""
    echo -e "  ${DIM}A macOS dialog will appear — click 'Install' and wait for it to finish.${RESET}"
    echo -e "  ${DIM}If no dialog appears, open a new terminal and run: xcode-select --install${RESET}"
    echo ""

    xcode-select --install 2>&1 | tee -a "${MACBEQUICK_LOG}" || true

    echo -ne "  Waiting for installation to complete (this can take a few minutes)..."
    until xcode-select -p &>/dev/null; do
        sleep 3
        echo -ne "."
    done
    echo ""
    ok "Xcode Command Line Tools installed"
}

_ensure_homebrew() {
    step "Checking Homebrew..."

    # Detect existing brew on both Apple Silicon and Intel paths
    local brew_bin=""
    if command -v brew &>/dev/null; then
        brew_bin="$(command -v brew)"
    elif [[ -x "/opt/homebrew/bin/brew" ]]; then
        brew_bin="/opt/homebrew/bin/brew"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        brew_bin="/usr/local/bin/brew"
    fi

    if [[ -n "${brew_bin}" ]]; then
        # Make sure brew is in PATH for this shell session
        eval "$("${brew_bin}" shellenv)" 2>/dev/null || true
        skip "Homebrew already installed: ${brew_bin}"
    else
        step "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
            2>&1 | tee -a "${MACBEQUICK_LOG}"

        # Load brew into PATH (Apple Silicon default location)
        if [[ -x "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -x "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        ok "Homebrew installed"
    fi

    step "Updating Homebrew..."
    brew update --quiet 2>&1 | tee -a "${MACBEQUICK_LOG}"
    ok "Homebrew up to date"
}
