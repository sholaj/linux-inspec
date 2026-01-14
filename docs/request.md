# Email: Database Service Account Permissions for Compliance Scanning

---

**To:** Database Administration Team  
**From:** Platform Engineering  
**Subject:** Service Account Permissions Required for Automated NIST Compliance Scanning  
**Priority:** Normal

---

Hi Team,

As part of our initiative to automate NIST compliance scanning using InSpec via Ansible Automation Platform, we need to request service account permissions for our scanning infrastructure. Below are the minimum permissions required for each database platform.

## Microsoft SQL Server (2008-2022)

We need a **read-only** service account with the following server-level permissions:

```sql
-- Create login
CREATE LOGIN [svc_inspec_compliance] WITH PASSWORD = '<secure_password>';

-- Grant minimum required permissions
GRANT CONNECT SQL TO [svc_inspec_compliance];
GRANT VIEW SERVER STATE TO [svc_inspec_compliance];
GRANT VIEW ANY DEFINITION TO [svc_inspec_compliance];
GRANT VIEW ANY DATABASE TO [svc_inspec_compliance];
```

| Permission | Purpose |
|------------|---------|
| VIEW SERVER STATE | Query DMVs for encryption, audit status, configurations |
| VIEW ANY DEFINITION | Inspect metadata, users, roles, permissions |
| VIEW ANY DATABASE | Enumerate databases for cross-database compliance checks |

**Note:** No sysadmin or db_owner roles are required. This follows the principle of least privilege.

## Sybase ASE (15/16)

For comprehensive NIST/CIS compliance coverage, the service account requires **sa_role**:

```sql
sp_addlogin 'svc_inspec_compliance', '<secure_password>', master
GO
EXEC sp_role 'grant', sa_role, svc_inspec_compliance
GO
```

**Why sa_role?** Unlike SQL Server, Sybase ASE restricts access to certain system tables (syslogins, sysloginroles, sysaudits) exclusively to sa_role. Industry guidance from Tenable and CIS confirms this requirement for complete compliance coverage.

## What the Scanner Does

- Executes **read-only SELECT queries** against system views and catalog tables
- Checks configuration settings, audit status, encryption, and user permissions
- **No write operations** are performed
- Results are exported as JSON for compliance reporting

## Reference Documentation

- Microsoft: [System Dynamic Management Views](https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/system-dynamic-management-views)
- Microsoft: [SQL Server 2022 Granular Permissions](https://techcommunity.microsoft.com/blog/sqlserver/new-granular-permissions-for-sql-server-2022-and-azure-sql-to-improve-adherence-/3607507)
- Tenable: [Sybase DB Compliance Checks](https://docs.tenable.com/nessus/compliance-checks-reference/Content/SybaseComplianceChecks.htm)
- Chef InSpec: [mssql_session Resource](https://docs.chef.io/inspec/resources/mssql_session/)
- MITRE SAF: [SQL Server STIG Baselines](https://github.com/mitre/microsoft-sql-server-2016-instance-stig-baseline)

## Next Steps

1. Please create the service accounts on the target database servers
2. Credentials will be stored securely in CyberArk (coordinating with the team)
3. We'll validate connectivity before proceeding with full scanning

Please let me know if you have any questions or concerns about these permissions.

Thanks,  
XXX  
Platform Engineering

---
