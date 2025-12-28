# Ansible Execution Environment for Database Compliance Scanning

This document provides the Ansible EE team with all requirements to build an Ansible Execution Environment (EE) capable of running InSpec database compliance scans against MSSQL, Oracle, and Sybase databases.

## Overview

The database compliance scanning solution uses InSpec profiles executed via Ansible roles. The EE must include InSpec and all database client binaries to execute SQL queries against target databases.

## Execution Environment Requirements

### Base Image

Use the official Red Hat Ansible EE base image:

```yaml
# execution-environment.yml
version: 3
images:
  base_image:
    name: registry.redhat.io/ansible-automation-platform-24/ee-minimal-rhel9:latest
```

### System Packages

The following system packages are required:

```yaml
# execution-environment.yml (continued)
dependencies:
  system:
    - unixODBC
    - unixODBC-devel
    - libaio
    - libaio-devel
    - openssl
    - openssl-devel
    - freetds              # For Sybase/MSSQL connectivity
    - freetds-devel
    - ruby
    - ruby-devel
    - gcc
    - gcc-c++
    - make
    - redhat-rpm-config
```

### Python Packages

```yaml
# requirements.txt
ansible-core>=2.14
jmespath>=1.0.0
```

### Ruby/Gem Packages

```yaml
# requirements.yml (bindep format) or post-install script
gem:
  - inspec-bin:5.22.29
```

---

## Database Client Binaries

### MSSQL - Microsoft SQL Tools 18

**Installation Path:** `/opt/mssql-tools18/bin`

**Required Binaries:**
- `sqlcmd` - SQL Server command-line query tool
- `bcp` - Bulk copy utility (optional)

**Installation Script:**

```bash
#!/bin/bash
# Install Microsoft SQL Tools 18 for RHEL 9

# Add Microsoft repository
curl -o /etc/yum.repos.d/mssql-release.repo \
  https://packages.microsoft.com/config/rhel/9/prod.repo

# Install SQL Tools
ACCEPT_EULA=Y dnf install -y mssql-tools18 unixODBC-devel

# Verify installation
/opt/mssql-tools18/bin/sqlcmd -?
```

**Alternative Paths (checked in order):**
1. `/opt/mssql-tools18/bin`
2. `/opt/mssql-tools/bin`
3. `/usr/local/bin`

---

### Oracle - Instant Client 19c

**Installation Path:** `/opt/oracle/instantclient_19_16`

**Required Binaries:**
- `sqlplus` - Oracle SQL command-line tool

**Required Libraries:**
- `libclntsh.so.19.1`
- `libnnz19.so`
- `libocci.so.19.1`

**Installation Script:**

```bash
#!/bin/bash
# Install Oracle Instant Client 19.16

ORACLE_VERSION="19.16.0.0.0"
ORACLE_BASE="/opt/oracle"
ORACLE_HOME="${ORACLE_BASE}/instantclient_19_16"

mkdir -p ${ORACLE_BASE}
cd ${ORACLE_BASE}

# Download from Oracle CDN (requires license acceptance)
# Basic, SQL*Plus, and SDK packages required
curl -O https://download.oracle.com/otn_software/linux/instantclient/1916000/instantclient-basic-linux.x64-${ORACLE_VERSION}dbru.zip
curl -O https://download.oracle.com/otn_software/linux/instantclient/1916000/instantclient-sqlplus-linux.x64-${ORACLE_VERSION}dbru.zip

unzip -o instantclient-basic-*.zip
unzip -o instantclient-sqlplus-*.zip

# Create symbolic links
cd ${ORACLE_HOME}
ln -sf libclntsh.so.19.1 libclntsh.so
ln -sf libocci.so.19.1 libocci.so

# Verify installation
${ORACLE_HOME}/sqlplus -V
```

**Environment Variables Required:**

```bash
export ORACLE_HOME=/opt/oracle/instantclient_19_16
export LD_LIBRARY_PATH=${ORACLE_HOME}:${LD_LIBRARY_PATH}
export PATH=${ORACLE_HOME}:${PATH}
export TNS_ADMIN=${ORACLE_HOME}/network/admin
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
```

---

### Sybase - SAP ASE Client (OCS-16_0)

