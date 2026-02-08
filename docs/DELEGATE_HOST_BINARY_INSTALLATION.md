# Delegate Host / Ansible EE Binary Installation Guide

This document provides step-by-step instructions for installing the required binaries on a **Delegate Host** or within an **Ansible Execution Environment (EE)** for database compliance scanning.

---

## Host Requirements

### Target Platform
| Requirement | Specification |
|-------------|---------------|
| **Operating System** | Red Hat Enterprise Linux 8.x |
| **Architecture** | x86_64 |
| **Kernel** | 4.18+ (RHEL 8 default) |

### Minimum Specifications
| Resource | Minimum | Recommended | Notes |
|----------|---------|-------------|-------|
| **CPU** | 2 vCPU | 4 vCPU | Parallel scan capability |
| **RAM** | 4 GB | 8 GB | InSpec + multiple DB clients |
| **Disk** | 20 GB | 50 GB | Binaries, logs, scan results |
| **Swap** | 2 GB | 4 GB | For memory spikes |

### Network Requirements

**IMPORTANT:** Port numbers vary by environment and instance. Coordinate with DBA team to confirm ports.

| Database | Default Port | Protocol | Notes |
|----------|--------------|----------|-------|
| MSSQL | 1433 | TCP | TDS direct connection (port varies, e.g., 1733) |
| MSSQL (WinRM) | 5985 | TCP | WinRM HTTP (Windows Auth) |
| MSSQL (WinRM SSL) | 5986 | TCP | WinRM HTTPS (Windows Auth) |
| Oracle | 1521 | TCP | Oracle Net listener |
| Sybase | 5000 | TCP | Sybase ASE (port varies by instance) |
| SSH (Sybase SSH transport) | 22 | TCP | Alternative Sybase access |

**Example: Non-standard MSSQL ports**
```
Server          Database        Port    Version
m02dms3         BIRS_Confidential 1733  2017
m02dms3         DBA_Reports       1733  2017
gdcuwvc8756     CMDB              1733  2017
gdcuwvc8756     CMDBStage         1733  2017
```

Ensure firewall rules are opened for the specific ports used by target databases.

---

## Installation Overview

### Binary Installation Paths

| Component | Installation Path | Binary/Plugin | Source |
|-----------|------------------|---------------|--------|
| Ansible | `/usr/bin` | `ansible` | Internal repo |
| InSpec | `/usr/bin` or `/usr/local/bin` | `inspec` | Internal repo |
| train-winrm | InSpec plugin | `inspec plugin install train-winrm` | InSpec plugin |
| MSSQL Tools 18 | `/opt/mssql-tools18/bin` | `sqlcmd` | `dnf` / `yum` |
| Oracle Client | `/tools/ver/oracle-19.16.0.0-64` | `sqlplus` | NFS share |
| Sybase ASE Client | `/tools/ver/sybase/OCS-16_0/bin` | `isql` | Official SAP sources |

**Note:** All binaries must be sourced from approved internal repositories or NFS shares. External public repositories (e.g., EPEL, Fedora) are **not permitted** in production environments.

---

## Step 1: System Prerequisites

**Note:** All packages must be installed from approved internal repositories only. External repositories (EPEL, Fedora, etc.) are **not permitted** in production.

```bash
#!/bin/bash
# Run as root or with sudo
# Packages sourced from internal RHEL repositories only

# Install base dependencies
dnf install -y \
    unixODBC \
    unixODBC-devel \
    libaio \
    libaio-devel \
    openssl \
    openssl-devel \
    ruby \
    ruby-devel \
    gcc \
    gcc-c++ \
    make \
    redhat-rpm-config \
    wget \
    unzip \
    nc

# Verify Ruby version (3.0+ required for InSpec 5.x)
ruby --version
```

---

## Step 2: Install InSpec

### Version
- **Required:** 5.22.29 or later
- **License:** Chef EULA acceptance required

### Installation

