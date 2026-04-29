#!/usr/bin/env bash
# @decision DEC-APPS-DATADRIVEN-001
# @title Data-driven app list with Ninite-style categorised selection menu
# @status accepted
# @rationale App list defined as structured entries so the selection menu and installer
#   share one source of truth. install_cask checks the cask receipt for idempotency.
#   docker-desktop is the correct cask name after Homebrew upstream rename from docker.
#   Each app entry follows the "cask_id|Display Name|description" format consumed by
#   app_selection_menu() in lib/ui.sh. CATEGORY: sentinel lines are section headers —
#   they are skipped by the installer loop (entry%%|* returns the full sentinel when
#   there is no | separator, so the cask lookup never matches them) and skipped
#   explicitly by app_selection_menu() when building the toggle index.

_APP_ENTRIES=(
    "CATEGORY:Security & Identity"
    "1password|1Password|Password manager"
    "signal|Signal|Encrypted messaging"

    "CATEGORY:Browsers"
    "google-chrome|Google Chrome|Fast, widely compatible browser"
    "firefox|Firefox|Privacy-focused open source browser"

    "CATEGORY:Communication"
    "discord|Discord|Communities and voice chat"
    "slack|Slack|Team communication"
    "zoom|Zoom|Video calls and meetings"

    "CATEGORY:Development"
    "visual-studio-code|VS Code|Code editor"
    "iterm2|iTerm2|Better terminal for macOS"
    "docker-desktop|Docker Desktop|Containers and local dev"
    "postman|Postman|API testing and development"

    "CATEGORY:Productivity"
    "rectangle|Rectangle|Window snapping and tiling"
    "raycast|Raycast|Launcher, clipboard history, shortcuts"

    "CATEGORY:Networking"
    "tailscale|Tailscale|VPN and remote access"

    "CATEGORY:Media & Utilities"
    "spotify|Spotify|Music streaming"
    "the-unarchiver|The Unarchiver|Open zip, rar, 7z and more"
    "vlc|VLC|Play any video or audio format"
)

install_apps() {
    section_header "Installing Apps"

    if [[ ${DRY_RUN:-0} -eq 1 ]]; then
        step "[DRY RUN] Would show app selection menu and install chosen apps"
        return 0
    fi

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
