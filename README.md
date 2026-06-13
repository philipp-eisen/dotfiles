# dotfiles

Portable shell setup via [Nix](https://nixos.org), [nix-darwin](https://github.com/nix-darwin/nix-darwin), and [Home Manager](https://github.com/nix-community/home-manager).
One repo, identical shell (zsh + oh-my-zsh + starship + fzf + mise + aliases + git config + CLI tools) on macOS and Linux, with macOS system and Homebrew state declared through nix-darwin.

```
flake.nix          pins nixpkgs + home-manager (flake.lock = exact versions everywhere)
darwin/system.nix  mac system config: nix-darwin, Homebrew, casks, editor extensions
home/common.nix    ~90% of the setup, shared across machines
home/darwin.nix    mac-only: brew shellenv, orbstack, 1Password git signing, macOS aliases
home/linux.nix     vm-only: genericLinux fixes, GNU ls, pnpm path
starship.toml      prompt config, tracked as plain toml
```

## Install: macOS

```sh
# 1. Install Nix (Determinate Systems installer — survives macOS updates,
#    flakes enabled out of the box). Run in a real terminal, it prompts for sudo.
curl -fsSL https://install.determinate.systems/nix | sh -s -- install

# 2. Open a NEW terminal (so `nix` is on PATH), then clone:
git clone <this-repo-url> ~/dev/repos/dotfiles

# 3. First activation. nix-darwin owns macOS system state and runs
#    Home Manager for the phil user.
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/dev/repos/dotfiles#phil

# 4. If a ~/.gitconfig exists, move it aside — git reads it AFTER the
#    home-manager-managed ~/.config/git/config, so it would win conflicts:
[ -f ~/.gitconfig ] && mv ~/.gitconfig ~/.gitconfig.old

# 5. Open a new shell.
```

Homebrew casks, taps, formulae, and editor extensions are declared in
`darwin/system.nix`. CLI tools still belong in `home.packages` when nixpkgs has
a good package; PATH is ordered (in `darwin.nix`) so the nix version wins if
brew has the same tool.

## Install: Ubuntu / Debian VM

```sh
# 0. Basics (fresh VMs often lack these):
sudo apt-get update && sudo apt-get install -y curl git xz-utils

# 1. Install Nix (same installer works on Linux):
curl -fsSL https://install.determinate.systems/nix | sh -s -- install

# 2. New shell (or `. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`), then:
git clone <this-repo-url> ~/dev/repos/dotfiles

# 3. Activate. If the VM is ARM (e.g. an aarch64 cloud box) or the user isn't
#    `phil`, adjust `system` / `username` for phil@vm in flake.nix first.
nix run home-manager/master -- switch -b backup --flake ~/dev/repos/dotfiles#phil@vm

# 4. Make the nix-installed zsh the login shell (home-manager can't do this
#    on non-NixOS). Run chsh via sudo — cloud VM accounts are usually
#    passwordless, so plain chsh can't authenticate. The trailing "$USER"
#    matters: without it, sudo chsh changes ROOT's shell.
command -v zsh | sudo tee -a /etc/shells
sudo chsh -s "$(command -v zsh)" "$USER"

# 5. Log out/in.
```

No sudo on the box? Leave bash as the login shell and hand interactive
sessions to zsh by appending this to `~/.bashrc`:

```sh
if [ -t 1 ] && [ -z "$ZSH_VERSION" ] && command -v zsh >/dev/null; then
  exec zsh
fi
```

## Daily usage

```sh
# change something: edit home/*.nix, then
sudo darwin-rebuild switch --flake ~/dev/repos/dotfiles#phil # mac
home-manager switch --flake ~/dev/repos/dotfiles#phil@vm     # linux VM

# IMPORTANT: the flake only sees git-TRACKED files — `git add` new files first,
# or you'll get "Path ... is not tracked by Git".

# update all packages to latest pinned nixpkgs:
cd ~/dev/repos/dotfiles && nix flake update && sudo darwin-rebuild switch --flake .#phil

# something broke? roll back to the previous generation:
darwin-rebuild --list-generations  # list mac states
sudo darwin-rebuild --rollback     # undo last mac switch
home-manager generations           # list linux VM states
home-manager switch --rollback     # undo last linux VM switch
```

Commit `flake.lock` — it's what makes every machine get bit-for-bit identical
tool versions.

## Future setup

Add managed per-machine private configuration once the preferred flow is settled.

## Conventions

- **Terraform = OpenTofu** here (`t` = `tofu`) — free license means prebuilt
  binaries from the nix cache.
- **Node versions via mise**: `mise use -g node@22`.
- **GitHub auth via `gh`** (`gh auth login`) — no credential files.
