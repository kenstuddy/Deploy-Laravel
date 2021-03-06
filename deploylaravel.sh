#!/bin/bash
#Warning: Do not run this script as root. See: https://getcomposer.org/doc/faqs/how-to-install-untrusted-packages-safely.md

if [ "$EUID" -eq 0 ]
then 
    echo "Do not run this script as root. See: https://getcomposer.org/doc/faqs/how-to-install-untrusted-packages-safely.md"
    exit
fi

EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
then
    >&2 echo 'ERROR: Invalid installer signature'
    rm composer-setup.php
    exit 1
fi

php composer-setup.php --quiet
RESULT=$?
rm composer-setup.php
sudo mv composer.phar /usr/local/bin/composer
#Since we cannot run this script as root, whoami is safe to use here.
sudo chown -R $(whoami) $HOME
composer global require "laravel/installer"
sudo find /var/www/html \( -type f -execdir chmod 644 {} \; \) \
                  -o \( -type d -execdir chmod 711 {} \; \)
sudo chown -R www-data:www-data /var/www/html
sudo a2enmod rewrite
#Adding the laravel command to zsh if zsh is installed.
if [ -e "$HOME/.zshrc" ]; then
    if ! grep -lir ".config/composer/vendor/bin" "$HOME/.zshrc"
    then
        echo 'export PATH="$PATH:$HOME/.config/composer/vendor/bin"' >> $HOME/.zshrc
        #Adding a custom laravel command (laravelv) to zsh.
        echo 'function laravelver() { if [[ $1 == "" || $2 == "" ]]; then echo "Usage: laravelver projectname laravelversion"; else composer create-project laravel/laravel="$2.*" "$1"; fi; }' >> $HOME/.zshrc
        echo 'function laravelinit() { composer install && npm install && npm run dev && cp .env.example .env && nano .env && php artisan key:generate && php artisan migrate:fresh && php artisan db:seed && php artisan serve; }' >> $HOME/.zshrc
        source $HOME/.zshrc
    fi
fi
#Adding the laravel command to bash.
if ! grep -lir ".config/composer/vendor/bin" "$HOME/.bashrc"
then
    echo 'export PATH="$PATH:$HOME/.config/composer/vendor/bin"' >> $HOME/.bashrc
    #Adding a custom laravel command (laravelv) to bash.
    echo 'function laravelver() { if [[ $1 == "" || $2 == "" ]]; then echo "Usage: laravelver projectname laravelversion"; else composer create-project laravel/laravel="$2.*" "$1"; fi; }' >> $HOME/.bashrc
    echo 'function laravelinit() { composer install && npm install && npm run dev && cp .env.example .env && nano .env && php artisan key:generate && php artisan migrate:fresh && php artisan db:seed && php artisan serve; }' >> $HOME/.bashrc
    source $HOME/.bashrc
fi
