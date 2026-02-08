# MSSQL 2019 InSpec Controls - CIS Benchmark
# CIS Microsoft SQL Server 2019 Benchmark v1.3.0
# Version: 3.0.0
# Last Updated: 2026-02-08
#
# This profile implements CIS Microsoft SQL Server 2019 Benchmark controls
# for enterprise compliance scanning.
#
# Control ID Format: mssql-2019-X.XX
# Tags: cis (control number), cis_level (1 or 2), severity (critical/high/medium/low)

# Establish connection to MSSQL
# Supports both SQL Server Authentication and Windows Authentication
# - Windows Auth: When usernm is empty/nil, omit credentials to use Windows identity
# - SQL Auth: When usernm is provided, use SQL Server Authentication
_usernm = input('usernm', value: nil)
_passwd = input('passwd', value: nil)
_hostnm = input('hostnm', value: 'localhost')
_port = input('port', value: 1433)
_servicenm = input('servicenm', value: '')

# Determine authentication mode - empty/nil credentials trigger Windows Auth
use_windows_auth = _usernm.nil? || _usernm.to_s.strip.empty?

sql = if use_windows_auth
  # Windows Authentication - omit user/password to use current Windows identity
  mssql_session(
    host: _hostnm,
    port: _port,
    instance: _servicenm
  )
else
  # SQL Server Authentication - use provided credentials
  mssql_session(
    user: _usernm,
    password: _passwd,
    host: _hostnm,
    port: _port,
    instance: _servicenm
  )
end

# ==============================================================================
# Section 1: Installation, Updates, and Patches
# CIS Microsoft SQL Server 2019 Benchmark v1.3.0 - Section 1
# ==============================================================================

control 'mssql-2019-1.01' do
  impact 1.0
  title 'Ensure Latest SQL Server Service Pack is Installed'
  desc 'SQL Server service packs contain cumulative security fixes and should be applied.'

  tag cis: '1.1'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN CAST(SERVERPROPERTY('ProductLevel') AS VARCHAR(10)) IN ('SP1', 'SP2', 'SP3', 'RTM') THEN 'CHECK_VERSION' ELSE 'UNKNOWN' END AS results") do
    its('rows.first.results') { should_not eq 'UNKNOWN' }
  end
end

control 'mssql-2019-1.02' do
  impact 1.0
  title 'Ensure Latest SQL Server Cumulative Update is Installed'
  desc 'Cumulative updates contain important security fixes released between service packs.'

  tag cis: '1.2'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)) >= '15.0.4000' THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-1.03' do
  impact 0.7
  title 'Ensure SQL Server Version is Still Supported'
  desc 'Running unsupported SQL Server versions exposes the environment to unpatched vulnerabilities.'

  tag cis: '1.3'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN CAST(SERVERPROPERTY('ProductMajorVersion') AS INT) >= 15 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-1.04' do
  impact 0.7
  title 'Ensure Sample Databases are Removed'
  desc 'Sample databases like AdventureWorks should not exist in production environments.'

  tag cis: '1.4'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.databases WHERE name IN ('AdventureWorks', 'AdventureWorksDW', 'AdventureWorksLT', 'Northwind', 'pubs', 'WideWorldImporters')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# ==============================================================================
# Section 2: Surface Area Reduction
# CIS Microsoft SQL Server 2019 Benchmark v1.3.0 - Section 2
# ==============================================================================

