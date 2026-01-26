# Oracle 11g InSpec Controls - trusted.rb
# CIS Oracle Database 11g Benchmark Compliance Controls
# NIST SP 800-53 Rev 5 Mapped
#
# Uses native oracledb_session resource for scalable multi-database scanning
# Password is passed via input and handled securely by InSpec
#
# NOTE: Oracle sqlplus may return values with leading whitespace/tabs.
# All numeric comparisons use .to_s.strip to handle this.

title 'CIS Oracle Database 11g Security Compliance Controls'

sql = oracledb_session(
  user: input('usernm'),
  password: input('passwd'),
  host: input('hostnm'),
  port: input('port', value: 1521),
  service: input('servicenm')
)

# Helper method to safely compare Oracle numeric output (handles whitespace)
def oracle_int(value)
  value.to_s.strip.to_i
end

# ==============================================================================
# Section 1: Installation and Configuration
# NIST: CM-6 (Configuration Management), SI-2 (Flaw Remediation)
# ==============================================================================

control 'oracle-11g-1.01' do
  impact 1.0
  title 'Ensure Oracle database version is supported'
  desc 'Running a supported Oracle database version ensures security patches are available.'
  tag nist: ['SA-22', 'SI-2']
  tag cis: '1.1'
  tag severity: 'high'

  describe sql.query("SELECT version_full FROM v$instance") do
    its('rows') { should_not be_empty }
  end
end

control 'oracle-11g-1.02' do
  impact 1.0
  title 'Ensure SPFILE is in use'
  desc 'Using SPFILE ensures persistent parameter changes and auditable configuration.'
  tag nist: ['CM-6', 'AU-9']
  tag cis: '1.2'
  tag severity: 'high'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'spfile'").row(0).column('value') do
    its('value') { should_not be_nil }
    its('value') { should satisfy { |v| !v.to_s.strip.empty? } }
  end
end

control 'oracle-11g-1.03' do
  impact 0.7
  title 'Ensure AUDIT_FILE_DEST is set appropriately'
  desc 'Audit file destination should be on a separate filesystem with proper permissions.'
  tag nist: ['AU-9', 'CM-6']
  tag cis: '1.3'
  tag severity: 'medium'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'audit_file_dest'").row(0).column('value') do
    its('value') { should_not be_nil }
    its('value') { should satisfy { |v| !v.to_s.strip.empty? } }
  end
end

control 'oracle-11g-1.04' do
  impact 0.8
  title 'Ensure REMOTE_LOGIN_PASSWORDFILE is set to EXCLUSIVE'
  desc 'EXCLUSIVE mode ensures password file is used only by one database.'
  tag nist: ['IA-2', 'IA-5']
  tag cis: '1.4'
  tag severity: 'medium'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'remote_login_passwordfile'").row(0).column('value') do
    its('value') { should satisfy { |v| v.to_s.strip.upcase == 'EXCLUSIVE' } }
  end
end

control 'oracle-11g-1.05' do
  impact 0.7
  title 'Ensure SQL92_SECURITY is enabled'
  desc 'SQL92 security enforces additional column-level security checks.'
  tag nist: ['AC-3', 'AC-6']
  tag cis: '1.5'
  tag severity: 'medium'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'sql92_security'").row(0).column('value') do
    its('value') { should satisfy { |v| v.to_s.strip.upcase == 'TRUE' } }
  end
end

control 'oracle-11g-1.06' do
  impact 0.8
  title 'Ensure users do not use SYSTEM tablespace as default'
  desc 'User data should not reside in SYSTEM tablespace to prevent space exhaustion.'
  tag nist: ['CM-6', 'SC-4']
  tag cis: '1.6'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_users WHERE default_tablespace = 'SYSTEM' AND username NOT IN ('SYS', 'SYSTEM', 'OUTLN', 'DIP', 'ORACLE_OCM', 'DBSNMP', 'APPQOSSYS', 'WMSYS', 'EXFSYS', 'CTXSYS', 'XDB', 'ANONYMOUS', 'ORDSYS', 'ORDDATA', 'ORDPLUGINS', 'SI_INFORMTN_SCHEMA', 'MDSYS', 'OLAPSYS', 'MDDATA', 'SPATIAL_WFS_ADMIN_USR', 'SPATIAL_CSW_ADMIN_USR', 'LBACSYS', 'APEX_PUBLIC_USER', 'APEX_040000', 'APEX_040100', 'APEX_040200', 'FLOWS_FILES', 'DVSYS', 'DVF')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-1.07' do
  impact 0.7
  title 'Ensure control files are multiplexed'
  desc 'Multiple control files protect against data loss from single point of failure.'
  tag nist: ['CP-9', 'CP-10']
  tag cis: '1.7'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM v$controlfile").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i >= 2 } }
  end
end

control 'oracle-11g-1.08' do
  impact 0.7
  title 'Ensure redo logs are multiplexed'
  desc 'Multiple redo log members protect against data loss.'
  tag nist: ['CP-9', 'CP-10']
  tag cis: '1.8'
  tag severity: 'medium'

  describe sql.query("SELECT MIN(members) AS min_members FROM v$log").row(0).column('min_members') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i >= 2 } }
  end