**Installation Path:** `/opt/sap`

**Required Binaries:**
- `isql` - SAP Interactive SQL utility (preferred)
- `tsql` - FreeTDS alternative (fallback)

**Required Libraries:**
- `libsybct64.so`
- `libsybcs64.so`
- `libsybintl64.so`

**Installation Script (SAP ASE Client):**

```bash
#!/bin/bash
# Install SAP ASE Client 16.0

SYBASE=/opt/sap
SYBASE_OCS=OCS-16_0

mkdir -p ${SYBASE}/${SYBASE_OCS}/{bin,lib}

# SAP ASE SDK installation (requires SAP license)
# Copy binaries from SAP installation media or existing installation
# - isql, isql64, bcp, bcp64
# - Required shared libraries

# Create SYBASE.sh environment script
cat > ${SYBASE}/SYBASE.sh << 'EOF'
#!/bin/bash
export SYBASE=/opt/sap
export SYBASE_OCS=OCS-16_0
export PATH=${SYBASE}/${SYBASE_OCS}/bin:${PATH}
export LD_LIBRARY_PATH=${SYBASE}/${SYBASE_OCS}/lib:${LD_LIBRARY_PATH}
EOF

chmod +x ${SYBASE}/SYBASE.sh
```

**FreeTDS Alternative (Open Source):**

```bash
#!/bin/bash
# Install FreeTDS for Sybase connectivity

dnf install -y freetds freetds-devel

# Configure FreeTDS
cat >> /etc/freetds.conf << 'EOF'
[SYBASE_SERVER]
    host = sybase.example.com
    port = 5000
    tds version = 5.0
EOF

# Verify installation
tsql -C
```

**Environment Variables Required:**

```bash
export SYBASE=/opt/sap
export SYBASE_OCS=OCS-16_0
export PATH=${SYBASE}/${SYBASE_OCS}/bin:${PATH}
export LD_LIBRARY_PATH=${SYBASE}/${SYBASE_OCS}/lib:${LD_LIBRARY_PATH}
```

---

## InSpec Installation

**Version Required:** 5.22.29 (or later compatible version)

**Installation Path:** `/usr/local/bin/inspec`

**Installation Script:**

```bash
#!/bin/bash
# Install InSpec via RubyGems

# Ensure Ruby is installed
ruby --version || dnf install -y ruby ruby-devel

# Install InSpec
gem install inspec-bin -v 5.22.29 --no-document

# Verify installation
inspec version
# Expected output: 5.22.29

# Accept InSpec license (required for first run)
inspec --chef-license=accept-silent
```

**Required Ruby Gems (installed as InSpec dependencies):**
- `inspec-core`
- `train` (transport abstraction)
- `train-ssh` (SSH transport)

---

## Complete PATH Configuration

The EE should configure the following PATH for all database client binaries:

```bash
# Combined PATH for all database clients
export PATH=/opt/mssql-tools18/bin:/opt/oracle/instantclient_19_16:/opt/sap/OCS-16_0/bin:/usr/local/bin:$PATH

# Combined LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/opt/oracle/instantclient_19_16:/opt/sap/OCS-16_0/lib:$LD_LIBRARY_PATH

# Oracle-specific
export ORACLE_HOME=/opt/oracle/instantclient_19_16
export TNS_ADMIN=/opt/oracle/instantclient_19_16/network/admin
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8

# Sybase-specific
export SYBASE=/opt/sap
export SYBASE_OCS=OCS-16_0
```

---

## Execution Environment Definition File

Complete `execution-environment.yml`:

```yaml
---
version: 3

images:
  base_image:
    name: registry.redhat.io/ansible-automation-platform-24/ee-minimal-rhel9:latest

dependencies:
  galaxy: requirements.yml
  python: requirements.txt
  system: bindep.txt

additional_build_files:
  - src: scripts/install-db-clients.sh
    dest: scripts

additional_build_steps:
  prepend_base:
    - RUN dnf install -y unixODBC unixODBC-devel libaio openssl freetds ruby ruby-devel gcc make

  append_final:
    - COPY scripts/install-db-clients.sh /tmp/
    - RUN chmod +x /tmp/install-db-clients.sh && /tmp/install-db-clients.sh
    - RUN gem install inspec-bin -v 5.22.29 --no-document
    - ENV PATH="/opt/mssql-tools18/bin:/opt/oracle/instantclient_19_16:/opt/sap/OCS-16_0/bin:/usr/local/bin:${PATH}"
    - ENV LD_LIBRARY_PATH="/opt/oracle/instantclient_19_16:/opt/sap/OCS-16_0/lib"
    - ENV ORACLE_HOME="/opt/oracle/instantclient_19_16"
    - ENV SYBASE="/opt/sap"
    - ENV SYBASE_OCS="OCS-16_0"
    - ENV NLS_LANG="AMERICAN_AMERICA.AL32UTF8"
```