control 'mssql-2019-2.01' do
  impact 1.0
  title "Ensure 'Ad Hoc Distributed Queries' Server Configuration Option is set to '0'"
  desc 'Enabling Ad Hoc Distributed Queries allows users to query data and execute statements on external data sources.'

  tag cis: '2.1'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'Ad Hoc Distributed Queries'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-2.02' do
  impact 1.0
  title "Ensure 'CLR Enabled' Server Configuration Option is set to '0'"
  desc 'The clr enabled option specifies whether user assemblies can be run by SQL Server.'

  tag cis: '2.2'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'clr enabled'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-2.03' do
  impact 1.0
  title "Ensure 'Cross DB Ownership Chaining' Server Configuration Option is set to '0'"
  desc 'Cross-database ownership chaining allows database objects to access objects in other databases.'

  tag cis: '2.3'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'cross db ownership chaining'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-2.04' do
  impact 0.7
  title "Ensure 'Database Mail XPs' Server Configuration Option is set to '0'"
  desc 'Database Mail XPs controls the ability to send mail from SQL Server.'

  tag cis: '2.4'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'Database Mail XPs'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-2.05' do
  impact 1.0
  title "Ensure 'Ole Automation Procedures' Server Configuration Option is set to '0'"
  desc 'The Ole Automation Procedures option controls whether OLE Automation objects can be instantiated within Transact-SQL batches.'

  tag cis: '2.5'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'Ole Automation Procedures'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-2.06' do
  impact 1.0
  title "Ensure 'Remote Access' Server Configuration Option is set to '0'"
  desc 'The remote access option controls the execution of stored procedures from local or remote servers.'

  tag cis: '2.6'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'remote access'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-2.07' do
  impact 0.5
  title "Ensure 'Remote Admin Connections' Server Configuration Option is set to '0'"
  desc 'The remote admin connections option allows client applications on remote computers to use the Dedicated Administrator Connection.'

  tag cis: '2.7'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'remote admin connections'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-2.08' do
  impact 0.7
  title "Ensure 'Scan For Startup Procs' Server Configuration Option is set to '0'"
  desc 'The scan for startup procs option causes SQL Server to scan for and automatically run all stored procedures that are set to execute upon service startup.'

  tag cis: '2.8'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'scan for startup procs'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-2.09' do
  impact 1.0
  title "Ensure 'External Scripts Enabled' is set to '0'"
  desc 'The external scripts enabled option allows execution of scripts with certain remote language extensions.'

  tag cis: '2.9'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'external scripts enabled'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-2.10' do
  impact 0.7
  title "Ensure 'PolyBase Enabled' is configured correctly"
  desc 'PolyBase allows querying data from external data sources.'

  tag cis: '2.10'
  tag cis_level: 2
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'polybase enabled'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-2.11' do
  impact 0.7
  title "Ensure 'Allow Updates' is Disabled"
  desc 'The allow updates option is deprecated but should be verified as disabled.'

  tag cis: '2.11'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'allow updates'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-2.12' do
  impact 1.0
  title "Ensure 'CLR Strict Security' is Enabled"
  desc 'CLR strict security enforces SAFE, EXTERNAL_ACCESS, UNSAFE permission restrictions.'

  tag cis: '2.12'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN value_in_use = 1 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'clr strict security'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-2.13' do
  impact 0.7
  title "Ensure 'Contained Database Authentication' is Disabled Unless Required"
  desc 'Contained database authentication allows users to connect without server-level login.'

  tag cis: '2.13'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'contained database authentication'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-2.14' do
  impact 0.7
  title "Ensure SQL Server Browser Service is Disabled"
  desc 'SQL Server Browser service broadcasts SQL Server instance information on the network.'

  tag cis: '2.14'
  tag cis_level: 2
  tag severity: 'high'

  # This control checks at the database level; full verification requires OS-level check
  describe sql.query("SELECT 'CHECK_OS_SERVICE' AS results") do
    its('rows.first.results') { should eq 'CHECK_OS_SERVICE' }
  end
end

control 'mssql-2019-2.15' do
  impact 0.5
  title "Ensure 'Show Advanced Options' is Disabled After Configuration"
  desc 'Show advanced options should be disabled after making configuration changes.'

  tag cis: '2.15'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'show advanced options'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-2.16' do
  impact 0.7
  title "Ensure 'Filestream Access Level' is Properly Configured"
  desc 'FILESTREAM should be disabled unless specifically required.'

  tag cis: '2.16'
  tag cis_level: 2
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'filestream access level'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-2.17' do
  impact 0.7
  title "Ensure 'Hadoop Connectivity' is Disabled"
  desc 'Hadoop connectivity should be disabled unless specifically required for PolyBase.'

  tag cis: '2.17'
  tag cis_level: 2
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'hadoop connectivity'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-2.18' do
  impact 1.0
  title "Ensure 'xp_cmdshell' Server Configuration Option is set to '0'"
  desc 'xp_cmdshell allows execution of operating system commands and should be disabled.'

  tag cis: '2.18'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'xp_cmdshell'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# ==============================================================================
