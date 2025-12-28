# MSSQL 2019 InSpec Control - trusted.rb
# NIST compliance checks for SQL Server 2019

# Establish connection to MSSQL
sql = mssql_session(
  user: input('usernm'),
  password: input('passwd'),
  host: input('hostnm'),
  port: input('port', value: 1433),
  instance: input('servicenm', value: '')
)

# Control 2.01: Ad Hoc Distributed Queries
control '2.01' do
  impact 1.0
  title "Ensure 'Ad Hoc Distributed Queries' Server Configuration Option is set to '0'"
  desc "Enabling Ad Hoc Distributed Queries allows users to query data and execute statements on external data sources."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'Ad Hoc Distributed Queries'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 2.02: CLR Enabled
control '2.02' do
  impact 1.0
  title "Ensure 'CLR Enabled' Server Configuration Option is set to '0'"
  desc "The clr enabled option specifies whether user assemblies can be run by SQL Server."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'clr enabled'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 2.03: Cross DB Ownership Chaining
control '2.03' do
  impact 1.0
  title "Ensure 'Cross DB Ownership Chaining' Server Configuration Option is set to '0'"
  desc "Cross-database ownership chaining allows database objects to access objects in other databases."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'cross db ownership chaining'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 2.04: Database Mail XPs
control '2.04' do
  impact 0.7
  title "Ensure 'Database Mail XPs' Server Configuration Option is set to '0'"
  desc "Database Mail XPs controls the ability to send mail from SQL Server."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'Database Mail XPs'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 2.05: Ole Automation Procedures
control '2.05' do
  impact 1.0
  title "Ensure 'Ole Automation Procedures' Server Configuration Option is set to '0'"
  desc "The Ole Automation Procedures option controls whether OLE Automation objects can be instantiated within Transact-SQL batches."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'Ole Automation Procedures'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 2.06: Remote Access
control '2.06' do
  impact 1.0
  title "Ensure 'Remote Access' Server Configuration Option is set to '0'"
  desc "The remote access option controls the execution of stored procedures from local or remote servers."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'remote access'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 2.07: Remote Admin Connections
control '2.07' do
  impact 0.5
  title "Ensure 'Remote Admin Connections' Server Configuration Option is set to '0'"
  desc "The remote admin connections option allows client applications on remote computers to use the Dedicated Administrator Connection."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'remote admin connections'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 2.08: Scan For Startup Procs
control '2.08' do
  impact 0.7
  title "Ensure 'Scan For Startup Procs' Server Configuration Option is set to '0'"
  desc "The scan for startup procs option causes SQL Server to scan for and automatically run all stored procedures that are set to execute upon service startup."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'scan for startup procs'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 2.09: External Scripts Enabled (SQL Server 2019 specific)
control '2.09' do
  impact 1.0
  title "Ensure 'External Scripts Enabled' is set to '0'"
  desc "The external scripts enabled option allows execution of scripts with certain remote language extensions."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'external scripts enabled'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 2.10: PolyBase Enabled (SQL Server 2019 specific)
control '2.10' do
  impact 0.7
  title "Ensure 'PolyBase Enabled' is configured correctly"
  desc "PolyBase allows querying data from external data sources."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'polybase enabled'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# ==============================================================================
# Section 3: Authentication and Authorization
# ==============================================================================

