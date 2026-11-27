#!/usr/bin/env bash
# kuumo-shell installer for Arch Linux and its derivatives.
# Installs the dependencies, then puts the shell where Quickshell looks for it.
# Safe to run again: installed packages are skipped and a correct link is kept.
# It never edits your Hyprland config (see the README, "Hyprland setup").
set -euo pipefail

# This checkout, and where Quickshell looks for its default config
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"

# Packages, grouped by what needs them
PKG_CORE=(quickshell hyprland polkit pipewire wireplumber networkmanager)
PKG_TOOLS=(awww hyprsunset brightnessctl cliphist wl-clipboard wtype fd ffmpeg xdg-utils kdeconnect)
PKG_FONTS=(inter-font ttf-jetbrains-mono-nerd ttf-material-symbols-variable)

# Only one of each can run: the shell is its own polkit agent and notification daemon
POLKIT_AGENTS=(polkit-gnome-authentication-agent-1 polkit-kde-authentication-agent-1
               hyprpolkitagent lxpolkit lxqt-policykit-agent mate-polkit xfce-polkit)
NOTIFY_DAEMONS=(mako dunst swaync fnott)

AUR_HELPER=""

say()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

# Yes/no question; anything but y is a no
ask() {
    local reply
    read -r -p "$1 [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

check_system() {
    command -v pacman >/dev/null || die "This installer is for Arch Linux and its derivatives (pacman not found)."
    [ "$(id -u)" -ne 0 ] || die "Run this as your normal user, not as root."
}

# yay-bin is the prebuilt package, so nothing has to be compiled
build_yay() {
    local dir
    dir="$(mktemp -d)"
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/yay-bin.git "$dir/yay-bin"
    (cd "$dir/yay-bin" && makepkg -si)
    rm -rf "$dir"
    AUR_HELPER=yay
}

# Use yay or paru, or offer to build yay
need_aur_helper() {
    local helper
    for helper in yay paru; do
        if command -v "$helper" >/dev/null; then
            AUR_HELPER="$helper"
            return
        fi
    done
    ask "No AUR helper found (yay or paru). Build yay now?" || die "Install yay or paru and run the installer again."
    build_yay
}

# Skip what is already satisfied (a -git build that provides the name counts),
# send official-repo packages to pacman and the rest to the AUR helper
install_packages() {
    local repo=() aur=() pkg
    for pkg in "$@"; do
        pacman -T "$pkg" >/dev/null 2>&1 && continue
        if pacman -Si "$pkg" >/dev/null 2>&1; then
            repo+=("$pkg")
        else
            aur+=("$pkg")
        fi
    done

    if [ "${#repo[@]}" -gt 0 ]; then
        say "Installing from the official repositories: ${repo[*]}"
        sudo pacman -S --needed "${repo[@]}"
    fi
    if [ "${#aur[@]}" -gt 0 ]; then
        need_aur_helper
        say "Installing from the AUR: ${aur[*]}"
        "$AUR_HELPER" -S --needed "${aur[@]}"
    fi
    if [ "${#repo[@]}" -eq 0 ] && [ "${#aur[@]}" -eq 0 ]; then
        say "All dependencies are already installed"
    fi
}

# Link this checkout to the config folder, unless it is already there
place_shell() {
    if [ "$(readlink -f "$TARGET")" = "$SRC" ]; then
        say "The shell is already at $TARGET"
        return
    fi
    if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
        local backup
        backup="$TARGET.bak-$(date +%Y%m%d-%H%M%S)"
        ask "$TARGET exists. Move it to $backup and link the shell there?" \
            || die "Left $TARGET alone. Move it yourself and run the installer again."
        mv "$TARGET" "$backup"
        say "Backed up the old folder to $backup"
    fi
    mkdir -p "$(dirname "$TARGET")"
    ln -s "$SRC" "$TARGET"
    say "Linked $TARGET -> $SRC"
}

# Warn about each name in the list that is running right now.
# Usage: warn_running "hint" name...
warn_running() {
    local hint="$1" name
    shift
    for name in "$@"; do
        if pgrep -f -- "(^|/)${name}( |\$)" >/dev/null; then
            warn "$name is running. $hint"
        fi
    done
}

check_conflicts() {
    warn_running "Remove it from your Hyprland autostart, or the shell cannot register its own polkit agent." \
        "${POLKIT_AGENTS[@]}"
    warn_running "Remove it from your autostart, or the shell cannot show notifications." \
        "${NOTIFY_DAEMONS[@]}"
    systemctl is-active --quiet NetworkManager \
        || warn "NetworkManager is not running. The Wi-Fi page needs it: sudo systemctl enable --now NetworkManager"
}

print_next_steps() {
    cat <<'EOF'

Done. The installer does not touch your Hyprland config, so two steps are yours:
  1. Start the shell from your Hyprland autostart (awww-daemon, then qs)
  2. Bind keys to the shell commands (qs ipc call ...)
Both are in the README under "Hyprland setup".
EOF
}

main() {
    check_system
    say "Checking dependencies"
    install_packages "${PKG_CORE[@]}" "${PKG_TOOLS[@]}" "${PKG_FONTS[@]}"
    place_shell
    check_conflicts
    print_next_steps
}

main "$@"s