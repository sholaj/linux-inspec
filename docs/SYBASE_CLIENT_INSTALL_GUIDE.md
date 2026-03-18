# SAP Sybase Open Client 16.0 — Installation Guide (RHEL 8)

## Prerequisites

| Requirement | Details |
|---|---|
| **OS** | RHEL 8.x (x86_64) |
| **Java** | OpenJDK 1.8+ (`yum install -y java-1.8.0-openjdk`) |
| **Disk Space** | ~500 MB free at install target + ~200 MB temp |
| **Permissions** | Root access required |
| **Installer** | SAP SDK for ASE 16.0 (`setup.bin` — download from SAP Service Marketplace) |

## Installation Steps

### 1. Install Java (if not present)

```bash
java -version  # Check if installed
yum install -y java-1.8.0-openjdk
```

### 2. Extract installer to an exec-safe location

> **Critical:** Do NOT run the installer from `/tmp` — hardened servers mount `/tmp` with `noexec`, causing "JRE libraries are missing or not compatible" errors.

```bash
mkdir -p /opt/sybase_install
cp -R /path/to/installer_files/ /opt/sybase_install/
cd /opt/sybase_install/<installer_dir>/
chmod +x setup.bin
```

### 3. Set IATEMPDIR to bypass /tmp noexec

This is the key step. The installer extracts its bundled JRE to `/tmp` at runtime. Redirect it:

```bash
mkdir -p /opt/sybase_tmp
chmod 755 /opt/sybase_tmp
export IATEMPDIR=/opt/sybase_tmp
```

### 4. Run silent install (Open Client only)

```bash
./setup.bin -i silent \
  -DUSER_INSTALL_DIR=/opt/sybase \
  -DINSTALL_OLDER_VERSION=false \
  -DDDO_UPDATE_INSTALL=FALSE \
  -DCHOSEN_INSTALL_SET=fopen_client \
  -DAGREE_TO_SAP_LICENSE=TRUE \
  -DRUN_SILENT=true
```

### 5. Verify installation

```bash
ls /opt/sybase/OCS_16_0/bin/    # Should contain isql, bcp, etc.
source /opt/sybase/SYBASE.sh
isql -v                          # Verify isql is available
```

### 6. Cleanup

```bash
rm -rf /opt/sybase_install /opt/sybase_tmp
```

## Post-Install: Environment Setup

Add to shell profile or Ansible playbook environment:

```bash
export SYBASE=/opt/sybase
source $SYBASE/SYBASE.sh
export PATH=$SYBASE/OCS_16_0/bin:$PATH
export LD_LIBRARY_PATH=$SYBASE/OCS_16_0/lib:$SYBASE/OCS_16_0/lib3p64:$LD_LIBRARY_PATH
```

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `JRE libraries are missing or not compatible` | `/tmp` mounted with `noexec` | Set `export IATEMPDIR=/opt/sybase_tmp` |
| `Permission denied` on `setup.bin` | File on `noexec` filesystem | Move to `/opt` and `chmod +x` |
| `java: command not found` | No JRE installed | `yum install -y java-1.8.0-openjdk` |

## Install Options Reference

| CHOSEN_INSTALL_SET Value | What It Installs |
|---|---|
| `fopen_client` | Open Client (isql, bcp, libraries) |
| `fdblib` | DB-Library |
| `Typical` | Standard component set |
| `Full` | All components |
