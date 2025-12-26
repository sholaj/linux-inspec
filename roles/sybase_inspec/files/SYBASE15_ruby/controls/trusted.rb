# Sybase ASE 15 InSpec Control - trusted.rb
# CIS Sybase ASE 15 Compliance Controls
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

title "Sybase ASE 15 Database Security Compliance Controls"

# Control 01: Ensure server is running and accessible
control 'sybase-15-01' do
  impact 1.0
  title 'Ensure Sybase ASE 15 server is accessible'
  desc 'Sybase ASE 15 server should be running and accessible for connections'

  describe sql.query('select @@servername as servername').row(0).column('servername') do
    its('value') { should_not be_nil }
  end
end

# Control 02: Check server version (ASE 15 specific)
control 'sybase-15-02' do
  impact 0.8
  title 'Verify Sybase ASE 15 version information'
  desc 'Sybase ASE should report version 15.x information'

  describe sql.query('select @@version as version').row(0).column('version') do
    its('value') { should match(/Adaptive Server Enterprise\/15/) }
  end
end

# Control 03: Ensure auditing is enabled (ASE 15 specific)
control 'sybase-15-03' do
  impact 1.0
  title 'Ensure Sybase ASE 15 auditing is enabled'
  desc 'Sybase ASE 15 should have auditing enabled for security compliance'

  describe sql.query("select value from master..sysconfigures where name = 'auditing'").row(0).column('value') do
    its('value') { should cmp 1 }
  end
end

# Control 04: Check login security (ASE 15)
control 'sybase-15-04' do
  impact 1.0
  title 'Ensure secure login configuration'
  desc 'Sybase ASE 15 should have secure login policies configured'

  describe sql.query("select count(*) as cnt from master..syslogins where password is null and name in ('sa', 'probe', 'guest')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 05: Check network security (ASE 15)
control 'sybase-15-05' do
  impact 0.8
  title 'Verify network security configuration'
  desc 'Sybase ASE 15 network security should be properly configured'

  describe sql.query("select value from master..sysconfigures where name = 'net password encryption reqd'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

# Control 06: Check system table permissions
control 'sybase-15-06' do
  impact 1.0
  title 'Ensure system table access is restricted'
  desc 'Sybase ASE 15 system tables should have proper access controls'

  describe sql.query("select value from master..sysconfigures where name = 'allow updates to system tables'").row(0).column('value') do
    its('value') { should cmp 0 }
  end
end

# Control 07: Check for remote access configuration
control 'sybase-15-07' do
  impact 0.8
  title 'Verify remote access is properly configured'
  desc 'Sybase ASE 15 remote access should be properly configured'

  describe sql.query("select value from master..sysconfigures where name = 'allow remote access'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end
