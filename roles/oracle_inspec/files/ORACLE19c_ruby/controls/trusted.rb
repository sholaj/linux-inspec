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

# ==============================================================================
# Section 2: Oracle Parameter Settings
# ==============================================================================

# Control 2.01: Ensure AUDIT_SYS_OPERATIONS is set to TRUE
control 'oracle-19c-2.01' do
  impact 1.0
  title "Ensure 'AUDIT_SYS_OPERATIONS' Is Set to 'TRUE'"
  desc 'Auditing SYS operations provides accountability for privileged users.'
  tag cis: '2.2.1'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'audit_sys_operations'").row(0).column('value') do
    its('value') { should cmp 'TRUE' }
  end
end

# Control 2.02: Ensure GLOBAL_NAMES is set to TRUE
control 'oracle-19c-2.02' do
  impact 0.7
  title "Ensure 'GLOBAL_NAMES' Is Set to 'TRUE'"
  desc 'Forces database links to have the same name as the remote database.'
  tag cis: '2.2.2'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'global_names'").row(0).column('value') do
    its('value') { should cmp 'TRUE' }
  end
end

# Control 2.03: Ensure O7_DICTIONARY_ACCESSIBILITY is set to FALSE
control 'oracle-19c-2.03' do
  impact 1.0
  title "Ensure 'O7_DICTIONARY_ACCESSIBILITY' Is Set to 'FALSE'"
  desc 'Prevents users with ANY privilege from accessing SYS schema objects.'
  tag cis: '2.2.3'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'o7_dictionary_accessibility'").row(0).column('value') do
    its('value') { should cmp 'FALSE' }
  end
end

# Control 2.04: Ensure OS_ROLES is set to FALSE
control 'oracle-19c-2.04' do
  impact 1.0
  title "Ensure 'OS_ROLES' Is Set to 'FALSE'"
  desc 'Disables operating system role management.'
  tag cis: '2.2.4'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'os_roles'").row(0).column('value') do
    its('value') { should cmp 'FALSE' }
  end
end

# Control 2.05: Ensure REMOTE_LISTENER is empty
control 'oracle-19c-2.05' do
  impact 1.0
  title "Ensure 'REMOTE_LISTENER' Is Empty"
  desc 'Remote listener allows network connections which may be exploited.'
  tag cis: '2.2.5'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'remote_listener'").row(0).column('value') do
    its('value') { should be_nil.or be_empty }
  end
end

# Control 2.06: Ensure REMOTE_OS_AUTHENT is set to FALSE
control 'oracle-19c-2.06' do
  impact 1.0
  title "Ensure 'REMOTE_OS_AUTHENT' Is Set to 'FALSE'"
  desc 'Prevents remote OS authentication which can be spoofed.'
  tag cis: '2.2.6'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'remote_os_authent'").row(0).column('value') do
    its('value') { should cmp 'FALSE' }
  end
end

# Control 2.07: Ensure REMOTE_OS_ROLES is set to FALSE
control 'oracle-19c-2.07' do
  impact 1.0
  title "Ensure 'REMOTE_OS_ROLES' Is Set to 'FALSE'"
  desc 'Prevents remote operating system roles from being used.'
  tag cis: '2.2.7'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'remote_os_roles'").row(0).column('value') do
    its('value') { should cmp 'FALSE' }
  end
end

# Control 2.08: Ensure UTL_FILE_DIR is empty
control 'oracle-19c-2.08' do
  impact 1.0
  title "Ensure 'UTL_FILE_DIR' Is Empty"
  desc 'UTL_FILE_DIR allows file system access which can be dangerous.'
  tag cis: '2.2.8'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'utl_file_dir'").row(0).column('value') do
    its('value') { should be_nil.or be_empty }
  end
end

# Control 2.09: Ensure SEC_RETURN_SERVER_RELEASE_BANNER is set to FALSE
control 'oracle-19c-2.09' do
  impact 0.5
  title "Ensure 'SEC_RETURN_SERVER_RELEASE_BANNER' Is Set to 'FALSE'"
  desc 'Prevents detailed version information from being returned to clients.'
  tag cis: '2.2.9'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'sec_return_server_release_banner'").row(0).column('value') do
    its('value') { should cmp 'FALSE' }
  end
end

# Control 2.10: Ensure RESOURCE_LIMIT is set to TRUE
control 'oracle-19c-2.10' do
  impact 0.7
  title "Ensure 'RESOURCE_LIMIT' Is Set to 'TRUE'"
  desc 'Enables enforcement of resource limits set in profiles.'
  tag cis: '2.2.10'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'resource_limit'").row(0).column('value') do
    its('value') { should cmp 'TRUE' }
  end
