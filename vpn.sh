#!/bin/bash

myDir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
myName=$(basename $0 | cut -d"." -f1)
pidFile=/var/run/${myName}.pid

source ${myDir}/common.sh
sanityCheck "$@"
parseOpts "$@"
