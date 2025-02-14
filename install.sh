#!/bin/bash

mkdir -p "$HOME"/.bin
cp bin/xdebug-enable.sh "$HOME"/.bin/xdebug-enable.sh
cp bin/xdebug-disable.sh "$HOME"/.bin/xdebug-disable.sh
cp bin/switch-php.sh "$HOME"/.bin/switch-php.sh
cp bin/install-php.sh "$HOME"/.bin/install-php.sh
cp aliases.bashrc "$HOME"/.bin/aliases.bashrc

echo "if [ -f \"$HOME/.bin/aliases.bashrc\" ]; then" >> "$HOME"/.bashrc
echo "    . \"$HOME/.bin/aliases.bashrc\"" >> "$HOME"/.bashrc
echo "fi" >> "$HOME"/.bashrc

source "$HOME"/.bashrc

echo "Restart you bash session or run source ~/.bashrc to apply changes!"