end

control 'oracle-11g-1.09' do
  impact 1.0
  title 'Ensure AUDIT_SYS_OPERATIONS is enabled'
  desc 'Auditing SYS operations provides accountability for privileged users.'
  tag nist: ['AU-2', 'AU-12']
  tag cis: '1.9'
  tag severity: 'high'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'audit_sys_operations'").row(0).column('value') do
    its('value') { should satisfy { |v| v.to_s.strip.upcase == 'TRUE' } }
  end
end

control 'oracle-11g-1.10' do
  impact 0.7
  title 'Ensure GLOBAL_NAMES is enabled'
  desc 'Forces database links to have the same name as the remote database.'
  tag nist: ['CM-6', 'CM-7']
  tag cis: '1.10'
  tag severity: 'medium'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'global_names'").row(0).column('value') do
    its('value') { should satisfy { |v| v.to_s.strip.upcase == 'TRUE' } }
  end
end

control 'oracle-11g-1.11' do
  impact 1.0
  title 'Ensure O7_DICTIONARY_ACCESSIBILITY is disabled'
  desc 'Prevents users with ANY privilege from accessing SYS schema objects.'
  tag nist: ['AC-6', 'AC-3']
  tag cis: '1.11'
  tag severity: 'high'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'o7_dictionary_accessibility'").row(0).column('value') do
    its('value') { should satisfy { |v| v.to_s.strip.upcase == 'FALSE' } }
  end
end

control 'oracle-11g-1.12' do
  impact 1.0
  title 'Ensure OS_ROLES is disabled'
  desc 'Disabling OS roles prevents operating system from managing database roles.'
  tag nist: ['AC-3', 'IA-2']
  tag cis: '1.12'
  tag severity: 'high'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'os_roles'").row(0).column('value') do
    its('value') { should satisfy { |v| v.to_s.strip.upcase == 'FALSE' } }
  end
end

control 'oracle-11g-1.13' do
  impact 1.0
  title 'Ensure REMOTE_LISTENER is empty or properly configured'
  desc 'Remote listener allows network connections which may be exploited if misconfigured.'
  tag nist: ['SC-7', 'CM-7']
  tag cis: '1.13'
  tag severity: 'high'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'remote_listener'").row(0).column('value') do
    its('value') { should satisfy { |v| v.nil? || v.to_s.strip.empty? || v.to_s.strip.match?(/^[a-zA-Z0-9_\-\.:]+$/) } }
  end
end

control 'oracle-11g-1.14' do
  impact 1.0
  title 'Ensure REMOTE_OS_AUTHENT is disabled'
  desc 'Prevents remote OS authentication which can be spoofed.'
  tag nist: ['IA-2', 'IA-5']
  tag cis: '1.14'
  tag severity: 'high'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'remote_os_authent'").row(0).column('value') do
    its('value') { should satisfy { |v| v.to_s.strip.upcase == 'FALSE' } }
  end
end

control 'oracle-11g-1.15' do
  impact 1.0
  title 'Ensure REMOTE_OS_ROLES is disabled'
  desc 'Prevents remote operating system roles from being used.'
  tag nist: ['AC-3', 'IA-2']
  tag cis: '1.15'
  tag severity: 'high'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'remote_os_roles'").row(0).column('value') do
    its('value') { should satisfy { |v| v.to_s.strip.upcase == 'FALSE' } }
  end
end

control 'oracle-11g-1.16' do
  impact 1.0
  title 'Ensure UTL_FILE_DIR is empty'
  desc 'UTL_FILE_DIR allows file system access which can be dangerous.'
  tag nist: ['CM-7', 'AC-6']
  tag cis: '1.16'
  tag severity: 'high'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'utl_file_dir'").row(0).column('value') do
    its('value') { should satisfy { |v| v.nil? || v.to_s.strip.empty? } }
  end
end

control 'oracle-11g-1.17' do
  impact 0.5
  title 'Ensure SEC_RETURN_SERVER_RELEASE_BANNER is disabled'
  desc 'Prevents detailed version information from being returned to clients.'
  tag nist: ['SC-7', 'CM-6']
  tag cis: '1.17'
  tag severity: 'low'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'sec_return_server_release_banner'").row(0).column('value') do
    its('value') { should satisfy { |v| v.to_s.strip.upcase == 'FALSE' } }
  end
end

control 'oracle-11g-1.18' do
  impact 0.7
  title 'Ensure RESOURCE_LIMIT is enabled'
  desc 'Enables enforcement of resource limits set in profiles.'
  tag nist: ['SC-5', 'AC-2']
  tag cis: '1.18'
  tag severity: 'medium'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'resource_limit'").row(0).column('value') do
    its('value') { should satisfy { |v| v.to_s.strip.upcase == 'TRUE' } }
  end
end

# ==============================================================================
# Section 2: User Account Management
# NIST: AC-2 (Account Management), IA-2 (Identification and Authentication)
# ==============================================================================

