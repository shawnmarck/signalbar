#!/bin/bash

# Signal Unread Waybar Module Installer
# This script installs the module to your Waybar configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
SIGNALBAR_DIR="$WAYBAR_CONFIG_DIR/signalbar"
SCRIPT_NAME="signal_unread.py"

echo -e "${GREEN}Signal Unread Waybar Module Installer${NC}"
echo "=================================="

# Check dependencies
echo -e "${YELLOW}Checking dependencies...${NC}"

if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is required but not installed${NC}"
    exit 1
fi

if ! command -v sqlite3 &> /dev/null; then
    echo -e "${RED}Error: sqlite3 is required but not installed${NC}"
    exit 1
fi

if ! command -v hyprctl &> /dev/null; then
    echo -e "${RED}Warning: hyprctl not found - Hyprland integration may not work${NC}"
fi

# Create Waybar config directory if it doesn't exist
if [ ! -d "$WAYBAR_CONFIG_DIR" ]; then
    echo -e "${YELLOW}Creating Waybar config directory...${NC}"
    mkdir -p "$WAYBAR_CONFIG_DIR"
fi

# Create signalbar directory
if [ -d "$SIGNALBAR_DIR" ]; then
    echo -e "${YELLOW}Removing existing signalbar directory...${NC}"
    rm -rf "$SIGNALBAR_DIR"
fi

echo -e "${YELLOW}Installing signalbar module...${NC}"
mkdir -p "$SIGNALBAR_DIR"

# Copy files
cp "$SCRIPT_NAME" "$SIGNALBAR_DIR/"
cp "style.css" "$SIGNALBAR_DIR/"
cp "waybar-config.jsonc" "$SIGNALBAR_DIR/"
cp "README.md" "$SIGNALBAR_DIR/"

# Make script executable
chmod +x "$SIGNALBAR_DIR/$SCRIPT_NAME"

echo -e "${GREEN}Files installed to $SIGNALBAR_DIR${NC}"

# Update Waybar config
CONFIG_FILE="$WAYBAR_CONFIG_DIR/config"
BACKUP_FILE="$WAYBAR_CONFIG_DIR/config.backup.$(date +%Y%m%d_%H%M%S)"

if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}Backing up existing Waybar config...${NC}"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    
    # Check if custom/signal already exists
    if grep -q "custom/signal" "$CONFIG_FILE"; then
        echo -e "${YELLOW}Signal module already exists in config. Skipping config update.${NC}"
    else
        echo -e "${YELLOW}Adding signal module to Waybar config...${NC}"
        
        # Create a temporary config with the signal module added
        python3 -c "
import json
import sys

try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
except:
    print('Could not parse existing config as JSON')
    sys.exit(1)

# Add signal module to modules-right if it exists
if 'modules-right' in config:
    if 'custom/signal' not in config['modules-right']:
        config['modules-right'].insert(0, 'custom/signal')
elif 'modules-left' in config:
    if 'custom/signal' not in config['modules-left']:
        config['modules-left'].append('custom/signal')
else:
    config['modules-right'] = ['custom/signal']

# Add the custom signal configuration
config['custom/signal'] = {
    'format': '{}',
    'exec': '$SIGNALBAR_DIR/$SCRIPT_NAME',
    'interval': 30,
    'on-click': 'hyprctl dispatch focuswindow class:signal-desktop || signal-desktop &',
    'on-click-right': 'signal-desktop --settings &',
    'tooltip': True,
    'return-type': 'json'
}

with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2)
"
        echo -e "${GREEN}Waybar config updated${NC}"
    fi
else
    echo -e "${YELLOW}No existing Waybar config found. Creating new one...${NC}"
    cat > "$CONFIG_FILE" << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "modules-left": ["custom/signal"],
    "modules-center": [],
    "modules-right": ["custom/signal"],
    
    "custom/signal": {
        "format": "{}",
        "exec": "/home/$USER/.config/waybar/signalbar/signal_unread.py",
        "interval": 30,
        "on-click": "hyprctl dispatch focuswindow class:signal-desktop || signal-desktop &",
        "on-click-right": "signal-desktop --settings &",
        "tooltip": true,
        "return-type": "json"
    }
}
EOF
fi

# Update CSS
STYLE_FILE="$WAYBAR_CONFIG_DIR/style.css"
if [ -f "$STYLE_FILE" ]; then
    if ! grep -q "#custom-signal" "$STYLE_FILE"; then
        echo -e "${YELLOW}Adding CSS styles to Waybar...${NC}"
        cat >> "$STYLE_FILE" << 'EOF'

/* Signal Unread Module */
#custom-signal {
    color: #ffffff;
    font-size: 16px;
    padding: 0 8px;
    transition: color 0.3s ease;
}

#custom-signal.signal-read {
    color: #ffffff;
}

#custom-signal.signal-unread {
    color: #00ff00;
    animation: flash-signal 2s infinite;
    text-shadow: 0 0 8px rgba(0, 255, 0, 0.5);
}

@keyframes flash-signal {
    0%, 50% {
        color: #00ff00;
    }
    25%, 75% {
        color: #ffffff;
    }
}
EOF
        echo -e "${GREEN}CSS styles added${NC}"
    else
        echo -e "${YELLOW}CSS styles already exist${NC}"
    fi
else
    echo -e "${YELLOW}Creating new Waybar style.css...${NC}"
    cp "$SIGNALBAR_DIR/style.css" "$STYLE_FILE"
fi

echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Restart Waybar: pkill waybar && waybar &"
echo "2. Make sure Signal Desktop is installed and has been run at least once"
echo "3. Test the module: $SIGNALBAR_DIR/$SCRIPT_NAME"
echo ""
echo -e "${YELLOW}Configuration files:${NC}"
echo "- Module: $SIGNALBAR_DIR/$SCRIPT_NAME"
echo "- Config: $CONFIG_FILE"
echo "- Styles: $STYLE_FILE"
echo "- Backup: $BACKUP_FILE"