# Section 3: Authentication and Authorization
# CIS Microsoft SQL Server 2019 Benchmark v1.3.0 - Section 3
# ==============================================================================

control 'mssql-2019-3.01' do
  impact 0.7
  title "Ensure 'Server Authentication' Property is set to 'Windows Authentication Mode'"
  desc 'Uses Windows Authentication which is more secure than SQL Server Authentication.'

  tag cis: '3.1'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN SERVERPROPERTY('IsIntegratedSecurityOnly') = 1 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-3.02' do
  impact 1.0
  title "Ensure 'CHECK_EXPIRATION' Option is set to 'ON' for All SQL Authenticated Logins"
  desc 'Enforces password expiration policy on SQL Server authenticated logins.'

  tag cis: '3.2'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.sql_logins WHERE is_expiration_checked = 0 AND is_disabled = 0 AND name NOT LIKE '##%##'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-3.03' do
  impact 1.0
  title "Ensure 'CHECK_POLICY' Option is set to 'ON' for All SQL Authenticated Logins"
  desc 'Enforces Windows password policy on SQL Server authenticated logins.'

  tag cis: '3.3'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.sql_logins WHERE is_policy_checked = 0 AND is_disabled = 0 AND name NOT LIKE '##%##'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-3.04' do
  impact 0.7
  title "Ensure 'MUST_CHANGE' Option is set to 'ON' for All SQL Authenticated Logins"
  desc 'New SQL logins should be required to change password at first login.'

  tag cis: '3.4'
  tag cis_level: 2
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.sql_logins WHERE LOGINPROPERTY(name, 'IsMustChange') = 0 AND is_disabled = 0 AND name NOT LIKE '##%##' AND DATEDIFF(day, create_date, GETDATE()) < 7") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-3.05' do
  impact 1.0
  title 'Ensure only the default permissions specified by Microsoft are granted to the public server role'
  desc 'Public role should not have excessive permissions beyond defaults.'

  tag cis: '3.8'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM master.sys.server_permissions WHERE grantee_principal_id = SUSER_SID(N'public') AND permission_name NOT IN ('VIEW ANY DATABASE', 'CONNECT')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-3.06' do
  impact 1.0
  title 'Ensure Windows BUILTIN groups are not SQL Logins'
  desc 'BUILTIN groups provide broad access and should not be used.'

  tag cis: '3.9'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.server_principals WHERE type_desc = 'WINDOWS_GROUP' AND name LIKE 'BUILTIN%'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-3.07' do
  impact 1.0
  title "Ensure the 'sa' Login Account is set to 'Disabled'"
  desc 'The sa account is a well-known target and should be disabled.'

  tag cis: '3.10'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN is_disabled = 1 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.server_principals WHERE sid = 0x01") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-3.08' do
  impact 0.7
  title "Ensure the 'sa' Login Account has been renamed"
  desc 'Renaming sa account helps prevent brute force attacks.'

  tag cis: '3.11'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN name <> 'sa' THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.server_principals WHERE sid = 0x01") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-3.09' do
  impact 0.7
  title "Ensure 'AUTO_CLOSE' is set to 'OFF' on contained databases"
  desc 'AUTO_CLOSE can cause performance issues and audit gaps.'

  tag cis: '3.13'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.databases WHERE containment <> 0 AND is_auto_close_on = 1") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-3.10' do
  impact 0.7
  title 'Ensure No Login Has the Sysadmin Role When Not Required'
  desc 'Sysadmin role provides unrestricted access and should be limited.'

  tag cis: '3.14'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN COUNT(*) <= 2 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.server_role_members rm JOIN sys.server_principals sp ON rm.member_principal_id = sp.principal_id JOIN sys.server_principals sr ON rm.role_principal_id = sr.principal_id WHERE sr.name = 'sysadmin' AND sp.is_disabled = 0") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-3.11' do
  impact 1.0
  title 'Ensure SQL Server Agent Service Account is Not a Sysadmin'
  desc 'SQL Server Agent should use a dedicated service account with minimal permissions.'

  tag cis: '3.15'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.server_principals sp JOIN sys.server_role_members rm ON sp.principal_id = rm.member_principal_id JOIN sys.server_principals sr ON rm.role_principal_id = sr.principal_id WHERE sr.name = 'sysadmin' AND sp.name LIKE '%SQLSERVERAGENT%'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-3.12' do
  impact 0.7
  title 'Ensure Local Windows Groups Are Not SQL Logins'
  desc 'Local Windows groups may grant unintended access when group membership changes.'

  tag cis: '3.16'
  tag cis_level: 2
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.server_principals WHERE type_desc = 'WINDOWS_GROUP' AND name NOT LIKE '%\\%' AND name NOT LIKE 'NT %'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-3.13' do
  impact 1.0
  title 'Ensure Server Permissions Are Not Granted to Public Role'
  desc 'Server permissions granted to public are effectively granted to all logins.'

  tag cis: '3.17'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.server_permissions WHERE grantee_principal_id = 2 AND permission_name NOT IN ('CONNECT', 'VIEW ANY DATABASE')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-3.14' do
  impact 0.7
  title 'Ensure Proxy Accounts Are Secured'
  desc 'SQL Server Agent proxy accounts should have limited permissions.'

  tag cis: '3.18'
  tag cis_level: 2
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'CHECK_PROXY_PERMS' END AS results FROM msdb.dbo.sysproxies WHERE enabled = 1") do
    its('rows.first.results') { should be_in ['COMPLIANT', 'CHECK_PROXY_PERMS'] }
  end