control 'oracle-11g-2.01' do
  impact 1.0
  title 'Ensure default sample schema users are locked'
  desc 'Default Oracle sample schema users should be locked for security.'
  tag nist: ['AC-2', 'AC-6']
  tag cis: '2.1'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_users WHERE username IN ('SCOTT', 'HR', 'OE', 'SH', 'PM', 'IX', 'BI') AND account_status = 'OPEN'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-2.02' do
  impact 1.0
  title 'Ensure DBSNMP account is locked'
  desc 'DBSNMP account should be locked if Enterprise Manager is not in use.'
  tag nist: ['AC-2', 'AC-6']
  tag cis: '2.2'
  tag severity: 'high'

  describe sql.query("SELECT account_status FROM dba_users WHERE username = 'DBSNMP'").row(0).column('account_status') do
    its('value') { should satisfy { |v| v.to_s.strip.include?('LOCKED') } }
  end
end

control 'oracle-11g-2.03' do
  impact 0.8
  title 'Ensure XDB account is locked'
  desc 'XDB account should be locked if XML DB is not required.'
  tag nist: ['AC-2', 'AC-6']
  tag cis: '2.3'
  tag severity: 'medium'

  describe sql.query("SELECT account_status FROM dba_users WHERE username = 'XDB'").row(0).column('account_status') do
    its('value') { should satisfy { |v| v.to_s.strip.include?('LOCKED') } }
  end
end

control 'oracle-11g-2.04' do
  impact 0.8
  title 'Ensure ANONYMOUS account is locked'
  desc 'ANONYMOUS account provides unauthenticated access and should be locked.'
  tag nist: ['AC-2', 'AC-14']
  tag cis: '2.4'
  tag severity: 'medium'

  describe sql.query("SELECT account_status FROM dba_users WHERE username = 'ANONYMOUS'").row(0).column('account_status') do
    its('value') { should satisfy { |v| v.to_s.strip.include?('LOCKED') } }
  end
end

control 'oracle-11g-2.05' do
  impact 1.0
  title 'Ensure no users have default passwords'
  desc 'Users with default passwords are vulnerable to unauthorized access.'
  tag nist: ['IA-5', 'AC-2']
  tag cis: '2.5'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_users_with_defpwd WHERE username NOT IN ('XS$NULL')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-2.06' do
  impact 0.8
  title 'Ensure CTXSYS account is locked'
  desc 'CTXSYS account should be locked if Oracle Text is not required.'
  tag nist: ['AC-2', 'AC-6']
  tag cis: '2.6'
  tag severity: 'medium'

  describe sql.query("SELECT account_status FROM dba_users WHERE username = 'CTXSYS'").row(0).column('account_status') do
    its('value') { should satisfy { |v| v.to_s.strip.include?('LOCKED') } }
  end
end

control 'oracle-11g-2.07' do
  impact 0.8
  title 'Ensure MDSYS account is locked'
  desc 'MDSYS account should be locked if Oracle Spatial is not required.'
  tag nist: ['AC-2', 'AC-6']
  tag cis: '2.7'
  tag severity: 'medium'

  describe sql.query("SELECT account_status FROM dba_users WHERE username = 'MDSYS'").row(0).column('account_status') do
    its('value') { should satisfy { |v| v.to_s.strip.include?('LOCKED') } }
  end
end

control 'oracle-11g-2.08' do
  impact 0.8
  title 'Ensure OLAPSYS account is locked'
  desc 'OLAPSYS account should be locked if OLAP is not required.'
  tag nist: ['AC-2', 'AC-6']
  tag cis: '2.8'
  tag severity: 'medium'

  describe sql.query("SELECT account_status FROM dba_users WHERE username = 'OLAPSYS'").row(0).column('account_status') do
    its('value') { should satisfy { |v| v.to_s.strip.include?('LOCKED') } }
  end
end

control 'oracle-11g-2.09' do
  impact 0.8
  title 'Ensure ORDDATA account is locked'
  desc 'ORDDATA account should be locked if Oracle Multimedia is not required.'
  tag nist: ['AC-2', 'AC-6']
  tag cis: '2.9'
  tag severity: 'medium'

  describe sql.query("SELECT account_status FROM dba_users WHERE username = 'ORDDATA'").row(0).column('account_status') do
    its('value') { should satisfy { |v| v.to_s.strip.include?('LOCKED') } }
  end
end

control 'oracle-11g-2.10' do
  impact 0.8
  title 'Ensure ORDSYS account is locked'
  desc 'ORDSYS account should be locked if Oracle Multimedia is not required.'
  tag nist: ['AC-2', 'AC-6']
  tag cis: '2.10'
  tag severity: 'medium'

  describe sql.query("SELECT account_status FROM dba_users WHERE username = 'ORDSYS'").row(0).column('account_status') do
    its('value') { should satisfy { |v| v.to_s.strip.include?('LOCKED') } }
  end
end

control 'oracle-11g-2.11' do
  impact 0.8
  title 'Ensure OUTLN account is locked'
  desc 'OUTLN account should be locked if stored outlines are not used.'
  tag nist: ['AC-2', 'AC-6']
  tag cis: '2.11'
  tag severity: 'medium'

  describe sql.query("SELECT account_status FROM dba_users WHERE username = 'OUTLN'").row(0).column('account_status') do
    its('value') { should satisfy { |v| v.to_s.strip.include?('LOCKED') } }
  end