```bash
#!/bin/bash
# Install InSpec binary

# Install via RubyGems
gem install inspec-bin -v 5.22.29 --no-document

# Verify installation
inspec version
# Expected: 5.22.29

# Accept license (required before first scan)
inspec --chef-license=accept-silent

# Verify binary location
which inspec
# Expected: /usr/local/bin/inspec
```

### Alternative: Install from Chef package

```bash
# Download and install Chef InSpec package
curl -L https://omnitruck.chef.io/install.sh | \
    bash -s -- -P inspec -v 5.22.29

# Verify
/opt/inspec/bin/inspec version
```

---

## Step 2b: Install train-winrm Plugin (For Windows/AD Authentication)

The `train-winrm` plugin enables InSpec to connect to Windows SQL Servers via WinRM transport with Active Directory authentication.

### When is train-winrm Required?

| Connection Mode | train-winrm Required | Authentication |
|-----------------|---------------------|----------------|
| Direct (sqlcmd) | No | SQL Server Auth |
| WinRM | **Yes** | Windows/AD Auth |

### Installation

```bash
#!/bin/bash
# Install train-winrm plugin for InSpec

# Install the plugin
inspec plugin install train-winrm

# Verify installation
inspec plugin list | grep train-winrm
# Expected: train-winrm (x.x.x)

# Check available transports
inspec plugin list
```

### Dependencies

The train-winrm plugin requires these Ruby gems (installed automatically):
- `winrm` - WinRM client library
- `winrm-fs` - WinRM file system operations
- `rubyntlm` - NTLM authentication

### Verify WinRM Transport

```bash
# Test WinRM connectivity (replace placeholders)
inspec detect -t winrm://[AD_USER]@[WINDOWS_HOST] --password '[AD_PASSWORD]'

# Example output:
# == Platform Details
# Name:      windows
# Families:  windows
# Release:   10.0.17763
# Arch:      x86_64
```

### Troubleshooting train-winrm

```bash
# Check if plugin is installed
inspec plugin list

# Reinstall if needed
inspec plugin uninstall train-winrm
inspec plugin install train-winrm

# Check for gem conflicts
gem list | grep -E '(winrm|train)'

# Verbose connection test
inspec detect -t winrm://[AD_USER]@[WINDOWS_HOST] --password '[AD_PASSWORD]' -l debug
```

### WinRM Architecture

```
┌─────────────────┐     WinRM (5985/5986)    ┌──────────────────┐
│  Delegate Host  │ ───────────────────────→ │ Windows SQL      │
│  (Linux/RHEL)   │   AD User credentials    │ Server           │
│                 │                          │                  │
│  - InSpec       │                          │  InSpec runs     │
│  - train-winrm  │                          │  commands here   │
└─────────────────┘                          └────────┬─────────┘
                                                      │
                                              mssql_session()
                                              Windows Auth
                                              (Trusted Connection)
                                                      │
                                                      ▼
                                              SQL Server Database
```

### Reference

