#!/usr/bin/env bash
# @decision: VS Code setup is split from terminal.sh because it requires the `code` CLI
# which may not be in PATH until VS Code is opened once. We check for it and gracefully
# skip rather than aborting — the user can re-run setup.sh after opening VS Code once.
# Settings are merged via jq (not overwritten) to preserve any existing user preferences.

VSCODE_EXTENSIONS=(
    "esbenp.prettier-vscode"
    "dbaeumer.vscode-eslint"
    "bradlc.vscode-tailwindcss"
    "eamodio.gitlens"
    "ms-python.python"
    "ms-python.vscode-pylance"
    "golang.go"
    "rust-lang.rust-analyzer"
    "PKief.material-icon-theme"
    "zhuangtongfa.material-theme"
    "christian-kohler.path-intellisense"
    "usernamehw.errorlens"
    "streetsidesoftware.code-spell-checker"
    "oderwat.indent-rainbow"
)

setup_vscode() {
    section_header "Configuring VS Code"

    if [[ ${DRY_RUN:-0} -eq 1 ]]; then
        step "[DRY RUN] Would install VS Code extensions and merge settings"
        return 0
    fi

    if ! command -v code &>/dev/null; then
        warn "'code' CLI not found. Open VS Code once, then run setup.sh again to install extensions."
        warn "VS Code > Command Palette > 'Shell Command: Install code command in PATH'"
        return 0
    fi

    _install_vscode_extensions
    _write_vscode_settings
}

_install_vscode_extensions() {
    step "Installing VS Code extensions..."

    local installed
    installed="$(code --list-extensions 2>/dev/null)"

    for ext in "${VSCODE_EXTENSIONS[@]}"; do
        if echo "${installed}" | grep -qi "^${ext}$"; then
            skip "Extension already installed: ${ext}"
        else
            step "Installing: ${ext}"
            code --install-extension "${ext}" --force 2>&1 | tee -a "${MACBEQUICK_LOG}"
            ok "Installed: ${ext}"
        fi
    done
}

_write_vscode_settings() {
    local settings_dir="${HOME}/Library/Application Support/Code/User"
    local settings_file="${settings_dir}/settings.json"

    step "Writing VS Code settings..."

    mkdir -p "${settings_dir}"

    # Skip if macbequick has already written settings
    if [[ -f "${settings_file}" ]] && grep -q '"macbequick"' "${settings_file}" 2>/dev/null; then
        skip "VS Code settings already written by macbequick"
        return 0
    fi

    local new_settings
    new_settings='{
  "editor.formatOnSave": true,
  "editor.fontSize": 14,
  "editor.fontFamily": "MesloLGM Nerd Font, Menlo, Monaco, monospace",
  "editor.tabSize": 2,
  "editor.wordWrap": "on",
  "editor.minimap.enabled": false,
  "workbench.colorTheme": "One Dark Pro",
  "workbench.iconTheme": "material-icon-theme",
  "terminal.integrated.fontFamily": "MesloLGM Nerd Font Mono",
  "terminal.integrated.fontSize": 13,
  "files.autoSave": "onFocusChange",
  "git.autofetch": true,
  "macbequick": true
}'

    if [[ -f "${settings_file}" ]]; then
        # Merge: existing settings take precedence; macbequick fills in gaps
        local backup
        backup="${settings_file}.macbequick-backup-$(date +%Y%m%d%H%M%S)"
        cp "${settings_file}" "${backup}"
        step "Backed up existing VS Code settings to ${backup}"
        if command -v jq &>/dev/null; then
            local merged
            merged="$(jq -s '.[0] * .[1]' "${settings_file}" <(echo "${new_settings}") 2>/dev/null)"
            if [[ -n "${merged}" ]]; then
                echo "${merged}" > "${settings_file}"
                ok "VS Code settings merged"
                return 0
            fi
        fi
    fi

    echo "${new_settings}" > "${settings_file}"
    ok "VS Code settings written"
}
