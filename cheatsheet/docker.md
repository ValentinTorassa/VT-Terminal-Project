# Docker Shortcuts

## Aliases

| Alias | Command |
|-------|---------|
| `dkps` | `docker ps` (formatted table) |
| `dkc` | `docker compose` |
| `dkcu` | `docker compose up -d` |
| `dkcd` | `docker compose down` |
| `dkcl` | `docker compose logs -f` |
| `dkl` | Launch lazydocker |
| `dksh` | Shell into container (fuzzy select) |

## Lazydocker Shortcuts

| Shortcut | Action |
|----------|--------|
| `Enter` | Focus panel |
| `[` / `]` | Switch panels |
| `d` | Remove container/image |
| `s` | Stop container |
| `r` | Restart container |
| `l` | View logs |
| `b` | Bulk actions |
| `q` | Quit |

## Useful Docker Commands

| Command | Action |
|---------|--------|
| `docker system prune -a` | Remove all unused data |
| `docker stats` | Live resource usage |
| `docker inspect <name>` | Container details (JSON) |