# Control 3.01: Ensure SQL Authentication is not used
control '3.01' do
  impact 0.7
  title "Ensure 'Server Authentication' Property is set to 'Windows Authentication Mode'"
  desc "Uses Windows Authentication which is more secure than SQL Server Authentication."
  tag cis: '3.1'

  describe sql.query("SELECT CASE WHEN SERVERPROPERTY('IsIntegratedSecurityOnly') = 1 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 3.02: Ensure CHECK_EXPIRATION is enabled for SQL logins
control '3.02' do
  impact 1.0
  title "Ensure 'CHECK_EXPIRATION' Option is set to 'ON' for All SQL Authenticated Logins"
  desc "Enforces password expiration policy on SQL Server authenticated logins."
  tag cis: '3.2'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.sql_logins WHERE is_expiration_checked = 0 AND is_disabled = 0 AND name NOT LIKE '##%##'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 3.03: Ensure CHECK_POLICY is enabled for SQL logins
control '3.03' do
  impact 1.0
  title "Ensure 'CHECK_POLICY' Option is set to 'ON' for All SQL Authenticated Logins"
  desc "Enforces Windows password policy on SQL Server authenticated logins."
  tag cis: '3.3'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.sql_logins WHERE is_policy_checked = 0 AND is_disabled = 0 AND name NOT LIKE '##%##'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 3.04: Ensure MUST_CHANGE is set for new SQL logins
control '3.04' do
  impact 0.7
  title "Ensure 'MUST_CHANGE' Option is set to 'ON' for All SQL Authenticated Logins"
  desc "New SQL logins should be required to change password at first login."
  tag cis: '3.4'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.sql_logins WHERE LOGINPROPERTY(name, 'IsMustChange') = 0 AND is_disabled = 0 AND name NOT LIKE '##%##' AND DATEDIFF(day, create_date, GETDATE()) < 7") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 3.05: Ensure public role does not have excessive permissions
control '3.05' do
  impact 1.0
  title "Ensure only the default permissions specified by Microsoft are granted to the public server role"
  desc "Public role should not have excessive permissions beyond defaults."
  tag cis: '3.8'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM master.sys.server_permissions WHERE grantee_principal_id = SUSER_SID(N'public') AND permission_name NOT IN ('VIEW ANY DATABASE', 'CONNECT')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 3.06: Ensure Windows BUILTIN groups are not SQL Logins
control '3.06' do
  impact 1.0
  title "Ensure Windows BUILTIN groups are not SQL Logins"
  desc "BUILTIN groups provide broad access and should not be used."
  tag cis: '3.9'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.server_principals WHERE type_desc = 'WINDOWS_GROUP' AND name LIKE 'BUILTIN%'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 3.07: Ensure the sa login is disabled
control '3.07' do
  impact 1.0
  title "Ensure the 'sa' Login Account is set to 'Disabled'"
  desc "The sa account is a well-known target and should be disabled."
  tag cis: '3.10'

  describe sql.query("SELECT CASE WHEN is_disabled = 1 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.server_principals WHERE sid = 0x01") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 3.08: Ensure the sa login has been renamed
control '3.08' do
  impact 0.7
  title "Ensure the 'sa' Login Account has been renamed"
  desc "Renaming sa account helps prevent brute force attacks."
  tag cis: '3.11'

  describe sql.query("SELECT CASE WHEN name <> 'sa' THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.server_principals WHERE sid = 0x01") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 3.09: Ensure xp_cmdshell is disabled
control '3.09' do
  impact 1.0
  title "Ensure 'xp_cmdshell' Server Configuration Option is set to '0'"
  desc "xp_cmdshell allows execution of operating system commands and should be disabled."
  tag cis: '3.12'

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'xp_cmdshell'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 3.10: Ensure AUTO_CLOSE is OFF on contained databases
control '3.10' do
  impact 0.7
  title "Ensure 'AUTO_CLOSE' is set to 'OFF' on contained databases"
  desc "AUTO_CLOSE can cause performance issues and audit gaps."
  tag cis: '3.13'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.databases WHERE containment <> 0 AND is_auto_close_on = 1") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# ==============================================================================
# Section 4: Password Policies
# ==============================================================================

# Control 4.01: Ensure CONNECT permissions on guest user is revoked
control '4.01' do
  impact 1.0
  title "Ensure 'CONNECT' permissions on the 'guest' user is Revoked within all SQL Server databases"
  desc "Guest user should not have connect permissions to databases."
  tag cis: '4.2'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.database_permissions dp JOIN sys.database_principals dpr ON dp.grantee_principal_id = dpr.principal_id WHERE dpr.name = 'guest' AND dp.permission_name = 'CONNECT' AND dp.state_desc IN ('GRANT', 'GRANT_WITH_GRANT_OPTION') AND DB_NAME() NOT IN ('master', 'tempdb', 'msdb')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 4.02: Ensure no orphaned users exist
control '4.02' do
  impact 0.7
  title "Ensure 'Orphaned Users' are Dropped From SQL Server Databases"
  desc "Orphaned users are database users with no corresponding server login."
  tag cis: '4.3'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.database_principals dp LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid WHERE dp.type IN ('S', 'U') AND dp.authentication_type_desc = 'INSTANCE' AND sp.sid IS NULL AND dp.name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys', 'MS_DataCollectorInternalUser')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 4.03: Ensure SQL logins do not use blank passwords
control '4.03' do
  impact 1.0
  title "Ensure SQL Authentication Logins do not use blank passwords"
  desc "Blank passwords allow unauthorized access."
  tag cis: '4.4'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.sql_logins WHERE PWDCOMPARE('', password_hash) = 1") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# ==============================================================================
# Section 5: Auditing and Logging
# ==============================================================================

# Control 5.01: Ensure maximum number of error log files is set
control '5.01' do
  impact 0.7
  title "Ensure 'Maximum number of error log files' is set to greater than or equal to 12"
  desc "Retaining error logs helps with troubleshooting and forensics."
  tag cis: '5.1'

  describe sql.query("DECLARE @NumErrorLogs INT; EXEC master.sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\\Microsoft\\MSSQLServer\\MSSQLServer', N'NumErrorLogs', @NumErrorLogs OUTPUT; SELECT CASE WHEN ISNULL(@NumErrorLogs, 6) >= 12 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 5.02: Ensure default trace is enabled
control '5.02' do
  impact 1.0
  title "Ensure 'Default Trace Enabled' Server Configuration Option is set to '1'"
  desc "Default trace provides valuable security auditing information."
  tag cis: '5.2'

  describe sql.query("SELECT CASE WHEN value_in_use = 1 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'default trace enabled'") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 5.03: Ensure login auditing is enabled
control '5.03' do
  impact 1.0
  title "Ensure 'Login Auditing' is set to 'failed logins' or 'both failed and successful logins'"
  desc "Login auditing helps detect brute force and unauthorized access attempts."
  tag cis: '5.3'

  describe sql.query("DECLARE @AuditLevel INT; EXEC master.sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\\Microsoft\\MSSQLServer\\MSSQLServer', N'AuditLevel', @AuditLevel OUTPUT; SELECT CASE WHEN @AuditLevel IN (2, 3) THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 5.04: Ensure SQL Server Audit is configured
control '5.04' do
  impact 1.0
  title "Ensure SQL Server Audit is set to capture both 'failed' and 'successful logins'"
  desc "SQL Server Audit provides granular auditing capabilities."
  tag cis: '5.4'

  describe sql.query("SELECT CASE WHEN EXISTS (SELECT 1 FROM sys.server_audits WHERE is_state_enabled = 1) THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# ==============================================================================
# Section 6: Application Development
# ==============================================================================

# Control 6.01: Ensure database and application user input is sanitized
control '6.01' do
  impact 0.7
  title "Ensure 'Trustworthy' Database Property is set to 'Off'"
  desc "Trustworthy setting can allow privilege escalation."
  tag cis: '6.1'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.databases WHERE is_trustworthy_on = 1 AND name NOT IN ('msdb')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 6.02: Ensure CLR assembly permission set is SAFE_ACCESS
control '6.02' do
  impact 1.0
  title "Ensure 'CLR Assembly Permission Set' is set to 'SAFE_ACCESS' for All CLR Assemblies"
  desc "CLR assemblies with EXTERNAL_ACCESS or UNSAFE can access external resources."
  tag cis: '6.2'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.assemblies WHERE permission_set_desc NOT IN ('SAFE_ACCESS') AND is_user_defined = 1") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# ==============================================================================
# Section 7: Encryption
# ==============================================================================

# Control 7.01: Ensure symmetric key encryption uses AES
control '7.01' do
  impact 1.0
  title "Ensure 'Symmetric Key encryption algorithm' is set to 'AES_128' or higher in non-system databases"
  desc "AES provides strong encryption for symmetric keys."
  tag cis: '7.1'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.symmetric_keys WHERE algorithm_desc NOT IN ('AES_128', 'AES_192', 'AES_256') AND DB_NAME() NOT IN ('master', 'msdb', 'tempdb', 'model')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 7.02: Ensure asymmetric key size is adequate
control '7.02' do
  impact 1.0
  title "Ensure Asymmetric Key Size is set to 'greater than or equal to 2048' in non-system databases"
  desc "RSA keys should be at least 2048 bits for adequate security."
  tag cis: '7.2'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.asymmetric_keys WHERE key_length < 2048 AND DB_NAME() NOT IN ('master', 'msdb', 'tempdb', 'model')") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 7.03: Ensure TDE is enabled for sensitive databases
control '7.03' do
  impact 0.7
  title "Ensure Transparent Data Encryption (TDE) is used for user databases"
  desc "TDE encrypts database files at rest."
  tag cis: '7.3'

  describe sql.query("SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM sys.databases WHERE database_id > 4 AND is_encrypted = 0 AND name NOT IN ('ReportServer', 'ReportServerTempDB')) THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end

# Control 7.04: Ensure backup encryption is enabled
control '7.04' do
  impact 0.7
  title "Ensure database backup encryption is considered"
  desc "Backup encryption protects data in backup files."
  tag cis: '7.4'

  describe sql.query("SELECT CASE WHEN EXISTS (SELECT 1 FROM msdb.dbo.backupset WHERE backup_finish_date > DATEADD(day, -30, GETDATE()) AND key_algorithm IS NOT NULL) OR NOT EXISTS (SELECT 1 FROM msdb.dbo.backupset WHERE backup_finish_date > DATEADD(day, -30, GETDATE())) THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results") do
    its('rows.first.results') { should eq 'COMPLIANT' }
  end
end
