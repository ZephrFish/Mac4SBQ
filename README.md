# macbequick

One-command Mac setup for new developers.

## What it does

Runs an interactive Ninite-style app picker, then installs and configures everything you need to start coding on a Mac.

**Apps** (toggle each on/off before installing)

| Category | Apps |
|---|---|
| Security & Identity | 1Password, Signal |
| Browsers | Google Chrome, Firefox |
| Communication | Discord, Slack, Zoom |
| Development | VS Code, iTerm2, Docker Desktop, Postman |
| Productivity | Rectangle, Raycast |
| Networking | Tailscale |
| Media & Utilities | Spotify, The Unarchiver, VLC |

**Terminal**
- Starship prompt (shows git branch, language versions)
- oh-my-zsh with smart tab-completion and plugins
- Fish-style autosuggestions and syntax highlighting
- fzf for fuzzy history search (CTRL+R) and file picking (CTRL+T)
- iTerm2 pre-configured with MesloLGM Nerd Font for Powerline symbols
- Useful CLI tools: `bat`, `eza`, `ripgrep`, `fd`, `jq`, `tldr`, `git-delta`, `thefuck`, and more

**VS Code**
- One Dark Pro theme + Material icons
- Prettier (format on save), ESLint, GitLens, ErrorLens
- Python, Go, and Rust language support
- Spell checker, indent rainbow, path intellisense

**Git & Identity**
- Prompts for your name and email during setup (no manual `git config` needed)
- Generates an Ed25519 SSH key and adds it to the macOS keychain
- Writes a global `.gitignore` covering macOS junk, secrets, and editor files
- Configures sensible git defaults (main branch, VS Code editor, keychain credentials)
- Optional: GitHub CLI (`gh`) auth via browser

**Node.js**
- nvm installed and Node.js LTS auto-installed during setup

After setup, a guided tour walks you through what was installed and how to use it.

## Usage

```bash
git clone https://github.com/ZephrFish/Mac4SBQ ~/tools/macbequick
bash ~/tools/macbequick/setup.sh
```

Safe to re-run — skips anything already installed.

**Preview without making changes:**
```bash
bash ~/tools/macbequick/setup.sh --dry-run
```

## Requirements

- macOS 12 (Monterey) or newer
- ~10 GB free disk space
- Internet connection

Homebrew and Xcode Command Line Tools are installed automatically if missing.

## What gets changed

| Location | What |
|---|---|
| `~/.zshrc` | Written from `config/zshrc.template` (existing file backed up) |
| `~/.config/starship.toml` | Starship prompt config (pastel-powerline preset) |
| `~/.oh-my-zsh` | oh-my-zsh installation |
| `~/.fzf.zsh` | fzf key bindings |
| `~/.ssh/id_ed25519` | SSH key (only if one doesn't already exist) |
| `~/.gitignore_global` | Global gitignore |
| `~/Library/Application Support/Code/User/settings.json` | VS Code settings (merged, not overwritten) |
| `~/Library/Application Support/iTerm2/DynamicProfiles/macbequick.json` | iTerm2 font profile |
| `~/.macbequick/` | Setup logs |

## Structure

```
setup.sh            ← run this (--dry-run to preview)
lib/
  ui.sh             ← output helpers and interactive menus
  prereqs.sh        ← system checks and Homebrew bootstrap
  apps.sh           ← interactive app selection and install
  terminal.sh       ← shell setup, CLI tools, Node.js LTS
  vscode.sh         ← VS Code extensions and settings
  gitconfig.sh      ← git identity, SSH key, gh auth
config/
  zshrc.template    ← the .zshrc written to your home directory
  Brewfile          ← declarative package list (brew bundle check)
tour/
  tour.sh           ← post-install guided narrative
.github/
  workflows/
    shellcheck.yml  ← CI: shellcheck on every push and PR
```

## After setup

1. Open iTerm2 — your new prompt and Powerline icons are ready
2. Sign into GitHub in VS Code (bottom-left account icon)
3. Open Rectangle from Applications — it runs in the menu bar (try CMD+OPT+←)
