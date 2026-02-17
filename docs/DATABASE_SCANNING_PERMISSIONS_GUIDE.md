# Database Scanning Permissions Guide

This document specifies the minimum database permissions required to execute InSpec compliance scans for each supported database platform.

---

## Table of Contents

1. [Overview](#overview)
2. [Oracle Database](#oracle-database)
3. [Microsoft SQL Server](#microsoft-sql-server)
4. [SAP Sybase ASE](#sap-sybase-ase)
5. [Security Best Practices](#security-best-practices)
6. [Permission Verification Scripts](#permission-verification-scripts)
7. [References](#references)

---

## Overview

### Purpose

This guide defines the **minimum database privileges** required for compliance scanning service accounts. Following the principle of least privilege, scan accounts should have:

- **Read-only access** to system catalogs and configuration views
- **No ability** to modify data, schema, or configuration
- **No access** to user data tables

### Scope

| Database Platform | Versions Supported |
|-------------------|-------------------|
| Oracle Database | 11g, 12c, 18c, 19c |
| Microsoft SQL Server | 2008, 2012, 2014, 2016, 2017, 2018, 2019, 2022 |
| SAP Sybase ASE | 15.x, 16.x |

### Principle: Least Privilege

Compliance scanning requires **read-only access to system metadata only**:

- Configuration parameters
- User and role definitions
- Permission grants
- Audit settings
- System statistics

**The scan account should NEVER have access to:**

- User application data
- Ability to modify configurations
- Ability to create, alter, or drop objects
- Administrative roles (DBA, sysadmin, sa_role)

---

## Oracle Database

### Supported Versions

Oracle 11g, 12c, 18c, 19c

### Minimum Required Permissions

```sql
-- ============================================================================
-- Oracle Database Scanning Account Setup
-- CIS Oracle Database 19c Benchmark v1.1.0
-- ============================================================================

-- Step 1: Create dedicated scan user
CREATE USER inspec_scan IDENTIFIED BY "<strong_password>"
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA 0 ON users;

-- Step 2: Grant connection privilege
GRANT CREATE SESSION TO inspec_scan;

-- Step 3: Grant read access to data dictionary views
-- SELECT_CATALOG_ROLE provides SELECT on DBA_* views
GRANT SELECT_CATALOG_ROLE TO inspec_scan;

-- Step 4: Grant access to dynamic performance views (V$ views)
-- Required for v$parameter, v$instance, v$controlfile, etc.
GRANT SELECT ANY DICTIONARY TO inspec_scan;

-- Step 5 (Optional): If SELECT ANY DICTIONARY is too broad,
-- grant specific views instead:
-- GRANT SELECT ON v_$parameter TO inspec_scan;
-- GRANT SELECT ON v_$instance TO inspec_scan;
-- GRANT SELECT ON v_$controlfile TO inspec_scan;
-- GRANT SELECT ON v_$log TO inspec_scan;
-- GRANT SELECT ON v_$option TO inspec_scan;
-- GRANT SELECT ON v_$encryption_wallet TO inspec_scan;
```

### Objects Accessed (Read-Only)

The InSpec controls query the following objects:

#### Dynamic Performance Views (V$ Views)

| View | Purpose | Controls Using |
|------|---------|---------------|
| `v$instance` | Database version and status | 1.01 |
| `v$parameter` | Configuration parameters | 1.02-1.18, 4.01, 5.01-5.03, 6.02, 7.03, 8.01 |
| `v$controlfile` | Control file configuration | 1.07 |
| `v$log` | Redo log configuration | 1.08 |
| `v$option` | Database options | 4.02 |
| `v$encryption_wallet` | TDE wallet status | 7.01 |

#### Data Dictionary Views (DBA_ Views)

| View | Purpose | Controls Using |
|------|---------|---------------|
| `dba_users` | User account information | 1.06, 2.01-2.13 |
| `dba_users_with_defpwd` | Users with default passwords | 2.05 |
| `dba_ts_quotas` | Tablespace quotas | 2.15 |
| `dba_tab_privs` | Object privileges | 3.01-3.16, 4.12 |
| `dba_role_privs` | Role grants | 3.17, 3.26 |
| `dba_sys_privs` | System privileges | 3.18-3.25 |
| `dba_stmt_audit_opts` | Statement audit options | 4.03-4.11 |
| `dba_profiles` | Profile settings | 6.01, 6.03-6.10 |
| `dba_libraries` | External libraries | 5.02 |
| `dba_tablespaces` | Tablespace information | 7.02 |
| `dba_db_links` | Database links | 8.02, 8.03 |

#### Other System Objects

| Object | Purpose | Controls Using |
|--------|---------|---------------|
| `proxy_users` | Proxy authentication | 2.14, 3.26 |

### What NOT to Grant

| Privilege | Risk |
|-----------|------|
| `DBA` | Full administrative access |
| `SYSDBA` / `SYSOPER` | Database startup/shutdown |
| `SELECT ANY TABLE` | Access to all user data |
| `CREATE`, `ALTER`, `DROP` privileges | Schema modification |
| `GRANT ANY PRIVILEGE` | Privilege escalation |

### Verification Query

```sql
-- Verify scan account permissions
SELECT
    grantee,
    privilege,
    admin_option
FROM dba_sys_privs
WHERE grantee = 'INSPEC_SCAN'
ORDER BY privilege;

SELECT
    grantee,
    granted_role,
    admin_option
FROM dba_role_privs
WHERE grantee = 'INSPEC_SCAN'
ORDER BY granted_role;

-- Expected output:
-- INSPEC_SCAN | CREATE SESSION | NO
-- INSPEC_SCAN | SELECT ANY DICTIONARY | NO
-- INSPEC_SCAN | SELECT_CATALOG_ROLE | NO
```

---

## Microsoft SQL Server

### Supported Versions

SQL Server 2008, 2012, 2014, 2016, 2017, 2018, 2019, 2022

### Minimum Required Permissions

```sql
-- ============================================================================
-- SQL Server Scanning Account Setup
-- CIS Microsoft SQL Server 2019 Benchmark v1.3.0
-- ============================================================================

-- Step 1: Create dedicated scan login
USE master;
GO
CREATE LOGIN [inspec_scan] WITH PASSWORD = '<strong_password>',
    CHECK_POLICY = ON,
    CHECK_EXPIRATION = ON,
    DEFAULT_DATABASE = master;
GO

-- Step 2: Grant server-level permissions
-- VIEW SERVER STATE: Required for sys.configurations, performance views
GRANT VIEW SERVER STATE TO [inspec_scan];
GO

-- VIEW ANY DATABASE: Required to enumerate databases
GRANT VIEW ANY DATABASE TO [inspec_scan];
GO

-- VIEW ANY DEFINITION: Required to view server objects
GRANT VIEW ANY DEFINITION TO [inspec_scan];
GO

-- Step 3: Grant registry read permission (required for CIS controls)
-- This is needed for error log count, audit level, encryption settings
USE master;
GO
GRANT EXECUTE ON master.sys.xp_instance_regread TO [inspec_scan];
GO

-- Step 4: Create user in master database
USE master;
GO
CREATE USER [inspec_scan] FOR LOGIN [inspec_scan];
GRANT VIEW DATABASE STATE TO [inspec_scan];
GO

-- Step 5: Create user in msdb database (for SQL Agent checks)
USE msdb;
GO
CREATE USER [inspec_scan] FOR LOGIN [inspec_scan];
GRANT SELECT ON dbo.sysproxies TO [inspec_scan];
GRANT SELECT ON dbo.backupset TO [inspec_scan];
GO

-- Step 6: For each user database to be scanned
-- USE [target_database];
-- GO
-- CREATE USER [inspec_scan] FOR LOGIN [inspec_scan];
-- GRANT VIEW DATABASE STATE TO [inspec_scan];
-- GO
```

### Objects Accessed (Read-Only)

The InSpec controls query the following objects:

#### Server-Level Catalogs

| Object | Purpose | Controls Using |
|--------|---------|---------------|
| `sys.configurations` | Server configuration options | 2.01-2.18, 5.02, 5.15 |
| `sys.databases` | Database properties | 1.04, 3.09, 6.01, 7.03 |
| `sys.sql_logins` | SQL authentication logins | 3.02-3.04, 4.03-4.04 |
| `sys.server_principals` | Server-level principals | 3.05-3.12, 3.14 |
| `sys.server_role_members` | Server role membership | 3.10-3.11 |
| `sys.server_permissions` | Server permissions | 3.05, 3.13 |
| `sys.server_audits` | Server audit objects | 5.04, 5.07-5.08 |
| `sys.server_audit_specifications` | Server audit specs | 5.05 |
| `sys.server_file_audits` | File audit destinations | 5.07 |
| `sys.endpoints` | Network endpoints | 8.04 |
| `sys.linked_logins` | Linked server logins | 4.08 |
| `sys.certificates` | Certificates | 7.07 |

#### Database-Level Catalogs

| Object | Purpose | Controls Using |
|--------|---------|---------------|
| `sys.database_permissions` | Database permissions | 4.01, 4.06-4.07 |
| `sys.database_principals` | Database users/roles | 4.01-4.02, 4.05 |
| `sys.database_role_members` | Database role membership | 4.05 |
| `sys.database_audit_specifications` | Database audit specs | 5.06 |
| `sys.assemblies` | CLR assemblies | 6.02 |
| `sys.symmetric_keys` | Symmetric encryption keys | 7.01 |
| `sys.asymmetric_keys` | Asymmetric encryption keys | 7.02 |
| `sys.objects` | Database objects | 4.07 |

#### Functions and Extended Stored Procedures

| Object | Purpose | Controls Using |
|--------|---------|---------------|
| `SERVERPROPERTY()` | Server properties | 1.01-1.03, 3.01 |
| `LOGINPROPERTY()` | Login properties | 3.04 |
| `PWDCOMPARE()` | Password validation | 4.03-4.04 |
| `master.sys.xp_instance_regread` | Registry reads | 5.01, 5.03, 7.05, 8.01-8.03 |

#### msdb Database Objects

| Object | Purpose | Controls Using |
|--------|---------|---------------|
| `msdb.dbo.sysproxies` | SQL Agent proxies | 3.14 |
| `msdb.dbo.backupset` | Backup history | 7.04 |

### What NOT to Grant

| Privilege | Risk |
|-----------|------|
| `sysadmin` role | Full server control |
| `db_owner` role | Full database control |
| `CONTROL SERVER` | Server-level control |
| `ALTER ANY LOGIN` | Modify authentication |
| `ALTER ANY DATABASE` | Modify databases |

### Verification Query

```sql
-- Verify scan account server permissions
SELECT
    pr.name AS login_name,
    pe.permission_name,
    pe.state_desc
FROM sys.server_permissions pe
JOIN sys.server_principals pr ON pe.grantee_principal_id = pr.principal_id
WHERE pr.name = 'inspec_scan'
ORDER BY pe.permission_name;

-- Verify scan account can execute required queries
SELECT
    pe.permission_name,
    pe.state_desc
FROM sys.fn_my_permissions(NULL, 'SERVER') pe
ORDER BY pe.permission_name;

-- Expected permissions:
-- VIEW ANY DATABASE | GRANT
-- VIEW ANY DEFINITION | GRANT
-- VIEW SERVER STATE | GRANT
```

---

## SAP Sybase ASE

### Supported Versions

Sybase ASE 15.x, 16.x

### Minimum Required Permissions

```sql
-- ============================================================================
-- Sybase ASE Scanning Account Setup
-- CIS SAP ASE 16.0 Benchmark v1.1.0
-- ============================================================================

-- Step 1: Create dedicated scan login
USE master
GO
sp_addlogin inspec_scan, '<strong_password>'
GO

-- Step 2: Grant SELECT on master system tables
USE master
GO
GRANT SELECT ON sysconfigures TO inspec_scan
GRANT SELECT ON syslogins TO inspec_scan
GRANT SELECT ON sysloginroles TO inspec_scan
GRANT SELECT ON syssrvroles TO inspec_scan
GRANT SELECT ON sysprotects TO inspec_scan
GRANT SELECT ON sysobjects TO inspec_scan
GRANT SELECT ON sysdatabases TO inspec_scan
GRANT SELECT ON sysservers TO inspec_scan
GRANT SELECT ON sysencryptkeys TO inspec_scan
GO

-- Step 3: Add user to sybsecurity database (for audit checks)
-- Note: sybsecurity database must be installed for audit controls
USE sybsecurity
GO
sp_adduser inspec_scan
GO
GRANT SELECT ON sysauditoptions TO inspec_scan
GO

-- Step 4: Add user to model database (for template checks)
USE model
GO
sp_adduser inspec_scan
GO
GRANT SELECT ON sysusers TO inspec_scan
GO

-- Step 5: Add user to sybsystemprocs database
USE sybsystemprocs
GO
sp_adduser inspec_scan
GO
GRANT SELECT ON sysusers TO inspec_scan
GO

-- Step 6: Add user to tempdb (for temp configuration checks)
USE tempdb
GO
sp_adduser inspec_scan
GO
GRANT SELECT ON sysusers TO inspec_scan
GO
```

### Objects Accessed (Read-Only)

The InSpec controls query the following objects:

#### master Database

| Object | Purpose | Controls Using |
|--------|---------|---------------|
| `sysconfigures` | Configuration parameters | 1.03, 1.05-1.12, 2.01-2.12, 4.11, 5.01-5.07, 6.01-6.08, 7.03, 8.01-8.05 |
| `syslogins` | Login information | 1.04, 2.03-2.05 |
| `sysloginroles` | Login role assignments | 3.01-3.04, 3.07-3.09, 9.03 |
| `syssrvroles` | Server roles | 3.01-3.04, 3.07-3.09 |
| `sysprotects` | Permission grants | 3.05, 7.01-7.02, 7.04-7.05, 10.02 |
| `sysobjects` | Database objects | 7.01-7.02, 7.04-7.08 |
| `sysdatabases` | Database information | 6.03-6.04, 9.02, 10.01 |
| `sysservers` | Remote servers | 9.01 |
| `sysencryptkeys` | Encryption keys | 8.04 |

#### sybsecurity Database

| Object | Purpose | Controls Using |
|--------|---------|---------------|
| `sysauditoptions` | Audit configuration | 4.01-4.10, 4.12-4.13 |

#### model/tempdb/sybsystemprocs Databases

| Object | Purpose | Controls Using |
|--------|---------|---------------|
| `sysusers` | Database users (guest check) | 3.06, 10.03-10.06 |

### Important Notes

1. **sybsecurity Database**: Access to the `sybsecurity` database is often restricted by default. The database must be installed for audit-related controls to function.

2. **No Administrative Roles Required**: The scan account does NOT need `sa_role`, `sso_role`, or `oper_role`. Only SELECT permissions on system tables are required.

3. **Database-Level Access**: The scan account needs to be added as a user in each database where compliance checks will run (master, sybsecurity, model, tempdb, sybsystemprocs).

### What NOT to Grant

| Role/Permission | Risk |
|-----------------|------|
| `sa_role` | Full system administrator |
| `sso_role` | Security administration |
| `oper_role` | Backup/restore operations |
| `replication_role` | Replication administration |
| `CREATE`, `ALTER`, `DROP` permissions | Schema modification |

### Verification Query

```sql
-- Verify scan account permissions in master
USE master
GO
SELECT
    u.name AS user_name,
    o.name AS object_name,
    p.action,
    CASE p.action
        WHEN 193 THEN 'SELECT'
        WHEN 195 THEN 'INSERT'
        WHEN 196 THEN 'DELETE'
        WHEN 197 THEN 'UPDATE'
        ELSE CONVERT(VARCHAR, p.action)
    END AS permission
FROM sysprotects p
JOIN sysobjects o ON p.id = o.id
JOIN sysusers u ON p.uid = u.uid
WHERE u.name = 'inspec_scan'
ORDER BY o.name
GO

-- Verify scan account has no administrative roles
SELECT
    l.name AS login_name,
    r.name AS role_name
FROM sysloginroles lr
JOIN syslogins l ON lr.suid = l.suid
JOIN syssrvroles r ON lr.srid = r.srid
WHERE l.name = 'inspec_scan'
GO

-- Expected: No rows (no administrative roles)
```

---

## Security Best Practices

### Service Account Guidelines

1. **Dedicated Account**: Create a separate service account exclusively for compliance scanning. Do not reuse accounts for other purposes.

2. **Strong Password**: Use a strong, randomly generated password of at least 16 characters with mixed case, numbers, and special characters.

3. **Password Rotation**: Rotate passwords according to organizational policy (typically 90 days).

4. **Network Restrictions**: Where possible, restrict the scan account to connect only from authorized scanning infrastructure:
   - Oracle: Use `CREATE PROFILE` with `PASSWORD_VERIFY_FUNCTION`
   - SQL Server: Use login triggers or endpoint restrictions
   - Sybase: Use `sp_configure 'allow remote access'` restrictions

5. **Audit Trail**: Enable auditing of scan account activities:
   - Oracle: Enable unified auditing for the scan user
   - SQL Server: Include in server audit specification
   - Sybase: Enable login/logout auditing

6. **No Interactive Login**: Where possible, configure the account to only allow connections from automated scanning systems, not interactive sessions.

### What NOT to Grant - Summary

| Database | Avoid These Privileges |
|----------|------------------------|
| **Oracle** | `DBA`, `SYSDBA`, `SYSOPER`, `SELECT ANY TABLE`, `CREATE/ALTER/DROP` privileges, `GRANT ANY PRIVILEGE` |
| **SQL Server** | `sysadmin`, `db_owner`, `CONTROL SERVER`, `ALTER ANY LOGIN`, `ALTER ANY DATABASE` |
| **Sybase ASE** | `sa_role`, `sso_role`, `oper_role`, `replication_role`, `CREATE/ALTER/DROP` permissions |

### Account Naming Convention

Use a consistent naming convention across all databases:

| Environment | Suggested Account Name |
|-------------|----------------------|
| Production | `inspec_scan_prod` |
| UAT | `inspec_scan_uat` |
| Development | `inspec_scan_dev` |

---

## Permission Verification Scripts

### Oracle: Verify Scan Account Permissions

```sql
-- ============================================================================
-- Oracle Permission Verification Script
-- Run as DBA to verify inspec_scan account configuration
-- ============================================================================

SET LINESIZE 200
SET PAGESIZE 100

PROMPT ===== System Privileges =====
SELECT grantee, privilege, admin_option
FROM dba_sys_privs
WHERE grantee = 'INSPEC_SCAN'
ORDER BY privilege;

PROMPT ===== Roles Granted =====
SELECT grantee, granted_role, admin_option, default_role
FROM dba_role_privs
WHERE grantee = 'INSPEC_SCAN'
ORDER BY granted_role;

PROMPT ===== Object Privileges =====
SELECT grantee, owner, table_name, privilege, grantable
FROM dba_tab_privs
WHERE grantee = 'INSPEC_SCAN'
ORDER BY owner, table_name;

PROMPT ===== Verify NO Dangerous Privileges =====
SELECT 'WARNING: Dangerous privilege detected' AS status, privilege
FROM dba_sys_privs
WHERE grantee = 'INSPEC_SCAN'
  AND privilege IN ('DBA', 'SYSDBA', 'SYSOPER', 'SELECT ANY TABLE',
                    'INSERT ANY TABLE', 'UPDATE ANY TABLE', 'DELETE ANY TABLE',
                    'ALTER ANY TABLE', 'DROP ANY TABLE', 'CREATE ANY TABLE',
                    'GRANT ANY PRIVILEGE', 'ALTER SYSTEM');

-- Expected: No rows returned (no dangerous privileges)
```

### SQL Server: Verify Scan Account Permissions

```sql
-- ============================================================================
-- SQL Server Permission Verification Script
-- Run as sysadmin to verify inspec_scan account configuration
-- ============================================================================

PRINT '===== Server-Level Permissions ====='
SELECT
    pr.name AS login_name,
    pe.permission_name,
    pe.state_desc
FROM sys.server_permissions pe
JOIN sys.server_principals pr ON pe.grantee_principal_id = pr.principal_id
WHERE pr.name = 'inspec_scan'
ORDER BY pe.permission_name;

PRINT '===== Server Role Membership ====='
SELECT
    sp.name AS login_name,
    sr.name AS role_name
FROM sys.server_role_members rm
JOIN sys.server_principals sp ON rm.member_principal_id = sp.principal_id
JOIN sys.server_principals sr ON rm.role_principal_id = sr.principal_id
WHERE sp.name = 'inspec_scan';

PRINT '===== Verify NO Sysadmin Membership ====='
SELECT
    'WARNING: Sysadmin membership detected' AS status,
    sp.name AS login_name
FROM sys.server_role_members rm
JOIN sys.server_principals sp ON rm.member_principal_id = sp.principal_id
JOIN sys.server_principals sr ON rm.role_principal_id = sr.principal_id
WHERE sp.name = 'inspec_scan'
  AND sr.name = 'sysadmin';

-- Expected: No rows returned (not a sysadmin)

PRINT '===== Test Permission (run as inspec_scan) ====='
-- Login as inspec_scan and run:
-- SELECT * FROM fn_my_permissions(NULL, 'SERVER');
```

### Sybase ASE: Verify Scan Account Permissions

```sql
-- ============================================================================
-- Sybase ASE Permission Verification Script
-- Run as sa to verify inspec_scan account configuration
-- ============================================================================

PRINT '===== Login Roles ====='
SELECT
    l.name AS login_name,
    r.name AS role_name
FROM master..sysloginroles lr
JOIN master..syslogins l ON lr.suid = l.suid
JOIN master..syssrvroles r ON lr.srid = r.srid
WHERE l.name = 'inspec_scan'
GO

PRINT '===== Verify NO Administrative Roles ====='
SELECT
    'WARNING: Administrative role detected' AS status,
    l.name AS login_name,
    r.name AS role_name
FROM master..sysloginroles lr
JOIN master..syslogins l ON lr.suid = l.suid
JOIN master..syssrvroles r ON lr.srid = r.srid
WHERE l.name = 'inspec_scan'
  AND r.name IN ('sa_role', 'sso_role', 'oper_role', 'replication_role')
GO

-- Expected: No rows returned (no administrative roles)

PRINT '===== Object Permissions in master ====='
USE master
GO
SELECT
    u.name AS user_name,
    o.name AS object_name,
    CASE p.action
        WHEN 193 THEN 'SELECT'
        WHEN 195 THEN 'INSERT'
        WHEN 196 THEN 'DELETE'
        WHEN 197 THEN 'UPDATE'
        ELSE CONVERT(VARCHAR, p.action)
    END AS permission
FROM sysprotects p
JOIN sysobjects o ON p.id = o.id
JOIN sysusers u ON p.uid = u.uid
WHERE u.name = 'inspec_scan'
ORDER BY o.name
GO
```

---

## References

### CIS Benchmarks

| Database | Benchmark | Link |
|----------|-----------|------|
| Oracle | CIS Oracle Database 19c Benchmark v1.1.0 | [cisecurity.org/benchmark/oracle_database](https://www.cisecurity.org/benchmark/oracle_database) |
| SQL Server | CIS Microsoft SQL Server 2019 Benchmark v1.3.0 | [cisecurity.org/benchmark/microsoft_sql_server](https://www.cisecurity.org/benchmark/microsoft_sql_server) |
| Sybase ASE | CIS SAP ASE 16.0 Benchmark v1.1.0 | [cisecurity.org/benchmark/sap_ase](https://www.cisecurity.org/benchmark/sap_ase) |

### NIST Checklists

| Database | NIST NCP ID | Link |
|----------|-------------|------|
| Oracle 19c | 965 | [ncp.nist.gov/checklist/965](https://ncp.nist.gov/checklist/965) |
| SQL Server 2019 | 939 | [ncp.nist.gov/checklist/939](https://ncp.nist.gov/checklist/939) |

### Vendor Documentation

#### Oracle
- [Oracle Database Security Guide](https://docs.oracle.com/en/database/oracle/oracle-database/19/dbseg/)
- [SELECT_CATALOG_ROLE Reference](https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/SELECT_CATALOG_ROLE.html)
- [Oracle DBSAT (Database Security Assessment Tool)](https://www.oracle.com/database/technologies/security/dbsat.html)

#### Microsoft SQL Server
- [SQL Server Security Best Practices](https://docs.microsoft.com/en-us/sql/relational-databases/security/security-center-for-sql-server-database-engine-and-azure-sql-database)
- [Server-Level Roles](https://docs.microsoft.com/en-us/sql/relational-databases/security/authentication-access/server-level-roles)
- [Database-Level Roles](https://docs.microsoft.com/en-us/sql/relational-databases/security/authentication-access/database-level-roles)

#### SAP Sybase ASE
- [Sybase ASE Security Administration Guide](https://help.sap.com/docs/SAP_ASE)
- [System Tables Reference](https://help.sap.com/docs/SAP_ASE/e0d4c0e5a4c94a20a2c4ec0f2f6a0eed/a87eb48484f21015b0b0f5c4a2c4b1a0.html)
- [Tenable Nessus Sybase Compliance Checks](https://www.tenable.com/audits/sybase)

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-02-17 | Database Compliance Team | Initial release |

---

*This document is maintained as part of the Database Compliance Scanning Modernization project.*
