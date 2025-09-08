#!/bin/bash

# Setup script for Git hooks
# This script configures Git to use the repository's hooks automatically

HOOKS_DIR="scripts/git-hooks"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Setting up Git hooks..."

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Check if hooks directory exists
if [ ! -d "$HOOKS_DIR" ]; then
    echo -e "${RED}Error: Hooks directory not found at $HOOKS_DIR${NC}"
    exit 1
fi

# Set the hooks path
git config core.hooksPath "$HOOKS_DIR"

# Verify the configuration
CONFIGURED_PATH=$(git config core.hooksPath)
if [ "$CONFIGURED_PATH" = "$HOOKS_DIR" ]; then
    echo -e "${GREEN}Success: Git hooks configured to use $HOOKS_DIR${NC}"
    
    # Make all hooks executable
    chmod +x "$HOOKS_DIR"/* 2>/dev/null
    
    echo ""
    echo "Available hooks:"
    for hook in "$HOOKS_DIR"/*; do
        if [ -f "$hook" ] && [ -x "$hook" ]; then
            basename "$hook"
        fi
    done
    
    echo ""
    echo -e "${GREEN}Setup complete!${NC}"
    echo ""
    echo "Commit message validation is now active."
    echo "See COMMIT_MESSAGE_GUIDE.md for commit message format requirements."
else
    echo -e "${RED}Error: Failed to configure hooks path${NC}"
    exit 1
fi