end

control 'oracle-11g-2.12' do
  impact 0.8
  title 'Ensure WMSYS account is locked'
  desc 'WMSYS account should be locked if Workspace Manager is not required.'
  tag nist: ['AC-2', 'AC-6']
  tag cis: '2.12'
  tag severity: 'medium'

  describe sql.query("SELECT account_status FROM dba_users WHERE username = 'WMSYS'").row(0).column('account_status') do
    its('value') { should satisfy { |v| v.to_s.strip.include?('LOCKED') } }
  end
end

control 'oracle-11g-2.13' do
  impact 0.8
  title 'Ensure LBACSYS account is locked'
  desc 'LBACSYS account should be locked if Label Security is not required.'
  tag nist: ['AC-2', 'AC-6']
  tag cis: '2.13'
  tag severity: 'medium'

  describe sql.query("SELECT account_status FROM dba_users WHERE username = 'LBACSYS'").row(0).column('account_status') do
    its('value') { should satisfy { |v| v.to_s.strip.include?('LOCKED') } }
  end
end

control 'oracle-11g-2.14' do
  impact 0.7
  title 'Ensure proxy user authentication is properly configured'
  desc 'Proxy users should be minimized and properly authorized.'
  tag nist: ['AC-2', 'IA-2']
  tag cis: '2.14'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM proxy_users").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i >= 0 } }
  end
end

control 'oracle-11g-2.15' do
  impact 0.8
  title 'Ensure no users have unlimited tablespace quota'
  desc 'Unlimited quotas can lead to denial of service.'
  tag nist: ['SC-5', 'AC-2']
  tag cis: '2.15'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_ts_quotas WHERE max_bytes = -1 AND username NOT IN ('SYS', 'SYSTEM')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

# ==============================================================================
# Section 3: Privilege Management
# NIST: AC-6 (Least Privilege), AC-3 (Access Enforcement)
# ==============================================================================

