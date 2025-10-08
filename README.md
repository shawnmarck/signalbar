# Signal Unread Waybar Module

A lightweight Waybar module that displays unread Signal Desktop message count with icon-based indicators and Hyprland integration.

## Features

- 🗨️ Icon-based display with unread count
- 🟢 Green flashing animation for unread messages
- Left-click to focus/launch Signal Desktop
- Local SQLite DB polling (no network calls)
- Hyprland IPC integration
- Minimal CSS styling

## Requirements

- Signal Desktop installed
- Hyprland window manager
- Waybar
- Python 3 with sqlite3 module
- Signal's local SQLite database

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/signalbar.git ~/.config/waybar/signalbar
cd ~/.config/waybar/signalbar
```

2. Make the script executable:
```bash
chmod +x signal_unread.py
```

3. Add to your Waybar config (`~/.config/waybar/config`):
```jsonc
{
  "modules-right": [
    "custom/signal",
    // ... other modules
  ],
  "custom/signal": {
    "format": "{}",
    "exec": "/home/youruser/.config/waybar/signalbar/signal_unread.py",
    "interval": 30,
    "on-click": "hyprctl dispatch focuswindow class:signal-desktop || signal-desktop &",
    "on-click-right": "signal-desktop --settings &",
    "tooltip": true,
    "return-type": "json"
  }
}
```

4. Add CSS import to your Waybar style (`~/.config/waybar/style.css`):
```css
/* Signal Unread Module Import */
@import 'signalbar/signal.css';
```

5. Restart Waybar:
```bash
pkill waybar && waybar &
```

## Configuration

### Database Path
The script automatically looks for Signal's database at `~/.config/Signal/sql/db.sqlite`. If your installation uses a different path, modify `SIGNAL_DB_PATH` in `signal_unread.py`.

### Polling Interval
Default is 30 seconds. Change `"interval": 30` in your Waybar config to adjust.

### Max Display Count
Unread counts above 99 are capped. Modify `MAX_COUNT_DISPLAY` in the script.

## Troubleshooting

### Module not showing
- Check that the script is executable: `chmod +x signal_unread.py`
- Verify the path in your Waybar config is correct
- Test the script manually: `./signal_unread.py`

### No unread count showing
- Ensure Signal Desktop is installed and has been run at least once
- Check that the database exists: `ls ~/.config/Signal/sql/db.sqlite`
- Test database access: `sqlite3 ~/.config/Signal/sql/db.sqlite "SELECT COUNT(*) FROM messages WHERE read_status = 0 AND type IN (6, 7);"`

### Click actions not working
- Verify Hyprland is running: `hyprctl version`
- Check Signal's window class: `hyprctl clients | grep signal`
- Test manually: `hyprctl dispatch focuswindow class:signal-desktop`

### Database locked errors
This is normal when Signal is running. The script handles this gracefully and will retry on the next poll.

## How it Works

1. **Data Fetching**: Queries Signal's local SQLite database for unread messages every 30 seconds
2. **Display**: Shows 🗨️ icon with count, flashes green when unread messages exist
3. **Interaction**: Left-click focuses Signal window or launches it if not running
4. **Privacy**: Only accesses local data, no network calls or external APIs

## License

MIT License - feel free to modify and distribute.