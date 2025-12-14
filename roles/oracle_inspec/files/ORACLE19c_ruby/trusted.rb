# Oracle 19c InSpec Compliance Controls
# Based on original NIST_for_db.ksh script patterns

# Oracle database session configuration
oracle = oracle_session(
  user: attribute('usernm'),
  password: attribute('passwd'),
  host: attribute('hostnm'),
  port: attribute('port'),
  service: attribute('servicenm')
)

title "Oracle 19c Database Security Compliance Controls"

# Control 01: Ensure audit trail is enabled
control 'oracle-19c-01' do
  impact 1.0
  title 'Ensure Oracle audit trail is enabled'
  desc 'Oracle database should have audit trail enabled for security compliance'

  describe oracle.query("SELECT value FROM v$parameter WHERE name = 'audit_trail'") do
    its('rows.first.VALUE') { should_not eq 'NONE' }
  end
end

# Control 02: Ensure password verification function is enabled
control 'oracle-19c-02' do
  impact 1.0
  title 'Ensure password verification function is enabled'
  desc 'Oracle should enforce strong password policies'

  describe oracle.query("SELECT resource_name, limit FROM dba_profiles WHERE resource_name = 'PASSWORD_VERIFY_FUNCTION' AND profile = 'DEFAULT'") do
    its('rows.first.LIMIT') { should_not eq 'NULL' }
  end
end

# Control 03: Check for default users
control 'oracle-19c-03' do
  impact 1.0
  title 'Ensure default Oracle users are locked or removed'
  desc 'Default Oracle users should be locked for security'

  describe oracle.query("SELECT username, account_status FROM dba_users WHERE username IN ('SCOTT', 'HR', 'OE', 'SH') AND account_status = 'OPEN'") do
    its('rows') { should be_empty }
  end
end

# Control 04: Ensure remote login password file is configured
control 'oracle-19c-04' do
  impact 0.8
  title 'Ensure remote login password file authentication'
  desc 'Oracle should use password file for remote authentication'

  describe oracle.query("SELECT value FROM v$parameter WHERE name = 'remote_login_passwordfile'") do
    its('rows.first.VALUE') { should eq 'EXCLUSIVE' }
  end
end

# Control 05: Ensure SQL92 security is enabled
control 'oracle-19c-05' do
  impact 0.7
  title 'Ensure SQL92 security is enabled'
  desc 'Oracle should enforce SQL92 security standards'

  describe oracle.query("SELECT value FROM v$parameter WHERE name = 'sql92_security'") do
    its('rows.first.VALUE') { should eq 'TRUE' }
  end
end