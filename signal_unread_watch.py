#!/usr/bin/env python3
"""
Signal Unread Messages Waybar Module (Event-driven with inotify)
Watches Signal's SQLite DB for changes and outputs updates immediately.
Much more efficient than polling!
"""

import sqlite3
import json
import sys
import time
from pathlib import Path

# Configuration
SIGNAL_DB_PATH = Path.home() / ".config/Signal/sql/db.sqlite"
SIGNAL_DB_DIR = SIGNAL_DB_PATH.parent
ICON_DEFAULT = "🗨️"
ICON_UNREAD = "🗨️"
MAX_COUNT_DISPLAY = 99

def get_unread_count():
    """Query Signal DB for unread messages."""
    if not SIGNAL_DB_PATH.exists():
        return 0
    
    try:
        conn = sqlite3.connect(f"file:{SIGNAL_DB_PATH}?mode=ro", uri=True, timeout=2.0)
        cursor = conn.cursor()
        
        # Query for unread messages (type 6=incoming text, 7=outgoing text)
        cursor.execute("""
            SELECT COUNT(*) 
            FROM messages 
            WHERE read_status = 0 AND type IN (6, 7)
        """)
        
        count = cursor.fetchone()[0]
        conn.close()
        return min(count, MAX_COUNT_DISPLAY)
        
    except (sqlite3.Error, sqlite3.OperationalError):
        # DB locked or other error - return 0 to avoid breaking Waybar
        return 0
    except Exception:
        return 0

def format_output(count):
    """Format Waybar JSON output."""
    click_help = "\n\nClick to open Signal"
    
    if count == 0:
        return {
            "text": ICON_DEFAULT,
            "class": "signal-read",
            "tooltip": f"No unread messages in Signal{click_help}"
        }
    else:
        text = f"{ICON_UNREAD} {count}" if count > 1 else ICON_UNREAD
        return {
            "text": text,
            "class": "signal-unread",
            "tooltip": f"{count} unread message{'s' if count != 1 else ''} in Signal{click_help}"
        }

def output_status(count):
    """Output status to stdout for Waybar."""
    output = format_output(count)
    print(json.dumps(output), flush=True)

def watch_with_inotify():
    """Watch Signal DB with inotify for instant updates."""
    try:
        import pyinotify
        
        # Output initial state
        output_status(get_unread_count())
        
        last_update = [time.time()]  # Use list for mutable closure
        
        class EventHandler(pyinotify.ProcessEvent):
            def process_default(self, event):
                # Only react to changes to our specific database file or its WAL
                if event.name and (event.name == 'db.sqlite' or 
                                  event.name.startswith('db.sqlite')):
                    # Debounce: only update once per second max
                    now = time.time()
                    if now - last_update[0] >= 1.0:
                        count = get_unread_count()
                        output_status(count)
                        last_update[0] = now
        
        wm = pyinotify.WatchManager()
        handler = EventHandler()
        notifier = pyinotify.Notifier(wm, handler)
        
        # Watch for modifications to the database directory
        mask = pyinotify.IN_MODIFY | pyinotify.IN_CLOSE_WRITE | pyinotify.IN_MOVED_TO
        wm.add_watch(str(SIGNAL_DB_DIR), mask, rec=False)
        
        # Loop forever, processing events
        notifier.loop()
                    
    except ImportError:
        # inotify module not available, fall back to simple mode
        sys.stderr.write("pyinotify module not available, falling back to single-shot mode\n")
        output_status(get_unread_count())
    except Exception as e:
        sys.stderr.write(f"Error in watch mode: {e}\n")
        output_status(get_unread_count())

def main():
    """Main function."""
    # Check if we should run in watch mode
    if len(sys.argv) > 1 and sys.argv[1] == '--watch':
        watch_with_inotify()
    else:
        # Single-shot mode (for polling fallback)
        count = get_unread_count()
        output_status(count)

if __name__ == "__main__":
    main()