---

## Delegate Host Preparation

When using delegate mode, InSpec executes on a dedicated "runner" or "bastion" host rather than the Ansible controller. This host must be prepared with all database clients and InSpec.

### Delegate Host Requirements

| Requirement | Specification |
|-------------|---------------|
| OS | RHEL 8+ or compatible |
| RAM | Minimum 4 GB |
| Disk | 10 GB free for logs/results |
| Network | Access to all target database ports |
| SSH | Ansible must be able to SSH to this host |

### Preparation Script

```bash
#!/bin/bash
# prepare-delegate-host.sh
# Run this on the delegate/runner host

set -e

echo "=== Installing InSpec ==="
gem install inspec-bin -v 5.22.29 --no-document
inspec --chef-license=accept-silent

echo "=== Installing MSSQL Tools ==="
curl -o /etc/yum.repos.d/mssql-release.repo \
  https://packages.microsoft.com/config/rhel/8/prod.repo
ACCEPT_EULA=Y dnf install -y mssql-tools18 unixODBC-devel

echo "=== Installing FreeTDS (Sybase) ==="
dnf install -y freetds

echo "=== Creating directories ==="
mkdir -p /opt/oracle/instantclient_19_16
mkdir -p /opt/sap/OCS-16_0/{bin,lib}
mkdir -p /tmp/compliance_scans

echo "=== Setting permissions ==="
chmod 755 /tmp/compliance_scans

echo "=== Verifying installations ==="
inspec version
/opt/mssql-tools18/bin/sqlcmd -?
tsql -C

echo "=== Delegate host preparation complete ==="
```

### Delegate Host Environment Profile

Create `/etc/profile.d/inspec-db.sh`:

```bash
#!/bin/bash
# /etc/profile.d/inspec-db.sh
# Database client environment for InSpec compliance scanning

# MSSQL
export PATH="/opt/mssql-tools18/bin:${PATH}"

# Oracle
export ORACLE_HOME="/opt/oracle/instantclient_19_16"
export LD_LIBRARY_PATH="${ORACLE_HOME}:${LD_LIBRARY_PATH}"
export PATH="${ORACLE_HOME}:${PATH}"
export TNS_ADMIN="${ORACLE_HOME}/network/admin"
export NLS_LANG="AMERICAN_AMERICA.AL32UTF8"

# Sybase
export SYBASE="/opt/sap"
export SYBASE_OCS="OCS-16_0"
export PATH="${SYBASE}/${SYBASE_OCS}/bin:${PATH}"
export LD_LIBRARY_PATH="${SYBASE}/${SYBASE_OCS}/lib:${LD_LIBRARY_PATH}"
```

### Network Requirements for Delegate Host

| Database | Port | Protocol | Notes |
|----------|------|----------|-------|
| MSSQL | 1433 | TCP | Default SQL Server port |
| Oracle | 1521 | TCP | Default Oracle listener port |
| Sybase | 5000 | TCP | Default SAP ASE port |
| SSH | 22 | TCP | For SSH-based InSpec transport |

### Using Delegate Mode in Playbooks

```yaml
---
- name: Run Database Compliance Scan (Delegate Mode)
  hosts: database_targets
  gather_facts: true

  vars:
    # Delegate all InSpec execution to the runner host
    inspec_delegate_host: "inspec-runner"

  roles:
    - mssql_inspec   # or oracle_inspec, sybase_inspec
```

### Inventory Configuration for Delegate Mode

