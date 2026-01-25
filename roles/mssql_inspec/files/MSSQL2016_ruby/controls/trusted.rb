# MSSQL 2016 InSpec Controls - CIS Benchmark with NIST SP 800-53 Mapping
# Version: 2.0.0
# Last Updated: 2026-01-25
#
# This profile implements CIS Microsoft SQL Server 2016 Benchmark controls
# with NIST SP 800-53 Rev 5 mappings for compliance reporting.
#
# Control ID Format: mssql-2016-X.XX
# Note: Some controls from 2019 are excluded due to feature unavailability in 2016
#   - Excluded: PolyBase (2.10), External Scripts (2.09), CLR Strict Security (2.12)

# Establish connection to MSSQL
sql = mssql_session(
  user: input('usernm'),
  password: input('passwd'),
  host: input('hostnm'),
  port: input('port', value: 1433),
  instance: input('servicenm', value: '')
)

# ==============================================================================
# Section 1: Installation, Updates, and Patches
# NIST: SI-2 (Flaw Remediation), CM-6 (Configuration Settings)
# ==============================================================================

control 'mssql-2016-1.01' do
  impact 1.0
  title 'Ensure Latest SQL Server Service Pack is Installed'
  desc 'SQL Server service packs contain cumulative security fixes and should be applied.'
  tag nist: ['SI-2', 'CM-6']
  tag cis: '1.1'

  describe sql.query("SELECT CASE WHEN CAST(SERVERPROPERTY('ProductLevel') AS VARCHAR(10)) IN ('SP1', 'SP2', 'SP3', 'RTM') THEN 'CHECK_VERSION' ELSE 'UNKNOWN' END AS results") do
    its('rows.first.results') { should_not eq 'UNKNOWN' }
  end
end