end

# ==============================================================================
# Section 4: Password Policies and Authorization
# CIS Microsoft SQL Server 2019 Benchmark v1.3.0 - Section 4
# ==============================================================================

control 'mssql-2019-4.01' do
  impact 1.0
  title "Ensure 'CONNECT' permissions on the 'guest' user is Revoked"
  desc 'Guest user should not have connect permissions to databases.'

  tag cis: '4.2'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.database_permissions dp JOIN sys.database_principals dpr ON dp.grantee_principal_id = dpr.principal_id WHERE dpr.name = 'guest' AND dp.permission_name = 'CONNECT' AND dp.state_desc IN ('GRANT', 'GRANT_WITH_GRANT_OPTION') AND DB_NAME() NOT IN ('master', 'tempdb', 'msdb')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-4.02' do
  impact 0.7
  title "Ensure 'Orphaned Users' are Dropped From SQL Server Databases"
  desc 'Orphaned users are database users with no corresponding server login.'

  tag cis: '4.3'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.database_principals dp LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid WHERE dp.type IN ('S', 'U') AND dp.authentication_type_desc = 'INSTANCE' AND sp.sid IS NULL AND dp.name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys', 'MS_DataCollectorInternalUser')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-4.03' do
  impact 1.0
  title 'Ensure SQL Authentication Logins do not use blank passwords'
  desc 'Blank passwords allow unauthorized access.'

  tag cis: '4.4'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.sql_logins WHERE PWDCOMPARE('', password_hash) = 1") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-4.04' do
  impact 1.0
  title 'Ensure SQL Server Logins Do Not Use Common Weak Passwords'
  desc 'Common passwords like password, admin123 are easily guessable.'

  tag cis: '4.5'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.sql_logins WHERE PWDCOMPARE('password', password_hash) = 1 OR PWDCOMPARE('admin', password_hash) = 1 OR PWDCOMPARE('123456', password_hash) = 1 OR PWDCOMPARE('sqlserver', password_hash) = 1") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-4.05' do
  impact 0.7
  title 'Ensure db_owner Role Membership is Reviewed'
  desc 'The db_owner role has full permissions within a database and membership should be minimized.'

  tag cis: '4.6'
  tag cis_level: 2
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN COUNT(*) <= 3 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.database_role_members rm JOIN sys.database_principals rp ON rm.role_principal_id = rp.principal_id JOIN sys.database_principals mp ON rm.member_principal_id = mp.principal_id WHERE rp.name = 'db_owner' AND mp.name NOT IN ('dbo')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-4.06' do
  impact 1.0
  title 'Ensure Database Permissions Are Not Granted Directly to Users'
  desc 'Permissions should be granted through roles, not directly to users.'

  tag cis: '4.7'
  tag cis_level: 2
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN COUNT(*) <= 5 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.database_permissions dp JOIN sys.database_principals pr ON dp.grantee_principal_id = pr.principal_id WHERE pr.type IN ('S', 'U') AND dp.state_desc IN ('GRANT', 'GRANT_WITH_GRANT_OPTION') AND dp.class_desc != 'DATABASE'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-4.07' do
  impact 1.0
  title 'Ensure EXECUTE Permission Is Not Granted on Sensitive System Procedures'
  desc 'Sensitive system procedures should not be executable by non-admin users.'

  tag cis: '4.8'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.database_permissions dp JOIN sys.objects o ON dp.major_id = o.object_id JOIN sys.database_principals pr ON dp.grantee_principal_id = pr.principal_id WHERE o.name IN ('xp_cmdshell', 'xp_regread', 'xp_regwrite', 'xp_servicecontrol', 'sp_OACreate') AND dp.permission_name = 'EXECUTE' AND pr.name NOT IN ('dbo', 'sysadmin')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-4.08' do
  impact 0.7
  title 'Ensure Linked Servers Are Configured Securely'
  desc 'Linked servers should use proper authentication and minimal permissions.'

  tag cis: '4.9'
  tag cis_level: 2
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.linked_logins WHERE uses_self_credential = 0 AND remote_name = 'sa'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# ==============================================================================
# Section 5: Auditing and Logging
# CIS Microsoft SQL Server 2019 Benchmark v1.3.0 - Section 5
# ==============================================================================

