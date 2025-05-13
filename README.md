# Media Server Docker Stack

This repository contains a complete self-hosted media server setup using Docker Compose. It includes:

- **Plex** (Media server)
- **Bazarr** (Subtitle downloader)
- **Sonarr** (TV series management)
- **Radarr** (Movies management)
- **Jackett** (Indexer proxy)
- **Deluge** (Torrent client)
- **Gluetun** (VPN container with killswitch for privacy)
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

2. Create the .env file for VPN credentials

Create a .env file with the following contents:
```
OPENVPN_USER=your_pia_username
OPENVPN_PASSWORD=your_pia_password
MEDIADIR=/path/to/your/media
```

3. Start the stack
``` docker compose up -d ```

5. **Access the services**

Use the following URLs (assuming default ports and localhost access):

| Service | Port  | URL                         |
|---------|-------|-----------------------------|
| Plex    | 32400 | http://localhost:32400      |
| Bazarr  | 6767  | http://localhost:6767       |
| Sonarr  | 8989  | http://localhost:8989       |
| Radarr  | 7878  | http://localhost:7878       |
| Deluge  | 8112  | http://localhost:8112       |
| Jackett | 9117  | http://localhost:9117       |

> ℹ️ **Deluge** and **Jackett** are routed through the **Gluetun VPN container** for privacy.
