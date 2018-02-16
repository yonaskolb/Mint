#!/bin/bash
#
# name:
#   release.sh
#
# description:
#   Archive your SwiftPM executable.
#   Created zip is intended to distributed via GitHub releases page and installed by using install.sh.
#   Executable should be built with `-static-stdlib` option.
#     e.g. `swift build -c release -Xswiftc -static-stdlib`
#
# parameters:
#   1: executable name ... e.g. cmdshelf
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

# executable
APP_NAME=${1:?}

RELEASE_DIR=.build/release
EXECUTABLE=${RELEASE_DIR}/${APP_NAME}
DOC=docs/man
BIN=bin

install_name_tool -delete_rpath `xcode-select -p`/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx $EXECUTABLE
mkdir -p $BIN
cp $EXECUTABLE $BIN/

# manual pages
MAN_DIR=doc/man
SHARE=share
mkdir -p $SHARE
cp -R $MAN_DIR $SHARE/

# resources
RESOURCES=
PACKAGE_RESOURCES=Packge.resources
if [ -f $PACKAGE_RESOURCES ];then
    RESOURCES=resources
    mkdir $RESOURCES
    while read dir
    do
        cp -R $dir $RESOURCES/
    done < $PACKAGE_RESOURCES
fi

zip -r ${APP_NAME}.zip $BIN $SHARE $RESOURCES
