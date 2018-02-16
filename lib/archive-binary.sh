#!/bin/bash
#
# name:
#   release.sh
#
# description:
#   Archive your SwiftPM executable.
#   Generated zip file is intended to uploaded to GitHub releases page and installed by using install.sh.
#   Executable must be built with `-static-stdlib` option.
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
TMPDIR=$(mktemp -d)
APP_NAME=${1:?}

RELEASE_DIR=.build/release
EXECUTABLE=${RELEASE_DIR}/${APP_NAME}
DOC=docs/man
BIN=$TMPDIR/bin

install_name_tool -delete_rpath `xcode-select -p`/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx $EXECUTABLE
mkdir $BIN
cp $EXECUTABLE $BIN/

# manual pages
SHARE=$TMPDIR/share
MAN_DIR=doc/man
mkdir $SHARE
cp -R $MAN_DIR $SHARE/

# resources
LIB=$TMPDIR/lib
RESOURCES=
PACKAGE_RESOURCES=Package.resources

if [ -f $PACKAGE_RESOURCES ];then
    RESOURCES=${LIB}/${APP_NAME}/resources
    mkdir -p $RESOURCES
    while read dir
    do
        cp -R $dir $RESOURCES/
    done < $PACKAGE_RESOURCES
fi

cd $TMPDIR
zip -r ${APP_NAME}.zip bin share lib
cd -

cp ${TMPDIR}/${APP_NAME}.zip .

rm -rf ${TMPDIR}