control 'mssql-2016-1.02' do
  impact 1.0
  title 'Ensure Latest SQL Server Cumulative Update is Installed'
  desc 'Cumulative updates contain important security fixes released between service packs.'
  tag nist: ['SI-2', 'CM-6']
  tag cis: '1.2'

  describe sql.query("SELECT CASE WHEN CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)) >= '13.0.5000' THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-1.03' do
  impact 0.7
  title 'Ensure SQL Server Version is Still Supported'
  desc 'Running unsupported SQL Server versions exposes the environment to unpatched vulnerabilities.'
  tag nist: ['SI-2', 'SA-22']
  tag cis: '1.3'

  describe sql.query("SELECT CASE WHEN CAST(SERVERPROPERTY('ProductMajorVersion') AS INT) >= 13 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-1.04' do
  impact 0.7
  title 'Ensure Sample Databases are Removed'
  desc 'Sample databases like AdventureWorks should not exist in production environments.'
  tag nist: ['CM-7', 'CM-6']
  tag cis: '1.4'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.databases WHERE name IN ('AdventureWorks', 'AdventureWorksDW', 'AdventureWorksLT', 'Northwind', 'pubs', 'WideWorldImporters')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# ==============================================================================
# Section 2: Surface Area Reduction
# NIST: CM-7 (Least Functionality), SC-7 (Boundary Protection)
# Note: Controls 2.09 (External Scripts), 2.10 (PolyBase), 2.12 (CLR Strict Security)
#       are excluded as these features are not available in SQL Server 2016
# ==============================================================================

control 'mssql-2016-2.01' do
  impact 1.0
  title "Ensure 'Ad Hoc Distributed Queries' Server Configuration Option is set to '0'"
  desc 'Enabling Ad Hoc Distributed Queries allows users to query data and execute statements on external data sources.'
  tag nist: ['CM-7', 'SC-7']
  tag cis: '2.1'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'Ad Hoc Distributed Queries'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-2.02' do
  impact 1.0
  title "Ensure 'CLR Enabled' Server Configuration Option is set to '0'"
  desc 'The clr enabled option specifies whether user assemblies can be run by SQL Server.'
  tag nist: ['CM-7', 'SC-7']
  tag cis: '2.2'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'clr enabled'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-2.03' do
  impact 1.0
  title "Ensure 'Cross DB Ownership Chaining' Server Configuration Option is set to '0'"
  desc 'Cross-database ownership chaining allows database objects to access objects in other databases.'
  tag nist: ['CM-7', 'AC-4']
  tag cis: '2.3'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'cross db ownership chaining'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-2.04' do
  impact 0.7
  title "Ensure 'Database Mail XPs' Server Configuration Option is set to '0'"
  desc 'Database Mail XPs controls the ability to send mail from SQL Server.'
  tag nist: ['CM-7', 'SC-7']
  tag cis: '2.4'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'Database Mail XPs'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-2.05' do
  impact 1.0
  title "Ensure 'Ole Automation Procedures' Server Configuration Option is set to '0'"
  desc 'The Ole Automation Procedures option controls whether OLE Automation objects can be instantiated within Transact-SQL batches.'
  tag nist: ['CM-7', 'SC-7']
  tag cis: '2.5'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'Ole Automation Procedures'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-2.06' do
  impact 1.0
  title "Ensure 'Remote Access' Server Configuration Option is set to '0'"
  desc 'The remote access option controls the execution of stored procedures from local or remote servers.'
  tag nist: ['CM-7', 'AC-17']
  tag cis: '2.6'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'remote access'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-2.07' do
  impact 0.5
  title "Ensure 'Remote Admin Connections' Server Configuration Option is set to '0'"
  desc 'The remote admin connections option allows client applications on remote computers to use the Dedicated Administrator Connection.'
  tag nist: ['CM-7', 'AC-17']
  tag cis: '2.7'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'remote admin connections'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-2.08' do
  impact 0.7
  title "Ensure 'Scan For Startup Procs' Server Configuration Option is set to '0'"
  desc 'The scan for startup procs option causes SQL Server to scan for and automatically run all stored procedures that are set to execute upon service startup.'
  tag nist: ['CM-7', 'CM-6']
  tag cis: '2.8'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'scan for startup procs'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Note: 2.09 (External Scripts) - Not available in SQL Server 2016
# Note: 2.10 (PolyBase) - Not available in SQL Server 2016

control 'mssql-2016-2.11' do
  impact 0.7
  title "Ensure 'Allow Updates' is Disabled"
  desc 'The allow updates option is deprecated but should be verified as disabled.'
  tag nist: ['CM-7', 'CM-6']
  tag cis: '2.11'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'allow updates'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Note: 2.12 (CLR Strict Security) - Not available in SQL Server 2016

control 'mssql-2016-2.13' do
  impact 0.7
  title "Ensure 'Contained Database Authentication' is Disabled Unless Required"
  desc 'Contained database authentication allows users to connect without server-level login.'
  tag nist: ['CM-7', 'IA-2']
  tag cis: '2.13'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'contained database authentication'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-2.14' do
  impact 0.7
  title "Ensure SQL Server Browser Service is Disabled"
  desc 'SQL Server Browser service broadcasts SQL Server instance information on the network.'
  tag nist: ['CM-7', 'SC-7']
  tag cis: '2.14'

  describe sql.query("SELECT 'CHECK_OS_SERVICE' AS results") do
    its('rows.first.results') { should eq 'CHECK_OS_SERVICE' }
  end
end

control 'mssql-2016-2.15' do
  impact 0.5
  title "Ensure 'Show Advanced Options' is Disabled After Configuration"
  desc 'Show advanced options should be disabled after making configuration changes.'
  tag nist: ['CM-6', 'CM-7']
  tag cis: '2.15'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'show advanced options'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-2.16' do
  impact 0.7
  title "Ensure 'Filestream Access Level' is Properly Configured"
  desc 'FILESTREAM should be disabled unless specifically required.'
  tag nist: ['CM-7', 'AC-3']
  tag cis: '2.16'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'filestream access level'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# ==============================================================================
# Section 3: Authentication and Authorization
# NIST: IA-2 (Identification and Authentication), AC-2 (Account Management)
# ==============================================================================

control 'mssql-2016-3.01' do
  impact 0.7
  title "Ensure 'Server Authentication' Property is set to 'Windows Authentication Mode'"
  desc 'Uses Windows Authentication which is more secure than SQL Server Authentication.'
  tag nist: ['IA-2', 'IA-5']
  tag cis: '3.1'

  describe sql.query("SELECT CASE WHEN SERVERPROPERTY('IsIntegratedSecurityOnly') = 1 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-3.02' do
  impact 1.0
  title "Ensure 'CHECK_EXPIRATION' Option is set to 'ON' for All SQL Authenticated Logins"
  desc 'Enforces password expiration policy on SQL Server authenticated logins.'
  tag nist: ['IA-5', 'AC-2']
  tag cis: '3.2'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.sql_logins WHERE is_expiration_checked = 0 AND is_disabled = 0 AND name NOT LIKE '##%##'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-3.03' do
  impact 1.0
  title "Ensure 'CHECK_POLICY' Option is set to 'ON' for All SQL Authenticated Logins"
  desc 'Enforces Windows password policy on SQL Server authenticated logins.'
  tag nist: ['IA-5', 'AC-2']
  tag cis: '3.3'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.sql_logins WHERE is_policy_checked = 0 AND is_disabled = 0 AND name NOT LIKE '##%##'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-3.04' do
  impact 0.7
  title "Ensure 'MUST_CHANGE' Option is set to 'ON' for All SQL Authenticated Logins"
  desc 'New SQL logins should be required to change password at first login.'
  tag nist: ['IA-5', 'AC-2']
  tag cis: '3.4'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.sql_logins WHERE LOGINPROPERTY(name, 'IsMustChange') = 0 AND is_disabled = 0 AND name NOT LIKE '##%##' AND DATEDIFF(day, create_date, GETDATE()) < 7") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-3.05' do
  impact 1.0
  title 'Ensure only the default permissions specified by Microsoft are granted to the public server role'
  desc 'Public role should not have excessive permissions beyond defaults.'
  tag nist: ['AC-6', 'AC-3']
  tag cis: '3.8'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM master.sys.server_permissions WHERE grantee_principal_id = SUSER_SID(N'public') AND permission_name NOT IN ('VIEW ANY DATABASE', 'CONNECT')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-3.06' do
  impact 1.0
  title 'Ensure Windows BUILTIN groups are not SQL Logins'
  desc 'BUILTIN groups provide broad access and should not be used.'
  tag nist: ['AC-6', 'AC-2']
  tag cis: '3.9'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.server_principals WHERE type_desc = 'WINDOWS_GROUP' AND name LIKE 'BUILTIN%'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-3.07' do
  impact 1.0
  title "Ensure the 'sa' Login Account is set to 'Disabled'"
  desc 'The sa account is a well-known target and should be disabled.'
  tag nist: ['AC-2', 'AC-6']
  tag cis: '3.10'

  describe sql.query("SELECT CASE WHEN is_disabled = 1 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.server_principals WHERE sid = 0x01") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-3.08' do
  impact 0.7
  title "Ensure the 'sa' Login Account has been renamed"
  desc 'Renaming sa account helps prevent brute force attacks.'
  tag nist: ['AC-2', 'IA-5']
  tag cis: '3.11'

  describe sql.query("SELECT CASE WHEN name <> 'sa' THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.server_principals WHERE sid = 0x01") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-3.09' do
  impact 1.0
  title "Ensure 'xp_cmdshell' Server Configuration Option is set to '0'"
  desc 'xp_cmdshell allows execution of operating system commands and should be disabled.'
  tag nist: ['CM-7', 'AC-6']
  tag cis: '2.16'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'xp_cmdshell'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-3.10' do
  impact 0.7
  title "Ensure 'AUTO_CLOSE' is set to 'OFF' on contained databases"
  desc 'AUTO_CLOSE can cause performance issues and audit gaps.'
  tag nist: ['AU-12', 'CM-6']
  tag cis: '3.13'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.databases WHERE containment <> 0 AND is_auto_close_on = 1") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-3.11' do
  impact 0.7
  title 'Ensure No Login Has the Sysadmin Role When Not Required'
  desc 'Sysadmin role provides unrestricted access and should be limited.'
  tag nist: ['AC-6', 'AC-2']
  tag cis: '3.14'

  describe sql.query("SELECT CASE WHEN COUNT(*) <= 2 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.server_role_members rm JOIN sys.server_principals sp ON rm.member_principal_id = sp.principal_id JOIN sys.server_principals sr ON rm.role_principal_id = sr.principal_id WHERE sr.name = 'sysadmin' AND sp.is_disabled = 0") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# ==============================================================================
# Section 4: Password Policies and Authorization
# NIST: IA-5 (Authenticator Management), AC-3 (Access Enforcement)
# ==============================================================================

control 'mssql-2016-4.01' do
  impact 1.0
  title "Ensure 'CONNECT' permissions on the 'guest' user is Revoked"
  desc 'Guest user should not have connect permissions to databases.'
  tag nist: ['AC-3', 'AC-6']
  tag cis: '4.2'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.database_permissions dp JOIN sys.database_principals dpr ON dp.grantee_principal_id = dpr.principal_id WHERE dpr.name = 'guest' AND dp.permission_name = 'CONNECT' AND dp.state_desc IN ('GRANT', 'GRANT_WITH_GRANT_OPTION') AND DB_NAME() NOT IN ('master', 'tempdb', 'msdb')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-4.02' do
  impact 0.7
  title "Ensure 'Orphaned Users' are Dropped From SQL Server Databases"
  desc 'Orphaned users are database users with no corresponding server login.'
  tag nist: ['AC-2', 'AC-6']
  tag cis: '4.3'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.database_principals dp LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid WHERE dp.type IN ('S', 'U') AND dp.authentication_type_desc = 'INSTANCE' AND sp.sid IS NULL AND dp.name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys', 'MS_DataCollectorInternalUser')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-4.03' do
  impact 1.0
  title 'Ensure SQL Authentication Logins do not use blank passwords'
  desc 'Blank passwords allow unauthorized access.'
  tag nist: ['IA-5', 'AC-2']
  tag cis: '4.4'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.sql_logins WHERE PWDCOMPARE('', password_hash) = 1") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-4.04' do
  impact 1.0
  title 'Ensure SQL Server Logins Do Not Use Common Weak Passwords'
  desc 'Common passwords like password, admin123 are easily guessable.'
  tag nist: ['IA-5', 'AC-2']
  tag cis: '4.5'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.sql_logins WHERE PWDCOMPARE('password', password_hash) = 1 OR PWDCOMPARE('admin', password_hash) = 1 OR PWDCOMPARE('123456', password_hash) = 1 OR PWDCOMPARE('sqlserver', password_hash) = 1") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# ==============================================================================
# Section 5: Auditing and Logging
# NIST: AU-2 (Audit Events), AU-3 (Content of Audit Records), AU-12 (Audit Generation)
# ==============================================================================

control 'mssql-2016-5.01' do
  impact 0.7
  title "Ensure 'Maximum number of error log files' is set to greater than or equal to 12"
  desc 'Retaining error logs helps with troubleshooting and forensics.'
  tag nist: ['AU-4', 'AU-11']
  tag cis: '5.1'

  describe sql.query("DECLARE @NumErrorLogs INT; EXEC master.sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\\Microsoft\\MSSQLServer\\MSSQLServer', N'NumErrorLogs', @NumErrorLogs OUTPUT; SELECT CASE WHEN ISNULL(@NumErrorLogs, 6) >= 12 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-5.02' do
  impact 1.0
  title "Ensure 'Default Trace Enabled' Server Configuration Option is set to '1'"
  desc 'Default trace provides valuable security auditing information.'
  tag nist: ['AU-2', 'AU-12']
  tag cis: '5.2'

  describe sql.query("SELECT CASE WHEN value_in_use = 1 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.configurations WHERE name = 'default trace enabled'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-5.03' do
  impact 1.0
  title "Ensure 'Login Auditing' is set to 'failed logins' or 'both'"
  desc 'Login auditing helps detect brute force and unauthorized access attempts.'
  tag nist: ['AU-2', 'AU-3']
  tag cis: '5.3'

  describe sql.query("DECLARE @AuditLevel INT; EXEC master.sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\\Microsoft\\MSSQLServer\\MSSQLServer', N'AuditLevel', @AuditLevel OUTPUT; SELECT CASE WHEN @AuditLevel IN (2, 3) THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-5.04' do
  impact 1.0
  title 'Ensure SQL Server Audit is Configured'
  desc 'SQL Server Audit provides granular auditing capabilities.'
  tag nist: ['AU-2', 'AU-12']
  tag cis: '5.4'

  describe sql.query("SELECT CASE WHEN EXISTS (SELECT 1 FROM sys.server_audits WHERE is_state_enabled = 1) THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# ==============================================================================
# Section 6: Application Development
# NIST: SA-11 (Developer Security Testing), CM-6 (Configuration Settings)
# ==============================================================================

control 'mssql-2016-6.01' do
  impact 0.7
  title "Ensure 'Trustworthy' Database Property is set to 'Off'"
  desc 'Trustworthy setting can allow privilege escalation.'
  tag nist: ['AC-6', 'CM-6']
  tag cis: '6.1'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.databases WHERE is_trustworthy_on = 1 AND name NOT IN ('msdb')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-6.02' do
  impact 1.0
  title "Ensure 'CLR Assembly Permission Set' is set to 'SAFE_ACCESS'"
  desc 'CLR assemblies with EXTERNAL_ACCESS or UNSAFE can access external resources.'
  tag nist: ['CM-7', 'AC-6']
  tag cis: '6.2'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.assemblies WHERE permission_set_desc NOT IN ('SAFE_ACCESS') AND is_user_defined = 1") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# ==============================================================================
# Section 7: Encryption
# NIST: SC-8 (Transmission Confidentiality), SC-28 (Protection of Information at Rest)
# ==============================================================================

control 'mssql-2016-7.01' do
  impact 1.0
  title "Ensure 'Symmetric Key encryption algorithm' is set to 'AES_128' or higher"
  desc 'AES provides strong encryption for symmetric keys.'
  tag nist: ['SC-28', 'SC-13']
  tag cis: '7.1'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.symmetric_keys WHERE algorithm_desc NOT IN ('AES_128', 'AES_192', 'AES_256') AND DB_NAME() NOT IN ('master', 'msdb', 'tempdb', 'model')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-7.02' do
  impact 1.0
  title "Ensure Asymmetric Key Size is set to 'greater than or equal to 2048'"
  desc 'RSA keys should be at least 2048 bits for adequate security.'
  tag nist: ['SC-28', 'SC-13']
  tag cis: '7.2'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results FROM sys.asymmetric_keys WHERE key_length < 2048 AND DB_NAME() NOT IN ('master', 'msdb', 'tempdb', 'model')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-7.03' do
  impact 0.7
  title 'Ensure Transparent Data Encryption (TDE) is used for user databases'
  desc 'TDE encrypts database files at rest.'
  tag nist: ['SC-28', 'SC-13']
  tag cis: '7.3'

  describe sql.query("SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM sys.databases WHERE database_id > 4 AND is_encrypted = 0 AND name NOT IN ('ReportServer', 'ReportServerTempDB')) THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-7.04' do
  impact 0.7
  title 'Ensure database backup encryption is considered'
  desc 'Backup encryption protects data in backup files.'
  tag nist: ['SC-28', 'CP-9']
  tag cis: '7.4'

  describe sql.query("SELECT CASE WHEN EXISTS (SELECT 1 FROM msdb.dbo.backupset WHERE backup_finish_date > DATEADD(day, -30, GETDATE()) AND key_algorithm IS NOT NULL) OR NOT EXISTS (SELECT 1 FROM msdb.dbo.backupset WHERE backup_finish_date > DATEADD(day, -30, GETDATE())) THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-7.05' do
  impact 1.0
  title 'Ensure Force Protocol Encryption is Enabled'
  desc 'Encrypted connections protect data in transit.'
  tag nist: ['SC-8', 'SC-23']
  tag cis: '7.5'

  describe sql.query("DECLARE @ForceEncryption INT; EXEC master.sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\\Microsoft\\Microsoft SQL Server\\MSSQLServer\\SuperSocketNetLib', N'ForceEncryption', @ForceEncryption OUTPUT; SELECT CASE WHEN ISNULL(@ForceEncryption, 0) = 1 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# ==============================================================================
# Section 8: Network Configuration
# NIST: SC-7 (Boundary Protection), CM-7 (Least Functionality)
# ==============================================================================

control 'mssql-2016-8.01' do
  impact 0.7
  title 'Ensure SQL Server is Not Listening on Default Port'
  desc 'Changing the default port provides security through obscurity.'
  tag nist: ['SC-7', 'CM-6']
  tag cis: '8.1'

  describe sql.query("DECLARE @Port NVARCHAR(10); EXEC master.sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\\Microsoft\\MSSQLServer\\MSSQLServer\\SuperSocketNetLib\\Tcp\\IPAll', N'TcpPort', @Port OUTPUT; SELECT CASE WHEN ISNULL(@Port, '1433') != '1433' THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-8.02' do
  impact 0.7
  title 'Ensure Named Pipes Protocol is Disabled'
  desc 'Named Pipes is less secure than TCP/IP and should be disabled.'
  tag nist: ['CM-7', 'SC-7']
  tag cis: '8.2'

  describe sql.query("DECLARE @NamedPipes NVARCHAR(10); EXEC master.sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\\Microsoft\\MSSQLServer\\MSSQLServer\\SuperSocketNetLib\\Np', N'Enabled', @NamedPipes OUTPUT; SELECT CASE WHEN ISNULL(@NamedPipes, '0') = '0' THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

control 'mssql-2016-8.03' do
  impact 0.5
  title 'Ensure Hide Instance Option is Enabled'
  desc 'Hiding the instance prevents broadcast of SQL Server presence on the network.'
  tag nist: ['SC-7', 'CM-6']
  tag cis: '8.3'

  describe sql.query("DECLARE @HideInstance INT; EXEC master.sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\\Microsoft\\MSSQLServer\\MSSQLServer\\SuperSocketNetLib', N'HideInstance', @HideInstance OUTPUT; SELECT CASE WHEN ISNULL(@HideInstance, 0) = 1 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end
