VSCODE_USER_PATH="$HOME/Library/Application Support/Code/User"
VSCODE_SETTINGS_DIR="$(pwd)/vscode/settings"

files=(
    "settings.json"
    "keybindings.json"
)

extensions=(
    "rebornix.toggle"
    "whizkydee.material-palenight-theme"
    "sissel.shopify-liquid"
    "killalau.vscode-liquid-snippets"
)

for file in ${files[@]}; do
    if [ ! -f "$VSCODE_USER_PATH/$file" ]; then
        ln -s "$VSCODE_SETTINGS_DIR/$file" "$VSCODE_USER_PATH"
    fi
done

for extension in ${extensions[@]}; do
    code --install-extension ${extension} --force
done
