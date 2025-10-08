#!/bin/bash

# Signal Unread Waybar Module Uninstaller
# Safely removes signalbar from your Waybar configuration

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

echo -e "${RED}╔════════════════════════════════════════════╗${NC}"
echo -e "${RED}║  Signal Unread Waybar Module Uninstaller  ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check if signalbar is installed
if [ ! -d "$SIGNALBAR_DIR" ]; then
    echo -e "${YELLOW}Signalbar is not installed.${NC}"
    echo -e "${YELLOW}Directory not found: $SIGNALBAR_DIR${NC}"
    exit 0
fi

echo -e "${YELLOW}This will remove signalbar from your Waybar configuration.${NC}"
echo ""
echo -e "${BLUE}What will be removed:${NC}"
echo -e "  • Signalbar directory: $SIGNALBAR_DIR"
echo -e "  • Signal module from Waybar config"
echo -e "  • CSS import from style.css"
echo ""
echo -e "${YELLOW}Backups will be created before any modifications.${NC}"
echo ""

# Ask for confirmation
read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Uninstallation cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}[1/4] Detecting Waybar configuration...${NC}"

CONFIG_FILE=""
if [ -f "$WAYBAR_CONFIG_DIR/config.jsonc" ]; then
    CONFIG_FILE="$WAYBAR_CONFIG_DIR/config.jsonc"
    echo -e "${GREEN}  ✓ Found config.jsonc${NC}"
elif [ -f "$WAYBAR_CONFIG_DIR/config" ]; then
    CONFIG_FILE="$WAYBAR_CONFIG_DIR/config"
    echo -e "${GREEN}  ✓ Found config${NC}"
else
    echo -e "${YELLOW}  ⚠ No Waybar config found${NC}"
fi

echo ""

# Remove signalbar module from config
if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
    echo -e "${BLUE}[2/4] Removing signal module from Waybar config...${NC}"
    
    # Create backup
    BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo -e "${GREEN}  ✓ Backup created: $BACKUP_FILE${NC}"
    
    # Remove using Python
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
    print(f"  ✗ Error parsing config: {e}", file=sys.stderr)
    sys.exit(1)

# Remove custom/signal from modules arrays
modified = False

if 'modules-right' in config and isinstance(config['modules-right'], list):
    if 'custom/signal' in config['modules-right']:
        config['modules-right'].remove('custom/signal')
        modified = True

if 'modules-left' in config and isinstance(config['modules-left'], list):
    if 'custom/signal' in config['modules-left']:
        config['modules-left'].remove('custom/signal')
        modified = True

if 'modules-center' in config and isinstance(config['modules-center'], list):
    if 'custom/signal' in config['modules-center']:
        config['modules-center'].remove('custom/signal')
        modified = True

# Remove custom/signal configuration
if 'custom/signal' in config:
    del config['custom/signal']
    modified = True

if modified:
    # Write back with proper formatting
    with open('$CONFIG_FILE', 'w') as f:
        json.dump(config, f, indent=2)
    print("  ✓ Signal module removed from config")
else:
    print("  ℹ Signal module not found in config")
EOF

else
    echo -e "${BLUE}[2/4] Skipping config update (no config file found)${NC}"
fi

echo ""

# Remove CSS import
echo -e "${BLUE}[3/4] Removing CSS import...${NC}"

STYLE_FILE="$WAYBAR_CONFIG_DIR/style.css"

if [ -f "$STYLE_FILE" ]; then
    if grep -q "signalbar/signal.css" "$STYLE_FILE"; then
        # Create backup
        STYLE_BACKUP="${STYLE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$STYLE_FILE" "$STYLE_BACKUP"
        echo -e "${GREEN}  ✓ Backup created: $STYLE_BACKUP${NC}"
        
        # Remove the import line and any comment above it
        sed -i '/Signal Unread Module Import/d' "$STYLE_FILE"
        sed -i '\|signalbar/signal.css|d' "$STYLE_FILE"
        
        # Remove empty lines left behind (max 2 consecutive)
        sed -i '/^$/N;/^\n$/D' "$STYLE_FILE"
        
        echo -e "${GREEN}  ✓ CSS import removed${NC}"
    else
        echo -e "${YELLOW}  ℹ CSS import not found${NC}"
    fi
else
    echo -e "${YELLOW}  ⚠ No style.css found${NC}"
fi

echo ""

# Remove signalbar directory
echo -e "${BLUE}[4/4] Removing signalbar directory...${NC}"

# Create backup of the directory
SIGNALBAR_BACKUP="${SIGNALBAR_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
cp -r "$SIGNALBAR_DIR" "$SIGNALBAR_BACKUP"
echo -e "${GREEN}  ✓ Backup created: $SIGNALBAR_BACKUP${NC}"

# Remove the directory
rm -rf "$SIGNALBAR_DIR"
echo -e "${GREEN}  ✓ Signalbar directory removed${NC}"

echo ""

# Summary
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Uninstallation Complete!            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Backups created:${NC}"
if [ -n "$BACKUP_FILE" ]; then
    echo -e "  • Config:  $BACKUP_FILE"
fi
if [ -n "$STYLE_BACKUP" ]; then
    echo -e "  • Styles:  $STYLE_BACKUP"
fi
echo -e "  • Module:  $SIGNALBAR_BACKUP"
echo ""
echo -e "${YELLOW}To restore signalbar:${NC}"
echo -e "  Run the installer again: ${BLUE}./install.sh${NC}"
echo ""
echo -e "${YELLOW}To permanently delete backups:${NC}"
echo -e "  ${BLUE}rm -rf $WAYBAR_CONFIG_DIR/*.backup.*${NC}"
echo ""

# Offer to restart Waybar
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
echo -e "${GREEN}Signalbar has been removed.${NC}"

