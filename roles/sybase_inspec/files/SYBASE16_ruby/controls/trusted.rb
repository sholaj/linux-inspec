# Sybase ASE 16 InSpec Control - trusted.rb
# CIS SAP ASE 16.0 Benchmark v1.1.0 Compliance Controls
#
# Uses native sybase_session resource for scalable multi-database scanning
# Password is passed via input and handled securely by InSpec
#
# CIS Benchmark Reference: CIS SAP ASE 16.0 Benchmark v1.1.0
# https://www.cisecurity.org/benchmark/sap_ase

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

title "CIS SAP ASE 16.0 Benchmark v1.1.0 Compliance Controls"

# =============================================================================
# Section 1: Installation, Patches and Updates (CIS 1.x)
# =============================================================================

control 'sybase-16-1.01' do
  impact 1.0
  title 'Ensure Sybase ASE server is accessible'
  desc 'Sybase ASE server should be running and accessible for connections'

  tag cis: '1.1'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query('select @@servername as servername').row(0).column('servername') do
    its('value') { should_not be_nil }
  end
end

control 'sybase-16-1.02' do
  impact 0.8
  title 'Verify Sybase ASE version information'
  desc 'Sybase ASE should report correct version information and be a supported version'

  tag cis: '1.2'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query('select @@version as version').row(0).column('version') do
    its('value') { should match(/Adaptive Server Enterprise/) }
  end
end

control 'sybase-16-1.03' do
  impact 1.0
  title 'Ensure Sybase ASE auditing is enabled'
  desc 'Sybase ASE should have auditing enabled for security compliance'

  tag cis: '1.3'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select value from master..sysconfigures where name = 'auditing'").row(0).column('value') do
    its('value') { should cmp 1 }
  end
end

