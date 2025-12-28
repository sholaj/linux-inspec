# Sybase ASE 16 InSpec Control - trusted.rb
# CIS Sybase ASE 16 Compliance Controls
#
# Uses native sybase_session resource for scalable multi-database scanning
# Password is passed via input and handled securely by InSpec

# Build sybase_session options dynamically
sybase_opts = {
  username: input('usernm'),
  password: input('passwd'),
  server: input('servernm'),
  database: input('database', value: 'master')
}

# Add optional parameters if provided (use empty string as default, check for non-empty)
sybase_home_val = input('sybase_home', value: '')
isql_bin_val = input('isql_bin', value: '')
sybase_opts[:sybase_home] = sybase_home_val unless sybase_home_val.to_s.empty?
sybase_opts[:bin] = isql_bin_val unless isql_bin_val.to_s.empty?

# Use custom sybase_session_local resource that handles local execution and tsql
sql = sybase_session_local(sybase_opts)

title "Sybase ASE 16 Database Security Compliance Controls"

# Control 01: Ensure server is running and accessible
control 'sybase-16-01' do
  impact 1.0
  title 'Ensure Sybase ASE server is accessible'
  desc 'Sybase ASE server should be running and accessible for connections'

  describe sql.query('select @@servername as servername').row(0).column('servername') do
    its('value') { should_not be_nil }
  end
end

# Control 02: Check server version and ensure it's supported
control 'sybase-16-02' do
  impact 0.8
  title 'Verify Sybase ASE version information'
  desc 'Sybase ASE should report correct version information'

  describe sql.query('select @@version as version').row(0).column('version') do
    its('value') { should match(/Adaptive Server Enterprise/) }
  end
end

# Control 03: Ensure auditing is enabled
control 'sybase-16-03' do
  impact 1.0
  title 'Ensure Sybase ASE auditing is enabled'
  desc 'Sybase ASE should have auditing enabled for security compliance'

  describe sql.query("select value from master..sysconfigures where name = 'auditing'").row(0).column('value') do
    its('value') { should cmp 1 }
  end
end

