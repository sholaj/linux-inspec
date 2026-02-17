# Database Scanning Permissions Guide

This document specifies the minimum database permissions required to execute InSpec compliance scans for each supported database platform.

---

## Table of Contents

1. [Overview](#overview)
2. [Oracle Database](#oracle-database)
3. [Microsoft SQL Server](#microsoft-sql-server)
4. [SAP Sybase ASE](#sap-sybase-ase)
5. [PostgreSQL](#postgresql)
6. [Security Best Practices](#security-best-practices)
7. [Permission Verification Scripts](#permission-verification-scripts)
8. [References](#references)

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
| PostgreSQL | 14, 15, 16, 17 |

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

## PostgreSQL

### Supported Versions

PostgreSQL 14, 15, 16, 17

### Minimum Required Permissions

```sql
-- ============================================================================
-- PostgreSQL Scanning Account Setup
-- CIS PostgreSQL 15 Benchmark v1.0.0
-- ============================================================================

-- Step 1: Create dedicated scan role
CREATE ROLE inspec_scan WITH
    LOGIN
    PASSWORD '<strong_password>'
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOREPLICATION;

-- Step 2: Grant connection to target database(s)
GRANT CONNECT ON DATABASE postgres TO inspec_scan;
-- Repeat for each database to scan:
-- GRANT CONNECT ON DATABASE <database_name> TO inspec_scan;

-- Step 3 (Recommended): Grant pg_read_all_settings for comprehensive access
-- This allows reading all configuration settings
GRANT pg_read_all_settings TO inspec_scan;

-- Step 4 (Optional): Grant pg_monitor for statistics views
-- This provides read access to various statistics and monitoring views
GRANT pg_monitor TO inspec_scan;

-- Step 5 (Alternative): If predefined roles are too broad,
-- PostgreSQL system catalogs are publicly readable by default,
-- so a basic login role can execute most compliance checks.
```

### Objects Accessed (Read-Only)

The InSpec controls query the following objects:

#### System Catalogs

| Catalog | Purpose | Controls Using |
|---------|---------|---------------|
| `pg_database` | Database information | 1.3 |
| `pg_extension` | Installed extensions | 1.5, 3.2, 4.6, 8.5 |
| `pg_settings` | Configuration parameters | 2.1-2.2, 3.1.x, 5.8-5.9, 6.7-6.8 |
| `pg_roles` | Role definitions | 4.1-4.2, 5.10, 7.1 |
| `pg_namespace` | Schema information | 4.3 |
| `pg_proc` | Function definitions | 4.5 |
| `pg_class` | Relation/table info | 4.7 |
| `pg_stat_archiver` | Archive statistics | 8.2 |
| `pg_available_extensions` | Available extensions | 8.5 |

#### SHOW Commands / current_setting()

| Setting | Purpose | Controls Using |
|---------|---------|---------------|
| `data_directory` | Data location | 2.1-2.2 |
| `log_destination` | Log output | 3.1.2 |
| `logging_collector` | Log collection | 3.1.3 |
| `log_directory` | Log location | 3.1.4 |
| `log_filename` | Log naming | 3.1.5 |
| `log_file_mode` | Log permissions | 3.1.6 |
| `log_connections` | Connection logging | 3.1.10 |
| `log_disconnections` | Disconnection logging | 3.1.11 |
| `log_statement` | Statement logging | 3.1.14 |
| `password_encryption` | Auth method | 5.1-5.2 |
| `ssl` | SSL status | 5.3, 7.4 |
| `ssl_cert_file` | Certificate file | 5.4 |
| `ssl_key_file` | Key file | 5.5 |
| `ssl_ciphers` | Cipher suites | 5.6 |
| `ssl_min_protocol_version` | TLS version | 5.7 |
| `listen_addresses` | Network interfaces | 6.1 |
| `fsync` | Data sync | 6.3 |
| `full_page_writes` | Page writes | 6.4 |
| `shared_preload_libraries` | Loaded libraries | 4.8, 6.5 |
| `archive_mode` | WAL archiving | 7.2 |
| `archive_command` | Archive command | 7.3 |
| `search_path` | Schema search path | 8.6 |

### Important Notes

1. **System Catalogs Are Public**: PostgreSQL system catalogs (`pg_catalog.*`) are **publicly readable by default**. A regular login user can execute most compliance checks without additional grants.

2. **Predefined Roles**: PostgreSQL 14+ provides predefined roles:
   - `pg_read_all_settings` - Read all configuration parameters
   - `pg_read_all_stats` - Read all statistics views
   - `pg_monitor` - Combination of monitoring-related roles

3. **No Superuser Required**: A regular user with CONNECT privilege can run all compliance controls.

4. **pgAudit Extension**: For comprehensive audit logging, the `pgaudit` extension is recommended but not required for scanning.

### What NOT to Grant

| Privilege | Risk |
|-----------|------|
| `SUPERUSER` | Full database control |
| `CREATEROLE` | Create/modify roles |
| `CREATEDB` | Create databases |
| `REPLICATION` | Streaming replication |
| `BYPASSRLS` | Bypass row-level security |

### Verification Query

```sql
-- Verify scan account privileges
SELECT
    rolname,
    rolsuper,
    rolcreaterole,
    rolcreatedb,
    rolcanlogin,
    rolreplication
FROM pg_roles
WHERE rolname = 'inspec_scan';

-- Verify granted roles
SELECT
    r.rolname AS role,
    m.rolname AS member
FROM pg_auth_members am
JOIN pg_roles r ON am.roleid = r.oid
JOIN pg_roles m ON am.member = m.oid
WHERE m.rolname = 'inspec_scan';

-- Test configuration access
SELECT current_setting('ssl');
SELECT current_setting('log_connections');

-- Expected: inspec_scan should have:
-- rolsuper = false
-- rolcreaterole = false
-- rolcreatedb = false
-- rolcanlogin = true
-- rolreplication = false
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
   - PostgreSQL: Use `pg_hba.conf` host restrictions

5. **Audit Trail**: Enable auditing of scan account activities:
   - Oracle: Enable unified auditing for the scan user
   - SQL Server: Include in server audit specification
   - Sybase: Enable login/logout auditing
   - PostgreSQL: Enable `log_connections` and `log_disconnections`

6. **No Interactive Login**: Where possible, configure the account to only allow connections from automated scanning systems, not interactive sessions.

### What NOT to Grant - Summary

| Database | Avoid These Privileges |
|----------|------------------------|
| **Oracle** | `DBA`, `SYSDBA`, `SYSOPER`, `SELECT ANY TABLE`, `CREATE/ALTER/DROP` privileges, `GRANT ANY PRIVILEGE` |
| **SQL Server** | `sysadmin`, `db_owner`, `CONTROL SERVER`, `ALTER ANY LOGIN`, `ALTER ANY DATABASE` |
| **Sybase ASE** | `sa_role`, `sso_role`, `oper_role`, `replication_role`, `CREATE/ALTER/DROP` permissions |
| **PostgreSQL** | `SUPERUSER`, `CREATEROLE`, `CREATEDB`, `REPLICATION`, `BYPASSRLS` |

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

### PostgreSQL: Verify Scan Account Permissions

```sql
-- ============================================================================
-- PostgreSQL Permission Verification Script
-- Run as postgres superuser to verify inspec_scan account configuration
-- ============================================================================

-- Role attributes
\echo '===== Role Attributes ====='
SELECT
    rolname,
    rolsuper,
    rolcreaterole,
    rolcreatedb,
    rolcanlogin,
    rolreplication,
    rolbypassrls
FROM pg_roles
WHERE rolname = 'inspec_scan';

-- Granted roles
\echo '===== Granted Roles ====='
SELECT
    r.rolname AS role,
    m.rolname AS member,
    am.admin_option
FROM pg_auth_members am
JOIN pg_roles r ON am.roleid = r.oid
JOIN pg_roles m ON am.member = m.oid
WHERE m.rolname = 'inspec_scan';

-- Verify NO superuser
\echo '===== Verify NO Superuser ====='
SELECT
    'WARNING: Superuser privilege detected' AS status,
    rolname
FROM pg_roles
WHERE rolname = 'inspec_scan'
  AND rolsuper = true;

-- Expected: No rows returned (not a superuser)

-- Database connection privileges
\echo '===== Database Connect Privileges ====='
SELECT
    datname,
    has_database_privilege('inspec_scan', datname, 'CONNECT') AS can_connect
FROM pg_database
WHERE datallowconn = true;

-- Test configuration access (run as inspec_scan)
\echo '===== Test Configuration Access ====='
SELECT current_setting('ssl') AS ssl_setting;
SELECT current_setting('log_connections') AS log_connections;
```

---

## References

### CIS Benchmarks

| Database | Benchmark | Link |
|----------|-----------|------|
| Oracle | CIS Oracle Database 19c Benchmark v1.1.0 | [cisecurity.org/benchmark/oracle_database](https://www.cisecurity.org/benchmark/oracle_database) |
| SQL Server | CIS Microsoft SQL Server 2019 Benchmark v1.3.0 | [cisecurity.org/benchmark/microsoft_sql_server](https://www.cisecurity.org/benchmark/microsoft_sql_server) |
| Sybase ASE | CIS SAP ASE 16.0 Benchmark v1.1.0 | [cisecurity.org/benchmark/sap_ase](https://www.cisecurity.org/benchmark/sap_ase) |
| PostgreSQL | CIS PostgreSQL 15 Benchmark v1.0.0 | [cisecurity.org/benchmark/postgresql](https://www.cisecurity.org/benchmark/postgresql) |

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

#### PostgreSQL
- [PostgreSQL Client Authentication](https://www.postgresql.org/docs/current/client-authentication.html)
- [System Catalogs](https://www.postgresql.org/docs/current/catalogs.html)
- [Predefined Roles](https://www.postgresql.org/docs/current/predefined-roles.html)
- [pgAudit Extension](https://github.com/pgaudit/pgaudit)
- [PGDSAT - PostgreSQL Database Security Assessment Tool](https://github.com/HexaCorp/PGDSAT)

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-02-17 | Database Compliance Team | Initial release |

---

*This document is maintained as part of the Database Compliance Scanning Modernization project.*
