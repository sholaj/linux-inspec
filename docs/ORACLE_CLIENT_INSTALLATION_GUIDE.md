# Oracle Instant Client Installation Guide

Installation guide for Oracle Instant Client on the AAP2 Execution Environment (EE) container and on-prem delegate hosts.

---

## What the Role Needs

The `oracle_inspec` role uses two Oracle binaries:

| Binary | Used By | Purpose |
|--------|---------|---------|
| `sqlplus` | `preflight.yml` | Database authentication check before scanning |
| `libclntsh.so` | InSpec `oracledb_session` | Ruby OCI8 driver for executing SQL controls |

Both are provided by installing **two** Oracle Instant Client RPM packages:

| Package | Contents | Required |
|---------|----------|----------|
| `oracle-instantclient-basic` | Core client libraries (`libclntsh.so`, `libnnz.so`, `adrci`, `genezi`) | Yes (pre-req) |
| `oracle-instantclient-sqlplus` | `sqlplus` binary + `libsqlplus.so`, `libsqlplusic.so`, `glogin.sql` | Yes |
| `oracle-instantclient-tools` | `exp`, `imp`, `expdp`, `impdp`, `sqlldr`, `wrc` | No (not used) |

---

## Package Details (Oracle 23c)

### RPM Package Contents

**basic** (`oracle-instantclient-basic-23.26.1.0.0-1.el8.x86_64.rpm`):
```
/usr/lib/oracle/23/client64/
/usr/lib/oracle/23/client64/bin/
/usr/lib/oracle/23/client64/bin/adrci
/usr/lib/oracle/23/client64/bin/genezi
/usr/lib/oracle/23/client64/lib/
/usr/lib/oracle/23/client64/lib/libclntsh.so*
/usr/lib/oracle/23/client64/lib/libnnz*.so
/usr/lib/oracle/23/client64/lib/libocci.so*
/usr/lib/oracle/23/client64/lib/libociicus.so
/usr/lib/oracle/23/client64/lib/libocijdbc23.so
```

**sqlplus** (`oracle-instantclient-sqlplus-23.26.1.0.0-1.el8.x86_64.rpm`):
```
/usr/lib/oracle/23/client64/bin/sqlplus        ← Required by preflight.yml
/usr/lib/oracle/23/client64/lib/libsqlplus.so
/usr/lib/oracle/23/client64/lib/libsqlplusic.so
/usr/lib/oracle/23/client64/lib/glogin.sql
```

**tools** (`oracle-instantclient-tools-23.26.1.0.0-1.el8.x86_64.rpm`) — NOT NEEDED:
```
/usr/lib/oracle/23/client64/bin/exp
/usr/lib/oracle/23/client64/bin/expdp
/usr/lib/oracle/23/client64/bin/imp
/usr/lib/oracle/23/client64/bin/impdp
/usr/lib/oracle/23/client64/bin/sqlldr
/usr/lib/oracle/23/client64/bin/wrc
/usr/lib/oracle/23/client64/lib/libnfsodm.so
/usr/lib/oracle/23/client64/lib/libopcodm.so
```

### Download URLs

```
https://download.oracle.com/otn_software/linux/instantclient/2326100/oracle-instantclient-basic-23.26.1.0.0-1.el8.x86_64.rpm
https://download.oracle.com/otn_software/linux/instantclient/2326100/oracle-instantclient-sqlplus-23.26.1.0.0-1.el8.x86_64.rpm
```

---

## Installation: AAP2 Execution Environment

The EE is a container image built with `ansible-builder`. Oracle client is baked in at image build time.

### Execution Environment Definition

The relevant section in `execution-environment/execution-environment.yml`:

