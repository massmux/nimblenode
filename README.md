# Nimble Node

Setup a Lightning Neutrino Node with LIT and Letsencrypt in seconds on a tiny VPS

## CLI

All the scripts under `scripts/` are also available as subcommands of a single `nimblenode` entry point, so you can run `./scripts/nimblenode <command> [args...]` instead of calling each script directly (both forms keep working):

```
./scripts/nimblenode help
./scripts/nimblenode install
./scripts/nimblenode create
./scripts/nimblenode bos balance
./scripts/nimblenode logs           # last 50 lines of the lit container
./scripts/nimblenode logs bos       # last 50 lines of the bos container
./scripts/nimblenode logs bos 200   # last 200 lines of the bos container
./scripts/nimblenode status         # container status (docker compose ps)
./scripts/nimblenode start          # start all containers (docker compose up -d)
./scripts/nimblenode stop           # stop all containers, keeping data (docker compose stop)
./scripts/nimblenode watchtower stats  # watchtower client stats (also: info, add, towers)
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

## Watchtower

LND can run a watchtower server (it watches the chain on behalf of other nodes and punishes channel breaches) and a watchtower client (it backs up your own channel states to remote towers). Both are optional and off by default. Enable them in `.env`:

- `WATCHTOWER=true`: runs the watchtower server, listening on port `9911`.
- `WTCLIENT=true`: runs the watchtower client. It is independent of the server, so you can enable only the client to use an external watchtower.

Absent or `false`, the generated configuration is unchanged.

### Apply the change

Always edit `.env` (the switches are read by `entrypoint.sh`), never `.lit/lit.conf`: it is regenerated from scratch at every start of the `lit` container. No image rebuild is needed; from the project folder recreate the container and unlock the wallet again:

```
docker compose up -d --no-deps --force-recreate lit
./scripts/unlock
```

On a node updated from an earlier version, the first `docker compose up -d` after `git pull` recreates `lit` anyway (its published ports changed), so unlock the wallet afterwards.

### Watchtower server with Tor (`hybrid` / `tor`)

LND creates an onion address for the watchtower automatically and forwards it to lit's internal IP, so no firewall change is required. Since `docker-compose.yml` always publishes `9911`, the tower also answers on the VPS public IP (as the p2p port `9735` already does): in `tor` mode keep this in mind if you don't want the IP linked to the node.

### Watchtower server in clearnet mode

Without Tor there is no onion address, so the tower is advertised on your `SETHOST` and port `9911` must be reachable from the Internet. `docker-compose.yml` always publishes `9911` on the host (nothing listens there while `WATCHTOWER` is off), so the only extra step is to allow `9911/tcp` in the provider's firewall, if your VPS has one, the same way as the p2p port `9735`.

Note: ports published by Docker bypass `ufw`, so a `ufw deny` does not close them. To keep the tower private, simply leave `WATCHTOWER=false`.

### Your watchtower's address

Share this with the nodes you want to protect:

```
docker exec lit /app/lncli --network mainnet tower info
```

The `uris` field lists `<pubkey>@<host>:9911` (the `.onion` host with Tor, your `SETHOST` in clearnet).

### Use a remote watchtower (client)

With `WTCLIENT=true`, register a remote tower:

```
docker exec lit /app/lncli --network mainnet wtclient add <pubkey>@<host>:9911
```

This is a one-time runtime step: the registration is stored in LND's database and does not go into the configuration. Onion towers work in `hybrid` and `tor` modes.

Check that it works:

```
docker exec lit /app/lncli --network mainnet wtclient towers
docker exec lit /app/lncli --network mainnet wtclient stats
```

In `stats`, expect `num_sessions_acquired` greater than 0 and `num_failed_backups` equal to 0.

The same commands are available through the CLI:

```
./scripts/nimblenode watchtower info                        # tower info
./scripts/nimblenode watchtower add <pubkey>@<host>:9911    # wtclient add
./scripts/nimblenode watchtower towers                      # wtclient towers
./scripts/nimblenode watchtower stats                       # wtclient stats
```

Note: when a tower is added while the node is already running, the client can take 5–10 minutes to open its sessions because of the back-off between attempts. This is normal.

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
