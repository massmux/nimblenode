# Nimble Node

Setup a Lightning Neutrino Node with LIT and Letsencrypt in seconds on a tiny VPS

## CLI

All the scripts under `scripts/` are also available as subcommands of a single `nimblenode` entry point, so you can run `./scripts/nimblenode <command> [args...]` instead of calling each script directly (both forms keep working):

```
./scripts/nimblenode help
./scripts/nimblenode install
./scripts/nimblenode create
./scripts/nimblenode bos balance
```

To use it as a plain `nimblenode` command, symlink it into your `PATH` (run from the repo root):

```
sudo ln -s "$(pwd)/scripts/nimblenode" /usr/local/bin/nimblenode
```

Running it with no arguments (in a terminal) opens an interactive shell instead of exiting: type a command, see it run, and you're back at the prompt for the next one.

```
$ nimblenode
...
nimblenode> bos balance
...
nimblenode> getinfo
...
nimblenode> exit
```

### Adding the CLI to an already-running node

`scripts/nimblenode` is a plain host-side script: it only calls the other scripts in `scripts/`, which talk to the already-running containers via `docker exec`. It is not baked into any Docker image, so on a node already in production you don't need to rebuild or restart any container — just update `scripts/`:

```
cd nimblenode
git pull
chmod +x scripts/nimblenode
```

Then use it right away (`./scripts/nimblenode help`, or symlink it as shown above).

## Quick install (guided)

The fastest way is the guided installer, which checks prerequisites, prepares `.env`, starts the services, creates the wallet and optionally configures BOS, ThunderHub and the Telegram bot:

```
git clone https://github.com/massmux/nimblenode
cd nimblenode
sudo ./scripts/install
```

On the first run it creates `.env` from the template and asks you to fill it in (UI password, alias, and the `SETHOST` / `THUB_HOST` / `LND_HOST` domains plus `LETSENCRYPT_EMAIL`). Set the matching DNS A records, then run `sudo ./scripts/install` again to complete the setup.

The manual steps below are still available if you prefer to run each part yourself.

## Install and run

Register a domain name and point the DNS A record to the VPS's public IP. Don't start the procedure until the zone is propagated and you have a fully qualified domain name which A to your VPS

```
git clone https://github.com/massmux/nimblenode
```

- edit .env file setting: 1) the UI password (at least 8 chars long), 2) your node's ALIAS, 3) your fully qualified hostname
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
https://your-domain-name
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

`initbos` reads the node alias from `SETALIAS` in `.env` and generates `.bos/<alias>/credentials.json` (when `SETALIAS` is empty it falls back to the `NimbleNode` account).

Then run BOS commands with the wrapper script, which automatically targets your node (`SETALIAS` in `.env`, same fallback as above):

```
./scripts/bos balance
./scripts/bos peers
./scripts/bos --help
```

Alternatively, enter the container directly (the `bos` executable lives in `/app`, and every command needs `--node <your-alias>`):

```
docker exec -ti -w /app bos bash
./bos balance --node <your-alias>
```

### Telegram bot (optional)

BOS can send node notifications to a Telegram bot and run persistently. After BOS is initialized (`./scripts/initbos`), create a bot with @BotFather and run:

```
./scripts/initbostelegram
```

The script saves your bot token, starts the bot and asks you to send `/connect` to it on Telegram. Paste back the connection code it replies with, and the bot switches to connected mode. From then on it runs persistently and reconnects automatically after container or VPS restarts (no need to run `/connect` again).

Check its status with:

```
docker logs -f bos
```

## ThunderHub

ThunderHub is a web UI to manage your node. It is served through the built-in reverse proxy (nginx-proxy + acme-companion) on its own subdomain with an automatic Let's Encrypt certificate.

Before starting, in your `.env` set `THUB_HOST` (e.g. `thunderhub.your-domain-name`) and `LETSENCRYPT_EMAIL`, and add a DNS A record for that subdomain pointing to your VPS.