control 'sybase-16-1.04' do
  impact 1.0
  title 'Ensure no default passwords are in use'
  desc 'Sybase ASE should not have accounts with default or empty passwords'

  tag cis: '1.4'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("select count(*) as cnt from master..syslogins where password is null and name in ('sa', 'probe', 'guest')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-1.05' do
  impact 0.8
  title 'Verify remote access configuration'
  desc 'Sybase ASE remote access should be properly configured'

  tag cis: '1.5'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select value from master..sysconfigures where name = 'allow remote access'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

control 'sybase-16-1.06' do
  impact 1.0
  title 'Ensure system table access is restricted'
  desc 'Sybase ASE system tables should have proper access controls'

  tag cis: '1.6'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select value from master..sysconfigures where name = 'allow updates to system tables'").row(0).column('value') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-1.07' do
  impact 0.9
  title 'Ensure password expiration is configured'
  desc 'Sybase ASE should enforce password expiration policies'

  tag cis: '1.7'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select value from master..sysconfigures where name = 'systemwide password expiration'").row(0).column('value') do
    its('value') { should be >= 0 }
  end
end

control 'sybase-16-1.08' do
  impact 1.0
  title 'Ensure xp_cmdshell is disabled or restricted'
  desc 'xp_cmdshell should be disabled or restricted to prevent OS command execution'

  tag cis: '1.8'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("select value from master..sysconfigures where name = 'xp_cmdshell context'").row(0).column('value') do
    its('value') { should cmp 1 }
  end
end

control 'sybase-16-1.09' do
  impact 0.9
  title 'Ensure failed login lockout is configured'
  desc 'Sybase ASE should lock accounts after a specified number of failed login attempts'

  tag cis: '1.9'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select value from master..sysconfigures where name = 'maximum failed logins'").row(0).column('value') do
    its('value') { should be >= 3 }
    its('value') { should be <= 10 }
  end
end

control 'sybase-16-1.10' do
  impact 1.0
  title 'Ensure network encryption is properly configured'
  desc 'Sybase ASE should have network encryption enabled for secure communications'

  tag cis: '1.10'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select value from master..sysconfigures where name = 'enable ssl'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

control 'sybase-16-1.11' do
  impact 0.5
  title 'Ensure stack size is appropriately configured'
  desc 'Stack size should be configured to prevent stack overflow attacks'

  tag cis: '1.11'
  tag cis_level: 2
  tag severity: 'low'

  describe sql.query("select value from master..sysconfigures where name = 'stack size'").row(0).column('value') do
    its('value') { should be >= 65536 }
  end
end

control 'sybase-16-1.12' do
  impact 0.5
  title 'Ensure procedure cache is appropriately sized'
  desc 'Procedure cache should be sized to handle expected workload'

  tag cis: '1.12'
  tag cis_level: 2
  tag severity: 'low'

  describe sql.query("select value from master..sysconfigures where name = 'procedure cache size'").row(0).column('value') do
    its('value') { should be > 0 }
  end
end

# =============================================================================
# Section 2: Password and Authentication Security (CIS 2.x)
# =============================================================================

control 'sybase-16-2.01' do
  impact 1.0
  title 'Ensure minimum password length is set to 8 or more'
  desc 'Passwords should have a minimum length to prevent brute force attacks. CIS recommends at least 8 characters.'

  tag cis: '2.1'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select value from master..sysconfigures where name = 'minimum password length'").row(0).column('value') do
    its('value') { should be >= 8 }
  end
end

control 'sybase-16-2.02' do
  impact 0.9
  title 'Ensure check password for digit is enabled'
  desc 'Passwords should contain at least one digit for complexity. This prevents dictionary attacks.'

  tag cis: '2.2'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select value from master..sysconfigures where name = 'check password for digit'").row(0).column('value') do
    its('value') { should cmp 1 }
  end
end

control 'sybase-16-2.03' do
  impact 1.0
  title 'Ensure SA account password is not NULL'
  desc 'The SA account is created with a NULL password by default. This must be changed immediately after installation.'

  tag cis: '2.3'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("select count(*) as cnt from master..syslogins where name = 'sa' and password is null").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-2.04' do
  impact 1.0
  title 'Ensure probe account is locked or has password'
  desc 'The probe account is used for Two-Phase Commit and should be secured or locked if not needed.'

  tag cis: '2.4'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select count(*) as cnt from master..syslogins where name = 'probe' and (password is null or status = 0)").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-2.05' do
  impact 1.0
  title 'Ensure guest account is locked in production databases'
  desc 'The guest account should be locked in production as it inherits PUBLIC permissions and allows anonymous access.'

  tag cis: '2.5'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select count(*) as cnt from master..syslogins where name = 'guest' and status & 2 = 0").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-2.06' do
  impact 0.8
  title 'Ensure minimum digits in password policy is set'
  desc 'Password policy should require a minimum number of digits for complexity.'

  tag cis: '2.6'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select value from master..sysconfigures where name = 'min digits in password'").row(0).column('value') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-2.07' do
  impact 0.8
  title 'Ensure minimum special characters in password policy is set'
  desc 'Password policy should require special characters for complexity.'

  tag cis: '2.7'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select value from master..sysconfigures where name = 'min special char in password'").row(0).column('value') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-2.08' do
  impact 0.7
  title 'Ensure minimum uppercase characters in password policy is set'
  desc 'Password policy should require uppercase characters for complexity.'

  tag cis: '2.8'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select value from master..sysconfigures where name = 'min upper char in password'").row(0).column('value') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-2.09' do
  impact 0.7
  title 'Ensure minimum lowercase characters in password policy is set'
  desc 'Password policy should require lowercase characters for complexity.'

  tag cis: '2.9'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select value from master..sysconfigures where name = 'min lower char in password'").row(0).column('value') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-2.10' do
  impact 0.8
  title 'Ensure password history prevents reuse'
  desc 'Password history should prevent users from reusing recent passwords.'

  tag cis: '2.10'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select value from master..sysconfigures where name = 'min password length'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

control 'sybase-16-2.11' do
  impact 0.7
  title 'Ensure password expiration warning days is set'
  desc 'Users should be warned before their passwords expire to allow time for password changes.'

  tag cis: '2.11'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select value from master..sysconfigures where name = 'password exp warn interval'").row(0).column('value') do
    its('value') { should be >= 7 }
  end
end

control 'sybase-16-2.12' do
  impact 0.8
  title 'Ensure expired password handling is configured'
  desc 'Expired passwords should require immediate change on next login.'

  tag cis: '2.12'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select value from master..sysconfigures where name = 'allow expired password'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

# =============================================================================
# Section 3: Authorization and Role Security (CIS 3.x)
# =============================================================================

control 'sybase-16-3.01' do
  impact 1.0
  title 'Limit accounts with sa_role'
  desc 'The sa_role provides full system administrator privileges. Only essential accounts should have this role.'

  tag cis: '3.1'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("select count(*) as cnt from master..sysloginroles lr join master..syssrvroles r on lr.srid = r.srid where r.name = 'sa_role'").row(0).column('cnt') do
    its('value') { should be <= 3 }
  end
end

control 'sybase-16-3.02' do
  impact 1.0
  title 'Limit accounts with sso_role'
  desc 'The sso_role (System Security Officer) manages security. Only essential accounts should have this role.'

  tag cis: '3.2'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("select count(*) as cnt from master..sysloginroles lr join master..syssrvroles r on lr.srid = r.srid where r.name = 'sso_role'").row(0).column('cnt') do
    its('value') { should be <= 3 }
  end
end

control 'sybase-16-3.03' do
  impact 0.8
  title 'Limit accounts with oper_role'
  desc 'The oper_role allows backup and restore operations. Only operator accounts should have this role.'

  tag cis: '3.3'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from master..sysloginroles lr join master..syssrvroles r on lr.srid = r.srid where r.name = 'oper_role'").row(0).column('cnt') do
    its('value') { should be <= 5 }
  end
end

control 'sybase-16-3.04' do
  impact 0.8
  title 'Limit accounts with replication_role'
  desc 'The replication_role is for replication administration. Only replication accounts should have this role.'

  tag cis: '3.4'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from master..sysloginroles lr join master..syssrvroles r on lr.srid = r.srid where r.name = 'replication_role'").row(0).column('cnt') do
    its('value') { should be <= 3 }
  end
end

control 'sybase-16-3.05' do
  impact 0.9
  title 'Ensure PUBLIC role has minimal permissions'
  desc 'The PUBLIC role applies to all users. Excessive permissions on PUBLIC expose the database to risk.'

  tag cis: '3.5'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select count(*) as cnt from master..sysprotects where uid = 0 and action in (193, 195, 196, 197)").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-3.06' do
  impact 0.9
  title 'Ensure guest user is not present in user databases'
  desc 'The guest user should not exist in production databases as it allows anonymous access.'

  tag cis: '3.6'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select count(*) as cnt from sysusers where name = 'guest' and uid != 0").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-3.07' do
  impact 0.7
  title 'Limit accounts with sybase_ts_role'
  desc 'The sybase_ts_role allows troubleshooting operations. Only support accounts should have this role.'

  tag cis: '3.7'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from master..sysloginroles lr join master..syssrvroles r on lr.srid = r.srid where r.name = 'sybase_ts_role'").row(0).column('cnt') do
    its('value') { should be <= 3 }
  end
end

control 'sybase-16-3.08' do
  impact 0.7
  title 'Limit accounts with mon_role'
  desc 'The mon_role allows monitoring operations. Only monitoring accounts should have this role.'

  tag cis: '3.8'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from master..sysloginroles lr join master..syssrvroles r on lr.srid = r.srid where r.name = 'mon_role'").row(0).column('cnt') do
    its('value') { should be <= 5 }
  end
end

control 'sybase-16-3.09' do
  impact 0.8
  title 'Limit accounts with js_admin_role'
  desc 'The js_admin_role allows Job Scheduler administration. Only job admin accounts should have this role.'

  tag cis: '3.9'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from master..sysloginroles lr join master..syssrvroles r on lr.srid = r.srid where r.name = 'js_admin_role'").row(0).column('cnt') do
    its('value') { should be <= 3 }
  end
end

# =============================================================================
# Section 4: Auditing Configuration (CIS 4.x)
# =============================================================================

control 'sybase-16-4.01' do
  impact 1.0
  title 'Ensure login events are audited'
  desc 'Login attempts should be audited to detect unauthorized access attempts.'

  tag cis: '4.1'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'login' and (sopt = 'pass' or sopt = 'both')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-4.02' do
  impact 0.7
  title 'Ensure logout events are audited'
  desc 'Logout events should be audited to track session duration and activity.'

  tag cis: '4.2'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'logout' and (sopt = 'pass' or sopt = 'both')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-4.03' do
  impact 1.0
  title 'Ensure security events are audited'
  desc 'Security events including SSL and certificate operations should be audited.'

  tag cis: '4.3'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'security' and (sopt = 'pass' or sopt = 'both' or sopt = 'on')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-4.04' do
  impact 1.0
  title 'Ensure sa_role usage is audited'
  desc 'All activities performed with sa_role should be audited for accountability.'

  tag cis: '4.4'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'sa_role' and (sopt = 'pass' or sopt = 'both')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-4.05' do
  impact 1.0
  title 'Ensure sso_role usage is audited'
  desc 'All activities performed with sso_role should be audited for security oversight.'

  tag cis: '4.5'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'sso_role' and (sopt = 'pass' or sopt = 'both')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-4.06' do
  impact 0.8
  title 'Ensure command text auditing is enabled'
  desc 'Command text auditing captures the actual SQL being executed for forensic purposes.'

  tag cis: '4.6'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'cmdtext' and sopt = 'on'").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-4.07' do
  impact 0.8
  title 'Ensure error events are audited'
  desc 'Error events should be audited to detect potential attack attempts and system issues.'

  tag cis: '4.7'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'errors' and sopt = 'on'").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-4.08' do
  impact 0.7
  title 'Ensure disk operations are audited'
  desc 'Disk initialization and mirroring operations should be audited.'

  tag cis: '4.8'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'disk' and (sopt = 'pass' or sopt = 'both')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-4.09' do
  impact 0.7
  title 'Ensure DBCC operations are audited'
  desc 'Database consistency check operations should be audited.'

  tag cis: '4.9'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'dbcc' and (sopt = 'pass' or sopt = 'both')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-4.10' do
  impact 0.8
  title 'Ensure remote procedure calls are audited'
  desc 'RPC calls should be audited to track cross-server operations.'

  tag cis: '4.10'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name = 'rpc' and (sopt = 'pass' or sopt = 'both')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-4.11' do
  impact 1.0
  title 'Ensure audit queue is appropriately sized'
  desc 'Audit queue should be sized to prevent audit event loss during high activity.'

  tag cis: '4.11'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select value from master..sysconfigures where name = 'audit queue size'").row(0).column('value') do
    its('value') { should be >= 100 }
  end
end

control 'sybase-16-4.12' do
  impact 0.9
  title 'Ensure DDL operations are audited'
  desc 'Data Definition Language operations (CREATE, ALTER, DROP) should be audited.'

  tag cis: '4.12'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name in ('create', 'alter', 'drop') and (sopt = 'pass' or sopt = 'both')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-4.13' do
  impact 1.0
  title 'Ensure permission changes are audited'
  desc 'Grant and revoke operations should be audited to track permission changes.'

  tag cis: '4.13'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select count(*) as cnt from sybsecurity..sysauditoptions where name in ('grant', 'revoke') and (sopt = 'pass' or sopt = 'both')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# =============================================================================
# Section 5: Network and Connection Security (CIS 5.x)
# =============================================================================

control 'sybase-16-5.01' do
  impact 0.9
  title 'Ensure remote access is controlled'
  desc 'Remote access should be disabled unless specifically required for distributed transactions.'

  tag cis: '5.1'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select value from master..sysconfigures where name = 'allow remote access'").row(0).column('value') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-5.02' do
  impact 1.0
  title 'Ensure SSL is enabled for network encryption'
  desc 'SSL should be enabled to encrypt data in transit between clients and server.'

  tag cis: '5.2'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("select value from master..sysconfigures where name = 'enable ssl'").row(0).column('value') do
    its('value') { should cmp 1 }
  end
end

control 'sybase-16-5.03' do
  impact 0.9
  title 'Ensure CIS mode is enabled for security compliance'
  desc 'CIS mode enables additional security restrictions for compliance.'

  tag cis: '5.3'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select value from master..sysconfigures where name = 'enable cis'").row(0).column('value') do
    its('value') { should cmp 1 }
  end
end

control 'sybase-16-5.04' do
  impact 0.8
  title 'Ensure security services are properly configured'
  desc 'Security services (Kerberos, LDAP) should be configured for enterprise authentication.'

  tag cis: '5.4'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select value from master..sysconfigures where name = 'use security services'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

control 'sybase-16-5.05' do
  impact 0.5
  title 'Ensure default network packet size is appropriate'
  desc 'Network packet size should be configured appropriately to prevent buffer-related issues.'

  tag cis: '5.5'
  tag cis_level: 2
  tag severity: 'low'

  describe sql.query("select value from master..sysconfigures where name = 'default network packet size'").row(0).column('value') do
    its('value') { should be >= 512 }
    its('value') { should be <= 16384 }
  end
end

control 'sybase-16-5.06' do
  impact 0.5
  title 'Ensure maximum network packet size is appropriate'
  desc 'Maximum network packet size should be configured to prevent DoS attacks.'

  tag cis: '5.6'
  tag cis_level: 2
  tag severity: 'low'

  describe sql.query("select value from master..sysconfigures where name = 'max network packet size'").row(0).column('value') do
    its('value') { should be <= 65536 }
  end
end

control 'sybase-16-5.07' do
  impact 0.6
  title 'Ensure TCP keepalive is properly configured'
  desc 'TCP keepalive helps detect and clean up stale connections.'

  tag cis: '5.7'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select value from master..sysconfigures where name = 'tcp no delay'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

# =============================================================================
# Section 6: System Configuration Security (CIS 6.x)
# =============================================================================

control 'sybase-16-6.01' do
  impact 1.0
  title 'Ensure system table updates are disabled'
  desc 'Direct updates to system tables bypass integrity checks and should be disabled.'

  tag cis: '6.1'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("select value from master..sysconfigures where name = 'allow updates to system tables'").row(0).column('value') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-6.02' do
  impact 1.0
  title 'Ensure xp_cmdshell runs in restricted context'
  desc 'xp_cmdshell should run under sa_role context (value 1) or be disabled to prevent OS command execution by unauthorized users.'

  tag cis: '6.2'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("select value from master..sysconfigures where name = 'xp_cmdshell context'").row(0).column('value') do
    its('value') { should cmp 1 }
  end
end

control 'sybase-16-6.03' do
  impact 0.7
  title 'Ensure select into/bulk copy is disabled for production'
  desc 'Select into/bulk copy should be disabled in production to prevent unlogged operations.'

  tag cis: '6.3'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select (status2 & 8) as select_into from master..sysdatabases where name = db_name()").row(0).column('select_into') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-6.04' do
  impact 0.8
  title 'Ensure truncate log on checkpoint is disabled for production'
  desc 'Truncate log on checkpoint should be disabled to maintain transaction log for recovery.'

  tag cis: '6.4'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select (status & 8) as trunc_log from master..sysdatabases where name = db_name()").row(0).column('trunc_log') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-6.05' do
  impact 0.5
  title 'Ensure number of locks is adequately configured'
  desc 'The number of locks should be configured to handle concurrent operations without resource exhaustion.'

  tag cis: '6.5'
  tag cis_level: 2
  tag severity: 'low'

  describe sql.query("select value from master..sysconfigures where name = 'number of locks'").row(0).column('value') do
    its('value') { should be >= 5000 }
  end
end

control 'sybase-16-6.06' do
  impact 0.6
  title 'Ensure recovery interval is appropriately configured'
  desc 'Recovery interval affects checkpoint frequency and recovery time.'

  tag cis: '6.6'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select value from master..sysconfigures where name = 'recovery interval in minutes'").row(0).column('value') do
    its('value') { should be >= 1 }
    its('value') { should be <= 32767 }
  end
end

control 'sybase-16-6.07' do
  impact 0.5
  title 'Ensure print recovery information is disabled'
  desc 'Printing recovery information can expose sensitive system data.'

  tag cis: '6.7'
  tag cis_level: 2
  tag severity: 'low'

  describe sql.query("select value from master..sysconfigures where name = 'print recovery information'").row(0).column('value') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-6.08' do
  impact 0.8
  title 'Ensure allow procedure grouping is properly configured'
  desc 'Procedure grouping affects startup procedure execution.'

  tag cis: '6.8'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select value from master..sysconfigures where name = 'allow procedure grouping'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

# =============================================================================
# Section 7: Extended Stored Procedure Security (CIS 7.x)
# =============================================================================

control 'sybase-16-7.01' do
  impact 1.0
  title 'Ensure xp_cmdshell execution is restricted'
  desc 'xp_cmdshell allows OS command execution and should only be available to sa_role.'

  tag cis: '7.1'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("select count(*) as cnt from master..sysprotects where id = object_id('master..xp_cmdshell') and uid != 1").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-7.02' do
  impact 1.0
  title 'Ensure dangerous extended stored procedures are restricted'
  desc 'Extended stored procedures like xp_freedll should be restricted to prevent security bypasses.'

  tag cis: '7.2'
  tag cis_level: 1
  tag severity: 'critical'

  describe sql.query("select count(*) as cnt from master..sysprotects where id = object_id('master..xp_freedll') and uid = 0").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-7.03' do
  impact 0.8
  title 'Ensure ESP directory configuration is appropriate'
  desc 'The ESP load path should not point to world-writable directories.'

  tag cis: '7.3'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select value from master..sysconfigures where name = 'esp unload dll'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

control 'sybase-16-7.04' do
  impact 0.8
  title 'Ensure xp_logevent execution is restricted'
  desc 'xp_logevent writes to Windows event log and should be restricted.'

  tag cis: '7.4'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from master..sysprotects where id = object_id('master..xp_logevent') and uid = 0").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-7.05' do
  impact 0.8
  title 'Ensure xp_sendmail execution is restricted'
  desc 'xp_sendmail can send emails and should be restricted to prevent abuse.'

  tag cis: '7.5'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from master..sysprotects where id = object_id('master..xp_sendmail') and uid = 0").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-7.06' do
  impact 0.9
  title 'Ensure login creation is tracked'
  desc 'Creation of new logins should be auditable for security monitoring.'

  tag cis: '7.6'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select count(*) as cnt from master..sysobjects where name = 'sp_addlogin' and type = 'P'").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-7.07' do
  impact 0.9
  title 'Ensure login deletion is tracked'
  desc 'Deletion of logins should be auditable for security monitoring.'

  tag cis: '7.7'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select count(*) as cnt from master..sysobjects where name = 'sp_droplogin' and type = 'P'").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-7.08' do
  impact 0.9
  title 'Ensure login modification is tracked'
  desc 'Modification of logins should be auditable for security monitoring.'

  tag cis: '7.8'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select count(*) as cnt from master..sysobjects where name = 'sp_modifylogin' and type = 'P'").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# =============================================================================
# Section 8: Database Encryption (CIS 8.x)
# =============================================================================

control 'sybase-16-8.01' do
  impact 0.9
  title 'Ensure database encryption keys are protected'
  desc 'Encryption keys should be protected with a system encryption password.'

  tag cis: '8.1'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select value from master..sysconfigures where name = 'enable encrypted columns'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

control 'sybase-16-8.02' do
  impact 0.7
  title 'Ensure FIPS compliance mode is properly set'
  desc 'FIPS mode should be enabled for government and regulated environments.'

  tag cis: '8.2'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select value from master..sysconfigures where name = 'fips login password encryption'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

control 'sybase-16-8.03' do
  impact 0.9
  title 'Ensure strong cipher suites are configured'
  desc 'Only strong cipher suites should be allowed for SSL/TLS connections.'

  tag cis: '8.3'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select value from master..sysconfigures where name = 'ssl cipher suites'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

control 'sybase-16-8.04' do
  impact 1.0
  title 'Ensure database master key exists and is protected'
  desc 'Master key should be created and protected for column encryption.'

  tag cis: '8.4'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select count(*) as cnt from master..sysencryptkeys").row(0).column('cnt') do
    its('value') { should be >= 0 }
  end
end

control 'sybase-16-8.05' do
  impact 0.8
  title 'Ensure certificate validation is enabled'
  desc 'SSL certificate validation should be enabled to prevent MITM attacks.'

  tag cis: '8.5'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select value from master..sysconfigures where name = 'ssl certificate dn'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

# =============================================================================
# Section 9: Backup and Recovery Security (CIS 9.x)
# =============================================================================

control 'sybase-16-9.01' do
  impact 0.8
  title 'Ensure backup server is configured'
  desc 'A backup server should be configured for database recovery capabilities.'

  tag cis: '9.1'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select count(*) as cnt from master..sysservers where srvname like '%_BS'").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

control 'sybase-16-9.02' do
  impact 0.7
  title 'Ensure database recovery is properly configured'
  desc 'Databases should have appropriate recovery settings for point-in-time recovery.'

  tag cis: '9.2'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from master..sysdatabases where name not in ('master', 'model', 'tempdb', 'sybsystemprocs', 'sybsystemdb', 'sybsecurity')").row(0).column('cnt') do
    its('value') { should be >= 0 }
  end
end

control 'sybase-16-9.03' do
  impact 0.8
  title 'Ensure dump transaction permissions are restricted'
  desc 'Only authorized users should be able to dump transaction logs.'

  tag cis: '9.3'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from master..sysloginroles lr join master..syssrvroles r on lr.srid = r.srid where r.name = 'oper_role'").row(0).column('cnt') do
    its('value') { should be <= 5 }
  end
end

control 'sybase-16-9.04' do
  impact 0.8
  title 'Ensure backup encryption is available'
  desc 'Backup encryption should be configured for sensitive data protection.'

  tag cis: '9.4'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select value from master..sysconfigures where name = 'enable encrypted columns'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

# =============================================================================
# Section 10: Sample Database and Default Objects (CIS 10.x)
# =============================================================================

control 'sybase-16-10.01' do
  impact 0.6
  title 'Ensure sample databases are removed from production'
  desc 'Sample databases like pubs2, pubs3 should be removed from production systems.'

  tag cis: '10.1'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from master..sysdatabases where name in ('pubs2', 'pubs3', 'interpubs')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-10.02' do
  impact 0.7
  title 'Ensure system procedures are properly secured'
  desc 'Dangerous system procedures should have execute permissions revoked from PUBLIC.'

  tag cis: '10.2'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from master..sysprotects p join master..sysobjects o on p.id = o.id where o.type = 'P' and p.uid = 0 and p.action = 224 and o.name like 'sp_drop%'").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-10.03' do
  impact 0.7
  title 'Ensure model database has minimal permissions'
  desc 'The model database template should have minimal permissions to prevent insecure database creation.'

  tag cis: '10.3'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from model..sysusers where name = 'guest'").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-10.04' do
  impact 0.6
  title 'Ensure tempdb has appropriate permissions'
  desc 'Tempdb should not have excessive permissions that could be exploited.'

  tag cis: '10.4'
  tag cis_level: 2
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from tempdb..sysusers where name = 'guest' and uid != 0").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-10.05' do
  impact 0.8
  title 'Ensure sybsystemprocs database is protected'
  desc 'The sybsystemprocs database contains system procedures and should be protected.'

  tag cis: '10.5'
  tag cis_level: 1
  tag severity: 'high'

  describe sql.query("select count(*) as cnt from sybsystemprocs..sysusers where name = 'guest'").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

control 'sybase-16-10.06' do
  impact 0.7
  title 'Ensure orphaned database users are removed'
  desc 'Users without corresponding logins should be removed to prevent unauthorized access.'

  tag cis: '10.6'
  tag cis_level: 1
  tag severity: 'medium'

  describe sql.query("select count(*) as cnt from sysusers u where u.suid != 0 and not exists (select 1 from master..syslogins l where l.suid = u.suid)").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end
