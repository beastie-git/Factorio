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

USERNAME=""
TOKEN=""

function help {
  cat <<EOF
update-factorio.sh v 1.0

Username, token and factorio binary path can be definded in the global variables of this script.

Arguments :
  -h, --help          : Print this help
  -v, --version       : Print version

  -u, --username      : Your factorio.com username
  -t, --token         : Your factorio.com authentication token

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
    -u | --username)
      if [[ $2 ]]
      then
        USERNAME=$2
        printf "Username : %s\n" "$2"
      else
        printf "\033[0;31m[update-factorio.sh]\033[0m syntax error, please use update-factorio.sh --help for more details\n"
        exit 1
      fi
      shift
      ;;
    -t | --token)
      if [[ $2 ]]
      then
        TOKEN=$2
        printf "Token : %s\n" "$2"
      else
        printf "\033[0;31m[update-factorio.sh]\033[0m syntax error, please use update-factorio.sh --help for more details\n"
        exit 1
      fi
      shift
      ;;
  esac
  shift
done

if [[ -z $USERNAME || -z $TOKEN ]]
then
  printf "\033[0;31m[update-factorio.sh]\033[0m Args missing, please use update-factorio.sh --help for more details\n"
  exit 1
fi

printf "\033[0;33m[update-mods.sh]\033[0m Fetching mod list :\n"
wget -O mods/mods.json https://mods.factorio.com/api/mods?page_size=max
if [[ $? ]]
then
  IFS=$'\n'
  for i in $(cat mods/mod-list.json | grep name | grep -v base | sed -E -e 's/\"|,|name|\: |^[[:blank:]]*//g')
  do
    MOD_VERSION=$(ls mods/ | grep "$i" | sed -e 's/.zip//g' -E -e 's/%20|_/ /g' | awk '{printf $NF}')
    AVAIABLE_VERSION=$(cat mods/mods.json | sed -e 's/}, {/\n/g' | grep "\"name\": \"$i\"" | sed -E -e 's/, /\n/g' -e 's/"|[[:blank:]]//g' | awk 'BEGIN {FS=":"} /^version/ {printf $2}')
    if [[ $MOD_VERSION != $AVAIABLE_VERSION ]]
    then
      printf "\033[0;31m[update-mods.sh]\033[0m Mod %s need update from %s to %s\n" "$i" "$MOD_VERSION" "$AVAIABLE_VERSION"
      MOD_LINK=$(cat mods/mods.json | sed -e 's/}, {/\n/g' | grep "\"name\": \"$i\"" | sed -E -e 's/, /\n/g' -e 's/"|[[:blank:]]//g' | awk 'BEGIN {FS=":"} /download_url/ {printf $3}')
      printf "\033[0;33m[update-mods.sh]\033[0m Fetching mod : https://mods.factorio.com%s\n" "$MOD_LINK"
      wget -O $i\_$AVAIABLE_VERSION.zip https://mods.factorio.com$MOD_LINK?username=$USERNAME\&token=$TOKEN
      if [[ $? ]]
      then
        mv $i\_$AVAIABLE_VERSION.zip mods/$i\_$AVAIABLE_VERSION.zip
        rm mods/$i\_$MOD_VERSION.zip
      else
        printf "\033[0;31m[update-mods.sh]\033[0m Error when fetching mod\n"
        exit 1
      fi
    else
      printf "\033[0;33m[update-mods.sh]\033[0m Mod %s is up to date\n" "$i"
    fi
  done
else
  printf "\033[0;31m[update-mods.sh]\033[0m Error when fetching mod list\n"
  exit 1
fi