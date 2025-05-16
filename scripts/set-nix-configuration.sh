#!/usr/bin/env bash
set -eo pipefail

NIXOS_CONFIG_PATH="/etc/nixos"

install_file() {
    local file
    file="$1"

    echo "[*] Install \"$file\" to \"$NIXOS_CONFIG_PATH/$file\""
    sudo install --preserve-timestamps --group root --owner root --mode 0644 "nix/$file" "$NIXOS_CONFIG_PATH/$file"
}

install_file 'configuration.nix'

while (($#)); do
    ARG="$1"

    case "$ARG" in
    -h|--hardware)
        [ -z "$HARDWARE_INSTALLED" ] && install_file 'hardware-configuration.nix'
        HARDWARE_INSTALLED=1
        ;;
    -c|--constants)
        [ -z "$CONSTANTS_INSTALLED" ] && install_file 'constants.nix'
        CONSTANTS_INSTALLED=1
        ;;
    -ch|-hc)
        [ -z "$HARDWARE_INSTALLED" ] && install_file 'hardware-configuration.nix'
        HARDWARE_INSTALLED=1

        [ -z "$CONSTANTS_INSTALLED" ] && install_file 'constants.nix'
        CONSTANTS_INSTALLED=1
        ;;
    *)
        [ -n "$HARDWARE_INSTALLED" ] || [ -f "$NIXOS_CONFIG_PATH/hardware-configuration.nix" ] || install_file 'hardware-configuration.nix'
        [ -n "$CONSTANTS_INSTALLED" ] || [ -f "$NIXOS_CONFIG_PATH/constants.nix" ] || install_file 'constants.nix'
        ;;
    esac

    shift
done
