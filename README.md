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

#### 1. Create Cross-Platform Mount Point

For database compatibility with Linux, macOS needs to mount at the same path (e.g., `/mnt/synology`). Since macOS has a read-only root filesystem, we use a synthetic firmlink:

```bash
# Create the synthetic firmlink (requires reboot)
echo -e "mnt\tUsers/Shared/mnt" | sudo tee -a /etc/synthetic.conf

# Reboot for the firmlink to take effect
sudo reboot
```

After reboot, create the mount directory:

```bash
sudo mkdir -p /Users/Shared/mnt/synology
```

Now `/mnt/synology` will exist and point to `/Users/Shared/mnt/synology`.

#### 2. Store Credentials in Keychain

```bash
darktable-nas --setup-keychain
```

This prompts for your NAS username and password, storing them securely in the macOS Keychain.

**Note:** If you've previously connected to your NAS via Finder, old Keychain entries may interfere. Delete them first:

```bash
security delete-internet-password -s "YOUR_NAS_IP"  # Run for each IP
darktable-nas --setup-keychain
```

#### 3. Create User Configuration

```bash
mkdir -p ~/.config/darktable-nas
cp /etc/darktable-nas/darktable-nas.conf.example ~/.config/darktable-nas/darktable-nas.conf
```

Edit `~/.config/darktable-nas/darktable-nas.conf` with your NAS details:

```bash
# NAS Configuration (use same mount path as Linux for database compatibility)
NAS_HOST_LOCAL="192.168.1.100"        # Your NAS local IP
NAS_HOST_TAILSCALE="100.x.x.x"        # Your NAS Tailscale IP
NAS_SHARE="/photos"                    # SMB share name
NAS_MOUNT="/mnt/synology"              # Same path as Linux!
NAS_DB_PATH="darktable-db"             # Path to darktable database on NAS
NAS_PHOTOS_PATH="raws"                 # Path to photos on NAS
```

#### 4. Configure darktable Import Path

On first launch, set the import base directory to use the consistent mount path:

1. Open darktable preferences (⌘,)
2. Go to **Import** section
3. Set **base directory pattern** to: `/mnt/synology/raws`

This ensures new imports use the cross-platform compatible path.

#### 5. Install darktable

```bash
# Via Homebrew
brew install darktable

# Or download from https://www.darktable.org/install/
```

#### 6. Tailscale (Optional)

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
# Verify credentials are stored (use your NAS IP)
security find-internet-password -s YOUR_NAS_IP

# Re-run setup if needed
darktable-nas --setup-keychain
```

### "Credentials not found in Keychain" (macOS)

This can happen if macOS created Keychain entries when you previously connected to your NAS via Finder. These old entries may have "No user account" and get found instead of the ones created by `--setup-keychain`.

To fix, delete the old entries and re-run setup:

```bash
# Delete old entries for your NAS IPs (replace with your actual IPs)
security delete-internet-password -s "YOUR_LOCAL_NAS_IP"
security delete-internet-password -s "YOUR_TAILSCALE_NAS_IP"

# Re-run setup
darktable-nas --setup-keychain
```

You may need to run the delete command multiple times if there are multiple old entries for the same IP.

### Photos Show Under Wrong Path (macOS)

If photos appear under `/Users/Shared/mnt/synology` instead of `/mnt/synology`, this is because macOS resolved the synthetic firmlink to its real path. Fix the database directly:

```bash
# Fix both local and NAS databases
sqlite3 ~/.local/share/darktable-nas/library.db \
  "UPDATE film_rolls SET folder = REPLACE(folder, '/Users/Shared/mnt/synology', '/mnt/synology');"

sqlite3 /mnt/synology/darktable-db/library.db \
  "UPDATE film_rolls SET folder = REPLACE(folder, '/Users/Shared/mnt/synology', '/mnt/synology');"
```

Also ensure darktable's import base directory is set correctly (Preferences → Import → base directory pattern: `/mnt/synology/raws`).

## Configuration Reference

### darktable-nas.conf

| Variable | Linux Default | macOS Default | Description |
|----------|---------------|---------------|-------------|
| `NAS_HOST_LOCAL` | `192.168.1.100` | `192.168.1.100` | NAS IP on local network |
| `NAS_HOST_TAILSCALE` | `100.100.100.100` | `100.100.100.100` | NAS IP via Tailscale |
| `NAS_SHARE` | `/home` | `/home` | SMB share path |
| `NAS_MOUNT` | `/mnt/NAS` | `/Volumes/NAS`* | Local mount point |
| `NAS_DB_PATH` | `darktable-db` | `darktable-db` | Database directory on NAS |
| `NAS_PHOTOS_PATH` | `raws` | `raws` | Photos directory on NAS |
| `CIFS_CREDENTIALS` | `/etc/cifs-credentials/NAS` | N/A (Keychain) | SMB credentials file |
| `LOCAL_DB_DIR` | `~/.local/share/darktable-nas` | `~/.local/share/darktable-nas` | Local database cache |
| `LOCAL_CONFIG_DIR` | `~/.config/darktable-nas` | `~/.config/darktable-nas` | Local config directory |

*For cross-platform database compatibility, set `NAS_MOUNT` to the same path on both Linux and macOS (e.g., `/mnt/synology`). See [macOS Setup](#macos-setup) for creating the required synthetic firmlink.

## License

MIT License - see [LICENSE](LICENSE)
