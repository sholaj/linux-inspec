# Sybase ASE 16 InSpec Control - trusted.rb
# CIS Sybase ASE 16 Compliance Controls
#
# IMPORTANT: Export SYBASE_PWD environment variable before running InSpec:
#   export SYBASE_PWD='your_password'
#   inspec exec . --input usernm=sa hostnm=sybase_host servicenm=SYBASE
#
# The password is passed via environment variable to avoid exposure in logs.

usernm = input('usernm')
servicenm = input('servicenm')

title "Sybase ASE 16 Database Security Compliance Controls"

# Control 01: Ensure server is running and accessible
control 'sybase-16-01' do
  impact 1.0
  title 'Ensure Sybase ASE server is accessible'
  desc 'Sybase ASE server should be running and accessible for connections'

  describe command("sybase_query #{usernm} #{servicenm} 'select @@servername'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should_not be_empty }
  end
end

# Control 02: Check server version and ensure it's supported
control 'sybase-16-02' do
  impact 0.8
  title 'Verify Sybase ASE version information'
  desc 'Sybase ASE should report correct version information'

  describe command("sybase_query #{usernm} #{servicenm} 'select @@version'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/Adaptive Server Enterprise/) }
  end
end

# Control 03: Ensure auditing is enabled
control 'sybase-16-03' do
  impact 1.0
  title 'Ensure Sybase ASE auditing is enabled'
  desc 'Sybase ASE should have auditing enabled for security compliance'

  describe command("sybase_query #{usernm} #{servicenm} 'select name, value from master..sysconfigures where name like \"%audit%\"'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should_not match(/auditing.*0/) }
  end
end

# Control 04: Check for default passwords
control 'sybase-16-04' do
  impact 1.0
  title 'Ensure no default passwords are in use'
  desc 'Sybase ASE should not have accounts with default or empty passwords'

  describe command("sybase_query #{usernm} #{servicenm} 'select name from master..syslogins where password is null or password = \"\"'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should_not match(/sa|probe|guest/) }
  end
end

# Control 05: Ensure remote access is properly configured
control 'sybase-16-05' do
  impact 0.8
  title 'Verify remote access configuration'
  desc 'Sybase ASE remote access should be properly configured'

  describe command("sybase_query #{usernm} #{servicenm} 'select name, value from master..sysconfigures where name = \"allow remote access\"'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/allow remote access/) }
  end
end

# Control 06: Check system table permissions
control 'sybase-16-06' do
  impact 1.0
  title 'Ensure system table access is restricted'
  desc 'Sybase ASE system tables should have proper access controls'

  describe command("sybase_query #{usernm} #{servicenm} 'select name, value from master..sysconfigures where name = \"allow updates to system tables\"'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/allow updates to system tables.*0/) }
  end
end
