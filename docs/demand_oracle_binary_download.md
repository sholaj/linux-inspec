# Demand Intake: Oracle Instant Client 23c Binary Download for Database Compliance Scanning

-----

## Current Challenge

The Database Compliance Scanning framework requires Oracle Instant Client binaries to execute NIST compliance checks against Oracle databases. These binaries must be installed in two locations: the AAP2 Ansible Execution Environment (EE) container image and on-premises delegate hosts. The Oracle Instant Client RPM packages are hosted on Oracle's public download servers, but enterprise policy requires all third-party binaries to be reviewed, approved, and hosted internally before deployment to production infrastructure. Currently, the Oracle client packages have not been through the intake process and cannot be deployed to production delegate hosts or included in approved container images.

## Business Need

Automated NIST compliance scanning against Oracle databases is a key deliverable of the Database Compliance Scanning Modernization initiative. The `oracle_inspec` Ansible role uses two Oracle binaries:

| Binary | Purpose | Used By |
|--------|---------|---------|
| `sqlplus` | Pre-flight authentication validation before scanning | `preflight.yml` task |
| `libclntsh.so` | Ruby OCI8 driver for executing SQL compliance controls | InSpec `oracledb_session` resource |

Without these binaries, Oracle database compliance scanning cannot function. The scanning framework covers approximately **100+ Oracle databases** across multiple affiliates, and this capability is required to achieve enterprise-wide NIST compliance coverage.

## Proposed Solution

Download and internally host two Oracle Instant Client 23c RPM packages for RHEL/UBI (x86_64). These are freely available from Oracle's public download site — no Oracle account, licence agreement, or support contract is required.

### Packages Required

| Package | Filename | Size | Purpose |
|---------|----------|------|---------|
| **Basic** | `oracle-instantclient-basic-23.26.1.0.0-1.el8.x86_64.rpm` | ~83 MB | Core client libraries (`libclntsh.so`, `libnnz.so`) |
| **SQL*Plus** | `oracle-instantclient-sqlplus-23.26.1.0.0-1.el8.x86_64.rpm` | ~4.7 MB | SQL*Plus binary for authentication checks |

### Download Source

```
https://download.oracle.com/otn_software/linux/instantclient/2326100/oracle-instantclient-basic-23.26.1.0.0-1.el8.x86_64.rpm
https://download.oracle.com/otn_software/linux/instantclient/2326100/oracle-instantclient-sqlplus-23.26.1.0.0-1.el8.x86_64.rpm
```

### NOT Required

The following package is **not needed** and should not be downloaded:

| Package | Filename | Reason |
|---------|----------|--------|
| Tools | `oracle-instantclient-tools-23.26.1.0.0-1.el8.x86_64.rpm` | Contains exp/imp/sqlldr — not used for compliance scanning |

## Deployment Targets

The downloaded packages will be deployed to two environments:

### 1. AAP2 Execution Environment (Container Image)

Installed at build time via `ansible-builder`. The RPMs are baked into the container image and removed after installation.

```
Installation path: /usr/lib/oracle/23/client64/
Container base:    registry.access.redhat.com/ubi9/ubi:latest
Install method:    rpm -ivh --nodeps (EL8 RPMs on UBI9 — verified compatible)
```

### 2. On-Premises Delegate Hosts (RHEL 8/9)

Installed on bastion/delegate servers that have network connectivity to Oracle databases.

```
Installation path: /usr/lib/oracle/23/client64/
Target OS:         RHEL 8.x or RHEL 9.x (x86_64)
Install method:    rpm -ivh (standard, or --nodeps on RHEL 9)
```

## Validation Performed

The Oracle 23c binaries have been tested and verified in an Azure test environment (2026-03-13) on a UBI 9 container image matching the production EE base:

| Verification | Result |
|-------------|--------|
| `sqlplus -V` | SQL*Plus: Release 23.26.1.0.0 - Production |
| `ldd sqlplus` | All dependencies resolved (zero missing) |
| `ldconfig -p \| grep libclntsh` | Library correctly registered |
| `libnsl.so.1` compatibility | Symlink resolves on RHEL 9 / UBI 9 |
| Binary file layout | Installs to `/usr/lib/oracle/23/client64/{bin,lib}` |
| Image size impact | ~350 MB (dominated by `libociei.so` at 205 MB) |

## Expected Outcome

Approval and internal hosting of the two Oracle Instant Client 23c RPM packages will:

1. **Unblock Oracle compliance scanning** — Enable the `oracle_inspec` role to run pre-flight checks and execute NIST controls against Oracle databases
2. **Support EE container builds** — Allow the AAP2 platform team to build the approved Execution Environment image (ref: DBSCAN-752)
3. **Enable delegate host provisioning** — Allow infrastructure teams to install Oracle client on delegate hosts during affiliate onboarding
4. **Maintain version consistency** — Ensure all environments use the same Oracle 23c client version

## Security Considerations

- The packages are **read-only client libraries** — they do not include any Oracle server components, listeners, or administrative tools
- The `sqlplus` binary connects to remote databases only — no local database instance is created
- All database credentials are passed via environment variables (never on command line) as documented in `SECURITY_PASSWORD_HANDLING.md`
- The download URLs are Oracle's official public CDN — no authentication required, no licence acceptance needed
- SHA-256 checksums should be verified after download before internal hosting

## Dependencies

| Dependency | Status | Notes |
|-----------|--------|-------|
| DBSCAN-752 | Created | AAP2 EE container build — blocked by this intake |
| DBSCAN-750 | Complete | Dual-path client resolution (EE vs delegate) |
| DBSCAN-711 | In progress | DB client installation documentation |
| Delegate host access | Per-affiliate | Required for on-prem installation |

## Requestor Information

| Field | Value |
|-------|-------|
| **Project** | Database Compliance Scanning Modernization |
| **JIRA Epic** | DBSCAN-001 |
| **Priority** | High — blocks Oracle scanning capability |
| **Estimated effort** | Minimal — download and host two RPM files |
| **Approvals needed** | Security review, Change Advisory Board |

-----

**Scope Summary:**

| Item | Detail |
|------|--------|
| Packages | 2 RPM files (~88 MB total) |
| Source | Oracle public CDN (no account required) |
| Target platforms | UBI 9 container, RHEL 8/9 on-prem |
| Oracle databases covered | 100+ across affiliates |
| Blocking ticket | DBSCAN-752 (EE build) |

-----

*Created: 2026-03-13*
*Related JIRA: DBSCAN-752, DBSCAN-750, DBSCAN-711*
*Reference: docs/ORACLE_CLIENT_INSTALLATION_GUIDE.md*
