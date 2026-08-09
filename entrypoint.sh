#!/usr/bin/env bash

# exit from script if error was raised.
set -e

# error function is used within a bash function in order to send the error
# message directly to the stderr output and exit with a failure status so
# Docker's restart policy can react to it.
error() {
    echo "$1" > /dev/stderr
    exit 1
}

# load variables from .env if present (allows running without docker-compose)
if [ -f /app/.env ]; then
    set -o allexport
    source /app/.env
    set +o allexport
fi

# setting timezone for the running process (inherited by litd below)
export TZ="Europe/Zurich"


cd /root/.lit

cat > lit.conf << EOF
httpslisten=0.0.0.0:8443
uipassword=${CHOSENPASSWORD}
lnd.rpclisten=0.0.0.0:10009
lnd.restlisten=0.0.0.0:8080
lnd.listen=0.0.0.0:9735
lnd.tlsextraip=0.0.0.0
lnd.tlsdisableautofill=1
lnd.tlsextradomain=${SETHOST}
lnd.tlsextradomain=lit
lnd.tlsautorefresh=true
lnd-mode=integrated
lnd.bitcoin.active=1
lnd.bitcoin.mainnet=1
lnd.bitcoin.node=neutrino
lnd.feeurl=https://nodes.lightning.computer/fees/v1/btc-fee-estimates.json
lnd.protocol.option-scid-alias=true
lnd.protocol.zero-conf=true
lnd.protocol.wumbo-channels=true
lnd.minchansize=1000000
databasebackend=bbolt
lnd.alias=${SETALIAS}
lnd.rpcmiddleware.enable=true
EOF

# Network privacy mode. Defaults to clearnet to preserve the previous behaviour
# when TOR_MODE is unset. The tor container (started via the "tor" compose
# profile) runs as a sidecar on the lan network, so LND reaches it at
# tor:9050 / tor:9051 and authenticates to the control port with the shared
# cookie. targetipaddress is lit's static IP so Tor forwards the onion to LND's
# p2p listener. Only LND's p2p uses Tor here; the web UIs stay on clearnet.
case "${TOR_MODE:-clearnet}" in
    tor)
        # Tor only: never advertise a clearnet address; isolate streams.
        cat >> lit.conf << EOF
lnd.tor.active=true
lnd.tor.v3=true
lnd.tor.socks=tor:9050
lnd.tor.control=tor:9051
lnd.tor.targetipaddress=172.28.0.10
lnd.tor.streamisolation=true
EOF
        ;;
    hybrid)
        # Reachable via both the clearnet FQDN and an auto-generated v3 onion.
        cat >> lit.conf << EOF
lnd.tor.active=true
lnd.tor.v3=true
lnd.tor.socks=tor:9050
lnd.tor.control=tor:9051
lnd.tor.targetipaddress=172.28.0.10
lnd.tor.skip-proxy-for-clearnet-targets=true
lnd.externalip=${SETHOST}
EOF
        ;;
    *)
        # Clearnet only (default): advertise the public FQDN, no Tor.
        echo "lnd.externalip=${SETHOST}" >> lit.conf
        ;;
esac

# add the LND REST subdomain to the TLS cert only when configured
if [ -n "${LND_HOST}" ]; then
    echo "lnd.tlsextradomain=${LND_HOST}" >> lit.conf
fi

cd /app
# run the software
./litd