```yaml
additional_build_steps:
  prepend_base:
    # libnsl.so.1 compatibility — Oracle client requires this on RHEL 9 / UBI 9
    - RUN ln -sf /usr/lib64/libnsl.so.3 /usr/lib64/libnsl.so.1
    # Install Oracle Instant Client 23c (basic + sqlplus only)
    - RUN curl -LO https://download.oracle.com/otn_software/linux/instantclient/2326100/oracle-instantclient-basic-23.26.1.0.0-1.el8.x86_64.rpm
    - RUN curl -LO https://download.oracle.com/otn_software/linux/instantclient/2326100/oracle-instantclient-sqlplus-23.26.1.0.0-1.el8.x86_64.rpm
    - RUN rpm -ivh --nodeps oracle-instantclient-basic-23.26.1.0.0-1.el8.x86_64.rpm oracle-instantclient-sqlplus-23.26.1.0.0-1.el8.x86_64.rpm
    - RUN rm -f oracle-instantclient*.rpm

  append_final:
    # Register Oracle libraries with the dynamic linker
    - RUN echo /usr/lib/oracle/23/client64/lib > /etc/ld.so.conf.d/oracle-instantclient.conf && ldconfig
    # Symlink sqlplus into PATH
    - RUN ln -sf /usr/lib/oracle/23/client64/bin/sqlplus /usr/local/bin/sqlplus
    # Set environment variables
    - ENV PATH=/opt/mssql-tools18/bin:/usr/lib/oracle/23/client64/bin:/usr/local/bin:$PATH
    - ENV LD_LIBRARY_PATH=/usr/lib/oracle/23/client64/lib
    - ENV ORACLE_HOME=/usr/lib/oracle/23/client64
```

### Key Notes for EE Build

1. **`--nodeps` flag** — The RPMs are built for EL8 but the base image is UBI 9. `--nodeps` skips the glibc version check. The binaries are compatible because Oracle Instant Client is statically linked against most dependencies.

2. **`libnsl.so.1` symlink** — Oracle client links against `libnsl.so.1` which doesn't exist on RHEL 9. The symlink `libnsl.so.3 → libnsl.so.1` resolves this.

