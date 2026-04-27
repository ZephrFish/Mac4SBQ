# macbequick

One-command Mac setup for new developers.

## What it does

Installs and configures everything you need to start coding on a Mac:

**Apps**
- 1Password — password manager
- Signal — encrypted messaging
- Discord — developer communities
- Tailscale — personal VPN / remote access
- iTerm2 — a much better terminal
- VS Code — code editor with extensions pre-configured

**Terminal**
- Starship prompt (shows git status, language versions)
- oh-my-zsh with smart tab-completion and plugins
- Fish-style autosuggestions and syntax highlighting
- fzf for fuzzy history search (CTRL+R) and file picking (CTRL+T)
- Useful CLI tools: `bat`, `eza`, `ripgrep`, `fd`, `jq`, `tldr`, `git-delta`, and more

**VS Code**
- One Dark Pro theme + Material icons
- Prettier (format on save), ESLint, GitLens, ErrorLens
- Python, Go, and Rust language support
- Spell checker, indent rainbow, path intellisense

After setup, a guided tour walks you through what was installed and how to use it.

## Usage

```bash
git clone https://github.com/ZephrFish/Mac4SBQ ~/tools/macbequick
bash ~/tools/macbequick/setup.sh
```

Safe to re-run — skips anything already installed.

## Requirements

- macOS 12 (Monterey) or newer
- ~5 GB free disk space
- Internet connection

Homebrew and Xcode Command Line Tools are installed automatically if missing.

## What gets changed

| Location | What |
|---|---|
| `~/.zshrc` | Written from `config/zshrc.template` (existing file backed up) |
| `~/.config/starship.toml` | Starship prompt config (pastel-powerline preset) |
| `~/.oh-my-zsh` | oh-my-zsh installation |
| `~/.fzf.zsh` | fzf key bindings |
| `~/Library/Application Support/Code/User/settings.json` | VS Code settings (merged, not overwritten) |
| `~/.macbequick/` | Setup logs |

## Structure

```
setup.sh          ← run this
lib/
  ui.sh           ← output helpers
  prereqs.sh      ← system checks and Homebrew bootstrap
  apps.sh         ← GUI app installs
  terminal.sh     ← shell setup
  vscode.sh       ← VS Code extensions and settings
config/
  zshrc.template  ← the .zshrc written to your home directory
  Brewfile        ← declarative package list (brew bundle check)
tour/
  tour.sh         ← post-install guided narrative
```

## After setup

1. Open iTerm2 (restart your terminal for the new prompt to appear)
2. Run `nvm install --lts && nvm use --lts` to install Node.js
3. Run `git config --global user.name "Your Name"` and `git config --global user.email "you@example.com"`
4. Sign into GitHub in VS Code (bottom-left account icon)
