# Getting Started with Your New Mac

Welcome. This guide walks you through everything that was set up on your Mac and how to make the most of it from day one.

---

## What Was Installed

### 1Password — Password Manager

1Password securely stores all of your passwords, so you only ever need to remember one. Every account you create going forward should use a unique, randomly generated password — 1Password handles that for you automatically.

**Getting started:** Open 1Password and create your account. When you sign into a website for the first time, it will offer to save your credentials. Let it.

---

### Signal — Private Messaging

Signal is an encrypted messaging app. Everything you send is visible only to you and the recipient — not to Signal, not to anyone else. Use it as your primary messaging app for personal conversations.

**Getting started:** Download Signal on your phone too and link it to your desktop app via Settings → Linked Devices.

---

### Discord — Communities & Communication

Discord is where developer communities, study groups, and professional networks gather. You can find communities for almost any topic, ask questions, and connect with people who are learning the same things you are.

**Getting started:** Create an account, then search for communities related to what you're learning or working on.

---

### Tailscale — Private Network

Tailscale creates a secure, private network between all of your devices. It means you can access your home computer from anywhere in the world as if you were sitting in front of it, without exposing anything to the public internet.

**Getting started:** Sign in with your Google or GitHub account. Install Tailscale on any other devices you want to connect.

---

### iTerm2 — Terminal

iTerm2 is your command line — the place where you run code, manage files, and interact with your computer at a deeper level. It is a significant upgrade over the default macOS Terminal, with split panes, searchable history, and a configurable profile system.

**Getting started:** iTerm2 is your default terminal from now on. Open it with Spotlight (CMD + Space, type "iTerm").

---

### Docker Desktop — Development Environments

Docker lets you run applications in isolated containers, which means you can run a database, a web server, or an entire application stack on your machine without installing anything permanently. It is the standard way to set up local development environments.

**Getting started:** Open Docker Desktop and sign in. You will use it through the terminal once you start working with projects.

---

### Visual Studio Code — Code Editor

VS Code is where you write code. It has been configured with a set of extensions that provide automatic formatting, error detection, and visual improvements out of the box.

**Getting started:** Open VS Code from your terminal by navigating to any folder and typing `code .` — the dot means "open this folder."

---

## Your Terminal Environment

Your terminal has been configured with several tools designed to make everyday tasks faster and more intuitive.

### The Prompt

Your prompt shows you:
- Which folder you are currently in
- Which git branch you are on (when inside a code project)
- Whether there are unsaved changes in your project

### Useful Shortcuts

| Shortcut | What it does |
|---|---|
| `CTRL + R` | Search your command history — type any part of a command you ran before |
| `CTRL + T` | Find and paste any file path on your machine |
| `ll` | List all files in the current folder with sizes and dates |
| `cat filename` | View a file's contents with syntax highlighting |
| `mkcd foldername` | Create a folder and immediately enter it |
| `tldr commandname` | Show a plain-English explanation of any command |
| `serve` | Start a local web server in the current folder |

### Python & Node.js

Two version managers are installed on your machine:

- **nvm** — manages Node.js versions. Run `nvm install --lts` to install Node.js.
- **pyenv** — manages Python versions. Run `pyenv install 3.12` to install Python 3.12.

Version managers let you switch between language versions per project, which is standard practice in professional development environments.

---

## Git: Saving Your Work

Git is version control — it tracks every change you make to your code so you can review history, undo mistakes, and collaborate with others.

Think of each **commit** as a save point in a video game. You can always return to any save point.

### Daily Commands

```
git status          See what has changed since your last save
git add .           Stage all changes to be saved
git commit -m "description"   Save a snapshot with a note about what changed
git push            Upload your saves to GitHub
git pull            Download the latest changes from GitHub
git log             Browse your history of saves
```

### Your SSH Key

An SSH key was generated and saved to `~/.ssh/id_ed25519`. This is a secure credential that identifies your machine to services like GitHub, removing the need to enter a password every time you push code.

To add it to GitHub: go to **github.com → Settings → SSH and GPG Keys → New SSH key**, then paste the contents of `~/.ssh/id_ed25519.pub`.

---

## First Steps Checklist

Work through this list after setup is complete:

- [ ] Open 1Password and create your account
- [ ] Add your SSH key to GitHub
- [ ] Run `git config --global user.name "Your Name"`
- [ ] Run `git config --global user.email "you@example.com"`
- [ ] Open iTerm2 and run `nvm install --lts` to install Node.js
- [ ] Sign into GitHub inside VS Code (account icon, bottom-left corner)
- [ ] Restart iTerm2 to see your new prompt

---

## Getting Help

If you want a plain-English explanation of any terminal command, run:

```
tldr commandname
```

For example: `tldr git`, `tldr ssh`, `tldr curl`.

For anything else, the developer communities on Discord are a good first stop.
