# Oracle 19c InSpec Control - trusted.rb
# CIS Oracle Database 19c Compliance Controls
#
# Uses native oracledb_session resource for scalable multi-database scanning
# Password is passed via input and handled securely by InSpec

sql = oracledb_session(
  user: input('usernm'),
  password: input('passwd'),
  host: input('hostnm'),
  port: input('port', value: 1521),
  service: input('servicenm')
)

# Control 01: Ensure audit trail is enabled
control 'oracle-19c-01' do
  impact 1.0
  title 'Ensure Oracle audit trail is enabled'
  desc 'Oracle database should have audit trail enabled for security compliance'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'audit_trail'").row(0).column('value') do
    its('value') { should_not cmp 'NONE' }
  end
end

# Control 02: Ensure password verification function is enabled
control 'oracle-19c-02' do
  impact 1.0
  title 'Ensure password verification function is enabled'
  desc 'Oracle should enforce strong password policies'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_VERIFY_FUNCTION' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should_not cmp 'NULL' }
  end
end

# Control 03: Check for default users
control 'oracle-19c-03' do
  impact 1.0
  title 'Ensure default Oracle users are locked or removed'
  desc 'Default Oracle users should be locked for security'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_users WHERE username IN ('SCOTT', 'HR', 'OE', 'SH') AND account_status = 'OPEN'").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 04: Ensure remote login password file is configured
control 'oracle-19c-04' do
  impact 0.8
  title 'Ensure remote login password file authentication'
  desc 'Oracle should use password file for remote authentication'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'remote_login_passwordfile'").row(0).column('value') do
    its('value') { should cmp 'EXCLUSIVE' }
  end
end

# Control 05: Ensure SQL92 security is enabled
control 'oracle-19c-05' do
  impact 0.7
  title 'Ensure SQL92 security is enabled'
  desc 'Oracle should enforce SQL92 security standards'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'sql92_security'").row(0).column('value') do
    its('value') { should cmp 'TRUE' }
  end
end

# Control 06: Check for PUBLIC privileges on dangerous packages
control 'oracle-19c-06' do
  impact 1.0
  title 'Revoke dangerous package privileges from PUBLIC'
  desc 'PUBLIC should not have execute privileges on dangerous packages'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name IN ('UTL_FILE', 'UTL_HTTP', 'UTL_TCP', 'UTL_SMTP', 'DBMS_LOB')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 07: Ensure default tablespace is not SYSTEM
control 'oracle-19c-07' do
  impact 0.8
  title 'Ensure users do not use SYSTEM tablespace as default'
  desc 'User data should not reside in SYSTEM tablespace'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_users WHERE default_tablespace = 'SYSTEM' AND username NOT IN ('SYS', 'SYSTEM', 'OUTLN', 'DIP')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 08: Check for password expiration policy
control 'oracle-19c-08' do
  impact 0.9
  title 'Ensure password expiration is configured'
  desc 'Passwords should expire to enforce regular password changes'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_LIFE_TIME' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should_not cmp 'UNLIMITED' }
  end
end

# Control 09: Check failed login attempts limit
control 'oracle-19c-09' do
  impact 0.9
  title 'Ensure failed login attempts are limited'
  desc 'Accounts should be locked after failed login attempts'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'FAILED_LOGIN_ATTEMPTS' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should_not cmp 'UNLIMITED' }
  end
end

# Control 10: Ensure case-sensitive logon is enabled
control 'oracle-19c-10' do
  impact 0.7
  title 'Check case-sensitive logon configuration'
  desc 'Oracle should enforce case-sensitive passwords'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'sec_case_sensitive_logon'").row(0).column('value') do
    its('value') { should cmp 'TRUE' }
  end
end
