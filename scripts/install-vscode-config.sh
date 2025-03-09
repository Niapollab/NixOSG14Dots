#!/usr/bin/env bash
set -eo pipefail

VSCODE_CONFIG_PATH="$HOME/.config/Code/User"

print_error() {
    local message
    message="$1"

    echo -e "[\033[31m!\033[0m] \033[31m$message\033[0m"
}

echo '[*] Install VSCode configuration'

if ! command -v 'jq' &>/dev/null; then
    print_error 'Unable to find "jq" programm. Is it installed?'
    exit 1
fi

if ! command -v 'code' &>/dev/null; then
    print_error 'Unable to find "code" programm. Is it installed?'
    exit 2
fi

if [ ! -d "$VSCODE_CONFIG_PATH" ]; then
    print_error 'Unable to find VSCode user configuration. Is it installed?'
    exit 3
fi

echo '[*] Install extensions.json'
sed 's/^ *\/\/.*//' 'config/vscode/extensions.json' | jq '.recommendations[]' | xargs -L 1 code --install-extension

echo '[*] Install settings.json'
cp -f 'config/vscode/settings.json' "$VSCODE_CONFIG_PATH/settings.json"
