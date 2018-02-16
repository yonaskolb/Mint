#!/bin/bash
#
# name:
#   install.sh
#
# description:
#   Download latest release from GitHub and install.
#   Uploaded binary must be created with release.sh.
#
# parameters:
#   1: "user/app" ... your github repository name. (e.g. toshi0383/cmdshelf)
#   2: "version"  ... version string to install (e.g. 0.9.1)
#
# author:
#   Toshihiro Suzuki
#
# since:
#   2017-06-29
#
# copyright:
#   Copyright © 2017 Toshihiro Suzuki All rights reserved.
#

# e.g. toshi0383/cmdshelf
REPO_NAME=${1:?}

VERSION=${2}

# Separate arguments by '/'
OLD_IFS=$IFS; IFS=/; set -- $@; IFS=$OLD_IFS

# e.g. toshi0383/cmdshelf => cmshelf
APP_NAME=${2:?}

TEMPORARY_FOLDER=/tmp/${APP_NAME}.dst
DOWNLOAD_URLS=${TEMPORARY_FOLDER}/download.urls

# GitHub API Client ID to get rid of rate limit
CLIENT_ID=6da3e83e315e51292de6
CLIENT_SECRET=a748acd67f2e95d6098ff29243f415133b055226

# Cleanup
rm -rf $TEMPORARY_FOLDER
mkdir -p $TEMPORARY_FOLDER 2> /dev/null

# Get binary URL via github api
curl -s "https://api.github.com/repos/${REPO_NAME}/releases?client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}" \
    | grep browser_download_url \
    > $DOWNLOAD_URLS

# Grep given VERSION otherwise get latest
if [ ! -z $VERSION ];then
    BINARY_URL=$(grep $VERSION $DOWNLOAD_URLS | awk -F": \"" '{print $2}' | sed 's/\"//')
else
    BINARY_URL=$(head -1 $DOWNLOAD_URLS | awk -F": \"" '{print $2}' | sed 's/\"//')
fi

echo $BINARY_URL

# Download zip
cd ${TEMPORARY_FOLDER}
ZIP_NAME=${APP_NAME}.zip
curl -sLk $BINARY_URL -o ${ZIP_NAME}

# Install
unzip ${ZIP_NAME}
if [ -d usr/local/bin ];then
    # backward compatibility
    PREFIX=/
    TARGETS=usr
else
    PREFIX=${PREFIX:-/usr/local}/
    TARGETS=bin share lib
fi
chmod +x usr/local/bin/$APP_NAME
for target in $TARGETS
do
    cp -Rf $target $PREFIX
done