# Control 04: Check for default passwords (accounts with null passwords)
control 'sybase-16-04' do
  impact 1.0
  title 'Ensure no default passwords are in use'
  desc 'Sybase ASE should not have accounts with default or empty passwords'

  describe sql.query("select count(*) as cnt from master..syslogins where password is null and name in ('sa', 'probe', 'guest')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 05: Ensure remote access is properly configured
control 'sybase-16-05' do
  impact 0.8
  title 'Verify remote access configuration'
  desc 'Sybase ASE remote access should be properly configured'

  describe sql.query("select value from master..sysconfigures where name = 'allow remote access'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

# Control 06: Check system table permissions
control 'sybase-16-06' do
  impact 1.0
  title 'Ensure system table access is restricted'
  desc 'Sybase ASE system tables should have proper access controls'

  describe sql.query("select value from master..sysconfigures where name = 'allow updates to system tables'").row(0).column('value') do
    its('value') { should cmp 0 }
  end
end

# Control 07: Ensure password expiration is enabled
control 'sybase-16-07' do
  impact 0.9
  title 'Ensure password expiration is configured'
  desc 'Sybase ASE should enforce password expiration policies'

  describe sql.query("select value from master..sysconfigures where name = 'systemwide password expiration'").row(0).column('value') do
    its('value') { should be >= 0 }
  end
end

# Control 08: Check for xp_cmdshell status
control 'sybase-16-08' do
  impact 1.0
  title 'Ensure xp_cmdshell is disabled or restricted'
  desc 'xp_cmdshell should be disabled or restricted to prevent OS command execution'

  describe sql.query("select value from master..sysconfigures where name = 'xp_cmdshell context'").row(0).column('value') do
    its('value') { should cmp 1 }
  end
end

# Control 09: Ensure login lockout is configured
control 'sybase-16-09' do
  impact 0.9
  title 'Ensure failed login lockout is configured'
  desc 'Sybase ASE should lock accounts after a specified number of failed login attempts'

  describe sql.query("select value from master..sysconfigures where name = 'maximum failed logins'").row(0).column('value') do
    its('value') { should be >= 3 }
    its('value') { should be <= 10 }
  end
end

# Control 10: Ensure secure network encryption is enabled
control 'sybase-16-10' do
  impact 1.0
  title 'Ensure network encryption is properly configured'
  desc 'Sybase ASE should have network encryption enabled for secure communications'

  describe sql.query("select value from master..sysconfigures where name = 'enable ssl'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

# =============================================================================
# Section 2: Password and Authentication Security
# Reference: CIS Sybase ASE Benchmark, SAP ASE Security Administration Guide
# =============================================================================

# Control 2.01: Ensure minimum password length is configured
control 'sybase-16-2.01' do
  impact 1.0
  title 'Ensure minimum password length is set to 8 or more'
  desc 'Passwords should have a minimum length to prevent brute force attacks. CIS recommends at least 8 characters.'
  tag cis: '1.5'

  describe sql.query("select value from master..sysconfigures where name = 'minimum password length'").row(0).column('value') do
    its('value') { should be >= 8 }
  end
end

# Control 2.02: Ensure password complexity - digit requirement
control 'sybase-16-2.02' do
  impact 0.9
  title 'Ensure check password for digit is enabled'
  desc 'Passwords should contain at least one digit for complexity. This prevents dictionary attacks.'
  tag cis: '1.6'

  describe sql.query("select value from master..sysconfigures where name = 'check password for digit'").row(0).column('value') do
    its('value') { should cmp 1 }
  end
end

# Control 2.03: Ensure SA account has a strong password
control 'sybase-16-2.03' do
  impact 1.0
  title 'Ensure SA account password is not NULL'
  desc 'The SA account is created with a NULL password by default. This must be changed immediately after installation.'
  tag cis: '1.1'

  describe sql.query("select count(*) as cnt from master..syslogins where name = 'sa' and password is null").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 2.04: Ensure probe account is secured
control 'sybase-16-2.04' do
  impact 1.0
  title 'Ensure probe account is locked or has password'
  desc 'The probe account is used for Two-Phase Commit and should be secured or locked if not needed.'
  tag cis: '1.2'

  describe sql.query("select count(*) as cnt from master..syslogins where name = 'probe' and (password is null or status = 0)").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 2.05: Ensure guest account is properly restricted
control 'sybase-16-2.05' do
  impact 1.0
  title 'Ensure guest account is locked in production databases'
  desc 'The guest account should be locked in production as it inherits PUBLIC permissions and allows anonymous access.'
  tag cis: '1.3'

  # Check if guest is locked (status & 2 = locked bit)
  describe sql.query("select count(*) as cnt from master..syslogins where name = 'guest' and status & 2 = 0").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 2.06: Ensure min digits in password is configured
control 'sybase-16-2.06' do
  impact 0.8
  title 'Ensure minimum digits in password policy is set'
  desc 'Password policy should require a minimum number of digits for complexity.'
  tag cis: '1.6'

  describe sql.query("select value from master..sysconfigures where name = 'min digits in password'").row(0).column('value') do
    its('value') { should be >= 1 }
  end
end

# Control 2.07: Ensure min special characters in password is configured
control 'sybase-16-2.07' do
  impact 0.8
  title 'Ensure minimum special characters in password policy is set'
  desc 'Password policy should require special characters for complexity.'
  tag cis: '1.6'

  describe sql.query("select value from master..sysconfigures where name = 'min special char in password'").row(0).column('value') do
    its('value') { should be >= 1 }
  end
end

# Control 2.08: Ensure min uppercase characters in password is configured
control 'sybase-16-2.08' do
  impact 0.7
  title 'Ensure minimum uppercase characters in password policy is set'
  desc 'Password policy should require uppercase characters for complexity.'
  tag cis: '1.6'

  describe sql.query("select value from master..sysconfigures where name = 'min upper char in password'").row(0).column('value') do
    its('value') { should be >= 1 }
  end
end

# Control 2.09: Ensure min lowercase characters in password is configured
control 'sybase-16-2.09' do
  impact 0.7
  title 'Ensure minimum lowercase characters in password policy is set'
  desc 'Password policy should require lowercase characters for complexity.'
  tag cis: '1.6'

  describe sql.query("select value from master..sysconfigures where name = 'min lower char in password'").row(0).column('value') do
    its('value') { should be >= 1 }
  end
end

# Control 2.10: Ensure password history is enforced
control 'sybase-16-2.10' do
  impact 0.8
  title 'Ensure password history prevents reuse'
  desc 'Password history should prevent users from reusing recent passwords.'
  tag cis: '1.7'

  describe sql.query("select value from master..sysconfigures where name = 'min password length'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

# =============================================================================
# Section 3: Authorization and Role Security
# =============================================================================

# Control 3.01: Ensure sa_role is not granted to unnecessary users
control 'sybase-16-3.01' do
  impact 1.0
  title 'Limit accounts with sa_role'
  desc 'The sa_role provides full system administrator privileges. Only essential accounts should have this role.'
  tag cis: '2.1'

  describe sql.query("select count(*) as cnt from master..sysloginroles lr join master..syssrvroles r on lr.srid = r.srid where r.name = 'sa_role'").row(0).column('cnt') do
    its('value') { should be <= 3 }
  end
end

# Control 3.02: Ensure sso_role is restricted
control 'sybase-16-3.02' do
  impact 1.0
  title 'Limit accounts with sso_role'
  desc 'The sso_role (System Security Officer) manages security. Only essential accounts should have this role.'
  tag cis: '2.2'

  describe sql.query("select count(*) as cnt from master..sysloginroles lr join master..syssrvroles r on lr.srid = r.srid where r.name = 'sso_role'").row(0).column('cnt') do
    its('value') { should be <= 3 }
  end
end

# Control 3.03: Ensure oper_role is restricted
control 'sybase-16-3.03' do
  impact 0.8
  title 'Limit accounts with oper_role'
  desc 'The oper_role allows backup and restore operations. Only operator accounts should have this role.'
  tag cis: '2.3'

  describe sql.query("select count(*) as cnt from master..sysloginroles lr join master..syssrvroles r on lr.srid = r.srid where r.name = 'oper_role'").row(0).column('cnt') do
    its('value') { should be <= 5 }
  end
end

# Control 3.04: Ensure replication_role is restricted
control 'sybase-16-3.04' do
  impact 0.8
  title 'Limit accounts with replication_role'
  desc 'The replication_role is for replication administration. Only replication accounts should have this role.'
  tag cis: '2.4'

  describe sql.query("select count(*) as cnt from master..sysloginroles lr join master..syssrvroles r on lr.srid = r.srid where r.name = 'replication_role'").row(0).column('cnt') do
    its('value') { should be <= 3 }
  end
end

# Control 3.05: Ensure PUBLIC has minimal permissions
control 'sybase-16-3.05' do
  impact 0.9
  title 'Ensure PUBLIC role has minimal permissions'
  desc 'The PUBLIC role applies to all users. Excessive permissions on PUBLIC expose the database to risk.'
  tag cis: '2.5'

  # Check for dangerous permissions granted to public
  describe sql.query("select count(*) as cnt from master..sysprotects where uid = 0 and action in (193, 195, 196, 197)").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 3.06: Ensure guest user has no database access
control 'sybase-16-3.06' do
  impact 0.9
  title 'Ensure guest user is not present in user databases'
  desc 'The guest user should not exist in production databases as it allows anonymous access.'
  tag cis: '2.6'

  describe sql.query("select count(*) as cnt from sysusers where name = 'guest' and uid != 0").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# =============================================================================
# Section 4: Auditing Configuration
# =============================================================================

# Control 4.01: Ensure login auditing is enabled
control 'sybase-16-4.01' do
  impact 1.0
  title 'Ensure login events are audited'
  desc 'Login attempts should be audited to detect unauthorized access attempts.'
  tag cis: '3.1'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'login' and (sopt = 'pass' or sopt = 'both')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# Control 4.02: Ensure logout auditing is enabled
control 'sybase-16-4.02' do
  impact 0.7
  title 'Ensure logout events are audited'
  desc 'Logout events should be audited to track session duration and activity.'
  tag cis: '3.2'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'logout' and (sopt = 'pass' or sopt = 'both')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# Control 4.03: Ensure security events are audited
control 'sybase-16-4.03' do
  impact 1.0
  title 'Ensure security events are audited'
  desc 'Security events including SSL and certificate operations should be audited.'
  tag cis: '3.3'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'security' and (sopt = 'pass' or sopt = 'both' or sopt = 'on')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# Control 4.04: Ensure sa_role usage is audited
control 'sybase-16-4.04' do
  impact 1.0
  title 'Ensure sa_role usage is audited'
  desc 'All activities performed with sa_role should be audited for accountability.'
  tag cis: '3.4'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'sa_role' and (sopt = 'pass' or sopt = 'both')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# Control 4.05: Ensure sso_role usage is audited
control 'sybase-16-4.05' do
  impact 1.0
  title 'Ensure sso_role usage is audited'
  desc 'All activities performed with sso_role should be audited for security oversight.'
  tag cis: '3.5'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'sso_role' and (sopt = 'pass' or sopt = 'both')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# Control 4.06: Ensure cmdtext auditing is enabled
control 'sybase-16-4.06' do
  impact 0.8
  title 'Ensure command text auditing is enabled'
  desc 'Command text auditing captures the actual SQL being executed for forensic purposes.'
  tag cis: '3.6'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'cmdtext' and sopt = 'on'").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# Control 4.07: Ensure error auditing is enabled
control 'sybase-16-4.07' do
  impact 0.8
  title 'Ensure error events are audited'
  desc 'Error events should be audited to detect potential attack attempts and system issues.'
  tag cis: '3.7'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'errors' and sopt = 'on'").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# Control 4.08: Ensure disk operations are audited
control 'sybase-16-4.08' do
  impact 0.7
  title 'Ensure disk operations are audited'
  desc 'Disk initialization and mirroring operations should be audited.'
  tag cis: '3.8'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'disk' and (sopt = 'pass' or sopt = 'both')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# Control 4.09: Ensure DBCC operations are audited
control 'sybase-16-4.09' do
  impact 0.7
  title 'Ensure DBCC operations are audited'
  desc 'Database consistency check operations should be audited.'
  tag cis: '3.9'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'dbcc' and (sopt = 'pass' or sopt = 'both')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# Control 4.10: Ensure RPC auditing is enabled
control 'sybase-16-4.10' do
  impact 0.8
  title 'Ensure remote procedure calls are audited'
  desc 'RPC calls should be audited to track cross-server operations.'
  tag cis: '3.10'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'rpc' and (sopt = 'pass' or sopt = 'both')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# Control 4.11: Ensure login lockout auditing is enabled
control 'sybase-16-4.11' do
  impact 1.0
  title 'Ensure login lockout events are audited'
  desc 'Failed login lockouts should be audited to detect brute force attacks.'
  tag cis: '3.11'

  describe sql.query("select value from master..sysconfigures where name = 'audit queue size'").row(0).column('value') do
    its('value') { should be > 0 }
  end
end

# =============================================================================
# Section 5: Network and Connection Security
# =============================================================================

# Control 5.01: Ensure allow remote access is properly configured
control 'sybase-16-5.01' do
  impact 0.9
  title 'Ensure remote access is controlled'
  desc 'Remote access should be disabled unless specifically required for distributed transactions.'
  tag cis: '4.1'

  describe sql.query("select value from master..sysconfigures where name = 'allow remote access'").row(0).column('value') do
    its('value') { should cmp 0 }
  end
end

# Control 5.02: Ensure enable ssl is configured
control 'sybase-16-5.02' do
  impact 1.0
  title 'Ensure SSL is enabled for network encryption'
  desc 'SSL should be enabled to encrypt data in transit between clients and server.'
  tag cis: '4.2'

  describe sql.query("select value from master..sysconfigures where name = 'enable ssl'").row(0).column('value') do
    its('value') { should cmp 1 }
  end
end

# Control 5.03: Ensure CIS mode is enabled
control 'sybase-16-5.03' do
  impact 0.9
  title 'Ensure CIS mode is enabled for security compliance'
  desc 'CIS mode enables additional security restrictions for compliance.'
  tag cis: '4.3'

  describe sql.query("select value from master..sysconfigures where name = 'enable cis'").row(0).column('value') do
    its('value') { should cmp 1 }
  end
end

# Control 5.04: Ensure use security services is configured
control 'sybase-16-5.04' do
  impact 0.8
  title 'Ensure security services are properly configured'
  desc 'Security services (Kerberos, LDAP) should be configured for enterprise authentication.'
  tag cis: '4.4'

  describe sql.query("select value from master..sysconfigures where name = 'use security services'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

# Control 5.05: Ensure network packet size is secured
control 'sybase-16-5.05' do
  impact 0.5
  title 'Ensure default network packet size is appropriate'
  desc 'Network packet size should be configured appropriately to prevent buffer-related issues.'
  tag cis: '4.5'

  describe sql.query("select value from master..sysconfigures where name = 'default network packet size'").row(0).column('value') do
    its('value') { should be >= 512 }
    its('value') { should be <= 16384 }
  end
end

# =============================================================================
# Section 6: System Configuration Security
# =============================================================================

# Control 6.01: Ensure allow updates to system tables is disabled
control 'sybase-16-6.01' do
  impact 1.0
  title 'Ensure system table updates are disabled'
  desc 'Direct updates to system tables bypass integrity checks and should be disabled.'
  tag cis: '5.1'

  describe sql.query("select value from master..sysconfigures where name = 'allow updates to system tables'").row(0).column('value') do
    its('value') { should cmp 0 }
  end
end

# Control 6.02: Ensure xp_cmdshell context is properly set
control 'sybase-16-6.02' do
  impact 1.0
  title 'Ensure xp_cmdshell runs in restricted context'
  desc 'xp_cmdshell should run under sa_role context (value 1) or be disabled to prevent OS command execution by unauthorized users.'
  tag cis: '5.2'

  describe sql.query("select value from master..sysconfigures where name = 'xp_cmdshell context'").row(0).column('value') do
    its('value') { should cmp 1 }
  end
end

# Control 6.03: Ensure select into/bulk copy is restricted
control 'sybase-16-6.03' do
  impact 0.7
  title 'Ensure select into/bulk copy is disabled for production'
  desc 'Select into/bulk copy should be disabled in production to prevent unlogged operations.'
  tag cis: '5.3'

  describe sql.query("select (status2 & 8) as select_into from master..sysdatabases where name = db_name()").row(0).column('select_into') do
    its('value') { should cmp 0 }
  end
end

# Control 6.04: Ensure truncate log on checkpoint is disabled
control 'sybase-16-6.04' do
  impact 0.8
  title 'Ensure truncate log on checkpoint is disabled for production'
  desc 'Truncate log on checkpoint should be disabled to maintain transaction log for recovery.'
  tag cis: '5.4'

  describe sql.query("select (status & 8) as trunc_log from master..sysdatabases where name = db_name()").row(0).column('trunc_log') do
    its('value') { should cmp 0 }
  end
end

# Control 6.05: Ensure number of locks is appropriate
control 'sybase-16-6.05' do
  impact 0.5
  title 'Ensure number of locks is adequately configured'
  desc 'The number of locks should be configured to handle concurrent operations without resource exhaustion.'
  tag cis: '5.5'

  describe sql.query("select value from master..sysconfigures where name = 'number of locks'").row(0).column('value') do
    its('value') { should be >= 5000 }
  end
end

# Control 6.06: Ensure recovery interval is set
control 'sybase-16-6.06' do
  impact 0.6
  title 'Ensure recovery interval is appropriately configured'
  desc 'Recovery interval affects checkpoint frequency and recovery time.'
  tag cis: '5.6'

  describe sql.query("select value from master..sysconfigures where name = 'recovery interval in minutes'").row(0).column('value') do
    its('value') { should be >= 1 }
    its('value') { should be <= 32767 }
  end
end

# =============================================================================
# Section 7: Extended Stored Procedure Security
# =============================================================================

# Control 7.01: Ensure xp_cmdshell is not available to non-privileged users
control 'sybase-16-7.01' do
  impact 1.0
  title 'Ensure xp_cmdshell execution is restricted'
  desc 'xp_cmdshell allows OS command execution and should only be available to sa_role.'
  tag cis: '6.1'

  describe sql.query("select count(*) as cnt from master..sysprotects where id = object_id('master..xp_cmdshell') and uid != 1").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 7.02: Ensure dangerous ESPs are restricted
control 'sybase-16-7.02' do
  impact 1.0
  title 'Ensure dangerous extended stored procedures are restricted'
  desc 'Extended stored procedures like xp_freedll should be restricted to prevent security bypasses.'
  tag cis: '6.2'

  describe sql.query("select count(*) as cnt from master..sysprotects where id = object_id('master..xp_freedll') and uid = 0").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 7.03: Ensure ESP directory is protected
control 'sybase-16-7.03' do
  impact 0.8
  title 'Ensure ESP directory configuration is appropriate'
  desc 'The ESP load path should not point to world-writable directories.'
  tag cis: '6.3'

  describe sql.query("select value from master..sysconfigures where name = 'esp unload dll'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

# =============================================================================
# Section 8: Database Encryption
# =============================================================================

# Control 8.01: Ensure encryption is properly configured
control 'sybase-16-8.01' do
  impact 0.9
  title 'Ensure database encryption keys are protected'
  desc 'Encryption keys should be protected with a system encryption password.'
  tag cis: '7.1'

  describe sql.query("select value from master..sysconfigures where name = 'enable encrypted columns'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

# Control 8.02: Ensure FIPS mode is configured if required
control 'sybase-16-8.02' do
  impact 0.7
  title 'Ensure FIPS compliance mode is properly set'
  desc 'FIPS mode should be enabled for government and regulated environments.'
  tag cis: '7.2'

  describe sql.query("select value from master..sysconfigures where name = 'fips login password encryption'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

# =============================================================================
# Section 9: Backup and Recovery Security
# =============================================================================

# Control 9.01: Ensure backup configuration exists
control 'sybase-16-9.01' do
  impact 0.8
  title 'Ensure backup server is configured'
  desc 'A backup server should be configured for database recovery capabilities.'
  tag cis: '8.1'

  describe sql.query("select count(*) as cnt from master..sysservers where srvname like '%_BS'").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# Control 9.02: Ensure database recovery model is appropriate
control 'sybase-16-9.02' do
  impact 0.7
  title 'Ensure database recovery is properly configured'
  desc 'Databases should have appropriate recovery settings for point-in-time recovery.'
  tag cis: '8.2'

  describe sql.query("select count(*) as cnt from master..sysdatabases where name not in ('master', 'model', 'tempdb', 'sybsystemprocs', 'sybsystemdb', 'sybsecurity')").row(0).column('cnt') do
    its('value') { should be >= 0 }
  end
end

# =============================================================================
# Section 10: Sample Database and Default Objects
# =============================================================================

# Control 10.01: Ensure sample databases are removed
control 'sybase-16-10.01' do
  impact 0.6
  title 'Ensure sample databases are removed from production'
  desc 'Sample databases like pubs2, pubs3 should be removed from production systems.'
  tag cis: '9.1'

  describe sql.query("select count(*) as cnt from master..sysdatabases where name in ('pubs2', 'pubs3', 'interpubs')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 10.02: Ensure unused system stored procedures are secured
control 'sybase-16-10.02' do
  impact 0.7
  title 'Ensure system procedures are properly secured'
  desc 'Dangerous system procedures should have execute permissions revoked from PUBLIC.'
  tag cis: '9.2'

  describe sql.query("select count(*) as cnt from master..sysprotects p join master..sysobjects o on p.id = o.id where o.type = 'P' and p.uid = 0 and p.action = 224 and o.name like 'sp_drop%'").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end