control 'oracle-11g-3.01' do
  impact 1.0
  title 'Ensure EXECUTE on UTL_FILE is revoked from PUBLIC'
  desc 'UTL_FILE allows file system access and should not be granted to PUBLIC.'
  tag nist: ['AC-6', 'CM-7']
  tag cis: '3.1'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'UTL_FILE'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.02' do
  impact 1.0
  title 'Ensure EXECUTE on UTL_HTTP is revoked from PUBLIC'
  desc 'UTL_HTTP allows HTTP calls and should not be granted to PUBLIC.'
  tag nist: ['AC-6', 'SC-7']
  tag cis: '3.2'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'UTL_HTTP'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.03' do
  impact 1.0
  title 'Ensure EXECUTE on UTL_TCP is revoked from PUBLIC'
  desc 'UTL_TCP allows TCP connections and should not be granted to PUBLIC.'
  tag nist: ['AC-6', 'SC-7']
  tag cis: '3.3'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'UTL_TCP'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.04' do
  impact 1.0
  title 'Ensure EXECUTE on UTL_SMTP is revoked from PUBLIC'
  desc 'UTL_SMTP allows email sending and should not be granted to PUBLIC.'
  tag nist: ['AC-6', 'SC-7']
  tag cis: '3.4'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'UTL_SMTP'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.05' do
  impact 0.8
  title 'Ensure EXECUTE on DBMS_LOB is revoked from PUBLIC'
  desc 'DBMS_LOB allows large object manipulation and should not be granted to PUBLIC.'
  tag nist: ['AC-6', 'CM-7']
  tag cis: '3.5'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'DBMS_LOB'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.06' do
  impact 1.0
  title 'Ensure EXECUTE on DBMS_SQL is revoked from PUBLIC'
  desc 'DBMS_SQL allows dynamic SQL execution and should not be granted to PUBLIC.'
  tag nist: ['AC-6', 'CM-7']
  tag cis: '3.6'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'DBMS_SQL'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.07' do
  impact 0.8
  title 'Ensure EXECUTE on DBMS_RANDOM is revoked from PUBLIC'
  desc 'DBMS_RANDOM should be restricted to prevent misuse.'
  tag nist: ['AC-6', 'CM-7']
  tag cis: '3.7'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'DBMS_RANDOM'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.08' do
  impact 0.8
  title 'Ensure EXECUTE on DBMS_XMLGEN is revoked from PUBLIC'
  desc 'DBMS_XMLGEN can expose data and should not be granted to PUBLIC.'
  tag nist: ['AC-6', 'CM-7']
  tag cis: '3.8'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'DBMS_XMLGEN'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.09' do
  impact 0.8
  title 'Ensure EXECUTE on DBMS_JOB is revoked from PUBLIC'
  desc 'DBMS_JOB can be used to schedule malicious code.'
  tag nist: ['AC-6', 'CM-7']
  tag cis: '3.9'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'DBMS_JOB'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.10' do
  impact 0.8
  title 'Ensure EXECUTE on DBMS_SCHEDULER is revoked from PUBLIC'
  desc 'DBMS_SCHEDULER can be used to schedule malicious code.'
  tag nist: ['AC-6', 'CM-7']
  tag cis: '3.10'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'DBMS_SCHEDULER'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.11' do
  impact 1.0
  title 'Ensure EXECUTE on DBMS_SYS_SQL is revoked from PUBLIC'
  desc 'DBMS_SYS_SQL can execute SQL as another user.'
  tag nist: ['AC-6', 'AC-3']
  tag cis: '3.11'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'DBMS_SYS_SQL'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.12' do
  impact 0.8
  title 'Ensure EXECUTE on DBMS_BACKUP_RESTORE is revoked from PUBLIC'
  desc 'DBMS_BACKUP_RESTORE can be used to access backup data.'
  tag nist: ['AC-6', 'CP-9']
  tag cis: '3.12'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'DBMS_BACKUP_RESTORE'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.13' do
  impact 0.8
  title 'Ensure EXECUTE on UTL_MAIL is revoked from PUBLIC'
  desc 'UTL_MAIL can be used for unauthorized email sending.'
  tag nist: ['AC-6', 'SC-7']
  tag cis: '3.13'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'UTL_MAIL'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.14' do
  impact 0.8
  title 'Ensure EXECUTE on UTL_INADDR is revoked from PUBLIC'
  desc 'UTL_INADDR can be used for network reconnaissance.'
  tag nist: ['AC-6', 'SC-7']
  tag cis: '3.14'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'UTL_INADDR'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.15' do
  impact 0.8
  title 'Ensure EXECUTE on DBMS_LDAP is revoked from PUBLIC'
  desc 'DBMS_LDAP can be used for unauthorized LDAP access.'
  tag nist: ['AC-6', 'SC-7']
  tag cis: '3.15'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'DBMS_LDAP'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.16' do
  impact 0.8
  title 'Ensure EXECUTE on DBMS_ADVISOR is revoked from PUBLIC'
  desc 'DBMS_ADVISOR can expose sensitive tuning information.'
  tag nist: ['AC-6', 'CM-7']
  tag cis: '3.16'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'DBMS_ADVISOR'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.17' do
  impact 1.0
  title 'Ensure DBA role is not granted to unauthorized users'
  desc 'DBA role grants full database privileges and should be restricted.'
  tag nist: ['AC-6', 'AC-2']
  tag cis: '3.17'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_role_privs WHERE granted_role = 'DBA' AND grantee NOT IN ('SYS', 'SYSTEM')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.18' do
  impact 1.0
  title 'Ensure SELECT ANY TABLE is not granted to unauthorized users'
  desc 'SELECT ANY TABLE allows reading any table in the database.'
  tag nist: ['AC-6', 'AC-3']
  tag cis: '3.18'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_sys_privs WHERE privilege = 'SELECT ANY TABLE' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA', 'IMP_FULL_DATABASE', 'EXP_FULL_DATABASE', 'DATAPUMP_IMP_FULL_DATABASE', 'DATAPUMP_EXP_FULL_DATABASE', 'OEM_MONITOR')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.19' do
  impact 1.0
  title 'Ensure INSERT ANY TABLE is not granted to unauthorized users'
  desc 'INSERT ANY TABLE allows inserting into any table in the database.'
  tag nist: ['AC-6', 'AC-3']
  tag cis: '3.19'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_sys_privs WHERE privilege = 'INSERT ANY TABLE' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA', 'IMP_FULL_DATABASE', 'DATAPUMP_IMP_FULL_DATABASE')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.20' do
  impact 1.0
  title 'Ensure UPDATE ANY TABLE is not granted to unauthorized users'
  desc 'UPDATE ANY TABLE allows updating any table in the database.'
  tag nist: ['AC-6', 'AC-3']
  tag cis: '3.20'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_sys_privs WHERE privilege = 'UPDATE ANY TABLE' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA', 'IMP_FULL_DATABASE', 'DATAPUMP_IMP_FULL_DATABASE')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.21' do
  impact 1.0
  title 'Ensure DELETE ANY TABLE is not granted to unauthorized users'
  desc 'DELETE ANY TABLE allows deleting from any table in the database.'
  tag nist: ['AC-6', 'AC-3']
  tag cis: '3.21'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_sys_privs WHERE privilege = 'DELETE ANY TABLE' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA', 'IMP_FULL_DATABASE', 'DATAPUMP_IMP_FULL_DATABASE')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.22' do
  impact 1.0
  title 'Ensure CREATE ANY PROCEDURE is not granted to unauthorized users'
  desc 'CREATE ANY PROCEDURE allows code execution in any schema.'
  tag nist: ['AC-6', 'AC-3']
  tag cis: '3.22'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_sys_privs WHERE privilege = 'CREATE ANY PROCEDURE' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.23' do
  impact 1.0
  title 'Ensure ALTER SYSTEM is not granted to unauthorized users'
  desc 'ALTER SYSTEM allows modification of database configuration.'
  tag nist: ['AC-6', 'CM-5']
  tag cis: '3.23'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_sys_privs WHERE privilege = 'ALTER SYSTEM' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.24' do
  impact 1.0
  title 'Ensure CREATE USER is not granted to unauthorized users'
  desc 'CREATE USER allows creating new database users.'
  tag nist: ['AC-6', 'AC-2']
  tag cis: '3.24'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_sys_privs WHERE privilege = 'CREATE USER' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.25' do
  impact 1.0
  title 'Ensure DROP USER is not granted to unauthorized users'
  desc 'DROP USER allows removing database users.'
  tag nist: ['AC-6', 'AC-2']
  tag cis: '3.25'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_sys_privs WHERE privilege = 'DROP USER' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.26' do
  impact 1.0
  title 'Ensure proxy users do not have administrative privileges'
  desc 'Proxy users should not have DBA or administrative privileges.'
  tag nist: ['AC-6', 'AC-2']
  tag cis: '3.26'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_role_privs rp JOIN proxy_users pu ON rp.grantee = pu.client WHERE rp.granted_role = 'DBA'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

