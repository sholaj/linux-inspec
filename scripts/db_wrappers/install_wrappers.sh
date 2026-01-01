#!/bin/bash
# Install database query wrapper scripts
# These scripts hide passwords from InSpec command output
#
# Usage: sudo ./install_wrappers.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing database query wrappers..."

# Install oracle_query
if [ -f "$SCRIPT_DIR/oracle_query" ]; then
    sudo cp "$SCRIPT_DIR/oracle_query" /usr/local/bin/
    sudo chmod +x /usr/local/bin/oracle_query
    echo "  ✓ oracle_query installed"
fi

# Install sybase_query
if [ -f "$SCRIPT_DIR/sybase_query" ]; then
    sudo cp "$SCRIPT_DIR/sybase_query" /usr/local/bin/
    sudo chmod +x /usr/local/bin/sybase_query
    echo "  ✓ sybase_query installed"
fi

echo "Done. Wrapper scripts installed to /usr/local/bin/"
echo ""
echo "Usage:"
echo "  export ORACLE_PWD='password'"
echo "  oracle_query system 10.0.2.5 1521 ORCLCDB \"SELECT * FROM v\\\$version\""
echo ""
echo "  export SYBASE_PWD='password'"
echo "  sybase_query sa SYBASE \"select @@version\""