- [train-winrm GitHub](https://github.com/inspec/train-winrm)
- [InSpec WinRM Transport Docs](https://docs.chef.io/inspec/transport/)

---

## Step 3: Install MSSQL Tools 18

### Add Microsoft Repository

```bash
#!/bin/bash
# Add Microsoft RHEL 8 repository
curl -o /etc/yum.repos.d/mssql-release.repo \
    https://packages.microsoft.com/config/rhel/8/prod.repo

# Import GPG key
rpm --import https://packages.microsoft.com/keys/microsoft.asc
```

### Install sqlcmd

```bash
#!/bin/bash
# Install MSSQL Tools 18
ACCEPT_EULA=Y dnf install -y mssql-tools18 unixODBC-devel

# Verify installation
/opt/mssql-tools18/bin/sqlcmd -?

# Check version
/opt/mssql-tools18/bin/sqlcmd -? | head -5
```

### ODBC Driver (installed as dependency)
- `msodbcsql18` - Microsoft ODBC Driver 18 for SQL Server

---

## Step 4: Install Oracle Instant Client

### Version
- **Required:** 19.16.0.0-64 or higher (19c Long Term Release)

### Source Location
Oracle Client binaries are available on the internal NFS share:
```
/tools/ver/oracle-19.16.0.0-64
```

### Installation (Using NFS Share)

```bash
#!/bin/bash
# Oracle Instant Client installation from NFS share

# NFS share path (verify with infrastructure team)
ORACLE_NFS="/tools/ver/oracle-19.16.0.0-64"
ORACLE_HOME="/tools/ver/oracle-19.16.0.0-64"

# Verify NFS share is mounted
if [ ! -d "${ORACLE_NFS}" ]; then
    echo "ERROR: Oracle NFS share not mounted at ${ORACLE_NFS}"
    echo "Contact infrastructure team to mount the NFS share"
    exit 1
fi

# Verify sqlplus exists
if [ -f "${ORACLE_HOME}/sqlplus" ]; then
    echo "Oracle Client found at ${ORACLE_HOME}"
    ${ORACLE_HOME}/sqlplus -V
else
    echo "ERROR: sqlplus not found in ${ORACLE_HOME}"
    exit 1
fi

# Create TNS admin directory if needed
mkdir -p ${ORACLE_HOME}/network/admin
```

### Required Libraries
Verify these libraries exist on the NFS share:
- `libclntsh.so.19.1`
- `libnnz19.so`
- `libocci.so.19.1`
- `libociicus.so`

```bash
ls -la /tools/ver/oracle-19.16.0.0-64/*.so*
```

---

## Step 5: Install Sybase Client

### Version
- **Required:** OCS-16_0 (SAP ASE Open Client)

### Source Location
Sybase Client binaries are available on the internal NFS share:
```
/tools/ver/sybase/OCS-16_0
```

**Note:** Obtain Sybase client from official SAP sources only. SAP license required.

### Installation (Using NFS Share)

```bash
#!/bin/bash
# SAP ASE Client installation from NFS share

# NFS share path (verify with infrastructure team)
SYBASE_NFS="/tools/ver/sybase"
SYBASE="/tools/ver/sybase"
SYBASE_OCS="OCS-16_0"

# Verify NFS share is mounted
if [ ! -d "${SYBASE}/${SYBASE_OCS}" ]; then
    echo "ERROR: Sybase NFS share not mounted at ${SYBASE}/${SYBASE_OCS}"
    echo "Contact infrastructure team to mount the NFS share"
    exit 1
fi

# Verify isql exists
if [ -f "${SYBASE}/${SYBASE_OCS}/bin/isql" ]; then
    echo "Sybase Client found at ${SYBASE}/${SYBASE_OCS}"
    ${SYBASE}/${SYBASE_OCS}/bin/isql -v
else
    echo "ERROR: isql not found in ${SYBASE}/${SYBASE_OCS}/bin"
    exit 1
fi
```

### Alternative: Local Installation

If NFS is not available, copy binaries from SAP installation media:

```bash
#!/bin/bash
SYBASE=/tools/ver/sybase
SYBASE_OCS=OCS-16_0

# Create directory structure
mkdir -p ${SYBASE}/${SYBASE_OCS}/{bin,lib,locales}

# Copy binaries from SAP installation media (requires SAP license)
# - isql64 (rename to isql)
# - bcp64 (optional)
# - Required shared libraries from lib/

# Set permissions
chmod 755 ${SYBASE}/${SYBASE_OCS}/bin/*
chmod 644 ${SYBASE}/${SYBASE_OCS}/lib/*

# Verify installation
${SYBASE}/${SYBASE_OCS}/bin/isql -v
```

**Note:** FreeTDS is an open-source alternative but is **not approved** for production use.

---

## Step 6: Configure Environment Variables

### Create Profile Script

Create `/etc/profile.d/db-compliance.sh`:

```bash
#!/bin/bash
# /etc/profile.d/db-compliance.sh
# Database compliance scanning environment configuration
# Host: RHEL 8 Delegate Host / Ansible EE

#===============================================
# PATH Configuration
#===============================================
# InSpec
export PATH="/usr/local/bin:${PATH}"

# MSSQL Tools 18
export PATH="/opt/mssql-tools18/bin:${PATH}"

# Oracle Instant Client (NFS share)
export PATH="/tools/ver/oracle-19.16.0.0-64:${PATH}"

# Sybase ASE Client (NFS share)
export PATH="/tools/ver/sybase/OCS-16_0/bin:${PATH}"

#===============================================
# LD_LIBRARY_PATH Configuration
#===============================================
# Oracle libraries (required for sqlplus)
export LD_LIBRARY_PATH="/tools/ver/oracle-19.16.0.0-64:${LD_LIBRARY_PATH}"

# Sybase libraries (required for isql)
export LD_LIBRARY_PATH="/tools/ver/sybase/OCS-16_0/lib:${LD_LIBRARY_PATH}"

#===============================================
# Oracle Environment
#===============================================
export ORACLE_HOME="/tools/ver/oracle-19.16.0.0-64"
export TNS_ADMIN="${ORACLE_HOME}/network/admin"
export NLS_LANG="AMERICAN_AMERICA.AL32UTF8"

#===============================================
# Sybase Environment
#===============================================
export SYBASE="/tools/ver/sybase"
export SYBASE_OCS="OCS-16_0"

#===============================================
# InSpec License
#===============================================
export CHEF_LICENSE="accept-silent"
```

### Apply Configuration

```bash
# Make script executable
chmod +x /etc/profile.d/db-compliance.sh

# Load for current session
source /etc/profile.d/db-compliance.sh

# Verify PATH
echo $PATH | tr ':' '\n' | grep -E '(mssql|oracle|sap|local)'

# Verify LD_LIBRARY_PATH
echo $LD_LIBRARY_PATH | tr ':' '\n'
```

---

## Step 7: Verification

### Verify All Binaries

```bash
#!/bin/bash
# Verification script

echo "=== InSpec ==="
inspec version
which inspec

echo ""
echo "=== train-winrm Plugin ==="
inspec plugin list | grep train-winrm || echo "train-winrm NOT installed (required for WinRM mode)"

echo ""
echo "=== MSSQL (sqlcmd) ==="
sqlcmd -? 2>&1 | head -3
which sqlcmd

echo ""
echo "=== Oracle (sqlplus) ==="
sqlplus -V
which sqlplus

echo ""
echo "=== Sybase (isql or tsql) ==="
if command -v isql &> /dev/null; then
    isql -v 2>&1 | head -3
    which isql
else
    tsql -C
    which tsql
fi

echo ""
echo "=== NFS Shares ==="
echo "Oracle NFS:"
ls -la /tools/ver/oracle-19.16.0.0-64/sqlplus 2>/dev/null || echo "NOT MOUNTED"
echo "Sybase NFS:"
ls -la /tools/ver/sybase/OCS-16_0/bin/isql 2>/dev/null || echo "NOT MOUNTED"

echo ""
echo "=== Environment Variables ==="
echo "PATH includes:"
echo $PATH | tr ':' '\n' | grep -E '(mssql|tools|local)'

echo ""
echo "LD_LIBRARY_PATH includes:"
echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -E '(tools)' || echo "(empty or not set)"

echo ""
echo "ORACLE_HOME: ${ORACLE_HOME}"
echo "SYBASE: ${SYBASE}"
```

### Test Database Connectivity

```bash
# Test MSSQL (replace placeholders)
sqlcmd -S [DB_SERVER],1433 -U [USER] -P '[PASSWORD]' -Q "SELECT @@VERSION" -C

# Test Oracle (replace placeholders)
echo "SELECT * FROM V\$VERSION WHERE ROWNUM = 1;" | \
    sqlplus -s [USER]/[PASSWORD]@//[DB_SERVER]:1521/[SERVICE]

# Test Sybase with isql (replace placeholders)
echo "SELECT @@version\ngo" | isql -S [SERVER] -U [USER] -P [PASSWORD]

# Test Sybase with tsql (replace placeholders)
echo "SELECT @@version\ngo" | tsql -H [DB_SERVER] -p 5000 -U [USER] -P [PASSWORD]
```

---

## Quick Reference

### Complete PATH (Copy/Paste)

```bash
export PATH="/opt/mssql-tools18/bin:/tools/ver/oracle-19.16.0.0-64:/tools/ver/sybase/OCS-16_0/bin:/usr/local/bin:${PATH}"
```

### Complete LD_LIBRARY_PATH (Copy/Paste)

```bash
export LD_LIBRARY_PATH="/tools/ver/oracle-19.16.0.0-64:/tools/ver/sybase/OCS-16_0/lib:${LD_LIBRARY_PATH}"
```

### All Environment Variables (Copy/Paste)

```bash
export PATH="/opt/mssql-tools18/bin:/tools/ver/oracle-19.16.0.0-64:/tools/ver/sybase/OCS-16_0/bin:/usr/local/bin:${PATH}"
export LD_LIBRARY_PATH="/tools/ver/oracle-19.16.0.0-64:/tools/ver/sybase/OCS-16_0/lib:${LD_LIBRARY_PATH}"
export ORACLE_HOME="/tools/ver/oracle-19.16.0.0-64"
export TNS_ADMIN="${ORACLE_HOME}/network/admin"
export NLS_LANG="AMERICAN_AMERICA.AL32UTF8"
export SYBASE="/tools/ver/sybase"
export SYBASE_OCS="OCS-16_0"
export CHEF_LICENSE="accept-silent"
```

---

## Troubleshooting

### "command not found" Errors

```bash
# Check if binary exists
ls -la /opt/mssql-tools18/bin/sqlcmd
ls -la /tools/ver/oracle-19.16.0.0-64/sqlplus
ls -la /tools/ver/sybase/OCS-16_0/bin/isql

# Check if NFS shares are mounted
df -h | grep /tools/ver

# Check PATH
echo $PATH | grep -o '[^:]*' | head -20

# Reload profile
source /etc/profile.d/db-compliance.sh
```

### Library Loading Errors

```bash
# Check library dependencies
ldd /tools/ver/oracle-19.16.0.0-64/sqlplus
ldd /tools/ver/sybase/OCS-16_0/bin/isql

# Check LD_LIBRARY_PATH
echo $LD_LIBRARY_PATH

# Force library cache update
ldconfig
```

### Permission Denied

```bash
# Fix binary permissions (if local install, not NFS)
chmod 755 /opt/mssql-tools18/bin/*

# Note: NFS share permissions managed by infrastructure team
# Contact infrastructure if permission issues on /tools/ver/*
```

### NFS Share Not Mounted

```bash
# Check NFS mounts
mount | grep nfs
df -h | grep tools

# Contact infrastructure team to mount:
# - /tools/ver/oracle-19.16.0.0-64
# - /tools/ver/sybase/OCS-16_0
```

---

## Version Matrix

| Component | Minimum | Tested | Notes |
|-----------|---------|--------|-------|
| RHEL | 8.6 | 8.9 | RHEL 9 also supported |
| InSpec | 5.22.0 | 5.22.29 | Chef license required |
| train-winrm | 0.2.0 | 0.2.13 | Required for WinRM mode |
| Ruby | 2.7 | 3.0+ | For InSpec gem install |
| MSSQL Tools | 17.0 | 18.x | TLS 1.2/1.3 support |
| Oracle Client | 19.0 | 19.16 | 19c LTS release |
| FreeTDS | 1.0 | 1.3+ | TDS 5.0 for Sybase |

---

## Related Documentation

- [Ansible Execution Environment](ANSIBLE_EXECUTION_ENVIRONMENT.md) - Full EE build specifications
- [Delegate Execution Guide](DELEGATE_EXECUTION_CONFLUENCE.md) - Delegate vs. local mode
- [Local Testing Guide](LOCAL_TESTING_GUIDE.md) - Development environment setup

---

*Last Updated: February 2026*
*Platform: RHEL 8.x (x86_64)*
