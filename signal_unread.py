#!/usr/bin/env python3
"""
Signal Unread Messages Waybar Module
Queries local Signal SQLite DB for unread message count and outputs JSON for Waybar.
"""

import sqlite3
import json
import sys
import os
import time
from pathlib import Path

# Configuration
SIGNAL_DB_PATH = Path.home() / ".config/Signal/sql/db.sqlite"
ICON_DEFAULT = "🗨️"
ICON_UNREAD = "🗨️"
MAX_COUNT_DISPLAY = 99

def get_unread_count():
    """Query Signal DB for unread messages."""
    if not SIGNAL_DB_PATH.exists():
        return 0
    
    try:
        conn = sqlite3.connect(SIGNAL_DB_PATH, timeout=2.0)
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
        
    except (sqlite3.Error, sqlite3.OperationalError) as e:
        # DB locked or other error - return 0 to avoid breaking Waybar
        return 0
    except Exception:
        return 0

def format_output(count):
    """Format Waybar JSON output."""
    click_help = "\n\nLeft-click: Focus/Open Signal\nRight-click: Focus/Open Signal"
    
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

def main():
    """Main function."""
    count = get_unread_count()
    output = format_output(count)
    print(json.dumps(output))

if __name__ == "__main__":
    main()