# Nimble Node

Setup a Lightning Neutrino Node with LIT and Letsencrypt in seconds on a tiny VPS

## Install and run

Register a domain name and point the DNS A record to the VPS's public IP. Don't start the procedure until the zone is propagated and you have a fully qualified domain name which A to your VPS

```
git clone https://github.com/massmux/nimblenode
```

- edit docker-compose.yml setting: 1) the UI password (at least 8 chars long), 2) your node's ALIAS, 3) your fully qualified hostname
- pull the image from dockerhub

```
docker pull massmux/lit
```

- Run the containers

```
cd nimblenode
docker compose up -d
```

- Create the wallet. first usage

```
./scripts/create
```

You will be asked about the wallet encryption key and how to setup the seed phrase. Backup them all carefully offline.

- that's it
- after around 20 minutes, connect to the server with:

```
https://your-domain-name:8443
```

IMPORTANT: if you stop the docker container and restart you need to unlock your wallet with command

```
./scripts/unlock
```

## BOS

Balance of Satoshis (BOS) is preinstalled. To get this tool automatically configured, just run the command below. NB: You must execute this script only after created the LND Wallet (with /scripts/create).

```
./scripts/initbos
```

then you can use the tool by entering the container:

```
docker exec -ti bos bash
```

## Maintenance

Just connect to your running container with

```
docker exec -ti lit bash
```

then you can access the lncli command as usual to manage your node from the command line.

## Reset the node

This will completely whipeout your node and all lightning data (so be sure to have a backup or to have emptied all your funds). This is nice to redo the stuff from the beginning or to create a fresh node.

```
./scripts/reset
```


The whole system is available and configured on [DENALI](https://denali.pro) Lightning Node (LN2) VPS.
