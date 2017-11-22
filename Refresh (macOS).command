#!/bin/bash



set -e
REPOSITORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${REPOSITORY}"
if workspace version > /dev/null 2>&1 ; then
    echo "Using system install of Workspace..."
    workspace refresh •use‐version 0.2.0
elif ~/Library/Caches/ca.solideogloria.Workspace/Versions/0.2.0/workspace version > /dev/null 2>&1 ; then
    echo "Using cached build of Workspace..."
    ~/Library/Caches/ca.solideogloria.Workspace/Versions/0.2.0/workspace refresh •use‐version 0.2.0
elif ~/.cache/ca.solideogloria.Workspace/Versions/0.2.0/workspace version > /dev/null 2>&1 ; then
    echo "Using cached build of Workspace..."
    ~/.cache/ca.solideogloria.Workspace/Versions/0.2.0/workspace refresh •use‐version 0.2.0
else
    echo "No cached build detected, fetching Workspace..."
    rm -rf /tmp/Workspace
    git clone https://github.com/SDGGiesbrecht/Workspace /tmp/Workspace
    cd /tmp/Workspace
    swift build --configuration release
    cd "${REPOSITORY}"
    /tmp/Workspace/.build/release/workspace refresh •use‐version 0.2.0
    rm -rf /tmp/Workspace
fi
