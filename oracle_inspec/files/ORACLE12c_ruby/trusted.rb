# Oracle 12c InSpec Compliance Controls
# Based on original NIST_for_db.ksh script patterns

# Oracle database session configuration
oracle = oracle_session(
  user: attribute('usernm'),
  password: attribute('passwd'),
  host: attribute('hostnm'),
  port: attribute('port'),
  service: attribute('servicenm')
)

title "Oracle 12c Database Security Compliance Controls"

# Control 01: Ensure audit trail is enabled
control 'oracle-12c-01' do
  impact 1.0
  title 'Ensure Oracle audit trail is enabled'
  desc 'Oracle 12c database should have audit trail enabled for security compliance'

  describe oracle.query("SELECT value FROM v$parameter WHERE name = 'audit_trail'") do
    its('rows.first.VALUE') { should_not eq 'NONE' }
  end
end

# Control 02: Ensure unified auditing is enabled (12c feature)
control 'oracle-12c-02' do
  impact 1.0
  title 'Ensure unified auditing is enabled'
  desc 'Oracle 12c should use unified auditing for comprehensive audit trail'

  describe oracle.query("SELECT value FROM v$option WHERE parameter = 'Unified Auditing'") do
    its('rows.first.VALUE') { should eq 'TRUE' }
  end
end

# Control 03: Check PDB security (12c multitenant feature)
control 'oracle-12c-03' do
  impact 0.8
  title 'Ensure PDB isolation is properly configured'
  desc 'Oracle 12c pluggable databases should be properly isolated'

  describe oracle.query("SELECT count(*) as pdb_count FROM v$pdbs WHERE open_mode = 'READ WRITE'") do
    its('rows.first.PDB_COUNT') { should be >= 1 }
  end
end

# Control 04: Ensure password verification function is enabled
control 'oracle-12c-04' do
  impact 1.0
  title 'Ensure password verification function is enabled'
  desc 'Oracle 12c should enforce strong password policies'

  describe oracle.query("SELECT resource_name, limit FROM dba_profiles WHERE resource_name = 'PASSWORD_VERIFY_FUNCTION' AND profile = 'DEFAULT'") do
    its('rows.first.LIMIT') { should_not eq 'NULL' }
  end
end

# Control 05: Check for default users
control 'oracle-12c-05' do
  impact 1.0
  title 'Ensure default Oracle users are locked or removed'
  desc 'Default Oracle 12c users should be locked for security'

  describe oracle.query("SELECT username, account_status FROM dba_users WHERE username IN ('SCOTT', 'HR', 'OE', 'SH') AND account_status = 'OPEN'") do
    its('rows') { should be_empty }
  end
end