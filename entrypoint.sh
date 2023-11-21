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

echo "httpslisten=0.0.0.0:8443
uipassword=$CHOSENPASSWORD
lnd-mode=integrated
lnd.bitcoin.active=1
lnd.bitcoin.mainnet=1
lnd.bitcoin.node=neutrino
lnd.feeurl=https://nodes.lightning.computer/fees/v1/btc-fee-estimates.json
lnd.protocol.option-scid-alias=true
lnd.protocol.zero-conf=true
lnd.alias=$SETALIAS
lnd.externalip=$THEHOST
letsencrypt=true
letsencrypthost=$THEHOST
" > lit.conf

cd /app
# run the software
./litd