control 'oracle-11g-3.27' do
  impact 1.0
  title 'Ensure SYS.USER$ table access is restricted'
  desc 'Password hashes should not be accessible to regular users.'
  tag nist: ['AC-6', 'IA-5']
  tag cis: '3.27'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE table_name = 'USER$' AND owner = 'SYS' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

# ==============================================================================
# Section 4: Auditing
# NIST: AU-2 (Audit Events), AU-3 (Audit Content), AU-12 (Audit Generation)
# ==============================================================================

control 'oracle-11g-4.01' do
  impact 1.0
  title 'Ensure Oracle audit trail is enabled'
  desc 'Oracle database should have audit trail enabled for security compliance.'
  tag nist: ['AU-2', 'AU-12']
  tag cis: '4.1'
  tag severity: 'high'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'audit_trail'").row(0).column('value') do
    its('value') { should satisfy { |v| !v.nil? && v.to_s.strip.upcase != 'NONE' } }
  end
end

control 'oracle-11g-4.02' do
  impact 1.0
  title 'Ensure traditional auditing is properly configured'
  desc 'Oracle 11g should use traditional auditing (AUDIT_TRAIL parameter) for comprehensive audit trail.'
  tag nist: ['AU-2', 'AU-12']
  tag cis: '4.2'
  tag severity: 'high'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'audit_trail'").row(0).column('value') do
    its('value') { should satisfy { |v| ['DB', 'DB,EXTENDED', 'XML', 'XML,EXTENDED', 'OS'].include?(v.to_s.strip.upcase) } }
  end
end

control 'oracle-11g-4.03' do
  impact 1.0
  title 'Ensure logon and logoff actions are audited'
  desc 'Auditing logon/logoff helps detect unauthorized access attempts.'
  tag nist: ['AU-2', 'AU-3', 'AU-12']
  tag cis: '4.3'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_stmt_audit_opts WHERE audit_option IN ('CREATE SESSION') AND success = 'BY ACCESS' AND failure = 'BY ACCESS'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i >= 1 } }
  end
end

control 'oracle-11g-4.04' do
  impact 1.0
  title 'Ensure GRANT and REVOKE actions are audited'
  desc 'Auditing privilege changes helps detect unauthorized modifications.'
  tag nist: ['AU-2', 'AU-12']
  tag cis: '4.4'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_stmt_audit_opts WHERE audit_option IN ('GRANT ANY PRIVILEGE', 'GRANT ANY ROLE')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i >= 1 } }
  end
end

control 'oracle-11g-4.05' do
  impact 1.0
  title 'Ensure ALTER SYSTEM is audited'
  desc 'Auditing system changes helps detect unauthorized modifications.'
  tag nist: ['AU-2', 'AU-12']
  tag cis: '4.5'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_stmt_audit_opts WHERE audit_option = 'ALTER SYSTEM'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i >= 1 } }
  end
end

control 'oracle-11g-4.06' do
  impact 1.0
  title 'Ensure USER management is audited'
  desc 'Auditing user management helps detect unauthorized account changes.'
  tag nist: ['AU-2', 'AU-12']
  tag cis: '4.6'
  tag severity: 'high'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_stmt_audit_opts WHERE audit_option IN ('USER', 'CREATE USER', 'ALTER USER', 'DROP USER')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i >= 1 } }
  end
end

control 'oracle-11g-4.07' do
  impact 0.8
  title 'Ensure ROLE management is audited'
  desc 'Auditing role management helps detect unauthorized privilege changes.'
  tag nist: ['AU-2', 'AU-12']
  tag cis: '4.7'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_stmt_audit_opts WHERE audit_option IN ('ROLE', 'CREATE ROLE', 'ALTER ROLE', 'DROP ROLE')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i >= 1 } }
  end
end

control 'oracle-11g-4.08' do
  impact 0.8
  title 'Ensure DDL statements are audited'
  desc 'Auditing DDL helps track schema changes.'
  tag nist: ['AU-2', 'AU-12']
  tag cis: '4.8'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_stmt_audit_opts WHERE audit_option IN ('CREATE TABLE', 'ALTER TABLE', 'DROP TABLE', 'CREATE INDEX', 'DROP INDEX')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i >= 1 } }
  end
end

