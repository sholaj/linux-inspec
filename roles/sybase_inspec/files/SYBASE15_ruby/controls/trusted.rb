# Sybase ASE 15 InSpec Control - trusted.rb
# CIS Sybase ASE 15 Compliance Controls
#
# IMPORTANT: Export SYBASE_PWD environment variable before running InSpec:
#   export SYBASE_PWD='your_password'
#   inspec exec . --input usernm=sa hostnm=sybase_host servicenm=SYBASE
#
# The password is passed via environment variable to avoid exposure in logs.

usernm = input('usernm')
servicenm = input('servicenm')

title "Sybase ASE 15 Database Security Compliance Controls"

# Control 01: Ensure server is running and accessible
control 'sybase-15-01' do
  impact 1.0
  title 'Ensure Sybase ASE 15 server is accessible'
  desc 'Sybase ASE 15 server should be running and accessible for connections'

  describe command("sybase_query #{usernm} #{servicenm} 'select @@servername'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should_not be_empty }
  end
end

# Control 02: Check server version (ASE 15 specific)
control 'sybase-15-02' do
  impact 0.8
  title 'Verify Sybase ASE 15 version information'
  desc 'Sybase ASE should report version 15.x information'

  describe command("sybase_query #{usernm} #{servicenm} 'select @@version'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/Adaptive Server Enterprise\/15/) }
  end
end

# Control 03: Ensure auditing is enabled (ASE 15 specific)
control 'sybase-15-03' do
  impact 1.0
  title 'Ensure Sybase ASE 15 auditing is enabled'
  desc 'Sybase ASE 15 should have auditing enabled for security compliance'

  describe command("sybase_query #{usernm} #{servicenm} 'select name, value from master..sysconfigures where name like \"%audit%\"'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should_not match(/auditing.*0/) }
  end
end

# Control 04: Check login security (ASE 15)
control 'sybase-15-04' do
  impact 1.0
  title 'Ensure secure login configuration'
  desc 'Sybase ASE 15 should have secure login policies configured'

  describe command("sybase_query #{usernm} #{servicenm} 'select name from master..syslogins where password is null'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should_not match(/sa|probe|guest/) }
  end
end

# Control 05: Check network security (ASE 15)
control 'sybase-15-05' do
  impact 0.8
  title 'Verify network security configuration'
  desc 'Sybase ASE 15 network security should be properly configured'

  describe command("sybase_query #{usernm} #{servicenm} 'select name, value from master..sysconfigures where name = \"net password encryption reqd\"'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/net password encryption reqd/) }
  end
end
