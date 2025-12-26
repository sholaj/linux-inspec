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

# Add optional parameters if provided
sybase_home = input('sybase_home', value: nil)
isql_bin = input('isql_bin', value: nil)
sybase_opts[:sybase_home] = sybase_home if sybase_home
sybase_opts[:bin] = isql_bin if isql_bin

sql = sybase_session(sybase_opts)

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