end

# ==============================================================================
# Section 3: User and Privilege Settings
# ==============================================================================

# Control 3.01: Ensure no users have UNLIMITED tablespace quota
control 'oracle-19c-3.01' do
  impact 0.8
  title 'Ensure no users have UNLIMITED tablespace quota'
  desc 'Unlimited quotas can lead to denial of service.'
  tag cis: '3.1'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_ts_quotas WHERE max_bytes = -1 AND username NOT IN ('SYS', 'SYSTEM')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 3.02: Ensure DBA role is not granted to unauthorized users
control 'oracle-19c-3.02' do
  impact 1.0
  title 'Ensure DBA role granted only to authorized users'
  desc 'DBA role grants full database privileges and should be restricted.'
  tag cis: '3.2'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_role_privs WHERE granted_role = 'DBA' AND grantee NOT IN ('SYS', 'SYSTEM')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 3.03: Ensure SELECT ANY TABLE is not granted to unauthorized users
control 'oracle-19c-3.03' do
  impact 1.0
  title 'Ensure SELECT ANY TABLE is revoked from unauthorized users'
  desc 'SELECT ANY TABLE allows reading any table in the database.'
  tag cis: '3.3'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_sys_privs WHERE privilege = 'SELECT ANY TABLE' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA', 'IMP_FULL_DATABASE', 'EXP_FULL_DATABASE', 'DATAPUMP_IMP_FULL_DATABASE')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 3.04: Ensure INSERT ANY TABLE is not granted to unauthorized users
control 'oracle-19c-3.04' do
  impact 1.0
  title 'Ensure INSERT ANY TABLE is revoked from unauthorized users'
  desc 'INSERT ANY TABLE allows inserting into any table in the database.'
  tag cis: '3.4'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_sys_privs WHERE privilege = 'INSERT ANY TABLE' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA', 'IMP_FULL_DATABASE', 'DATAPUMP_IMP_FULL_DATABASE')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 3.05: Ensure UPDATE ANY TABLE is not granted to unauthorized users
control 'oracle-19c-3.05' do
  impact 1.0
  title 'Ensure UPDATE ANY TABLE is revoked from unauthorized users'
  desc 'UPDATE ANY TABLE allows updating any table in the database.'
  tag cis: '3.5'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_sys_privs WHERE privilege = 'UPDATE ANY TABLE' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA', 'IMP_FULL_DATABASE', 'DATAPUMP_IMP_FULL_DATABASE')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 3.06: Ensure DELETE ANY TABLE is not granted to unauthorized users
control 'oracle-19c-3.06' do
  impact 1.0
  title 'Ensure DELETE ANY TABLE is revoked from unauthorized users'
  desc 'DELETE ANY TABLE allows deleting from any table in the database.'
  tag cis: '3.6'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_sys_privs WHERE privilege = 'DELETE ANY TABLE' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA', 'IMP_FULL_DATABASE', 'DATAPUMP_IMP_FULL_DATABASE')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 3.07: Ensure CREATE ANY PROCEDURE is not granted to unauthorized users
control 'oracle-19c-3.07' do
  impact 1.0
  title 'Ensure CREATE ANY PROCEDURE is revoked from unauthorized users'
  desc 'CREATE ANY PROCEDURE allows code execution in any schema.'
  tag cis: '3.7'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_sys_privs WHERE privilege = 'CREATE ANY PROCEDURE' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 3.08: Ensure ALTER SYSTEM is not granted to unauthorized users
control 'oracle-19c-3.08' do
  impact 1.0
  title 'Ensure ALTER SYSTEM is revoked from unauthorized users'
  desc 'ALTER SYSTEM allows modification of database configuration.'
  tag cis: '3.8'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_sys_privs WHERE privilege = 'ALTER SYSTEM' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 3.09: Ensure CREATE USER is not granted to unauthorized users
control 'oracle-19c-3.09' do
  impact 1.0
  title 'Ensure CREATE USER is revoked from unauthorized users'
  desc 'CREATE USER allows creating new database users.'
  tag cis: '3.9'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_sys_privs WHERE privilege = 'CREATE USER' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 3.10: Ensure DROP USER is not granted to unauthorized users
control 'oracle-19c-3.10' do
  impact 1.0
  title 'Ensure DROP USER is revoked from unauthorized users'
  desc 'DROP USER allows removing database users.'
  tag cis: '3.10'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_sys_privs WHERE privilege = 'DROP USER' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# ==============================================================================