Then, after the LND wallet has been created (with `./scripts/create`), run:

```
./scripts/initthub
```

The script asks for a master password (or generates one), writes `thubConfig.yaml`, and starts ThunderHub and the reverse proxy. Once the certificate is issued you can access it at:

```
https://thunderhub.your-domain-name
```

## LND REST API

To connect external apps (e.g. Zeus, LNbits) via a clean URL instead of a raw IP and port, the node exposes LND's REST API on its own subdomain through the reverse proxy, with a valid Let's Encrypt certificate.

Set `LND_HOST` in your `.env` (e.g. `lnd.your-domain-name`) and add a DNS A record for that subdomain pointing to your VPS. After `docker compose up -d`, the endpoint is:

```
https://lnd.your-domain-name
```

Apps authenticate with a macaroon (no IP/port and no custom certificate needed, since the proxy serves a trusted certificate). The URL alone grants no access: every request requires a valid macaroon.

Security note: for third-party apps prefer a least-privilege macaroon over `admin.macaroon` (which can spend funds). Consider also restricting access by IP at the proxy level.

### Custom macaroons

To generate a least-privilege macaroon for an app (instead of the all-powerful `admin.macaroon`), run:

```
./scripts/mkmacaroon
```

It offers ready-made profiles (read-only, invoice-only) or a custom set of `entity:action` permissions, can restrict the macaroon to a single IP address, and prints it in both hex and base64 for use with the REST endpoint above.

## Tor

The node can run LND behind a Tor v3 onion service. A hardened `tor` sidecar is built from the official Tor Project repository (see `Dockerfile.tor`) and runs on the internal `lan` network, so LND reaches it at `tor:9050` (SOCKS) and `tor:9051` (control) and authenticates with the standard control cookie (shared through the `tor-data` volume). LND creates and manages its own onion address; only LND's peer-to-peer traffic uses Tor (the web UIs stay on clearnet). The control and SOCKS ports are never published to the host, staying on the internal docker network only.

Choose the mode during `./scripts/install`, or set `TOR_MODE` in `.env`:

- `clearnet` (default): public IP + domain only, no Tor. The `tor` container does not start.
- `hybrid`: reachable via both the clearnet FQDN and an auto-generated `.onion`.
- `tor`: onion only, the public IP is never advertised (stream isolation on).

The installer keeps `COMPOSE_PROFILES` in sync (empty for clearnet, `tor` otherwise), so a plain `docker compose up -d` starts or skips the Tor container automatically. To switch mode on an existing node, edit `TOR_MODE` and `COMPOSE_PROFILES` in `.env`, then:

```
docker compose up -d
docker compose restart lit
```

Find your node's onion address once LND is running with:

```
docker exec -ti lit lncli getinfo
```

Look for the `.onion` entry under `uris`.

## Maintenance

Just connect to your running container with

```
docker exec -ti lit bash
```

then you can access the lncli command as usual to manage your node from the command line.

## Refresh credentials (TLS certificate changed)

BOS and ThunderHub connect to LND using a copy of the node's TLS certificate embedded in their configuration (`.bos/<node>/credentials.json` and `thubConfig.yaml`). If LND ever regenerates `tls.cert` (for example after the node's IP or hostnames change, or on TLS auto-refresh), those embedded copies become stale and the apps stop connecting. Typical symptoms:

- BOS logs show `14 UNAVAILABLE ... self-signed certificate`
- ThunderHub shows accounts as missing credentials / cannot connect

Re-sync the embedded credentials with the current certificate (this preserves all your passwords and only restarts the affected containers, and does nothing if everything already matches):

```
sudo ./scripts/refreshcreds
```

## Reset the node

This will completely whipeout your node and all lightning data (so be sure to have a backup or to have emptied all your funds). This is nice to redo the stuff from the beginning or to create a fresh node.

```
./scripts/reset
```


The whole system is available and configured on [DENALI](https://denali.pro) Lightning Node (LN2) VPS.