```yaml
all:
  hosts:
    # The delegate/runner host
    inspec-runner:
      ansible_host: runner.example.com
      ansible_user: ansible_svc
      ansible_ssh_private_key_file: /path/to/key

  children:
    mssql_databases:
      hosts:
        SQLPROD01:
          mssql_server: sqlprod01.example.com
          mssql_port: 1433
          mssql_version: "2019"
      vars:
        inspec_delegate_host: "inspec-runner"
        mssql_username: nist_scan_user
```

---

## Production Readiness Checklist

### Pre-Deployment Validation

- [ ] InSpec version 5.22.29+ installed and licensed
- [ ] MSSQL Tools 18 installed and `sqlcmd` accessible
- [ ] Oracle Instant Client installed and `sqlplus` accessible
- [ ] Sybase client (isql or tsql) installed and accessible
- [ ] All environment variables set correctly
- [ ] PATH includes all database client binary directories
- [ ] LD_LIBRARY_PATH includes all library directories

### Connectivity Testing

```bash
# Test MSSQL connectivity
sqlcmd -S server,1433 -U user -P 'password' -Q "SELECT @@VERSION" -C

# Test Oracle connectivity
echo "SELECT * FROM V\$VERSION;" | sqlplus -s user/password@//host:1521/service

# Test Sybase connectivity (isql)
echo "SELECT @@version\ngo" | isql -S SERVER -U user -P password

# Test Sybase connectivity (tsql)
echo "SELECT @@version\ngo" | tsql -H host -p 5000 -U user -P password
```

### Security Considerations

- [ ] Credentials stored in Ansible Vault or AAP Credentials
- [ ] SSH keys for delegate hosts secured
- [ ] Database scan users have minimal required privileges
- [ ] Results directories have appropriate permissions
- [ ] Network segmentation allows only required connections
- [ ] Audit logging enabled for compliance scans

### Monitoring and Logging

- [ ] Scan results saved to persistent storage
- [ ] Splunk/SIEM integration configured (optional)
- [ ] Failed scan alerts configured
- [ ] Execution timing within SLA

---

## Troubleshooting

### InSpec License Issues

```bash
# Accept license interactively
inspec --chef-license=accept

# Or set environment variable
export CHEF_LICENSE=accept-silent
```

### Library Not Found Errors

```bash
# Check library paths
ldd /opt/oracle/instantclient_19_16/sqlplus
ldd /opt/sap/OCS-16_0/bin/isql

# Add missing library path
export LD_LIBRARY_PATH=/path/to/libs:$LD_LIBRARY_PATH
```

### Database Connection Timeouts

```bash
# Test network connectivity
nc -zv database.host 1433  # MSSQL
nc -zv database.host 1521  # Oracle
nc -zv database.host 5000  # Sybase

# Check firewall rules
firewall-cmd --list-all
```

### Delegate Host SSH Issues

```bash
# Test SSH connectivity
ssh -i /path/to/key user@delegate-host

# Verify Ansible can reach delegate
ansible inspec-runner -m ping -i inventory.yml
```

---

## Version Compatibility Matrix

| Component | Minimum Version | Recommended | Notes |
|-----------|-----------------|-------------|-------|
| Ansible Core | 2.14 | 2.15+ | Required for EE support |
| InSpec | 5.22.0 | 5.22.29 | License required |
| Ruby | 3.0 | 3.1+ | For InSpec gem |
| MSSQL Tools | 17.0 | 18.x | TLS 1.2 support |
| Oracle Client | 19.0 | 19.16+ | Long-term support |
| FreeTDS | 1.0 | 1.3+ | Sybase TDS 5.0 |
| RHEL | 8.6 | 9.x | EE base image |

---

## References

- [Ansible Execution Environments](https://docs.ansible.com/automation-controller/latest/html/userguide/execution_environments.html)
- [InSpec Documentation](https://docs.chef.io/inspec/)
- [Microsoft SQL Tools](https://docs.microsoft.com/en-us/sql/tools/sqlcmd-utility)
- [Oracle Instant Client](https://www.oracle.com/database/technologies/instant-client.html)
- [FreeTDS User Guide](https://www.freetds.org/userguide/)
- [SAP ASE Documentation](https://help.sap.com/docs/SAP_ASE)

---

*Last Updated: December 2024*
*Author: DevOps Team*
