#!/usr/bin/env bash
# @decision: SSH key generation and global gitignore live here rather than in terminal.sh
# because they touch identity/credentials, not shell config. Keeps terminal.sh focused
# on tools. SSH key is skipped if one already exists so re-runs are safe.

setup_gitconfig() {
    section_header "Git & SSH Setup"

    _write_global_gitignore
    _setup_ssh_key
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
