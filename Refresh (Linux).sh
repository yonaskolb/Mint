#!/bin/bash



set -e
REPOSITORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${REPOSITORY}"
gnome-terminal -e "bash --login -c \"source ~/.bashrc; ./Refresh\ \(macOS\).command; exec bash\""