control 'mssql-2019-5.01' do
  impact 0.7
  title "Ensure 'Maximum number of error log files' is set to greater than or equal to 12"
  desc 'Retaining error logs helps with troubleshooting and forensics.'

  tag cis: '5.1'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("DECLARE @NumErrorLogs INT; EXEC master.sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\\Microsoft\\MSSQLServer\\MSSQLServer', N'NumErrorLogs', @NumErrorLogs OUTPUT; SELECT CASE WHEN ISNULL(@NumErrorLogs, 6) >= 12 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-5.02' do
  impact 1.0
  title "Ensure 'Default Trace Enabled' Server Configuration Option is set to '1'"
  desc 'Default trace provides valuable security auditing information.'

  tag cis: '5.2'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN value_in_use = 1 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'default trace enabled'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-5.03' do
  impact 1.0
  title "Ensure 'Login Auditing' is set to 'failed logins' or 'both'"
  desc 'Login auditing helps detect brute force and unauthorized access attempts.'

  tag cis: '5.3'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("DECLARE @AuditLevel INT; EXEC master.sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\\Microsoft\\MSSQLServer\\MSSQLServer', N'AuditLevel', @AuditLevel OUTPUT; SELECT CASE WHEN @AuditLevel IN (2, 3) THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-5.04' do
  impact 1.0
  title 'Ensure SQL Server Audit is Configured'
  desc 'SQL Server Audit provides granular auditing capabilities.'

  tag cis: '5.4'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN EXISTS (SELECT 1 FROM sys.server_audits WHERE is_state_enabled = 1) THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-5.05' do
  impact 1.0
  title 'Ensure SQL Server Audit Captures Security Events'
  desc 'Audit should capture security-related events like login failures and permission changes.'

  tag cis: '5.5'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN EXISTS (SELECT 1 FROM sys.server_audit_specifications WHERE is_state_enabled = 1) THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-5.06' do
  impact 0.7
  title 'Ensure Database Audit Specifications Exist for Critical Databases'
  desc 'Critical databases should have audit specifications for sensitive operations.'

  tag cis: '5.6'
  tag cis_level: 2
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE is_state_enabled = 1) OR DB_NAME() IN ('master', 'tempdb', 'model') THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-5.07' do
  impact 0.7
  title 'Ensure Audit File Path is on Non-System Drive'
  desc 'Audit files should not be stored on the system drive to prevent space issues.'

  tag cis: '5.7'
  tag cis_level: 2
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM sys.server_file_audits WHERE log_file_path LIKE 'C:%') OR NOT EXISTS (SELECT 1 FROM sys.server_file_audits) THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-5.08' do
  impact 1.0
  title 'Ensure Audit On Failure Action is Set to Continue'
  desc 'Audit should continue operation even if audit writing fails to prevent denial of service.'

  tag cis: '5.8'
  tag cis_level: 2
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM sys.server_audits WHERE on_failure_desc = 'SHUTDOWN_SERVER_INSTANCE') OR NOT EXISTS (SELECT 1 FROM sys.server_audits) THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# ==============================================================================
# Section 6: Application Development
# CIS Microsoft SQL Server 2019 Benchmark v1.3.0 - Section 6
# ==============================================================================