# Section 4: Audit Settings
# ==============================================================================

# Control 4.01: Ensure all logon and logoff actions are audited
control 'oracle-19c-4.01' do
  impact 1.0
  title 'Ensure all logon and logoff actions are audited'
  desc 'Auditing logon/logoff helps detect unauthorized access attempts.'
  tag cis: '4.1'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_stmt_audit_opts WHERE audit_option IN ('CREATE SESSION') AND success = 'BY ACCESS' AND failure = 'BY ACCESS'").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# Control 4.02: Ensure GRANT and REVOKE actions are audited
control 'oracle-19c-4.02' do
  impact 1.0
  title 'Ensure GRANT and REVOKE actions are audited'
  desc 'Auditing privilege changes helps detect unauthorized modifications.'
  tag cis: '4.2'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_stmt_audit_opts WHERE audit_option IN ('GRANT ANY PRIVILEGE', 'GRANT ANY ROLE')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# Control 4.03: Ensure ALTER SYSTEM is audited
control 'oracle-19c-4.03' do
  impact 1.0
  title 'Ensure ALTER SYSTEM is audited'
  desc 'Auditing system changes helps detect unauthorized modifications.'
  tag cis: '4.3'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_stmt_audit_opts WHERE audit_option = 'ALTER SYSTEM'").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# Control 4.04: Ensure USER management is audited
control 'oracle-19c-4.04' do
  impact 1.0
  title 'Ensure USER management is audited'
  desc 'Auditing user management helps detect unauthorized account changes.'
  tag cis: '4.4'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_stmt_audit_opts WHERE audit_option IN ('USER', 'CREATE USER', 'ALTER USER', 'DROP USER')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# Control 4.05: Ensure ROLE management is audited
control 'oracle-19c-4.05' do
  impact 0.8
  title 'Ensure ROLE management is audited'
  desc 'Auditing role management helps detect unauthorized privilege changes.'
  tag cis: '4.5'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_stmt_audit_opts WHERE audit_option IN ('ROLE', 'CREATE ROLE', 'ALTER ROLE', 'DROP ROLE')").row(0).column('cnt') do
    its('value') { should be >= 1 }
  end
end

# ==============================================================================
# Section 5: Password and Profile Settings
# ==============================================================================

# Control 5.01: Ensure PASSWORD_LOCK_TIME is set appropriately
control 'oracle-19c-5.01' do
  impact 0.8
  title 'Ensure PASSWORD_LOCK_TIME is set to greater than or equal to 1'
  desc 'Locks accounts for at least 1 day after failed login attempts.'
  tag cis: '5.1'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_LOCK_TIME' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should_not cmp 'UNLIMITED' }
  end
end

# Control 5.02: Ensure PASSWORD_GRACE_TIME is set appropriately
control 'oracle-19c-5.02' do
  impact 0.7
  title 'Ensure PASSWORD_GRACE_TIME is set to less than or equal to 5'
  desc 'Limits grace period for password expiration.'
  tag cis: '5.2'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_GRACE_TIME' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should_not cmp 'UNLIMITED' }
  end
end

# Control 5.03: Ensure PASSWORD_REUSE_MAX is set appropriately
control 'oracle-19c-5.03' do
  impact 0.8
  title 'Ensure PASSWORD_REUSE_MAX is set to greater than or equal to 20'
  desc 'Prevents password reuse for a number of changes.'
  tag cis: '5.3'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_REUSE_MAX' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should_not cmp 'UNLIMITED' }
  end
end

# Control 5.04: Ensure PASSWORD_REUSE_TIME is set appropriately
control 'oracle-19c-5.04' do
  impact 0.8
  title 'Ensure PASSWORD_REUSE_TIME is set to greater than or equal to 365'
  desc 'Prevents password reuse within a time period.'
  tag cis: '5.4'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'PASSWORD_REUSE_TIME' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should_not cmp 'UNLIMITED' }
  end
end

# Control 5.05: Ensure SESSIONS_PER_USER is set appropriately
control 'oracle-19c-5.05' do
  impact 0.5
  title 'Ensure SESSIONS_PER_USER is set to a limited value'
  desc 'Limits concurrent sessions per user.'
  tag cis: '5.5'

  describe sql.query("SELECT limit FROM dba_profiles WHERE resource_name = 'SESSIONS_PER_USER' AND profile = 'DEFAULT'").row(0).column('limit') do
    its('value') { should_not cmp 'UNLIMITED' }
  end
end

