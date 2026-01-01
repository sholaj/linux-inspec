#!/bin/bash
# Database Client Installation Script for AAP2 Execution Environment
set -ex

echo "Installing database clients for InSpec compliance scanning..."

# ========================================
# MSSQL Tools 18
# ========================================
echo "Installing MSSQL Tools 18..."
curl -fsSL https://packages.microsoft.com/config/rhel/9/prod.repo \
  -o /etc/yum.repos.d/mssql-release.repo
ACCEPT_EULA=Y microdnf install -y mssql-tools18 unixODBC-devel

# Create wrapper with SSL trust for self-signed certs
cat > /usr/local/bin/sqlcmd << 'EOF'
#!/bin/bash
/opt/mssql-tools18/bin/sqlcmd -C "$@"
EOF
chmod +x /usr/local/bin/sqlcmd

echo "MSSQL Tools installed: $(which sqlcmd)"

# ========================================
# Oracle Instant Client 19c
# ========================================
echo "Installing Oracle Instant Client 19c..."
mkdir -p /opt/oracle
cd /tmp

# Download Oracle Instant Client (basic + sqlplus)
curl -LO https://download.oracle.com/otn_software/linux/instantclient/1916000/instantclient-basic-linux.x64-19.16.0.0.0dbru.zip || echo "Oracle basic download failed"
curl -LO https://download.oracle.com/otn_software/linux/instantclient/1916000/instantclient-sqlplus-linux.x64-19.16.0.0.0dbru.zip || echo "Oracle sqlplus download failed"

if [ -f instantclient-basic-linux.x64-19.16.0.0.0dbru.zip ]; then
  unzip -o instantclient-basic-*.zip -d /opt/oracle/
  unzip -o instantclient-sqlplus-*.zip -d /opt/oracle/

  cd /opt/oracle/instantclient_19_16
  ln -sf libclntsh.so.19.1 libclntsh.so 2>/dev/null || true
  ln -sf libocci.so.19.1 libocci.so 2>/dev/null || true

  # Create symbolic link for sqlplus
  ln -sf /opt/oracle/instantclient_19_16/sqlplus /usr/local/bin/sqlplus
  echo "Oracle Instant Client installed: $(which sqlplus)"
else
  echo "Oracle Instant Client installation skipped - download failed"
fi

# ========================================
# PostgreSQL Client
# ========================================
echo "Installing PostgreSQL client..."
microdnf install -y postgresql

echo "PostgreSQL client installed: $(which psql)"

# ========================================
# Sybase/FreeTDS (tsql)
# ========================================
echo "Installing FreeTDS for Sybase..."
microdnf install -y freetds

# Create Sybase directory structure for compatibility
mkdir -p /opt/sap/OCS-16_0/{bin,lib}

# Create SYBASE.sh environment script
cat > /opt/sap/SYBASE.sh << 'SYBASE_ENV'
#!/bin/bash
export SYBASE=/opt/sap
export SYBASE_OCS=OCS-16_0
export PATH=$SYBASE/$SYBASE_OCS/bin:$PATH
export LD_LIBRARY_PATH=$SYBASE/$SYBASE_OCS/lib:$LD_LIBRARY_PATH
SYBASE_ENV
chmod +x /opt/sap/SYBASE.sh

echo "FreeTDS installed: $(which tsql)"

# ========================================
# Cleanup
# ========================================
rm -f /tmp/instantclient-*.zip 2>/dev/null || true

echo ""
echo "=========================================="
echo "Database clients installation complete!"
echo "=========================================="
echo "Installed clients:"
echo "  - sqlcmd (MSSQL): $(which sqlcmd 2>/dev/null || echo 'not found')"
echo "  - sqlplus (Oracle): $(which sqlplus 2>/dev/null || echo 'not found')"
echo "  - psql (PostgreSQL): $(which psql 2>/dev/null || echo 'not found')"
echo "  - tsql (Sybase): $(which tsql 2>/dev/null || echo 'not found')"
echo ""
