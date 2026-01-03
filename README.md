# darktable-nas

Launch [darktable](https://www.darktable.org/) with a NAS-based photo library, optimized for performance and multi-machine access.

## Features

- **Local database sync** - Database synced locally for fast performance, even over slow WiFi
- **Multi-machine support** - Lock files prevent simultaneous access from multiple computers
- **Smart mounting** - Tries local network first, falls back to Tailscale VPN
- **Proper config separation** - Local config is never synced, preventing settings conflicts
- **Thumbnail cache management** - Preserves existing thumbnails to avoid regeneration
- **Conflict detection** - Detects and backs up conflicting database changes
- **Cross-platform** - Works on both Linux and macOS

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

### Linux (Arch Linux AUR)

```bash
yay -S darktable-nas
```

### Linux/macOS (Manual)

```bash
git clone https://github.com/yourusername/darktable-nas
cd darktable-nas
sudo make install
```

## Setup

### Linux Setup

#### 1. Configure CIFS Credentials

```bash
sudo mkdir -p /etc/cifs-credentials
sudo tee /etc/cifs-credentials/NAS << EOF
username=YOUR_NAS_USERNAME
password=YOUR_NAS_PASSWORD
EOF
sudo chmod 600 /etc/cifs-credentials/NAS
```

#### 2. Create User Configuration

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
NAS_MOUNT="/mnt/NAS"                   # Local mount point
NAS_DB_PATH="darktable-db"             # Path to darktable database on NAS
NAS_PHOTOS_PATH="raws"                 # Path to photos on NAS
```

#### 3. Set Up Mount Point

```bash
sudo mkdir -p /mnt/NAS
```

### macOS Setup

#### 1. Store Credentials in Keychain

```bash
darktable-nas --setup-keychain
```

This will prompt for your NAS username and password, and store them securely in the macOS Keychain.

#### 2. Create User Configuration

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
NAS_MOUNT="/Volumes/NAS"               # Local mount point (macOS default)
NAS_DB_PATH="darktable-db"             # Path to darktable database on NAS
NAS_PHOTOS_PATH="raws"                 # Path to photos on NAS
```

#### 3. Install darktable

```bash
# Via Homebrew
brew install darktable

# Or download from https://www.darktable.org/install/
```

#### 4. Tailscale (Optional)

For remote access, install Tailscale from the Mac App Store or via Homebrew:

```bash
brew install tailscale
```

The script will check if Tailscale is running but won't try to start it - manage Tailscale via the menu bar app.

### Migrate Existing Database (Optional)

If you have an existing darktable database on your NAS, no migration is needed - just point the config to it.

If you have a local darktable database you want to use:

```bash
# Copy your database to NAS
cp ~/.config/darktable/library.db /mnt/NAS/darktable-db/
cp ~/.config/darktable/data.db /mnt/NAS/darktable-db/
```

## Usage

```bash
# Normal launch
darktable-nas

# Check connection status
darktable-nas --status

# Force remove lock (if crashed)
darktable-nas --unlock

# Store macOS Keychain credentials
darktable-nas --setup-keychain

# Pass arguments to darktable
darktable-nas -- --help

# Enable debug output
darktable-nas --debug

# Monitor thumbnail generation progress
darktable-nas-progress
```

## Tailscale Setup (Optional)

For remote access, install and configure [Tailscale](https://tailscale.com/):

### Linux

```bash
# Install on your machine
sudo pacman -S tailscale  # Arch
# or
sudo apt install tailscale  # Debian/Ubuntu

# The script will automatically start Tailscale when local network is unavailable
```

### macOS

```bash
# Install via Homebrew or Mac App Store
brew install tailscale

# Manage via the menu bar app - the script will detect if it's running
```

### NAS

Install Tailscale on your NAS (varies by NAS OS). See: https://tailscale.com/kb/installation

## Troubleshooting

### "Database is locked"

Another instance is running, or the previous session crashed:

```bash
# Check what's holding the lock
cat /mnt/NAS/darktable-db/darktable.lock   # Linux
cat /Volumes/NAS/darktable-db/darktable.lock  # macOS

# Force remove lock
darktable-nas --unlock
```

### Slow Thumbnail Loading

Thumbnails are cached locally in `~/.cache/darktable/`. On first launch with a new database, they need to be generated. Subsequent launches will be faster.

Use `darktable-nas-progress` to monitor thumbnail generation progress.

### XMP Sidecar Check Still Running

The script sets `run_crawler_on_start=FALSE` via command-line override. If you still see the check:

1. Verify local config: `grep run_crawler ~/.config/darktable-nas/darktablerc`
2. Delete and reinitialize: `rm ~/.config/darktable-nas/darktablerc && darktable-nas`

### Mount Fails (Linux)

Check credentials and network:

```bash
# Test mount manually
sudo mount -t cifs //192.168.1.100/photos /mnt/NAS -o credentials=/etc/cifs-credentials/NAS,uid=$(id -u),gid=$(id -g)
```

### Mount Fails (macOS)

Check Keychain credentials:

```bash
# Verify credentials are stored
security find-internet-password -s 192.168.1.100

# Re-run setup if needed
darktable-nas --setup-keychain
```

## Configuration Reference

### darktable-nas.conf

| Variable | Linux Default | macOS Default | Description |
|----------|---------------|---------------|-------------|
| `NAS_HOST_LOCAL` | `192.168.1.100` | `192.168.1.100` | NAS IP on local network |
| `NAS_HOST_TAILSCALE` | `100.100.100.100` | `100.100.100.100` | NAS IP via Tailscale |
| `NAS_SHARE` | `/home` | `/home` | SMB share path |
| `NAS_MOUNT` | `/mnt/NAS` | `/Volumes/NAS` | Local mount point |
| `NAS_DB_PATH` | `darktable-db` | `darktable-db` | Database directory on NAS |
| `NAS_PHOTOS_PATH` | `raws` | `raws` | Photos directory on NAS |
| `CIFS_CREDENTIALS` | `/etc/cifs-credentials/NAS` | N/A (Keychain) | SMB credentials file |
| `LOCAL_DB_DIR` | `~/.local/share/darktable-nas` | `~/.local/share/darktable-nas` | Local database cache |
| `LOCAL_CONFIG_DIR` | `~/.config/darktable-nas` | `~/.config/darktable-nas` | Local config directory |

## License

MIT License - see [LICENSE](LICENSE)
