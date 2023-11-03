#!/usr/bin/env bash

# exit from script if error was raised.
set -e

# error function is used within a bash function in order to send the error
# message directly to the stderr output and exit.
error() {
    echo "$1" > /dev/stderr
    exit 0
}

# setting timezone
echo "export TZ=\"/usr/share/zoneinfo/Europe/Zurich\"" >>  ~/.bashrc

cd /root/.lit
sed -i "s/uipassword=UIPSW/uipassword=$CHOSENPASSWORD/g" lit.conf

cd /app
# run the software
./litd
