#!/bin/bash
if [ "$1" = "1" ]; then
    sudo phpenmod xdebug
else
    sudo phpdismod xdebug
fi

sudo service php7.0-fpm restart