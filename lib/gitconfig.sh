#!/usr/bin/env bash
# @decision: SSH key generation and global gitignore live here rather than in terminal.sh
# because they touch identity/credentials, not shell config. Keeps terminal.sh focused
# on tools. SSH key is skipped if one already exists so re-runs are safe.

setup_gitconfig() {
    section_header "Git & SSH Setup"

    _configure_git_defaults
    _write_global_gitignore
    _setup_ssh_key
    _run_gh_auth
    _check_filevault
    _setup_brew_autoupdate
}

_write_global_gitignore() {
    step "Writing global .gitignore..."

    local gitignore_global="${HOME}/.gitignore_global"
    if [[ -f "${gitignore_global}" ]] && grep -q "macbequick" "${gitignore_global}" 2>/dev/null; then
        skip "Global .gitignore already configured"
        return 0
    fi

    cat > "${gitignore_global}" << 'EOF'
# macbequick — global gitignore
# These are ignored in every git repo on this machine.

# macOS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
.AppleDouble
.LSOverride

# Environment & secrets — never commit these
.env
.env.*
.envrc
*.pem
*.key
*.p12
*.pfx
secrets/
credentials/

# Editor
.vscode/settings.json
.idea/
*.swp
*.swo
*~

# Logs & temp
*.log
tmp/
temp/
EOF

    git config --global core.excludesfile "${gitignore_global}"
    ok "Global .gitignore written to ${gitignore_global}"
}

_setup_ssh_key() {
    step "Checking for SSH key..."

    if [[ -f "${HOME}/.ssh/id_ed25519" ]]; then
        skip "SSH key already exists at ~/.ssh/id_ed25519"
        _print_ssh_instructions
        return 0
    fi

    step "Generating SSH key (Ed25519)..."
    mkdir -p "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"

    ssh-keygen -t ed25519 -C "macbequick-$(hostname)" -f "${HOME}/.ssh/id_ed25519" -N "" \
        2>&1 | tee -a "${MACBEQUICK_LOG}"

    # Add to ssh-agent
    eval "$(ssh-agent -s)" > /dev/null 2>&1
    ssh-add --apple-use-keychain "${HOME}/.ssh/id_ed25519" 2>/dev/null || \
        ssh-add "${HOME}/.ssh/id_ed25519" 2>/dev/null || true

    # Write ~/.ssh/config for keychain persistence
    if [[ ! -f "${HOME}/.ssh/config" ]]; then
        cat > "${HOME}/.ssh/config" << 'EOF'
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
        chmod 600 "${HOME}/.ssh/config"
    fi

    ok "SSH key generated"
    _print_ssh_instructions
}

_print_ssh_instructions() {
    local pubkey="${HOME}/.ssh/id_ed25519.pub"
    if [[ -f "${pubkey}" ]]; then
        echo ""
        echo -e "  ${BOLD}Your SSH public key (add this to GitHub):${RESET}"
        echo -e "  ${DIM}github.com → Settings → SSH and GPG keys → New SSH key${RESET}"
        echo ""
        echo -e "  ${CYAN}$(cat "${pubkey}")${RESET}"
        echo ""
    fi
}

_configure_git_defaults() {
    step "Configuring global git defaults..."

    # Sensible defaults that every new user needs but rarely discovers themselves
    git config --global pull.rebase false          # merge on pull (less confusing than rebase for beginners)
    git config --global init.defaultBranch main    # new repos start on 'main' not 'master'
    git config --global core.editor "code --wait"  # VS Code as commit message editor
    git config --global core.autocrlf input        # normalize line endings on commit
    git config --global push.autoSetupRemote true  # git push works without -u origin branch

    # macOS Keychain credential store — HTTPS git auth persists across sessions
    git config --global credential.helper osxkeychain

    ok "Git defaults configured"
}

_run_gh_auth() {
    step "Checking GitHub CLI authentication..."

    if gh auth status &>/dev/null 2>&1; then
        skip "GitHub CLI already authenticated"
        return 0
    fi

    echo ""
    echo -e "  ${BOLD}GitHub Authentication${RESET}"
    echo "  The GitHub CLI (gh) lets you push code, open pull requests, and"
    echo "  manage repositories without typing your password every time."
    echo ""

    if ! ask_optional "Sign into GitHub now? (Opens browser)"; then
        skip "GitHub auth skipped — run 'gh auth login' whenever you're ready"
        return 0
    fi

    gh auth login --web --git-protocol ssh 2>&1 | tee -a "${MACBEQUICK_LOG}" || \
        warn "GitHub auth failed — run 'gh auth login' manually to retry"
}

_check_filevault() {
    step "Checking FileVault disk encryption..."

    local fv_status
    fv_status="$(fdesetup status 2>/dev/null)"

    if echo "${fv_status}" | grep -q "FileVault is On"; then
        ok "FileVault is enabled — disk is encrypted"
        return 0
    fi

    echo ""
    echo -e "  ${YELLOW}[NOTICE]${RESET} FileVault is ${BOLD}not enabled${RESET} on this Mac."
    echo "  FileVault encrypts your entire disk, protecting your data if your"
    echo "  Mac is ever lost or stolen. It runs in the background and has no"
    echo "  noticeable impact on performance on Apple Silicon."
    echo ""
    echo -e "  ${DIM}To enable: System Settings → Privacy & Security → FileVault → Turn On${RESET}"
    echo ""
}

_setup_brew_autoupdate() {
    step "Setting up Homebrew auto-update..."

    # brew-autoupdate keeps formulae fresh in the background weekly
    if brew autoupdate status 2>/dev/null | grep -q "running"; then
        skip "Homebrew auto-update already configured"
        return 0
    fi

    # Install brew-autoupdate tap if needed and start weekly updates
    brew tap domt4/autoupdate 2>&1 | tee -a "${MACBEQUICK_LOG}" || true
    brew autoupdate start 604800 --upgrade --cleanup 2>&1 | tee -a "${MACBEQUICK_LOG}" || \
        warn "brew-autoupdate setup failed — run 'brew update && brew upgrade' periodically"

    ok "Homebrew will auto-update weekly in the background"
}
