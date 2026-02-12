# Matrix

Self-hosted [Matrix](https://matrix.org/) server based on Synapse + Element Web.

## Stack

| Service | Image | Role |
|---|---|---|
| Synapse | matrixdotorg/synapse | Matrix homeserver |
| Element Web | vectorim/element-web | Web client |
| PostgreSQL | postgres:16 | Database |
| Caddy | caddy:2 | Reverse proxy + automatic TLS |

## Requirements

Ubuntu server with `make` and `sudo` access. Everything else is installed via `make init`.

## Quick start

```bash
git clone <repo> && cd matrix
make init          # install Docker
cp .env.example .env && nano .env
make up            # configure and start
make user          # create first user
```

## Configuration

Copy `.env.example` to `.env` and fill in:

```env
SERVER_NAME=example.com          # appears in user IDs: @user:example.com
MATRIX_HOST=matrix.example.com   # Synapse API endpoint
CHAT_HOST=chat.example.com       # Element Web UI

ELEMENT_BRAND=Element            # client title

POSTGRES_DB=synapse
POSTGRES_USER=synapse
POSTGRES_PASSWORD=<strong password>
```

> **Note:** `SERVER_NAME` is permanent — it cannot be changed after first launch.

DNS records required (A or CNAME → server IP):
- `SERVER_NAME`
- `MATRIX_HOST`
- `CHAT_HOST`

## Make targets

| Command | Description |
|---|---|
| `make init` | Install Docker and Docker Compose |
| `make up` | Generate configs and start all services |
| `make user` | Add a user (interactive) |
| `make user USERNAME=alice PASSWORD=secret ADMIN=yes` | Add a user (non-interactive) |

## Architecture

```
Internet → Caddy (443)
              ├── MATRIX_HOST  → Synapse :8008
              ├── CHAT_HOST    → Element Web :80
              └── SERVER_NAME  → well-known (Matrix federation discovery)
```

Synapse overrides are applied from `conf.d/overrides.yaml` at startup:
- Federation disabled
- Public registration disabled
- PostgreSQL configured via environment variables