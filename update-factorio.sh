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
FACTORIO_BINARY_PATH=""
PACKAGE="core-linux_headless64"
APIVERSION="2"
SERVER_VERSION=""
LATEST_STABLE_VERSION=""
AVAIABLE_VERSIONS=$(GET https://updater.factorio.com/get-available-versions)

function help {
  cat <<EOF
update-factorio.sh v 1.0

Username, token and factorio binary path can be definded in the global variables of this script.

Arguments :
  -h, --help          : Print this help
  -v, --version       : Print version

  -u, --username      : Your factorio.com username
  -t, --token         : Your factorio.com authentication token
  -p, --path          : Factorio binary path

Copyright (C) 2021 Jeremie SALVI.
License GPLv3+: GNU GPL version 3 or later.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.

Originally written by Jeremie SALVI <jeremie.salvi@unixyourbrain.org>.
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
        printf "[update-factorio.sh] syntax error, please use update-factorio.sh --help for more details\n"
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
        printf "[update-factorio.sh] syntax error, please use update-factorio.sh --help for more details\n"
        exit 1
      fi
      shift
      ;;
    -p | --path)
      if [[ $2 ]]
      then
        FACTORIO_BINARY_PATH=$2
        printf "Path to factorio binary : %s\n" "$2"
      else
        printf "[update-factorio.sh] syntax error, please use update-factorio.sh --help for more details\n"
        exit 1
      fi
      shift
      ;;
  esac
  shift
done

if [[ -z $USERNAME ]] || [[ -z $TOKEN ]] || [[ -z $FACTORIO_BINARY_PATH ]]
then
  printf "[update-factorio.sh] Args missing, please use update-factorio.sh --help for more details\n"
  exit 1
fi

#Get server version :
SERVER_VERSION=$(bin/x64/factorio --version | awk '/Version:/ {print $2}')
printf "[update-factorio.sh] server version : %s\n" "$SERVER_VERSION"

#Get latest stable version :
LATEST_STABLE_VERSION=$(printf "$AVAIABLE_VERSIONS" | sed -e s/},{/\\n/g -e s/}]}//g -e s/\"//g | awk 'BEGIN{FS=":"} /stable/ {printf $2}')
printf "[update-factorio.sh] Latest stable version : %s\n" "$LATEST_STABLE_VERSION"

# for test only
SERVER_VERSION="1.1.24"

# If needed, fetch the patch and update
if [[ $SERVER_VERSION == $LATEST_STABLE_VERSION ]]
then
  printf "[update-factorio.sh] Factorio is on the latest stable version, skipping\n"
  exit 0
else
  printf "[update-factorio.sh] Factorio is not on the latest stable version, checking for update\n"
  printf "$AVAIABLE_VERSIONS" | sed -e s/},{/\\n/g | grep \"from\"\:\"$SERVER_VERSION\",\"to\"\:\"$LATEST_STABLE_VERSION\" > /dev/null
  if [[ $? == "0" ]]
  then
    printf "[update-factorio.sh] Update avaiable, trying to get download patch link :\n"
    DOWNLOAD_LINK=$(GET https://updater.factorio.com/get-download-link?username=$USERNAME\&token=$TOKEN\&package=$PACKAGE\&from=$SERVER_VERSION\&to=$LATEST_STABLE_VERSION\&apiversion=$APIVERSION | sed -e s/\\[\"//g -e s/\"]//g)
    if [[ $DOWNLOAD_LINK == https* ]]
    then
      mkdir -p updates
      printf "\t%s\n" "$DOWNLOAD_LINK"
      printf "[update-factorio.sh] Patch avaiable, downloading it\n"
      wget -O updates/update-$SERVER_VERSION-$LATEST_STABLE_VERSION.zip $DOWNLOAD_LINK
      ERROR=$?
      if [[ $ERROR == "0" ]]
      then
        printf "[update-factorio.sh] Applying patch...\n"
        bin/x64/factorio --apply-update updates/update-$SERVER_VERSION-$LATEST_STABLE_VERSION.zip
        if [[ $? ]]
        then
          printf "[update-factorio.sh] Patch applied sucessfull\n"
          exit 0
        else
          printf "[update-factorio.sh] Error when applying the patch\n"
          exit 1
        fi
      else
        printf "[update-factorio.sh] Wget download failled whith return %s\n" "$ERROR"
      fi
    else
      printf "[update-factorio.sh] Getting link failed, api response : %s\n" "$DOWNLOAD_LINK"
      exit 1
    fi
  else
    printf "[update-factorio.sh] No patch avaiable, exiting\n"
    exit 1
  fi
fi