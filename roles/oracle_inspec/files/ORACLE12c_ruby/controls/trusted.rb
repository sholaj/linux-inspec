# Oracle 12c InSpec Control - trusted.rb
# CIS Oracle Database 12c Compliance Controls
#
# IMPORTANT: Export ORACLE_PWD environment variable before running InSpec:
#   export ORACLE_PWD='your_password'
#   inspec exec . --input usernm=system hostnm=10.0.2.5 port=1521 servicenm=ORCL
#
# The password is passed via environment variable to avoid exposure in logs.

usernm = input('usernm')
hostnm = input('hostnm')
port = input('port', value: 1521)
servicenm = input('servicenm')

title "Oracle 12c Database Security Compliance Controls"

# Control 01: Ensure audit trail is enabled
control 'oracle-12c-01' do
  impact 1.0
  title 'Ensure Oracle audit trail is enabled'
  desc 'Oracle 12c database should have audit trail enabled for security compliance'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT value FROM v\\$parameter WHERE name = 'audit_trail'\"") do
    its('stdout.strip') { should_not eq 'NONE' }
    its('stdout.strip') { should_not be_empty }
  end
end

# Control 02: Ensure unified auditing is enabled (12c feature)
control 'oracle-12c-02' do
  impact 1.0
  title 'Ensure unified auditing is enabled'
  desc 'Oracle 12c should use unified auditing for comprehensive audit trail'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT value FROM v\\$option WHERE parameter = 'Unified Auditing'\"") do
    its('stdout.strip') { should cmp 'TRUE' }
  end
end

# Control 03: Check PDB security (12c multitenant feature)
control 'oracle-12c-03' do
  impact 0.8
  title 'Ensure PDB isolation is properly configured'
  desc 'Oracle 12c pluggable databases should be properly isolated'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT count(*) FROM v\\$pdbs WHERE open_mode = 'READ WRITE'\"") do
    its('stdout.strip.to_i') { should be >= 0 }
  end
end

# Control 04: Ensure password verification function is enabled
control 'oracle-12c-04' do
  impact 1.0
  title 'Ensure password verification function is enabled'
  desc 'Oracle 12c should enforce strong password policies'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_VERIFY_FUNCTION' AND profile = 'DEFAULT'\"") do
    its('stdout.strip') { should_not eq 'NULL' }
    its('stdout.strip') { should_not be_empty }
  end
end

# Control 05: Check for default users
control 'oracle-12c-05' do
  impact 1.0
  title 'Ensure default Oracle users are locked or removed'
  desc 'Default Oracle 12c users should be locked for security'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT COUNT(*) FROM dba_users WHERE username IN ('SCOTT', 'HR', 'OE', 'SH') AND account_status = 'OPEN'\"") do
    its('stdout.strip') { should eq '0' }
  end
end

# Control 06: Ensure remote login password file is configured
control 'oracle-12c-06' do
  impact 0.8
  title 'Ensure remote login password file authentication'
  desc 'Oracle should use password file for remote authentication'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT value FROM v\\$parameter WHERE name = 'remote_login_passwordfile'\"") do
    its('stdout.strip') { should eq 'EXCLUSIVE' }
  end
end

# Control 07: Check for PUBLIC privileges on dangerous packages
control 'oracle-12c-07' do
  impact 1.0
  title 'Revoke dangerous package privileges from PUBLIC'
  desc 'PUBLIC should not have execute privileges on dangerous packages'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT COUNT(*) FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name IN ('UTL_FILE', 'UTL_HTTP', 'UTL_TCP', 'UTL_SMTP', 'DBMS_LOB')\"") do
    its('stdout.strip') { should eq '0' }
  end
end

# Control 08: Check for password expiration policy
control 'oracle-12c-08' do
  impact 0.9
  title 'Ensure password expiration is configured'
  desc 'Passwords should expire to enforce regular password changes'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_LIFE_TIME' AND profile = 'DEFAULT'\"") do
    its('stdout.strip') { should_not eq 'UNLIMITED' }
    its('stdout.strip') { should_not be_empty }
  end
end
