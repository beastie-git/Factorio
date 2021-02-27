#!/bin/bash

# Copyright (C) 2021 Jeremie SALVI.
# License GPLv3+: GNU GPL version 3 or later.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
# See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along with this program. 
# If not, see https://www.gnu.org/licenses/.

# Originally written by Jeremie SALVI <jeremie.salvi@unixyourbrain.org>.

# Server Settings
FACTORIO_BINARY_FILE="bin/x64/factorio"
SERVER_SETTINGS_FILE="data/server-settings.json"
SAVE_FILE=""

# Iptables flag
IPTABLES=""

function help {
  cat <<EOF
Factorio.sh v 1.0

Config file, username and token can be definded in the global variables script.

Arguments :
  -h, --help         : Print this help
  -v, --version      : Print version

  -c, --config       : Server config file (default : data/server-settings.json)
  -s, --save         : Save file (eg. saves/MyAwesomeSave.zip)

Copyright (C) 2021 Jeremie SALVI.
License GPLv3+: GNU GPL version 3 or later.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.

Originally written by Jeremie SALVI <jeremie.salvi@unixyourbrain.org>.

Please visit <https://github.com/beastie-git/https://github.com/beastie-git/Factorio>.
EOF
}

function version {
  cat <<EOF
1.0
EOF
}

function setIptables {
  if [[ $(which iptables) && ! $(iptables -L -n | grep 'udp.*34197\|34197.*udp') ]]
  then
   printf "\033[0;33m[factorio.sh]\033[0m Setting a factorio iptables rule\n"
   iptables -A INPUT -p udp --dport 34197 -j ACCEPT
   IPTABLES="flag"
  fi
}

function unsetIptables {
  if [[ $IPTABLES == "flag" ]]
  then
   printf "\033[0;33m[factorio.sh]\033[0m Unsetting factorio iptables rule\n"
   iptables -D INPUT -p udp --dport 34197 -j ACCEPT
  fi
}

###
### Main
###

while [[ $1 ]]
do
  case $1 in
    -h | --help)
      help
      ;;
    -v | --version)
      version
      ;;
    -c | --config)
      if [ $2 ] && [ -s $2 ]
      then
        SERVER_SETTINGS_FILE=$2
        printf "\033[0;33m[factorio.sh]\033[0m Server settings file : %s\n" "$2"
      else
        printf "\033[0;31m[factorio.sh]\033[0m syntax error, please use factorio.sh -h for more details\n"
        exit 1
      fi
      shift
      ;;
    -s | --save)
      if [[ $2 ]] && [[ -s $2 ]]
      then
        SAVE_FILE=$2
        printf "\033[0;33m[factorio.sh]\033[0m Save file : %s\n" "$2"
      else
        printf "\033[0;31m[factorio.sh]\033[0m syntax error, please use factorio.sh -h for more details\n"
        exit 1
      fi
      shift
      ;;
  esac
  shift
done

if [[ -z $SAVE_FILE ]]
then
  printf "\033[0;31m[factorio.sh]\033[0m Args missing, please use update-factorio.sh --help for more details\n"
  exit 1
fi

# Verify versions and update factorio if needed
./update-factorio.sh || ( printf "\033[0;31m[factorio.sh]\033[0m update-factorio.sh return an error code\n" && exit 1 )
./update-mods.sh || ( printf "\033[0;31m[factorio.sh]\033[0m update-mods.sh return an error code\n" && exit 1 )

setIptables
echo "launching factorio server : "
echo "$FACTORIO_BINARY_FILE --start-server $SAVE_FILE --server_settings $SERVER_SETTINGS_FILE"
$FACTORIO_BINARY_FILE --start-server $SAVE_FILE --server-settings $SERVER_SETTINGS_FILE
unsetIptables
