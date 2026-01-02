# darktable-nas

Launch [darktable](https://www.darktable.org/) with a NAS-based photo library, optimized for performance and multi-machine access.

## Features

- **Local database sync** - Database synced locally for fast performance, even over slow WiFi
- **Multi-machine support** - Lock files prevent simultaneous access from multiple computers
- **Smart mounting** - Tries local network first, falls back to Tailscale VPN
- **Proper config separation** - Local config is never synced, preventing settings conflicts
- **Thumbnail cache management** - Preserves existing thumbnails to avoid regeneration
- **Conflict detection** - Detects and backs up conflicting database changes

## How It Works

```
NAS (Source of Truth)                    Local Machine
┌─────────────────────┐                  ┌─────────────────────┐
│ darktable-db/       │   rsync at       │ ~/.local/share/     │
│   library.db ───────┼──────────────────┼──→ darktable-nas/   │
│   data.db    ───────┼── launch/close ──┼──→   library.db     │
│   darktable.lock    │                  │     data.db         │
│                     │                  │                     │
│ raws/               │   direct read    │ ~/.config/          │
│   photos... ◄───────┼──────────────────┼──  darktable-nas/   │
│                     │                  │     darktablerc     │
└─────────────────────┘                  │     (local only!)   │
                                         └─────────────────────┘
```

## Installation

### Arch Linux (AUR)

```bash
yay -S darktable-nas
```

### Manual Installation

```bash
git clone https://github.com/yourusername/darktable-nas
cd darktable-nas
sudo make install
```

## Setup

### 1. Configure CIFS Credentials

```bash
sudo mkdir -p /etc/cifs-credentials
sudo tee /etc/cifs-credentials/synology << EOF
username=YOUR_NAS_USERNAME
password=YOUR_NAS_PASSWORD
EOF
sudo chmod 600 /etc/cifs-credentials/synology
```

### 2. Create User Configuration

```bash
mkdir -p ~/.config/darktable-nas
cp /etc/darktable-nas/darktable-nas.conf.example ~/.config/darktable-nas/darktable-nas.conf
```

Edit `~/.config/darktable-nas/darktable-nas.conf` with your NAS details:

```bash
# NAS Configuration
NAS_HOST_LOCAL="192.168.1.100"        # Your NAS local IP
NAS_HOST_TAILSCALE="100.x.x.x"        # Your NAS Tailscale IP
NAS_SHARE="/photos"                    # SMB share name
NAS_MOUNT="/mnt/nas"                   # Local mount point
NAS_DB_PATH="darktable-db"             # Path to darktable database on NAS
NAS_PHOTOS_PATH="raws"                 # Path to photos on NAS
```

### 3. Set Up Mount Point

```bash
sudo mkdir -p /mnt/synology
```

### 4. Migrate Existing Database (Optional)

If you have an existing darktable database on your NAS, no migration is needed - just point the config to it.

If you have a local darktable database you want to use:

```bash
# Copy your database to NAS
cp ~/.config/darktable/library.db /mnt/synology/darktable-db/
cp ~/.config/darktable/data.db /mnt/synology/darktable-db/
```

## Usage

```bash
# Normal launch
darktable-nas

# Check connection status
darktable-nas --status

# Force remove lock (if crashed)
darktable-nas --unlock

# Pass arguments to darktable
darktable-nas -- --help

# Enable debug output
darktable-nas --debug
```

## Tailscale Setup (Optional)

For remote access, install and configure [Tailscale](https://tailscale.com/):

```bash
# Install on your machine
sudo pacman -S tailscale

# Install on your NAS (varies by NAS OS)
# See: https://tailscale.com/kb/installation

# The script will automatically start Tailscale when local network is unavailable
```

## Troubleshooting

### "Database is locked"

Another instance is running, or the previous session crashed:

```bash
# Check what's holding the lock
cat /mnt/synology/darktable-db/darktable.lock

# Force remove lock
darktable-nas --unlock
```

### Slow Thumbnail Loading

Thumbnails are cached locally in `~/.cache/darktable/`. On first launch with a new database, they need to be generated. Subsequent launches will be faster.

### XMP Sidecar Check Still Running

The script sets `run_crawler_on_start=FALSE` via command-line override. If you still see the check:

1. Verify local config: `grep run_crawler ~/.config/darktable-nas/darktablerc`
2. Delete and reinitialize: `rm ~/.config/darktable-nas/darktablerc && darktable-nas`

### Mount Fails

Check credentials and network:

```bash
# Test mount manually
sudo mount -t cifs //192.168.1.100/photos /mnt/nas -o credentials=/etc/cifs-credentials/synology,uid=$(id -u),gid=$(id -g)
```

## Configuration Reference

### darktable-nas.conf

| Variable | Default | Description |
|----------|---------|-------------|
| `NAS_HOST_LOCAL` | `192.168.1.100` | NAS IP on local network |
| `NAS_HOST_TAILSCALE` | `100.100.100.100` | NAS IP via Tailscale |
| `NAS_SHARE` | `/home` | SMB share path |
| `NAS_MOUNT` | `/mnt/synology` | Local mount point |
| `NAS_DB_PATH` | `darktable-db` | Database directory on NAS |
| `NAS_PHOTOS_PATH` | `raws` | Photos directory on NAS |
| `CIFS_CREDENTIALS` | `/etc/cifs-credentials/synology` | SMB credentials file |
| `LOCAL_DB_DIR` | `~/.local/share/darktable-nas` | Local database cache |
| `LOCAL_CONFIG_DIR` | `~/.config/darktable-nas` | Local config directory |

## License

MIT License - see [LICENSE](LICENSE)
