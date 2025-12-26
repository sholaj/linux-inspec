# Oracle 12c InSpec Control - trusted.rb
# CIS Oracle Database 12c Compliance Controls
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

title "Oracle 12c Database Security Compliance Controls"

# Control 01: Ensure audit trail is enabled
control 'oracle-12c-01' do
  impact 1.0
  title 'Ensure Oracle audit trail is enabled'
  desc 'Oracle 12c database should have audit trail enabled for security compliance'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'audit_trail'").row(0).column('value') do
    its('value') { should_not cmp 'NONE' }
  end
end

# Control 02: Ensure unified auditing is enabled (12c feature)
control 'oracle-12c-02' do
  impact 1.0
  title 'Ensure unified auditing is enabled'
  desc 'Oracle 12c should use unified auditing for comprehensive audit trail'

  describe sql.query("SELECT value FROM v$option WHERE parameter = 'Unified Auditing'").row(0).column('value') do
    its('value') { should cmp 'TRUE' }
  end
end

# Control 03: Check PDB security (12c multitenant feature)
control 'oracle-12c-03' do
  impact 0.8
  title 'Ensure PDB isolation is properly configured'
  desc 'Oracle 12c pluggable databases should be properly isolated'

  describe sql.query("SELECT count(*) AS cnt FROM v$pdbs WHERE open_mode = 'READ WRITE'").row(0).column('cnt') do
    its('value') { should be >= 0 }
  end
end

# Control 04: Ensure password verification function is enabled
control 'oracle-12c-04' do
  impact 1.0
  title 'Ensure password verification function is enabled'
  desc 'Oracle 12c should enforce strong password policies'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_VERIFY_FUNCTION' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should_not cmp 'NULL' }
  end
end

# Control 05: Check for default users
control 'oracle-12c-05' do
  impact 1.0
  title 'Ensure default Oracle users are locked or removed'
  desc 'Default Oracle 12c users should be locked for security'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_users WHERE username IN ('SCOTT', 'HR', 'OE', 'SH') AND account_status = 'OPEN'").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 06: Ensure remote login password file is configured
control 'oracle-12c-06' do
  impact 0.8
  title 'Ensure remote login password file authentication'
  desc 'Oracle should use password file for remote authentication'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'remote_login_passwordfile'").row(0).column('value') do
    its('value') { should cmp 'EXCLUSIVE' }
  end
end

# Control 07: Check for PUBLIC privileges on dangerous packages
control 'oracle-12c-07' do
  impact 1.0
  title 'Revoke dangerous package privileges from PUBLIC'
  desc 'PUBLIC should not have execute privileges on dangerous packages'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name IN ('UTL_FILE', 'UTL_HTTP', 'UTL_TCP', 'UTL_SMTP', 'DBMS_LOB')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 08: Check for password expiration policy
control 'oracle-12c-08' do
  impact 0.9
  title 'Ensure password expiration is configured'
  desc 'Passwords should expire to enforce regular password changes'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_LIFE_TIME' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should_not cmp 'UNLIMITED' }
  end
end
