# LND-Fastnode

setup a LND neutrino node in seconds on a tiny VPS.

## Install and run

```
git clone https://github.com/massmux/lnd-fastnode
```

- edit docker-compose.yml setting the UI password
- pull the image

```
docker pull massmux/lit
```

- run the container

```
cd lnd-fastnode
docker-compose up -d
```
- create the wallet

```
./create.sh
```

you will be asked about the wallet encryption key and how to setup the seed phrase. Backup them all carefully offline.

- that's it
- connect to the server with

```
https://YOURVPSIP:8443
```
or better use nginx with a own domain name