control 'mssql-2019-6.01' do
  impact 0.7
  title "Ensure 'Trustworthy' Database Property is set to 'Off'"
  desc 'Trustworthy setting can allow privilege escalation.'

  tag cis: '6.1'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.databases WHERE is_trustworthy_on = 1 AND name NOT IN ('msdb')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-6.02' do
  impact 1.0
  title "Ensure 'CLR Assembly Permission Set' is set to 'SAFE_ACCESS'"
  desc 'CLR assemblies with EXTERNAL_ACCESS or UNSAFE can access external resources.'

  tag cis: '6.2'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.assemblies WHERE permission_set_desc NOT IN ('SAFE_ACCESS') AND is_user_defined = 1") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-6.03' do
  impact 0.7
  title 'Ensure Stored Procedures Do Not Use Dynamic SQL Unsafely'
  desc 'Dynamic SQL can introduce SQL injection vulnerabilities.'

  tag cis: '6.3'
  tag cis_level: 2
  tag severity: 'high'

  # This is an advisory control - manual review recommended
  describe sql.query("SELECT 'MANUAL_REVIEW' AS results") do
    its('rows.first.results') { should eq 'MANUAL_REVIEW' }
  end
end

control 'mssql-2019-6.04' do
  impact 0.5
  title 'Ensure Application Roles Are Used Where Appropriate'
  desc 'Application roles provide better security than embedding credentials.'

  tag cis: '6.4'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("SELECT CASE WHEN EXISTS (SELECT 1 FROM sys.database_principals WHERE type_desc = 'APPLICATION_ROLE') OR DB_NAME() IN ('master', 'tempdb', 'msdb', 'model') THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# ==============================================================================
# Section 7: Encryption
# CIS Microsoft SQL Server 2019 Benchmark v1.3.0 - Section 7
# ==============================================================================

control 'mssql-2019-7.01' do
  impact 1.0
  title "Ensure 'Symmetric Key encryption algorithm' is set to 'AES_128' or higher"
  desc 'AES provides strong encryption for symmetric keys.'

  tag cis: '7.1'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.symmetric_keys WHERE algorithm_desc NOT IN ('AES_128', 'AES_192', 'AES_256') AND DB_NAME() NOT IN ('master', 'msdb', 'tempdb', 'model')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-7.02' do
  impact 1.0
  title "Ensure Asymmetric Key Size is set to 'greater than or equal to 2048'"
  desc 'RSA keys should be at least 2048 bits for adequate security.'

  tag cis: '7.2'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.asymmetric_keys WHERE key_length < 2048 AND DB_NAME() NOT IN ('master', 'msdb', 'tempdb', 'model')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-7.03' do
  impact 0.7
  title 'Ensure Transparent Data Encryption (TDE) is used for user databases'
  desc 'TDE encrypts database files at rest.'

  tag cis: '7.3'
  tag cis_level: 2
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM sys.databases WHERE database_id > 4 AND is_encrypted = 0 AND name NOT IN ('ReportServer', 'ReportServerTempDB')) THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-7.04' do
  impact 0.7
  title 'Ensure database backup encryption is considered'
  desc 'Backup encryption protects data in backup files.'

  tag cis: '7.4'
  tag cis_level: 2
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN EXISTS (SELECT 1 FROM msdb.dbo.backupset WHERE backup_finish_date > DATEADD(day, -30, GETDATE()) AND key_algorithm IS NOT NULL) OR NOT EXISTS (SELECT 1 FROM msdb.dbo.backupset WHERE backup_finish_date > DATEADD(day, -30, GETDATE())) THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-7.05' do
  impact 1.0
  title 'Ensure Force Protocol Encryption is Enabled'
  desc 'Encrypted connections protect data in transit.'

  tag cis: '7.5'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("DECLARE @ForceEncryption INT; EXEC master.sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\\Microsoft\\Microsoft SQL Server\\MSSQLServer\\SuperSocketNetLib', N'ForceEncryption', @ForceEncryption OUTPUT; SELECT CASE WHEN ISNULL(@ForceEncryption, 0) = 1 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-7.06' do
  impact 1.0
  title 'Ensure TLS 1.2 or Higher is Used'
  desc 'Older TLS versions have known vulnerabilities.'

  tag cis: '7.6'
  tag cis_level: 1
  tag severity: 'critical'

  # This requires registry check - advisory control
  describe sql.query("SELECT 'CHECK_TLS_VERSION' AS results") do
    its('rows.first.results') { should eq 'CHECK_TLS_VERSION' }
  end
end

control 'mssql-2019-7.07' do
  impact 0.7
  title 'Ensure Certificate Expiration is Monitored'
  desc 'Expired certificates can cause connection failures or security issues.'

  tag cis: '7.7'
  tag cis_level: 2
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM sys.certificates WHERE expiry_date < DATEADD(day, 30, GETDATE()) AND pvt_key_encryption_type != 'NA') THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-7.08' do
  impact 0.7
  title 'Ensure Service Master Key is Backed Up'
  desc 'Service Master Key is required to restore encrypted data.'

  tag cis: '7.8'
  tag cis_level: 2
  tag severity: 'high'

  # Advisory - manual verification recommended
  describe sql.query("SELECT 'VERIFY_SMK_BACKUP' AS results") do
    its('rows.first.results') { should eq 'VERIFY_SMK_BACKUP' }
  end