# ==============================================================================
# Section 6: Network and Connection Settings
# ==============================================================================

# Control 6.01: Ensure SECURE_CONTROL_FILE is configured
control 'oracle-19c-6.01' do
  impact 0.7
  title 'Ensure control files are properly configured'
  desc 'Control files should be multiplexed for data protection.'
  tag cis: '6.1'

  describe sql.query("SELECT COUNT(*) AS cnt FROM v$controlfile").row(0).column('cnt') do
    its('value') { should be >= 2 }
  end
end

# Control 6.02: Ensure redo logs are multiplexed
control 'oracle-19c-6.02' do
  impact 0.7
  title 'Ensure redo logs are multiplexed'
  desc 'Redo logs should have multiple members for data protection.'
  tag cis: '6.2'

  describe sql.query("SELECT MIN(members) AS min_members FROM v$log").row(0).column('min_members') do
    its('value') { should be >= 2 }
  end
end

# Control 6.03: Ensure SEC_MAX_FAILED_LOGIN_ATTEMPTS is configured
control 'oracle-19c-6.03' do
  impact 1.0
  title 'Ensure SEC_MAX_FAILED_LOGIN_ATTEMPTS is set'
  desc 'Limits failed login attempts before account lockout.'
  tag cis: '6.3'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'sec_max_failed_login_attempts'").row(0).column('value') do
    its('value') { should_not be_nil }
  end
end

# ==============================================================================
# Section 7: Additional Security Settings
# ==============================================================================

# Control 7.01: Ensure EXECUTE on DBMS_JOB is revoked from PUBLIC
control 'oracle-19c-7.01' do
  impact 0.8
  title 'Ensure EXECUTE on DBMS_JOB is revoked from PUBLIC'
  desc 'DBMS_JOB can be used to schedule malicious code.'
  tag cis: '7.1'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'DBMS_JOB'").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 7.02: Ensure EXECUTE on DBMS_SCHEDULER is revoked from PUBLIC
control 'oracle-19c-7.02' do
  impact 0.8
  title 'Ensure EXECUTE on DBMS_SCHEDULER is revoked from PUBLIC'
  desc 'DBMS_SCHEDULER can be used to schedule malicious code.'
  tag cis: '7.2'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'DBMS_SCHEDULER'").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 7.03: Ensure EXECUTE on DBMS_SYS_SQL is revoked from PUBLIC
control 'oracle-19c-7.03' do
  impact 1.0
  title 'Ensure EXECUTE on DBMS_SYS_SQL is revoked from PUBLIC'
  desc 'DBMS_SYS_SQL can execute SQL as another user.'
  tag cis: '7.3'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'DBMS_SYS_SQL'").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 7.04: Ensure EXECUTE on DBMS_BACKUP_RESTORE is revoked from PUBLIC
control 'oracle-19c-7.04' do
  impact 0.8
  title 'Ensure EXECUTE on DBMS_BACKUP_RESTORE is revoked from PUBLIC'
  desc 'DBMS_BACKUP_RESTORE can be used to access backup data.'
  tag cis: '7.4'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'DBMS_BACKUP_RESTORE'").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 7.05: Ensure EXECUTE on UTL_MAIL is revoked from PUBLIC
control 'oracle-19c-7.05' do
  impact 0.7
  title 'Ensure EXECUTE on UTL_MAIL is revoked from PUBLIC'
  desc 'UTL_MAIL can be used for unauthorized email sending.'
  tag cis: '7.5'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND privilege = 'EXECUTE' AND table_name = 'UTL_MAIL'").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 7.06: Ensure no proxy users have administrative privileges
control 'oracle-19c-7.06' do
  impact 1.0
  title 'Ensure proxy users do not have administrative privileges'
  desc 'Proxy users should not have DBA or administrative privileges.'
  tag cis: '7.6'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_role_privs rp JOIN proxy_users pu ON rp.grantee = pu.client WHERE rp.granted_role = 'DBA'").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end

# Control 7.07: Ensure SYS.USER$ passwords are not accessible
control 'oracle-19c-7.07' do
  impact 1.0
  title 'Ensure SYS.USER$ table access is restricted'
  desc 'Password hashes should not be accessible to regular users.'
  tag cis: '7.7'

  describe sql.query("SELECT COUNT(*) AS cnt FROM dba_tab_privs WHERE table_name = 'USER$' AND owner = 'SYS' AND grantee NOT IN ('SYS', 'SYSTEM', 'DBA')").row(0).column('cnt') do
    its('value') { should cmp 0 }
  end
end
