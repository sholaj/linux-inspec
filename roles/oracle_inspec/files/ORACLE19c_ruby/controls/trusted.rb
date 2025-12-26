# Oracle 19c InSpec Control - trusted.rb
# CIS Oracle Database 19c Compliance Controls
#
# IMPORTANT: Export ORACLE_PWD environment variable before running InSpec:
#   export ORACLE_PWD='your_password'
#   inspec exec . --input usernm=system hostnm=10.0.2.5 port=1521 servicenm=ORCLCDB
#
# The password is passed via environment variable to avoid exposure in logs.

usernm = input('usernm')
hostnm = input('hostnm')
port = input('port', value: 1521)
servicenm = input('servicenm')

# Control 01: Ensure audit trail is enabled
control 'oracle-19c-01' do
  impact 1.0
  title 'Ensure Oracle audit trail is enabled'
  desc 'Oracle database should have audit trail enabled for security compliance'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT value FROM v\\$parameter WHERE name = 'audit_trail'\"") do
    its('stdout.strip') { should_not eq 'NONE' }
    its('stdout.strip') { should_not be_empty }
  end
end

# Control 02: Ensure password verification function is enabled
control 'oracle-19c-02' do
  impact 1.0
  title 'Ensure password verification function is enabled'
  desc 'Oracle should enforce strong password policies'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_VERIFY_FUNCTION' AND profile = 'DEFAULT'\"") do
    its('stdout.strip') { should_not eq 'NULL' }
    its('stdout.strip') { should_not be_empty }
  end
end

# Control 03: Check for default users
control 'oracle-19c-03' do
  impact 1.0
  title 'Ensure default Oracle users are locked or removed'
  desc 'Default Oracle users should be locked for security'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT COUNT(*) FROM dba_users WHERE username IN ('SCOTT', 'HR', 'OE', 'SH') AND account_status = 'OPEN'\"") do
    its('stdout.strip') { should eq '0' }
  end
end

# Control 04: Ensure remote login password file is configured
control 'oracle-19c-04' do
  impact 0.8
  title 'Ensure remote login password file authentication'
  desc 'Oracle should use password file for remote authentication'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT value FROM v\\$parameter WHERE name = 'remote_login_passwordfile'\"") do
    its('stdout.strip') { should eq 'EXCLUSIVE' }
  end
end

# Control 05: Ensure SQL92 security is enabled
control 'oracle-19c-05' do
  impact 0.7
  title 'Ensure SQL92 security is enabled'
  desc 'Oracle should enforce SQL92 security standards'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT value FROM v\\$parameter WHERE name = 'sql92_security'\"") do
    its('stdout.strip') { should cmp 'TRUE' }
  end
end

# Control 06: Check for PUBLIC privileges on dangerous packages
control 'oracle-19c-06' do
  impact 1.0
  title 'Revoke dangerous package privileges from PUBLIC'
  desc 'PUBLIC should not have execute privileges on dangerous packages'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT COUNT(*) FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name IN ('UTL_FILE', 'UTL_HTTP', 'UTL_TCP', 'UTL_SMTP', 'DBMS_LOB')\"") do
    its('stdout.strip') { should eq '0' }
  end
end

# Control 07: Ensure default tablespace is not SYSTEM
control 'oracle-19c-07' do
  impact 0.8
  title 'Ensure users do not use SYSTEM tablespace as default'
  desc 'User data should not reside in SYSTEM tablespace'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT COUNT(*) FROM dba_users WHERE default_tablespace = 'SYSTEM' AND username NOT IN ('SYS', 'SYSTEM', 'OUTLN', 'DIP')\"") do
    its('stdout.strip') { should eq '0' }
  end
end

# Control 08: Check for password expiration policy
control 'oracle-19c-08' do
  impact 0.9
  title 'Ensure password expiration is configured'
  desc 'Passwords should expire to enforce regular password changes'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_LIFE_TIME' AND profile = 'DEFAULT'\"") do
    its('stdout.strip') { should_not eq 'UNLIMITED' }
    its('stdout.strip') { should_not be_empty }
  end
end

# Control 09: Check failed login attempts limit
control 'oracle-19c-09' do
  impact 0.9
  title 'Ensure failed login attempts are limited'
  desc 'Accounts should be locked after failed login attempts'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT limit FROM dba_profiles WHERE resource_name = 'FAILED_LOGIN_ATTEMPTS' AND profile = 'DEFAULT'\"") do
    its('stdout.strip') { should_not eq 'UNLIMITED' }
    its('stdout.strip') { should_not be_empty }
  end
end

# Control 10: Ensure case-sensitive logon is enabled
control 'oracle-19c-10' do
  impact 0.7
  title 'Check case-sensitive logon configuration'
  desc 'Oracle should enforce case-sensitive passwords'

  describe command("oracle_query #{usernm} #{hostnm} #{port} #{servicenm} \"SELECT value FROM v\\$parameter WHERE name = 'sec_case_sensitive_logon'\"") do
    its('stdout.strip') { should cmp 'TRUE' }
  end
end
