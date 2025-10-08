#!/bin/bash

# Signal Unread Waybar Module Installer (Safe & Idempotent)
# Safe to run multiple times - will not break existing configs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
SIGNALBAR_DIR="$WAYBAR_CONFIG_DIR/signalbar"
WATCH_SCRIPT="signal_unread_watch.py"
POLL_SCRIPT="signal_unread.py"

echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Signal Unread Waybar Module Installer    ║${NC}"
echo -e "${GREEN}║  Safe & Idempotent - Run Anytime          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check dependencies
echo -e "${BLUE}[1/6] Checking dependencies...${NC}"

DEPS_OK=true

if ! command -v python3 &> /dev/null; then
    echo -e "${RED}  ✗ Python 3 is required but not installed${NC}"
    DEPS_OK=false
else
    echo -e "${GREEN}  ✓ Python 3${NC}"
fi

if ! command -v sqlite3 &> /dev/null; then
    echo -e "${RED}  ✗ sqlite3 is required but not installed${NC}"
    DEPS_OK=false
else
    echo -e "${GREEN}  ✓ sqlite3${NC}"
fi

if ! command -v hyprctl &> /dev/null; then
    echo -e "${YELLOW}  ⚠ hyprctl not found - click actions may not work${NC}"
else
    echo -e "${GREEN}  ✓ Hyprland${NC}"
fi

# Check for pyinotify (optional but recommended)
if python3 -c "import pyinotify" 2>/dev/null; then
    echo -e "${GREEN}  ✓ pyinotify (instant updates enabled)${NC}"
    USE_WATCH=true
else
    echo -e "${YELLOW}  ⚠ pyinotify not found - using polling mode${NC}"
    echo -e "${YELLOW}    Install with: sudo pacman -S python-pyinotify${NC}"
    USE_WATCH=false
fi

if [ "$DEPS_OK" = false ]; then
    echo -e "${RED}Missing required dependencies. Please install them and try again.${NC}"
    exit 1
fi

echo ""

# Detect Waybar config file
echo -e "${BLUE}[2/6] Detecting Waybar configuration...${NC}"

CONFIG_FILE=""
if [ -f "$WAYBAR_CONFIG_DIR/config.jsonc" ]; then
    CONFIG_FILE="$WAYBAR_CONFIG_DIR/config.jsonc"
    CONFIG_TYPE="jsonc"
    echo -e "${GREEN}  ✓ Found config.jsonc (JSONC with comments)${NC}"
elif [ -f "$WAYBAR_CONFIG_DIR/config" ]; then
    CONFIG_FILE="$WAYBAR_CONFIG_DIR/config"
    CONFIG_TYPE="json"
    echo -e "${GREEN}  ✓ Found config (JSON)${NC}"
else
    echo -e "${RED}  ✗ No Waybar config found!${NC}"
    echo -e "${RED}    Expected: $WAYBAR_CONFIG_DIR/config.jsonc or config${NC}"
    echo -e "${RED}    Please set up Waybar first, then run this installer.${NC}"
    exit 1
fi

echo ""

# Install signalbar files
echo -e "${BLUE}[3/6] Installing signalbar files...${NC}"

SIGNALBAR_BACKUP=""

# Backup existing signalbar directory if it exists
if [ -d "$SIGNALBAR_DIR" ]; then
    SIGNALBAR_BACKUP="${SIGNALBAR_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}  ⚠ Signalbar directory exists, creating backup...${NC}"
    cp -r "$SIGNALBAR_DIR" "$SIGNALBAR_BACKUP"
    echo -e "${GREEN}  ✓ Backup created: $SIGNALBAR_BACKUP${NC}"
else
    echo -e "${GREEN}  ✓ Creating signalbar directory...${NC}"
    mkdir -p "$SIGNALBAR_DIR"
fi

# Copy files
cp "$POLL_SCRIPT" "$SIGNALBAR_DIR/"
cp "$WATCH_SCRIPT" "$SIGNALBAR_DIR/"
cp "signal.css" "$SIGNALBAR_DIR/"
cp "README.md" "$SIGNALBAR_DIR/"

