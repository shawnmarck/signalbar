# Signal Unread Waybar Module

A lightweight Waybar module that displays unread Signal Desktop message count with icon-based indicators and Hyprland integration. Designed to integrate seamlessly with Omarchy's All Hallows Eve theme.

## Features

- 🗨️ Icon-based display with unread count
- 🟢 Green flashing animation for unread messages
- **Instant updates** via `inotify` (or polling fallback)
- Omarchy theme integration (orange/purple pulsing animation)
- Left-click to focus/launch Signal Desktop
- Privacy-focused: Local SQLite DB only (no network calls)
- Hyprland IPC integration
- Idempotent installer - safe to run multiple times

## Requirements

- Signal Desktop installed
- Hyprland window manager
- Waybar
- Python 3 with sqlite3 module
- **Optional but recommended**: `python-pyinotify` for instant updates

## Installation

**Simple one-command installation:**

```bash
git clone https://github.com/yourusername/signalbar.git ~/signalbar
cd ~/signalbar
./install.sh
```

The installer will:
-  Detect your Waybar config (config.jsonc or config)
-  Create backups of all files before modifying
-  Install event-driven mode if `pyinotify` is available
-  Integrate with your existing Waybar setup
-  Handle JSONC configs with comments and trailing commas
-  Work with Omarchy or any Waybar setup

### Enable Instant Updates (Recommended)

For instant notifications instead of 30-second polling:

```bash
sudo pacman -S python-pyinotify
./install.sh  # Run installer again to upgrade to watch mode
```

### Restart Waybar

```bash
pkill waybar && waybar &
```

That's it! 🎉

## How It Works

### Event-Driven Mode (with pyinotify)
1. Script watches Signal's SQLite database using `inotify`
2. When Signal receives a message, the database file changes
3. Module updates **instantly** (no polling!)
4. Debounced to max 1 update per second

### Polling Mode (fallback)
1. Queries Signal's local SQLite database every 30 seconds
2. Shows unread count with icon
3. Updates on interval

### Visual Feedback
- **No unread messages**: White icon 🗨️
- **Unread messages**: Pulsing orange → purple animation (Omarchy theme)
- **Click actions**: Left/Right-click focuses Signal or launches it if not running
- **Tooltip**: Shows unread count and click instructions

## Configuration

All configuration is handled automatically by the installer. Files are installed to:
- `~/.config/waybar/signalbar/` - Module files
- `~/.config/waybar/config.jsonc` - Your Waybar config (backed up)
- `~/.config/waybar/style.css` - Your styles (backed up)

### Customization

**Database Path**: Edit `SIGNAL_DB_PATH` in `signal_unread_watch.py` if your Signal database is elsewhere.

**Colors**: Edit `~/.config/waybar/signalbar/signal.css` to customize colors:
```css
#custom-signal.signal-unread {
    color: #cc7833;  /* Change to your preferred color */
}
```

**Update Interval** (polling mode only): Change `"interval": 30` in your Waybar config.

## Troubleshooting

### Installation Issues

**"No Waybar config found"**
- Set up Waybar first, then run the installer
- The installer looks for `~/.config/waybar/config.jsonc` or `config`

**"Python package not found"**
- Ensure Python 3 is installed: `sudo pacman -S python`
- For instant updates: `sudo pacman -S python-pyinotify`

### Module Not Working

**Module not showing**
- Check waybar logs: `pkill waybar; waybar` (foreground)
- Test the script manually: `~/.config/waybar/signalbar/signal_unread_watch.py`
- Verify backups weren't needed: Check `~/.config/waybar/*.backup.*`

**No unread count showing**
- Ensure Signal Desktop is installed and has been run at least once
- Check database exists: `ls ~/.config/Signal/sql/db.sqlite`
- Test database: `sqlite3 ~/.config/Signal/sql/db.sqlite "SELECT COUNT(*) FROM messages WHERE read_status = 0;"`

**Click actions not working**
- Verify Hyprland is running: `hyprctl version`
- Check Signal's window class: `hyprctl clients | grep -i signal`
- Test manually: `hyprctl dispatch focuswindow class:signal-desktop`

**Database locked errors**
- This is normal when Signal is running
- The script handles this gracefully
- In watch mode, it will retry on the next change

### Reverting Installation

All modified files are backed up with timestamps:
```bash
~/.config/waybar/config.jsonc.backup.20251008_033228
~/.config/waybar/signalbar.backup.20251008_033228/
~/.config/waybar/style.css.backup.20251008_033228
```

To revert, simply restore the backup:
```bash
cp ~/.config/waybar/config.jsonc.backup.TIMESTAMP ~/.config/waybar/config.jsonc
pkill waybar && waybar &
```

## Advanced: Manual Installation

<details>
<summary>Click to expand manual installation steps</summary>

If you prefer not to use the installer:

1. **Copy files:**
```bash
mkdir -p ~/.config/waybar/signalbar
cp signal_unread_watch.py signal.css ~/.config/waybar/signalbar/
chmod +x ~/.config/waybar/signalbar/signal_unread_watch.py
```

2. **Add to your Waybar config:**
```jsonc
"custom/signal": {
  "format": "{}",
  "exec": "~/.config/waybar/signalbar/signal_unread_watch.py --watch",
  "on-click": "hyprctl dispatch focuswindow class:signal-desktop || signal-desktop &",
  "on-click-right": "signal-desktop --settings &",
  "tooltip": true,
  "return-type": "json"
}
```

Add `"custom/signal"` to your `modules-right` or `modules-left` array.

3. **Add CSS import:**
```css
@import 'signalbar/signal.css';
```

4. **Restart Waybar:**
```bash
pkill waybar && waybar &
```

</details>

## Uninstallation

**Simple one-command uninstallation:**

```bash
./uninstall.sh
```

The uninstaller will:
- Create backups before removing anything
- Remove signalbar directory
- Remove signal module from your Waybar config
- Remove CSS import from style.css
- Show you all backup locations

Then restart Waybar:
```bash
pkill waybar && waybar &
```

**Manual uninstallation:**
```bash
# Remove the module directory
rm -rf ~/.config/waybar/signalbar

# Edit your config to remove "custom/signal" from modules array
# Edit style.css to remove the signalbar import line
# Restart Waybar
```

## Contributing

Contributions welcome! This module is designed for:
- Omarchy Linux users
- Signal Desktop users on Hyprland
- Anyone wanting instant notification counts in Waybar

## License

MIT License - feel free to modify and distribute.

---

**Note**: This module only accesses your local Signal database. No network calls, no external APIs, no data leaves your machine.