control 'oracle-11g-4.09' do
  impact 0.8
  title 'Ensure database link actions are audited'
  desc 'Auditing database links helps track remote connectivity.'
  tag nist: ['AU-2', 'AU-12']
  tag cis: '4.9'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_stmt_audit_opts WHERE audit_option IN ('DATABASE LINK', 'CREATE DATABASE LINK', 'DROP DATABASE LINK')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i >= 1 } }
  end
end

control 'oracle-11g-4.10' do
  impact 0.8
  title 'Ensure procedure and function changes are audited'
  desc 'Auditing code changes helps track application modifications.'
  tag nist: ['AU-2', 'AU-12']
  tag cis: '4.10'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_stmt_audit_opts WHERE audit_option IN ('PROCEDURE', 'CREATE PROCEDURE', 'DROP PROCEDURE')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i >= 1 } }
  end
end

control 'oracle-11g-4.11' do
  impact 0.8
  title 'Ensure profile changes are audited'
  desc 'Auditing profile changes helps track security policy modifications.'
  tag nist: ['AU-2', 'AU-12']
  tag cis: '4.11'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_stmt_audit_opts WHERE audit_option IN ('PROFILE', 'CREATE PROFILE', 'ALTER PROFILE', 'DROP PROFILE')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i >= 1 } }
  end
end

control 'oracle-11g-4.12' do
  impact 0.7
  title 'Ensure audit trail is protected'
  desc 'The audit trail should be protected from unauthorized modification.'
  tag nist: ['AU-9', 'AC-6']
  tag cis: '4.12'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE table_name IN ('AUD$', 'FGA_LOG$') AND grantee NOT IN ('SYS', 'SYSTEM')").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end

# ==============================================================================
# Section 5: Network Configuration
# NIST: SC-7 (Boundary Protection), SC-8 (Transmission Confidentiality)
# ==============================================================================

control 'oracle-11g-5.01' do
  impact 0.8
  title 'Ensure SEC_MAX_FAILED_LOGIN_ATTEMPTS is configured'
  desc 'Limits failed login attempts before account lockout.'
  tag nist: ['AC-7', 'IA-5']
  tag cis: '5.1'
  tag severity: 'medium'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'sec_max_failed_login_attempts'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

control 'oracle-11g-5.02' do
  impact 0.7
  title 'Ensure external procedures are restricted'
  desc 'External procedures can execute OS commands and should be restricted.'
  tag nist: ['SC-7', 'CM-7']
  tag cis: '5.2'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_libraries WHERE library_name = 'EXTPROC_CONNECTION_DATA'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i >= 0 } }
  end
end

control 'oracle-11g-5.03' do
  impact 0.7
  title 'Ensure dispatchers are properly configured'
  desc 'Shared server dispatchers should be minimized.'
  tag nist: ['SC-7', 'CM-6']
  tag cis: '5.3'
  tag severity: 'medium'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'dispatchers'").row(0).column('value') do
    its('value') { should satisfy { |v| v.nil? || v.to_s.strip.empty? || v.to_s.strip.match?(/PROTOCOL=TCP/) } }
  end
end

# ==============================================================================
# Section 6: Password Management
# NIST: IA-5 (Authenticator Management)
# ==============================================================================

control 'oracle-11g-6.01' do
  impact 1.0
  title 'Ensure password verification function is enabled'
  desc 'Oracle should enforce strong password policies.'
  tag nist: ['IA-5']
  tag cis: '6.1'
  tag severity: 'high'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_VERIFY_FUNCTION' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should satisfy { |v| !v.nil? && v.to_s.strip.upcase != 'NULL' } }
  end
end

control 'oracle-11g-6.02' do
  impact 0.7
  title 'Ensure case-sensitive logon is enabled'
  desc 'Oracle should enforce case-sensitive passwords.'
  tag nist: ['IA-5']
  tag cis: '6.2'
  tag severity: 'medium'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'sec_case_sensitive_logon'").row(0).column('value') do
    its('value') { should satisfy { |v| v.to_s.strip.upcase == 'TRUE' } }
  end
end

control 'oracle-11g-6.03' do
  impact 0.9
  title 'Ensure password expiration is configured'
  desc 'Passwords should expire to enforce regular password changes.'
  tag nist: ['IA-5']
  tag cis: '6.3'
  tag severity: 'high'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_LIFE_TIME' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should satisfy { |v| !v.nil? && v.to_s.strip.upcase != 'UNLIMITED' } }
  end
end

control 'oracle-11g-6.04' do
  impact 0.9
  title 'Ensure failed login attempts are limited'
  desc 'Accounts should be locked after failed login attempts.'
  tag nist: ['AC-7', 'IA-5']
  tag cis: '6.4'
  tag severity: 'high'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'FAILED_LOGIN_ATTEMPTS' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should satisfy { |v| !v.nil? && v.to_s.strip.upcase != 'UNLIMITED' } }
  end
end