# Make scripts executable
chmod +x "$SIGNALBAR_DIR/$POLL_SCRIPT"
chmod +x "$SIGNALBAR_DIR/$WATCH_SCRIPT"

echo -e "${GREEN}  ✓ Files installed to $SIGNALBAR_DIR${NC}"
echo ""

# Determine which script to use
if [ "$USE_WATCH" = true ]; then
    EXEC_SCRIPT="$SIGNALBAR_DIR/$WATCH_SCRIPT --watch"
    EXEC_MODE="event-driven (instant updates)"
else
    EXEC_SCRIPT="$SIGNALBAR_DIR/$POLL_SCRIPT"
    EXEC_MODE="polling every 30 seconds"
fi

# Update Waybar config
echo -e "${BLUE}[4/6] Updating Waybar configuration...${NC}"

# Create backup
BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo -e "${GREEN}  ✓ Backup created: $BACKUP_FILE${NC}"

# Check if signal module already exists
if grep -q '"custom/signal"' "$CONFIG_FILE"; then
    echo -e "${YELLOW}  ⚠ Signal module already exists in config${NC}"
    echo -e "${YELLOW}    Updating configuration...${NC}"
    
    # Update existing entry using Python
    python3 << EOF
import json
import re
import sys

# Read file
with open('$CONFIG_FILE', 'r') as f:
    content = f.read()

# Strip comments for parsing (preserve original)
stripped = re.sub(r'//.*?$', '', content, flags=re.MULTILINE)
stripped = re.sub(r'/\*.*?\*/', '', stripped, flags=re.DOTALL)

# Remove trailing commas (JSONC allows them, JSON doesn't)
stripped = re.sub(r',(\s*[}\]])', r'\1', stripped)

try:
    config = json.loads(stripped)
except json.JSONDecodeError as e:
    print(f"Error parsing config: {e}", file=sys.stderr)
    sys.exit(1)

# Update or add custom/signal configuration
config['custom/signal'] = {
    'format': '{}',
    'exec': '$EXEC_SCRIPT',
    'on-click': 'omarchy-launch-or-focus signal \"uwsm app -- signal-desktop\"',
    'tooltip': True,
    'return-type': 'json'
}

# Only add interval if polling mode
if not '$USE_WATCH' == 'true':
    config['custom/signal']['interval'] = 30

# Write back with proper formatting
with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2)
    
print("Config updated successfully")
EOF

    echo -e "${GREEN}  ✓ Configuration updated${NC}"
else
    echo -e "${GREEN}  ✓ Adding signal module to config...${NC}"
    
    # Add new entry using Python
    python3 << EOF
import json
import re
import sys

# Read file
with open('$CONFIG_FILE', 'r') as f:
    content = f.read()

# Strip comments for parsing
stripped = re.sub(r'//.*?$', '', content, flags=re.MULTILINE)
stripped = re.sub(r'/\*.*?\*/', '', stripped, flags=re.DOTALL)

# Remove trailing commas (JSONC allows them, JSON doesn't)
stripped = re.sub(r',(\s*[}\]])', r'\1', stripped)

try:
    config = json.loads(stripped)
except json.JSONDecodeError as e:
    print(f"Error parsing config: {e}", file=sys.stderr)
    sys.exit(1)

# Add custom/signal to modules-right if it exists
if 'modules-right' in config and isinstance(config['modules-right'], list):
    if 'custom/signal' not in config['modules-right']:
        # Insert after first item (usually custom/omarchy or similar)
        if len(config['modules-right']) > 1:
            config['modules-right'].insert(1, 'custom/signal')
        else:
            config['modules-right'].append('custom/signal')
elif 'modules-left' in config and isinstance(config['modules-left'], list):
    if 'custom/signal' not in config['modules-left']:
        config['modules-left'].append('custom/signal')

