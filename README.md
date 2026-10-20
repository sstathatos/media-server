# Media Server Docker Stack

This repository contains a complete self-hosted media server setup using Docker Compose. It includes:

- **Plex** (Media server)
- **Bazarr** (Subtitle downloader)
- **Sonarr** (TV series management)
- **Radarr** (Movies management)
- **Prowlarr** (Indexer manager — feeds indexers to Sonarr/Radarr)
- **Deluge** (Torrent client)
- **Gluetun** (VPN container with killswitch, PIA port forwarding)
- **Tailscale** (Remote access to the host)
- **Docker Networks** for container communication

## 🧰 Requirements

- Docker
- Docker Compose
- Git

## ⚙️ Setup Instructions

1. **Clone the repo**

```bash
git clone https://github.com/sstathatos/media-server-docker.git
cd media-server-docker
```

2. Create the .env file

Create a .env file with the following contents:
```
OPENVPN_USER=your_pia_username
OPENVPN_PASSWORD=your_pia_password
MEDIADIR=/path/to/your/media
TAILSCALE_AUTHKEY=tskey-auth-...
DELUGE_PASSWORD=deluge        # Deluge web UI password, used by deluge-port-sync
```

3. Start the stack
``` docker compose up -d ```

4. **Access the services**

Use the following URLs (assuming default ports and localhost access):

| Service  | Port  | URL                         |
|----------|-------|-----------------------------|
| Plex     | 32400 | http://localhost:32400      |
| Bazarr   | 6767  | http://localhost:6767       |
| Sonarr   | 8989  | http://localhost:8989       |
| Radarr   | 7878  | http://localhost:7878       |
| Prowlarr | 9696  | http://localhost:9696       |
| Deluge   | 8112  | http://localhost:8112       |

> ℹ️ **Deluge** runs inside the **Gluetun VPN** network namespace (killswitch on), and its
> web UI is published through Gluetun's `8112` port mapping. Prowlarr, Sonarr and Radarr are
> on `media_net` and talk to the internet over the host connection, not the VPN.

## 🔌 VPN and port forwarding

Gluetun requests a forwarded port from PIA (`VPN_PORT_FORWARDING=on`), and
`PORT_FORWARD_ONLY=on` keeps it on servers that support it. Without a forwarded port
Deluge accepts no incoming peer connections, which makes every torrent slow no matter
how many seeders it has.

PIA issues a new port on each reconnect, so the **deluge-port-sync** sidecar polls
Gluetun's control server and writes the current port into Deluge
([scripts/deluge-port-sync.sh](scripts/deluge-port-sync.sh)).

Useful checks:

```bash
docker exec vpn wget -qO- http://127.0.0.1:8000/v1/portforward   # current forwarded port
docker exec vpn wget -qO- http://127.0.0.1:8000/v1/publicip/ip   # VPN exit IP
docker logs deluge-port-sync                                     # port pushed into Deluge
```

> ⚠️ `deluge` and `deluge-port-sync` share the VPN container's network namespace, so after
> restarting `vpn` both must be restarted as well:
> `docker compose restart deluge deluge-port-sync`

`SERVER_REGIONS` lists several port-forward-capable regions so one dead endpoint does not
take the stack down, and `UPDATER_PERIOD=24h` keeps `config/vpn/servers.json` current —
a stale server list produces `TLS key negotiation failed` errors against dead server IPs.

## 🌱 Release quality / seeders

Minimum seeders is enforced by **Prowlarr**, not Sonarr: Settings → Apps → Sync Profiles →
`Minimum Seeders` (currently **10**). Both apps are set to *Full Sync*, so Prowlarr
overwrites indexer settings inside Sonarr/Radarr — editing minimum seeders there will be
reverted on the next sync.

Indexer preference is set per indexer in Prowlarr (lower number wins). Sonarr ranks
releases by protocol → quality → custom format score → indexer priority and only uses
seeder count as a late tie-break, so minimum seeders acts as a filter rather than a
preference.