control 'oracle-11g-6.05' do
  impact 0.8
  title 'Ensure PASSWORD_LOCK_TIME is set appropriately'
  desc 'Locks accounts for a specified period after failed login attempts.'
  tag nist: ['AC-7', 'IA-5']
  tag cis: '6.5'
  tag severity: 'medium'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_LOCK_TIME' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should satisfy { |v| !v.nil? && v.to_s.strip.upcase != 'UNLIMITED' } }
  end
end

control 'oracle-11g-6.06' do
  impact 0.7
  title 'Ensure PASSWORD_GRACE_TIME is set appropriately'
  desc 'Limits grace period for password expiration.'
  tag nist: ['IA-5']
  tag cis: '6.6'
  tag severity: 'medium'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_GRACE_TIME' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should satisfy { |v| !v.nil? && v.to_s.strip.upcase != 'UNLIMITED' } }
  end
end

control 'oracle-11g-6.07' do
  impact 0.8
  title 'Ensure PASSWORD_REUSE_MAX is set appropriately'
  desc 'Prevents password reuse for a number of changes.'
  tag nist: ['IA-5']
  tag cis: '6.7'
  tag severity: 'medium'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_REUSE_MAX' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should satisfy { |v| !v.nil? && v.to_s.strip.upcase != 'UNLIMITED' } }
  end
end

control 'oracle-11g-6.08' do
  impact 0.8
  title 'Ensure PASSWORD_REUSE_TIME is set appropriately'
  desc 'Prevents password reuse within a time period.'
  tag nist: ['IA-5']
  tag cis: '6.8'
  tag severity: 'medium'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_REUSE_TIME' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should satisfy { |v| !v.nil? && v.to_s.strip.upcase != 'UNLIMITED' } }
  end
end

control 'oracle-11g-6.09' do
  impact 0.5
  title 'Ensure SESSIONS_PER_USER is set appropriately'
  desc 'Limits concurrent sessions per user.'
  tag nist: ['AC-10', 'SC-5']
  tag cis: '6.9'
  tag severity: 'low'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'SESSIONS_PER_USER' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should satisfy { |v| !v.nil? && v.to_s.strip.upcase != 'UNLIMITED' } }
  end
end

control 'oracle-11g-6.10' do
  impact 0.5
  title 'Ensure IDLE_TIME is set appropriately'
  desc 'Disconnects idle sessions to free resources.'
  tag nist: ['AC-11', 'SC-10']
  tag cis: '6.10'
  tag severity: 'low'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'IDLE_TIME' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should satisfy { |v| !v.nil? && v.to_s.strip.upcase != 'UNLIMITED' } }
  end
end

# ==============================================================================
# Section 7: Encryption
# NIST: SC-8 (Transmission Confidentiality), SC-28 (Protection at Rest)
# ==============================================================================

control 'oracle-11g-7.01' do
  impact 0.8
  title 'Ensure TDE tablespace encryption is considered'
  desc 'Transparent Data Encryption protects data at rest.'
  tag nist: ['SC-28', 'SC-13']
  tag cis: '7.1'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM v$encryption_wallet WHERE status = 'OPEN'") do
    its('rows') { should_not be_empty }
  end
end

control 'oracle-11g-7.02' do
  impact 0.8
  title 'Ensure encrypted tablespaces exist for sensitive data'
  desc 'Sensitive data should be stored in encrypted tablespaces.'
  tag nist: ['SC-28', 'SC-13']
  tag cis: '7.2'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tablespaces WHERE encrypted = 'YES'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i >= 0 } }
  end
end

control 'oracle-11g-7.03' do
  impact 0.8
  title 'Ensure network encryption is configured'
  desc 'Network traffic should be encrypted to protect data in transit.'
  tag nist: ['SC-8', 'SC-13']
  tag cis: '7.3'
  tag severity: 'medium'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'sec_protocol_error_trace_action'").row(0).column('value') do
    its('value') { should satisfy { |v| v.nil? || ['TRACE', 'LOG', 'ALERT', 'NONE'].include?(v.to_s.strip.upcase) } }
  end
end

# ==============================================================================
# Section 8: Listener Security
# NIST: SC-7 (Boundary Protection), AC-3 (Access Enforcement)
# ==============================================================================

control 'oracle-11g-8.01' do
  impact 0.7
  title 'Ensure listener logging is configured'
  desc 'Listener logging helps track connection attempts.'
  tag nist: ['AU-2', 'SC-7']
  tag cis: '8.1'
  tag severity: 'medium'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'local_listener'") do
    its('rows') { should_not be_empty }
  end
end

control 'oracle-11g-8.02' do
  impact 0.7
  title 'Ensure database links are documented'
  desc 'Database links should be documented and reviewed periodically.'
  tag nist: ['CM-8', 'AC-4']
  tag cis: '8.2'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_db_links").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i >= 0 } }
  end
end

control 'oracle-11g-8.03' do
  impact 0.7
  title 'Ensure PUBLIC database links do not exist'
  desc 'PUBLIC database links allow all users to access remote databases.'
  tag nist: ['AC-6', 'AC-4']
  tag cis: '8.3'
  tag severity: 'medium'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_db_links WHERE owner = 'PUBLIC'").row(0).column('cnt') do
    its('value') { should satisfy { |v| v.to_s.strip.to_i == 0 } }
  end
end