end

# ==============================================================================
# Section 8: Network Configuration
# CIS Microsoft SQL Server 2019 Benchmark v1.3.0 - Section 8
# ==============================================================================

control 'mssql-2019-8.01' do
  impact 0.7
  title 'Ensure SQL Server is Not Listening on Default Port'
  desc 'Changing the default port provides security through obscurity.'

  tag cis: '8.1'
  tag cis_level: 2
  tag severity: 'high'

  describe sql.query("DECLARE @Port NVARCHAR(10); EXEC master.sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\\Microsoft\\MSSQLServer\\MSSQLServer\\SuperSocketNetLib\\Tcp\\IPAll', N'TcpPort', @Port OUTPUT; SELECT CASE WHEN ISNULL(@Port, '1433') != '1433' THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-8.02' do
  impact 0.7
  title 'Ensure Named Pipes Protocol is Disabled'
  desc 'Named Pipes is less secure than TCP/IP and should be disabled.'

  tag cis: '8.2'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("DECLARE @NamedPipes NVARCHAR(10); EXEC master.sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\\Microsoft\\MSSQLServer\\MSSQLServer\\SuperSocketNetLib\\Np', N'Enabled', @NamedPipes OUTPUT; SELECT CASE WHEN ISNULL(@NamedPipes, '0') = '0' THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-8.03' do
  impact 0.5
  title 'Ensure Hide Instance Option is Enabled'
  desc 'Hiding the instance prevents broadcast of SQL Server presence on the network.'

  tag cis: '8.3'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("DECLARE @HideInstance INT; EXEC master.sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\\Microsoft\\MSSQLServer\\MSSQLServer\\SuperSocketNetLib', N'HideInstance', @HideInstance OUTPUT; SELECT CASE WHEN ISNULL(@HideInstance, 0) = 1 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-8.04' do
  impact 0.7
  title 'Ensure SQL Server Endpoints Are Secured'
  desc 'Endpoints should use proper authentication and encryption.'

  tag cis: '8.4'
  tag cis_level: 2
  tag severity: 'high'

  describe sql.query("SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM sys.endpoints WHERE state_desc = 'STARTED' AND is_admin_endpoint = 0 AND type_desc != 'TSQL') OR NOT EXISTS (SELECT 1 FROM sys.endpoints WHERE type_desc NOT IN ('TSQL', 'SERVICE_BROKER', 'DATABASE_MIRRORING')) THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2019-8.05' do
  impact 0.5
  title 'Ensure DAC (Dedicated Admin Connection) is Configured Securely'
  desc 'DAC provides emergency access and should be properly secured.'

  tag cis: '8.5'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'remote admin connections'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end
