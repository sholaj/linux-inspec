# Sybase ASE 16 InSpec Compliance Controls
# Based on original NIST_for_db.ksh script patterns
# Note: SSH connectivity handled by InSpec framework

title "Sybase ASE 16 Database Security Compliance Controls"

# Sybase connection using command execution (since InSpec may not have native Sybase support)
# This approach uses isql commands as shown in the original script pattern

# Control 01: Ensure server is running and accessible
control 'sybase-16-01' do
  impact 1.0
  title 'Ensure Sybase ASE server is accessible'
  desc 'Sybase ASE server should be running and accessible for connections'

  describe command("isql -U#{attribute('usernm')} -P#{attribute('passwd')} -S#{attribute('servicenm')} -w999 <<< 'select @@servername go quit'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should_not be_empty }
  end
end

# Control 02: Check server version and ensure it's supported
control 'sybase-16-02' do
  impact 0.8
  title 'Verify Sybase ASE version information'
  desc 'Sybase ASE should report correct version information'

  describe command("isql -U#{attribute('usernm')} -P#{attribute('passwd')} -S#{attribute('servicenm')} -w999 <<< 'select @@version go quit'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/Adaptive Server Enterprise/) }
  end
end

# Control 03: Ensure auditing is enabled
control 'sybase-16-03' do
  impact 1.0
  title 'Ensure Sybase ASE auditing is enabled'
  desc 'Sybase ASE should have auditing enabled for security compliance'

  describe command("isql -U#{attribute('usernm')} -P#{attribute('passwd')} -S#{attribute('servicenm')} -w999 <<< 'select name, value from master..sysconfigures where name like \"%audit%\" go quit'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should_not match(/auditing.*0/) }
  end
end

# Control 04: Check for default passwords
control 'sybase-16-04' do
  impact 1.0
  title 'Ensure no default passwords are in use'
  desc 'Sybase ASE should not have accounts with default or empty passwords'

  describe command("isql -U#{attribute('usernm')} -P#{attribute('passwd')} -S#{attribute('servicenm')} -w999 <<< 'select name from master..syslogins where password is null or password = \"\" go quit'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should_not match(/sa|probe|guest/) }
  end
end

# Control 05: Ensure remote access is properly configured
control 'sybase-16-05' do
  impact 0.8
  title 'Verify remote access configuration'
  desc 'Sybase ASE remote access should be properly configured'

  describe command("isql -U#{attribute('usernm')} -P#{attribute('passwd')} -S#{attribute('servicenm')} -w999 <<< 'select name, value from master..sysconfigures where name = \"allow remote access\" go quit'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/allow remote access/) }
  end
end

# Control 06: Check system table permissions
control 'sybase-16-06' do
  impact 1.0
  title 'Ensure system table access is restricted'
  desc 'Sybase ASE system tables should have proper access controls'

  describe command("isql -U#{attribute('usernm')} -P#{attribute('passwd')} -S#{attribute('servicenm')} -w999 <<< 'select name, value from master..sysconfigures where name = \"allow updates to system tables\" go quit'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/allow updates to system tables.*0/) }
  end
end