# Add the custom signal configuration
config['custom/signal'] = {
    'format': '{}',
    'exec': '$EXEC_SCRIPT',
    'on-click': 'omarchy-launch-or-focus signal \"uwsm app -- signal-desktop\"',
    'tooltip': True,
    'return-type': 'json'
}

# Only add interval if polling mode
if not '$USE_WATCH' == 'true':
    config['custom/signal']['interval'] = 30

# Write back with proper formatting
with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2)

print("Signal module added successfully")
EOF

    echo -e "${GREEN}  ✓ Signal module added to config${NC}"
fi

echo ""

# Update CSS
echo -e "${BLUE}[5/6] Updating styles...${NC}"

STYLE_FILE="$WAYBAR_CONFIG_DIR/style.css"
STYLE_BACKUP=""

if [ ! -f "$STYLE_FILE" ]; then
    echo -e "${RED}  ✗ No style.css found!${NC}"
    echo -e "${YELLOW}    Creating minimal style.css...${NC}"
    echo "@import 'signalbar/signal.css';" > "$STYLE_FILE"
    echo -e "${GREEN}  ✓ Created style.css with signalbar import${NC}"
elif grep -q "signalbar/signal.css" "$STYLE_FILE"; then
    echo -e "${GREEN}  ✓ CSS import already exists (no changes needed)${NC}"
else
    # Backup style.css before modifying
    STYLE_BACKUP="${STYLE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$STYLE_FILE" "$STYLE_BACKUP"
    echo -e "${GREEN}  ✓ Backup created: $STYLE_BACKUP${NC}"
    
    echo -e "${GREEN}  ✓ Adding CSS import...${NC}"
    
    # Add import after other imports or at the beginning
    if grep -q "@import" "$STYLE_FILE"; then
        # Find last import line and add after it
        sed -i '/^@import/a \@import '"'"'signalbar/signal.css'"'"';' "$STYLE_FILE" | head -1
    else
        # Add at the beginning
        sed -i '1i\@import '"'"'signalbar/signal.css'"'"';' "$STYLE_FILE"
    fi
    
    echo -e "${GREEN}  ✓ CSS import added${NC}"
fi

echo ""

# Summary
echo -e "${BLUE}[6/6] Installation complete!${NC}"
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Installation Summary             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Mode:${NC}          $EXEC_MODE"
echo -e "${YELLOW}Config:${NC}        $CONFIG_FILE"
echo -e "${YELLOW}Styles:${NC}        $STYLE_FILE"
echo -e "${YELLOW}Module dir:${NC}    $SIGNALBAR_DIR"
echo ""
echo -e "${YELLOW}Backups created:${NC}"
echo -e "  • Config:  $BACKUP_FILE"
if [ -n "$SIGNALBAR_BACKUP" ]; then
    echo -e "  • Module:  $SIGNALBAR_BACKUP"
fi
if [ -n "$STYLE_BACKUP" ]; then
    echo -e "  • Styles:  $STYLE_BACKUP"
fi
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo -e "  1. Restart Waybar to apply changes"
echo -e "  2. Test the module: ${BLUE}$SIGNALBAR_DIR/$POLL_SCRIPT${NC}"
echo ""
if [ "$USE_WATCH" = false ]; then
    echo -e "${YELLOW}Tip:${NC} For instant updates, install pyinotify:"
    echo -e "     ${BLUE}sudo pacman -S python-pyinotify${NC}"
    echo -e "     Then run this installer again."
    echo ""
fi

# Offer to restart Waybar
echo ""
read -p "Would you like to restart Waybar now? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}Skipping Waybar restart.${NC}"
    echo -e "${YELLOW}Remember to restart manually: ${BLUE}pkill waybar && waybar &${NC}"
else
    echo -e "${BLUE}Restarting Waybar...${NC}"
    pkill waybar 2>/dev/null || true
    sleep 0.5
    waybar &>/dev/null &
    sleep 1
    echo -e "${GREEN}✓ Waybar restarted!${NC}"
fi

echo ""
echo -e "${GREEN}Enjoy your Signal notifications! 🗨️${NC}"
