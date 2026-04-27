#!/usr/bin/env bash
# @decision: All GUI app installs via brew cask in one place. install_cask checks the
# cask receipt (not /Applications) for idempotency because users may rename or move .app
# bundles. Non-fatal on individual failure so one broken cask doesn't abort the session.

install_apps() {
    section_header "Installing Apps"

    install_cask "1password"           "1Password"       "password manager"
    install_cask "signal"              "Signal Desktop"  "encrypted messaging"
    install_cask "discord"             "Discord"         "voice + text chat for communities"
    install_cask "tailscale"           "Tailscale"       "personal VPN / remote access"
    install_cask "iterm2"              "iTerm2"          "better terminal for macOS"
    install_cask "visual-studio-code"  "VS Code"         "code editor"
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
