# 🛠️ NixOS Configuration - Asus ROG Zephyrus G14 GA402XV

## VSCode

To install recommended extensions automatically execute:

```shell
cat 'config/vscode/extensions.json' | sed 's/^ *\/\/.*//' | jq '.recommendations[]' | xargs -L 1 code --install-extension
```
