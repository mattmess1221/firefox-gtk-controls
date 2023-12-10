#!/usr/bin/env bash

set -eu

script_dir=$(dirname -- "$(readlink -f -- "$0")")

if [[ -z "${HOME:-}" ]]; then
    echo "HOME is not set" >&2
    exit 1
fi

declare XDG_CONFIG_DIR="${XDG_CONFIG_DIR:-$HOME/.config}"

declare -a firefox_dirs=(
    "$HOME/.mozilla/firefox"
    "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"
    "$HOME/snap/firefox/common/.mozilla/firefox"
)

declare -A profiles=()

prompt_yes_no() {
    local prompt="$1" yesno
    echo -n "$prompt [Y/n]: " >/dev/tty
    read -r yesno
    if [[ -z "$yesno" || "$yesno" == [yY]* ]]; then
        return 0
    fi
    return 1
}

find_firefox_profiles() {
    local index=1 dir prof
    for dir in "${firefox_dirs[@]}"; do
        if [[ -f "$dir/profiles.ini" ]]; then
            while read -r prof; do
                profiles["$index"]="$dir/$prof"
                index=$((index + 1))
            done < <(grep '^Path=' "$dir/profiles.ini" | cut -d '=' -f 2)
        fi
    done
}

print_profiles() {
    local i
    for i in "${!profiles[@]}"; do
        printf "%2d: %s\n" "$i" "${profiles["$i"]}"
    done
}

choose_profile() {
    if [[ "${#profiles[@]}" -gt 1 ]]; then
        local choice=
        while [[ -z "$choice" || " ${!profiles[*]} " != *" $choice "* ]]; do
            echo -n "Choose a profile [1-${#profiles[@]}]: " >/dev/tty
            read -r choice
        done
        echo "${profiles["$choice"]}"
    else
        if prompt_yes_no "Continue with profile 1?"; then
            echo "${profiles[1]}"
        fi
    fi
}

install_gtk_controls() {
    local profile="$1"
    local userChrome="$profile/chrome/userChrome.css"

    mkdir -p "$profile/chrome"

    ln -sf "$XDG_CONFIG_DIR/gtk-3.0" "$profile/chrome/gtk-3.0"

    cp "$script_dir"/firefox-csd.* "$profile/chrome/"

    if [[ ! -f "$userChrome" ]] || ! grep -q '^@import "./firefox-csd.css";$' "$userChrome"; then
        echo '@import "./firefox-csd.css";' >>"$userChrome"
    fi
}

parse_flatpak_filesystem_override() {
    grep '^filesystems=' | cut -d= -f2 | tr ';' '\n'
}

flatpak_filesystem_overrides() {
    flatpak override --show --user | parse_flatpak_filesystem_override
    flatpak override --show --user org.mozilla.firefox | parse_flatpak_filesystem_override
}

flatpak_has_gtk3() {
    local gtk_override
    gtk_override=$(flatpak_filesystem_overrides | grep -P '^!?xdg-config/gtk-3\.0(:ro)?$' | tail -n 1)
    if [[ -z "$gtk_override" || "$gtk_override" == !* ]]; then
        return 1
    fi
    return 0
}

apply_fix_for_flatpak() {
    if type flatpak >/dev/null; then
        if ! flatpak_has_gtk3; then
            if prompt_yes_no "GTK 3.0 assets are not accessible to Firefox. Fix it?"; then
                flatpak override --user org.mozilla.firefox --filesystem="xdg-config/gtk-3.0:ro"
            fi
        fi
    fi
}

main() {
    find_firefox_profiles

    if [[ "${#profiles[@]}" -eq 0 ]]; then
        echo "No Firefox profiles have been created. Did you launch firefox yet?" >&2
        exit 1
    fi

    echo "Found these profiles:"
    print_profiles | sort -nr

    local profile
    profile=$(choose_profile)
    if [ -n "$profile" ]; then
        install_gtk_controls "$profile"

        if [[ "$profile" == "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox/"* ]]; then
            apply_fix_for_flatpak
        fi

        echo "Install successful!"
        echo "  Don't forget to visit about:config and set \`toolkit.legacyUserProfileCustomizations.stylesheets\` to true."
        echo "  Restart firefox to apply changes."
    fi
}

main