3. **`ldconfig`** — Registers `/usr/lib/oracle/23/client64/lib` so the dynamic linker can find `libclntsh.so` at runtime (required by both `sqlplus` and InSpec's Ruby OCI8 gem).

4. **Symlink to `/usr/local/bin`** — Makes `sqlplus` available without full path. The role also uses the full path `{{ _effective_oracle_home }}/bin/sqlplus` in preflight checks.

### Build and Verify

```bash
# Build the EE image
cd execution-environment/
ansible-builder build \
  --tag acrinspecwzrr.azurecr.io/db-compliance-ee:1.0.0 \
  --container-runtime podman

# Verify Oracle client inside the container
podman run --rm acrinspecwzrr.azurecr.io/db-compliance-ee:1.0.0 \
  /bin/bash -c '
    echo "=== sqlplus ==="
    /usr/lib/oracle/23/client64/bin/sqlplus -V
    echo ""
    echo "=== sqlplus symlink ==="
    sqlplus -V
    echo ""
    echo "=== ORACLE_HOME ==="
    echo $ORACLE_HOME
    echo ""
    echo "=== Libraries ==="
    ls -la /usr/lib/oracle/23/client64/lib/libclntsh.so*
    echo ""
    echo "=== ldconfig ==="
    ldconfig -p | grep oracle
    echo ""
    echo "=== libnsl symlink ==="
    ls -la /usr/lib64/libnsl.so.1
  '
```

**Expected output:**
```
=== sqlplus ===
SQL*Plus: Release 23.0.0.0.0 - Production
Version 23.26.1.0.0

=== sqlplus symlink ===
SQL*Plus: Release 23.0.0.0.0 - Production
Version 23.26.1.0.0

=== ORACLE_HOME ===
/usr/lib/oracle/23/client64

=== Libraries ===
... libclntsh.so -> libclntsh.so.23.1
... libclntsh.so.23.1

=== ldconfig ===
    libclntsh.so.23.1 ... => /usr/lib/oracle/23/client64/lib/libclntsh.so.23.1
    libsqlplus.so ... => /usr/lib/oracle/23/client64/lib/libsqlplus.so

=== libnsl symlink ===
lrwxrwxrwx. 1 root root ... /usr/lib64/libnsl.so.1 -> libnsl.so.3
```

### Installed File Layout (EE)

```
/usr/lib/oracle/23/client64/          ← ORACLE_HOME
├── bin/
│   ├── adrci                          # Automatic Diagnostic Repository
│   ├── genezi                         # Oracle Net config tool
│   └── sqlplus                        # SQL*Plus ← Used by preflight.yml
└── lib/
    ├── glogin.sql                     # SQL*Plus login script
    ├── libclntsh.so → libclntsh.so.23.1  # Client shared library ← Used by InSpec
    ├── libclntsh.so.23.1              # Actual library
    ├── libnnz*.so                     # Network security libraries
    ├── libocci.so*                    # C++ interface
    ├── libociicus.so                  # Instant Client
    ├── libsqlplus.so                  # SQL*Plus library
    └── libsqlplusic.so               # SQL*Plus IC library
```

---

## Installation: On-Prem Delegate Host

The delegate host is an existing Linux server (RHEL 7/8/9) that acts as a bastion for database connectivity.

### Option A: RPM Install (Recommended)

```bash
#!/bin/bash
# Install Oracle Instant Client 23c on delegate host
# Run as root or with sudo

# Download packages
cd /tmp
curl -LO https://download.oracle.com/otn_software/linux/instantclient/2326100/oracle-instantclient-basic-23.26.1.0.0-1.el8.x86_64.rpm
curl -LO https://download.oracle.com/otn_software/linux/instantclient/2326100/oracle-instantclient-sqlplus-23.26.1.0.0-1.el8.x86_64.rpm

# Install (use --nodeps if on RHEL 9)
rpm -ivh oracle-instantclient-basic-23.26.1.0.0-1.el8.x86_64.rpm \
         oracle-instantclient-sqlplus-23.26.1.0.0-1.el8.x86_64.rpm

# Register libraries
echo /usr/lib/oracle/23/client64/lib > /etc/ld.so.conf.d/oracle-instantclient.conf
ldconfig

# libnsl compatibility (RHEL 9 only)
if [ ! -f /usr/lib64/libnsl.so.1 ]; then
    ln -sf /usr/lib64/libnsl.so.3 /usr/lib64/libnsl.so.1
fi

# Clean up
rm -f /tmp/oracle-instantclient*.rpm

# Verify
/usr/lib/oracle/23/client64/bin/sqlplus -V
```

### Option B: NFS Share (Existing On-Prem Pattern)

Many delegate hosts access Oracle client via a shared NFS mount:

```bash
# Typical NFS path (coordinate with infrastructure team)
ORACLE_HOME="/tools/ver/oracle-client-21.3.0.0-32"

# Verify NFS is mounted and sqlplus exists
ls -la ${ORACLE_HOME}/bin/sqlplus
${ORACLE_HOME}/bin/sqlplus -V
```

### Environment Configuration

```bash
# /etc/profile.d/oracle-client.sh
export ORACLE_HOME="/usr/lib/oracle/23/client64"
export PATH="${ORACLE_HOME}/bin:${PATH}"
export LD_LIBRARY_PATH="${ORACLE_HOME}/lib:${LD_LIBRARY_PATH}"
export TNS_ADMIN="${ORACLE_HOME}/network/admin"
export NLS_LANG="AMERICAN_AMERICA.AL32UTF8"
```

### Verify Installation

```bash
#!/bin/bash
echo "=== Oracle Client Verification ==="

# Check sqlplus binary
echo "1. sqlplus binary:"
ls -la /usr/lib/oracle/23/client64/bin/sqlplus && echo "   OK" || echo "   MISSING"

# Check sqlplus runs
echo "2. sqlplus version:"
/usr/lib/oracle/23/client64/bin/sqlplus -V 2>&1 | head -2

# Check core library
echo "3. libclntsh.so:"
ls -la /usr/lib/oracle/23/client64/lib/libclntsh.so* && echo "   OK" || echo "   MISSING"

# Check dynamic linker
echo "4. ldconfig registration:"
ldconfig -p | grep libclntsh && echo "   OK" || echo "   NOT REGISTERED - run: ldconfig"

# Check libnsl (RHEL 9 only)
echo "5. libnsl.so.1 (RHEL 9):"
ls -la /usr/lib64/libnsl.so.1 2>/dev/null && echo "   OK" || echo "   N/A or MISSING"

# Test connectivity (replace placeholders)
# echo "6. Database connectivity:"
# echo "SELECT 'OK' FROM DUAL;" | \
#   /usr/lib/oracle/23/client64/bin/sqlplus -S \
#   [USER]/[PASSWORD]@//[DB_SERVER]:1521/[SERVICE]
```

---

## Role Path Configuration

The `oracle_inspec` role auto-selects the correct `ORACLE_HOME` based on execution mode:

| Execution Mode | Variable Used | Default Path |
|---|---|---|
| Localhost (EE) | `oracle_home_ee` | `/usr/lib/oracle/23/client64` |
| Delegate (on-prem) | `oracle_home_delegate` | `/tools/ver/oracle-client-21.3.0.0-32` |
| Direct override | `ORACLE_HOME` | (empty — set to force a specific path) |

If you install Oracle 23c on the delegate host via RPM (Option A above), update the delegate default:

```yaml
# group_vars/all.yml or inventory
oracle_home_delegate: "/usr/lib/oracle/23/client64"
```

---

## Upgrading from Oracle 19 to 23

### EE Container

1. Rebuild the EE image — the `execution-environment.yml` already references Oracle 23c
2. Push to container registry
3. Update AAP2 to use the new EE image

### Delegate Host

```bash
# Check current version
/tools/ver/oracle-client-21.3.0.0-32/bin/sqlplus -V
# or
/usr/lib/oracle/19.29/client64/bin/sqlplus -V

# Install 23c alongside existing version (non-destructive)
rpm -ivh oracle-instantclient-basic-23.26.1.0.0-1.el8.x86_64.rpm \
         oracle-instantclient-sqlplus-23.26.1.0.0-1.el8.x86_64.rpm

# Update ldconfig
echo /usr/lib/oracle/23/client64/lib > /etc/ld.so.conf.d/oracle-instantclient.conf
ldconfig

# Verify both versions coexist
/usr/lib/oracle/19.29/client64/bin/sqlplus -V   # Old (still works)
/usr/lib/oracle/23/client64/bin/sqlplus -V       # New

# Update role config to point to 23c
# oracle_home_delegate: "/usr/lib/oracle/23/client64"
```

Oracle Instant Client versions install to separate directories (`/usr/lib/oracle/<version>/`) so multiple versions can coexist without conflict.

---

## Troubleshooting

### sqlplus: error while loading shared libraries: libclntsh.so

```bash
# Library not registered with dynamic linker
echo /usr/lib/oracle/23/client64/lib > /etc/ld.so.conf.d/oracle-instantclient.conf
ldconfig

# Verify
ldconfig -p | grep libclntsh
```

### sqlplus: error while loading shared libraries: libnsl.so.1

```bash
# RHEL 9 / UBI 9 — libnsl.so.1 removed, Oracle expects it
dnf install -y libnsl2
ln -sf /usr/lib64/libnsl.so.3 /usr/lib64/libnsl.so.1
```

### ORA-12162: TNS:net service name is incorrectly specified

```bash
# ORACLE_HOME not set or incorrect
export ORACLE_HOME=/usr/lib/oracle/23/client64
export TNS_ADMIN=${ORACLE_HOME}/network/admin
```

### Preflight fails with "sqlplus not found on execution host"

The role checks `{{ _effective_oracle_home }}/bin/sqlplus`. Verify the path matches:

```bash
# Check which path the role will use
# EE mode (localhost):
ls -la /usr/lib/oracle/23/client64/bin/sqlplus

# Delegate mode:
ssh [DELEGATE_HOST] 'ls -la /tools/ver/oracle-client-21.3.0.0-32/bin/sqlplus'
# or if RPM-installed on delegate:
ssh [DELEGATE_HOST] 'ls -la /usr/lib/oracle/23/client64/bin/sqlplus'
```

---

## Version History

| Version | EE Path | Delegate Path | Notes |
|---------|---------|---------------|-------|
| 19.29 | `/usr/lib/oracle/19.29/client64` | N/A (NFS) | Original EE version |
| 21.3 | N/A | `/tools/ver/oracle-client-21.3.0.0-32` | On-prem NFS share |
| **23.26.1** | **`/usr/lib/oracle/23/client64`** | `/tools/ver/oracle-client-21.3.0.0-32` or RPM | **Current** |

---

*Last Updated: March 2026*
*Packages: oracle-instantclient-basic-23.26.1.0.0, oracle-instantclient-sqlplus-23.26.1.0.0*
