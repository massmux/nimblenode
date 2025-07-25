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

- Run the container

```
cd nimblenode
docker-compose up -d
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

Balance of Satoshis (BOS) is now preinstalled. you can use it by entering the container with

```
docker exec -ti bos bash
```
then you can access the bos command in the local directory. Please bear in mind that you must configure the configuration file located in

```
.bos/YOURNODENAME/credentials.json
```
to get the content of this configuration file automatically, just run the command

```
./scripts/grpc
```

## Maintenance

Just connect to your running container with

```
docker exec -ti lit bash
```

then you can access the lncli command as usual to manage your node from the command line.


Tested with [Tritema](https://tritema.ch) VPS. The base version is ok.
