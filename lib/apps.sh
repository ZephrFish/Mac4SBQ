#!/usr/bin/env bash
# @decision DEC-APPS-DATADRIVEN-001
# @title Data-driven app list with selection menu
# @status accepted
# @rationale App list defined as structured entries so the selection menu and installer
#   share one source of truth. install_cask checks the cask receipt for idempotency.
#   docker-desktop is the correct cask name after Homebrew upstream rename from docker.
#   Each entry follows the "cask_id|Display Name|description" format consumed by
#   app_selection_menu() in lib/ui.sh.

_APP_ENTRIES=(
    "1password|1Password|Password manager"
    "signal|Signal|Encrypted messaging"
    "discord|Discord|Communities and voice chat"
    "slack|Slack|Team communication"
    "tailscale|Tailscale|VPN / remote access"
    "iterm2|iTerm2|Better terminal for macOS"
    "docker-desktop|Docker Desktop|Containers and local dev"
    "visual-studio-code|VS Code|Code editor"
)

install_apps() {
    section_header "Installing Apps"

    app_selection_menu "${_APP_ENTRIES[@]}"

    if [[ ${#SELECTED_APPS[@]} -eq 0 ]]; then
        skip "No apps selected — skipping app installation"
        return 0
    fi

    for cask in "${SELECTED_APPS[@]}"; do
        local display="" desc=""
        for entry in "${_APP_ENTRIES[@]}"; do
            if [[ "${entry%%|*}" == "${cask}" ]]; then
                local rest="${entry#*|}"
                display="${rest%%|*}"
                desc="${rest#*|}"
                break
            fi
        done
        install_cask "${cask}" "${display}" "${desc}"
    done
}

install_cask() {
    local cask_name="$1"
    local display_name="$2"
    local description="$3"

    step "Installing ${display_name} — ${description}"

    if brew list --cask "${cask_name}" &>/dev/null 2>&1; then
        skip "${display_name} already installed"
        return 0
    fi

    if brew install --cask "${cask_name}" 2>&1 | tee -a "${MACBEQUICK_LOG}"; then
        ok "${display_name} installed"
    else
        warn "${display_name} install failed — you can install it manually later"
    fi
}
