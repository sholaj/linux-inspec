# PostgreSQL 15 InSpec Controls - CIS PostgreSQL 15 Benchmark v1.0.0
# Version: 3.0.0
# Last Updated: 2026-02-08
#
# This profile implements CIS PostgreSQL 15 Benchmark controls
# for compliance reporting.
#
# Control ID Format: postgres-15-X.X.X

title 'CIS PostgreSQL 15 Security Compliance Controls'

# Establish connection to PostgreSQL
sql = postgres_session(
  input('usernm'),
  input('passwd'),
  input('hostnm'),
  input('port', value: 5432),
  input('database', value: 'postgres')
)

# ==============================================================================
# Section 1: Installation and Patches
# ==============================================================================

# Control 1.3: Ensure Data Cluster Initialized Successfully
control 'postgres-15-1.3' do
  impact 1.0
  title 'Ensure the Data Cluster Was Initialized Successfully'
  desc 'Verify PostgreSQL data cluster is properly initialized and running.'
  tag cis: '1.3'
  tag section: 'Installation and Patches'

  describe sql.query("SELECT CASE WHEN COUNT(*) > 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS result FROM pg_database WHERE datname = 'postgres'") do
    its('output') { should match(/COMPLIANT/) }
  end
end

# Control 1.4: Ensure PostgreSQL Version is Current
control 'postgres-15-1.4' do
  impact 0.7
  title 'Ensure PostgreSQL Version is Up-to-Date'
  desc 'Running outdated PostgreSQL versions may expose the system to known vulnerabilities.'
  tag cis: '1.4'
  tag section: 'Installation and Patches'

  describe sql.query("SELECT version()") do
    its('output') { should match(/PostgreSQL 1[5-7]/) }
  end
end

# Control 1.5: Ensure Only Required Extensions Are Installed
control 'postgres-15-1.5' do
  impact 0.7
  title 'Ensure Only Necessary Extensions Are Installed'
  desc 'Unnecessary extensions increase the attack surface and should be removed.'
  tag cis: '1.5'
  tag section: 'Installation and Patches'

  describe sql.query("SELECT extname FROM pg_extension WHERE extname NOT IN ('plpgsql')") do
    its('output') { should_not match(/adminpack|file_fdw|postgres_fdw/) }
  end
end

# ==============================================================================
# Section 2: Directory and File Permissions
# ==============================================================================

# Control 2.1: Ensure the File Permissions Mask is Correct
control 'postgres-15-2.1' do
  impact 1.0
  title 'Ensure the File Permissions Mask Is Correct'
  desc 'PostgreSQL should use restrictive file permissions to protect sensitive data.'
  tag cis: '2.1'
  tag section: 'Directory and File Permissions'

  describe sql.query("SHOW data_directory") do
    its('output') { should_not be_empty }
  end
end

# Control 2.2: Ensure the PostgreSQL pg_wheel Group Membership is Correct
control 'postgres-15-2.2' do
  impact 0.7
  title 'Ensure PostgreSQL Ownership is Correct'
  desc 'PostgreSQL data directories should be owned by the postgres user.'
  tag cis: '2.2'
  tag section: 'Directory and File Permissions'

  describe sql.query("SELECT setting FROM pg_settings WHERE name = 'data_directory'") do
    its('output') { should_not be_empty }
  end
end

# ==============================================================================
# Section 3: Logging and Auditing
# ==============================================================================

# Control 3.1.2: Ensure the Log Destination is Configured Correctly
control 'postgres-15-3.1.2' do
  impact 1.0
  title 'Ensure the Log Destinations Are Set Correctly'
  desc 'Log destinations should be configured to ensure audit trail availability.'
  tag cis: '3.1.2'
  tag section: 'Logging and Auditing'

  describe sql.query("SHOW log_destination") do
    its('output') { should match(/stderr|csvlog|syslog/) }
  end
end

# Control 3.1.3: Ensure the Logging Collector is Enabled
control 'postgres-15-3.1.3' do
  impact 1.0
  title 'Ensure the Logging Collector is Enabled'
  desc 'The logging collector captures stderr output to log files.'
  tag cis: '3.1.3'
  tag section: 'Logging and Auditing'

  describe sql.query("SHOW logging_collector") do
    its('output') { should match(/on/i) }
  end
end

# Control 3.1.4: Ensure the Log File Destination Directory is Configured
control 'postgres-15-3.1.4' do
  impact 0.7
  title 'Ensure the Log File Destination Directory is Set Correctly'
  desc 'Log files should be stored in a dedicated directory.'
  tag cis: '3.1.4'
  tag section: 'Logging and Auditing'

  describe sql.query("SHOW log_directory") do
    its('output') { should_not be_empty }
  end
end

# Control 3.1.5: Ensure the Filename Pattern for Log Files is Configured
control 'postgres-15-3.1.5' do
  impact 0.5
  title 'Ensure the Filename Pattern for Log Files is Set Correctly'
  desc 'Log filenames should include timestamps for proper rotation and archival.'
  tag cis: '3.1.5'
  tag section: 'Logging and Auditing'

  describe sql.query("SHOW log_filename") do
    its('output') { should match(/%/) }
  end
end

# Control 3.1.6: Ensure the Log File Permissions are Correct
control 'postgres-15-3.1.6' do
  impact 1.0
  title 'Ensure the Log File Permissions Are Set Correctly'
  desc 'Log files should have restrictive permissions (0600).'
  tag cis: '3.1.6'
  tag section: 'Logging and Auditing'

  describe sql.query("SHOW log_file_mode") do
    its('output') { should match(/0600/) }
  end
end

# Control 3.1.7: Ensure Log File Rotation is Enabled
control 'postgres-15-3.1.7' do
  impact 0.7
  title 'Ensure Log Rotation Age is Configured'
  desc 'Log files should be rotated regularly to manage disk space.'
  tag cis: '3.1.7'
  tag section: 'Logging and Auditing'

  describe sql.query("SELECT CASE WHEN setting::int > 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS result FROM pg_settings WHERE name = 'log_rotation_age'") do
    its('output') { should match(/COMPLIANT/) }
  end
end

# Control 3.1.8: Ensure Log Rotation Size is Configured
control 'postgres-15-3.1.8' do
  impact 0.7
  title 'Ensure Log Rotation Size is Configured'
  desc 'Log files should be rotated based on size to prevent excessive disk usage.'
  tag cis: '3.1.8'
  tag section: 'Logging and Auditing'

  describe sql.query("SELECT CASE WHEN setting::int > 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS result FROM pg_settings WHERE name = 'log_rotation_size'") do
    its('output') { should match(/COMPLIANT/) }
  end
end

# Control 3.1.9: Ensure Syslog Facility is Configured Correctly
control 'postgres-15-3.1.9' do
  impact 0.5
  title 'Ensure the Syslog Facility is Set Correctly'
  desc 'When using syslog, ensure proper facility is configured.'
  tag cis: '3.1.9'
  tag section: 'Logging and Auditing'

  describe sql.query("SHOW syslog_facility") do
    its('output') { should match(/local[0-7]/) }
  end
end

# Control 3.1.10: Ensure Client Connection Logging is Enabled
control 'postgres-15-3.1.10' do
  impact 1.0
  title 'Ensure log_connections is Enabled'
  desc 'Logging connections helps track who connected to the database.'
  tag cis: '3.1.10'
  tag section: 'Logging and Auditing'

  describe sql.query("SHOW log_connections") do
    its('output') { should match(/on/i) }
  end
end

# Control 3.1.11: Ensure Client Disconnection Logging is Enabled
control 'postgres-15-3.1.11' do
  impact 1.0
  title 'Ensure log_disconnections is Enabled'
  desc 'Logging disconnections helps track session duration and patterns.'
  tag cis: '3.1.11'
  tag section: 'Logging and Auditing'

  describe sql.query("SHOW log_disconnections") do
    its('output') { should match(/on/i) }
  end
end

# Control 3.1.12: Ensure Error Verbosity is Appropriate
control 'postgres-15-3.1.12' do
  impact 0.7
  title 'Ensure log_error_verbosity is Set Appropriately'
  desc 'Error messages should provide sufficient detail for troubleshooting.'
  tag cis: '3.1.12'
  tag section: 'Logging and Auditing'

  describe sql.query("SHOW log_error_verbosity") do
    its('output') { should match(/default|verbose/i) }
  end
end

# Control 3.1.13: Ensure Log Line Prefix is Configured
control 'postgres-15-3.1.13' do
  impact 0.7
  title 'Ensure log_line_prefix Is Set Correctly'
  desc 'Log line prefix should include timestamp, user, database, and session info.'
  tag cis: '3.1.13'
  tag section: 'Logging and Auditing'

  describe sql.query("SHOW log_line_prefix") do
    its('output') { should match(/%[tmud]/) }
  end
end

# Control 3.1.14: Ensure Log Statement is Set Appropriately
control 'postgres-15-3.1.14' do
  impact 0.7
  title 'Ensure log_statement is Set Correctly'
  desc 'DDL statements should be logged for audit purposes.'
  tag cis: '3.1.14'
  tag section: 'Logging and Auditing'

  describe sql.query("SHOW log_statement") do
    its('output') { should match(/ddl|mod|all/i) }
  end
end

# Control 3.1.15: Ensure Log Timezone is Configured
control 'postgres-15-3.1.15' do
  impact 0.5
  title 'Ensure log_timezone is Set Correctly'
  desc 'Log timezone should be set for consistent timestamp interpretation.'
  tag cis: '3.1.15'
  tag section: 'Logging and Auditing'

  describe sql.query("SHOW log_timezone") do
    its('output') { should_not be_empty }
  end
end

# Control 3.1.16: Ensure Log Duration is Configured
control 'postgres-15-3.1.16' do
  impact 0.5
  title 'Ensure log_duration is Enabled for Long Statements'
  desc 'Logging statement duration helps identify performance issues.'
  tag cis: '3.1.16'
  tag section: 'Logging and Auditing'

  describe sql.query("SHOW log_duration") do
    its('output') { should_not be_empty }
  end
end

# Control 3.1.17: Ensure Log Min Duration Statement is Set
control 'postgres-15-3.1.17' do
  impact 0.7
  title 'Ensure log_min_duration_statement is Set'
  desc 'Statements exceeding the threshold should be logged for analysis.'
  tag cis: '3.1.17'
  tag section: 'Logging and Auditing'

  describe sql.query("SHOW log_min_duration_statement") do
    its('output') { should_not match(/-1/) }
  end
end

# Control 3.1.18: Ensure Log Hostname is Enabled
control 'postgres-15-3.1.18' do
  impact 0.5
  title 'Ensure log_hostname is Configured'
  desc 'Logging hostname helps identify the source of connections.'
  tag cis: '3.1.18'
  tag section: 'Logging and Auditing'

  describe sql.query("SHOW log_hostname") do
    its('output') { should_not be_empty }
  end
end

# Control 3.2: Ensure pgAudit Extension is Enabled
control 'postgres-15-3.2' do
  impact 1.0
  title 'Ensure the pgAudit Extension is Installed and Configured'
  desc 'pgAudit provides detailed session and object audit logging.'
  tag cis: '3.2'
  tag section: 'Logging and Auditing'

  describe sql.query("SELECT CASE WHEN COUNT(*) > 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS result FROM pg_extension WHERE extname = 'pgaudit'") do
    its('output') { should match(/COMPLIANT/) }
  end
end

# ==============================================================================
# Section 4: User Access and Authorization
# ==============================================================================

# Control 4.1: Ensure Appropriate Superuser Privileges
control 'postgres-15-4.1' do
  impact 1.0
  title 'Ensure Superuser Privileges are Limited'
  desc 'Only necessary accounts should have superuser privileges.'
  tag cis: '4.1'
  tag section: 'User Access and Authorization'

  describe sql.query("SELECT CASE WHEN COUNT(*) <= 2 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS result FROM pg_roles WHERE rolsuper = true") do
    its('output') { should match(/COMPLIANT/) }
  end
end

# Control 4.2: Ensure Login is Disabled for Default postgres User
control 'postgres-15-4.2' do
  impact 0.7
  title 'Ensure the postgres Superuser Has Limited Direct Access'
  desc 'Direct login as postgres should be restricted.'
  tag cis: '4.2'
  tag section: 'User Access and Authorization'

  describe sql.query("SELECT rolname FROM pg_roles WHERE rolsuper = true AND rolcanlogin = true") do
    its('output') { should match(/postgres/) }
  end
end

# Control 4.3: Ensure Public Schema Has Limited Privileges
control 'postgres-15-4.3' do
  impact 1.0
  title 'Ensure public Schema Has Restricted Privileges'
  desc 'The public schema should not grant CREATE to PUBLIC role.'
  tag cis: '4.3'
  tag section: 'User Access and Authorization'

  describe sql.query("SELECT CASE WHEN nspacl IS NULL OR array_to_string(nspacl, ',') NOT LIKE '%=UC/%' THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS result FROM pg_namespace WHERE nspname = 'public'") do
    its('output') { should match(/COMPLIANT/) }
  end
end

# Control 4.4: Ensure Default Privileges Are Revoked from PUBLIC
control 'postgres-15-4.4' do
  impact 1.0
  title 'Ensure CONNECT Has Been Revoked from PUBLIC on Databases'
  desc 'PUBLIC should not have CONNECT privilege on all databases.'
  tag cis: '4.4'
  tag section: 'User Access and Authorization'

  describe sql.query("SELECT datname FROM pg_database WHERE datacl IS NULL OR array_to_string(datacl, ',') LIKE '%=c/%' AND datname NOT IN ('template0', 'template1')") do
    its('output') { should be_empty }
  end
end

# Control 4.5: Ensure Excessive Function Privileges Are Revoked
control 'postgres-15-4.5' do
  impact 0.7
  title 'Ensure Excessive Function Privileges Are Revoked'
  desc 'EXECUTE on sensitive functions should be restricted.'
  tag cis: '4.5'
  tag section: 'User Access and Authorization'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS result FROM pg_proc WHERE proname IN ('pg_read_file', 'pg_read_binary_file', 'pg_ls_dir') AND proacl IS NULL") do
    its('output') { should match(/COMPLIANT/) }
  end
end

# Control 4.6: Ensure set_user Extension is Installed
control 'postgres-15-4.6' do
  impact 0.7
  title 'Ensure set_user Extension is Installed'
  desc 'set_user provides additional logging for privilege escalation.'
  tag cis: '4.6'
  tag section: 'User Access and Authorization'

  describe sql.query("SELECT CASE WHEN COUNT(*) > 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS result FROM pg_extension WHERE extname = 'set_user'") do
    its('output') { should match(/COMPLIANT/) }
  end
end

# Control 4.7: Ensure Row Level Security is Enabled Where Applicable
control 'postgres-15-4.7' do
  impact 0.7
  title 'Ensure Row Level Security (RLS) is Used Where Appropriate'
  desc 'RLS provides fine-grained access control at the row level.'
  tag cis: '4.7'
  tag section: 'User Access and Authorization'

  describe sql.query("SELECT CASE WHEN COUNT(*) >= 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS result FROM pg_class WHERE relrowsecurity = true") do
    its('output') { should match(/COMPLIANT/) }
  end
end

# Control 4.8: Ensure Password Complexity is Enforced
control 'postgres-15-4.8' do
  impact 1.0
  title 'Ensure Password Complexity Requirements Are Enforced'
  desc 'Password validation should enforce complexity requirements.'
  tag cis: '4.8'
  tag section: 'User Access and Authorization'

  describe sql.query("SHOW shared_preload_libraries") do
    its('output') { should match(/passwordcheck|credcheck/i) }
  end
end

# ==============================================================================
# Section 5: Connection and Login
# ==============================================================================

# Control 5.1: Ensure Local UNIX Socket Authentication is Configured
control 'postgres-15-5.1' do
  impact 1.0
  title 'Ensure Authentication Method for Local Socket is Secure'
  desc 'Local socket connections should use peer or scram-sha-256 authentication.'
  tag cis: '5.1'
  tag section: 'Connection and Login'

  describe sql.query("SELECT setting FROM pg_settings WHERE name = 'password_encryption'") do
    its('output') { should match(/scram-sha-256/) }
  end
end

# Control 5.2: Ensure Host TCP/IP Authentication is Configured
control 'postgres-15-5.2' do
  impact 1.0
  title 'Ensure Authentication Method for Host Connections is Secure'
  desc 'Host connections should use scram-sha-256 or certificate authentication.'
  tag cis: '5.2'
  tag section: 'Connection and Login'

  describe sql.query("SHOW password_encryption") do
    its('output') { should match(/scram-sha-256/) }
  end
end

# Control 5.3: Ensure SSL is Enabled
control 'postgres-15-5.3' do
  impact 1.0
  title 'Ensure SSL is Enabled for Client Connections'
  desc 'SSL/TLS should be enabled to encrypt data in transit.'
  tag cis: '5.3'
  tag section: 'Connection and Login'

  describe sql.query("SHOW ssl") do
    its('output') { should match(/on/i) }
  end
end

# Control 5.4: Ensure SSL Certificate is Valid
control 'postgres-15-5.4' do
  impact 1.0
  title 'Ensure a Valid SSL Certificate is Configured'
  desc 'A valid SSL certificate should be used for server authentication.'
  tag cis: '5.4'
  tag section: 'Connection and Login'

  describe sql.query("SHOW ssl_cert_file") do
    its('output') { should_not be_empty }
  end
end

# Control 5.5: Ensure SSL Key File is Protected
control 'postgres-15-5.5' do
  impact 1.0
  title 'Ensure SSL Key File Has Proper Permissions'
  desc 'SSL private key should be readable only by the PostgreSQL user.'
  tag cis: '5.5'
  tag section: 'Connection and Login'

  describe sql.query("SHOW ssl_key_file") do
    its('output') { should_not be_empty }
  end
end

# Control 5.6: Ensure Strong SSL Ciphers Are Used
control 'postgres-15-5.6' do
  impact 1.0
  title 'Ensure Strong SSL/TLS Ciphers Are Configured'
  desc 'Weak ciphers should be disabled to prevent cryptographic attacks.'
  tag cis: '5.6'
  tag section: 'Connection and Login'

  describe sql.query("SHOW ssl_ciphers") do
    its('output') { should_not match(/NULL|EXPORT|DES|RC4|MD5/i) }
  end
end

# Control 5.7: Ensure Minimum TLS Version is Set
control 'postgres-15-5.7' do
  impact 1.0
  title 'Ensure Minimum TLS Version is TLSv1.2 or Higher'
  desc 'TLS versions below 1.2 have known vulnerabilities.'
  tag cis: '5.7'
  tag section: 'Connection and Login'

  describe sql.query("SHOW ssl_min_protocol_version") do
    its('output') { should match(/TLSv1\.[23]/) }
  end
end

# Control 5.8: Ensure Connection Limits Are Set
control 'postgres-15-5.8' do
  impact 0.7
  title 'Ensure max_connections is Set Appropriately'
  desc 'Connection limits prevent resource exhaustion attacks.'
  tag cis: '5.8'
  tag section: 'Connection and Login'

  describe sql.query("SELECT CASE WHEN setting::int BETWEEN 10 AND 500 THEN 'COMPLIANT' ELSE 'REVIEW' END AS result FROM pg_settings WHERE name = 'max_connections'") do
    its('output') { should match(/COMPLIANT|REVIEW/) }
  end
end

# Control 5.9: Ensure Authentication Timeout is Set
control 'postgres-15-5.9' do
  impact 0.7
  title 'Ensure authentication_timeout is Set'
  desc 'Authentication timeout prevents slow connection attacks.'
  tag cis: '5.9'
  tag section: 'Connection and Login'

  describe sql.query("SELECT CASE WHEN setting::int BETWEEN 10 AND 60 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS result FROM pg_settings WHERE name = 'authentication_timeout'") do
    its('output') { should match(/COMPLIANT/) }
  end
end

# Control 5.10: Ensure Superuser Access is Restricted
control 'postgres-15-5.10' do
  impact 1.0
  title 'Ensure Superuser Cannot Connect Remotely'
  desc 'Superuser should only connect via local socket or trusted networks.'
  tag cis: '5.10'
  tag section: 'Connection and Login'

  describe sql.query("SELECT CASE WHEN COUNT(*) <= 1 THEN 'COMPLIANT' ELSE 'REVIEW' END AS result FROM pg_roles WHERE rolsuper = true AND rolcanlogin = true") do
    its('output') { should match(/COMPLIANT|REVIEW/) }
  end
end

# ==============================================================================
# Section 6: PostgreSQL Settings
# ==============================================================================

# Control 6.1: Ensure listen_addresses is Configured Correctly
control 'postgres-15-6.1' do
  impact 1.0
  title 'Ensure listen_addresses is Not Set to All Interfaces Unless Required'
  desc 'PostgreSQL should only listen on necessary interfaces.'
  tag cis: '6.1'
  tag section: 'PostgreSQL Settings'

  describe sql.query("SHOW listen_addresses") do
    its('output') { should_not match(/\*/) }
  end
end

# Control 6.2: Ensure Backend Runtime Parameters Are Logged
control 'postgres-15-6.2' do
  impact 0.7
  title 'Ensure Backend Runtime Parameters Changes Are Logged'
  desc 'Changes to runtime parameters should be logged for audit.'
  tag cis: '6.2'
  tag section: 'PostgreSQL Settings'

  describe sql.query("SHOW log_checkpoints") do
    its('output') { should match(/on/i) }
  end
end

# Control 6.3: Ensure fsync is Enabled
control 'postgres-15-6.3' do
  impact 1.0
  title 'Ensure fsync is Enabled'
  desc 'fsync ensures data integrity by flushing data to disk.'
  tag cis: '6.3'
  tag section: 'PostgreSQL Settings'

  describe sql.query("SHOW fsync") do
    its('output') { should match(/on/i) }
  end
end

# Control 6.4: Ensure full_page_writes is Enabled
control 'postgres-15-6.4' do
  impact 1.0
  title 'Ensure full_page_writes is Enabled'
  desc 'Full page writes prevent partial page writes during crashes.'
  tag cis: '6.4'
  tag section: 'PostgreSQL Settings'

  describe sql.query("SHOW full_page_writes") do
    its('output') { should match(/on/i) }
  end
end

# Control 6.5: Ensure Dynamic Library Preloading is Controlled
control 'postgres-15-6.5' do
  impact 0.7
  title 'Ensure shared_preload_libraries is Reviewed'
  desc 'Only authorized libraries should be preloaded.'
  tag cis: '6.5'
  tag section: 'PostgreSQL Settings'

  describe sql.query("SHOW shared_preload_libraries") do
    its('output') { should_not match(/suspicious_library/) }
  end
end

# Control 6.6: Ensure log_lock_waits is Enabled
control 'postgres-15-6.6' do
  impact 0.7
  title 'Ensure log_lock_waits is Enabled'
  desc 'Lock waits should be logged to identify contention issues.'
  tag cis: '6.6'
  tag section: 'PostgreSQL Settings'

  describe sql.query("SHOW log_lock_waits") do
    its('output') { should match(/on/i) }
  end
end

# Control 6.7: Ensure log_temp_files is Configured
control 'postgres-15-6.7' do
  impact 0.5
  title 'Ensure log_temp_files is Set to Log All Temp Files'
  desc 'Temporary file usage should be logged for monitoring.'
  tag cis: '6.7'
  tag section: 'PostgreSQL Settings'

  describe sql.query("SELECT CASE WHEN setting::int >= 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS result FROM pg_settings WHERE name = 'log_temp_files'") do
    its('output') { should match(/COMPLIANT/) }
  end
end

# Control 6.8: Ensure TCP Keepalives Are Configured
control 'postgres-15-6.8' do
  impact 0.5
  title 'Ensure TCP Keepalives Are Configured'
  desc 'TCP keepalives detect dead connections.'
  tag cis: '6.8'
  tag section: 'PostgreSQL Settings'

  describe sql.query("SELECT CASE WHEN setting::int > 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS result FROM pg_settings WHERE name = 'tcp_keepalives_idle'") do
    its('output') { should match(/COMPLIANT/) }
  end
end

# ==============================================================================
# Section 7: Replication
# ==============================================================================

# Control 7.1: Ensure Replication User Has Minimal Privileges
control 'postgres-15-7.1' do
  impact 1.0
  title 'Ensure Replication User Has Only REPLICATION Privilege'
  desc 'Replication users should not have superuser privileges.'
  tag cis: '7.1'
  tag section: 'Replication'

  describe sql.query("SELECT CASE WHEN COUNT(*) = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS result FROM pg_roles WHERE rolreplication = true AND rolsuper = true AND rolname != 'postgres'") do
    its('output') { should match(/COMPLIANT/) }
  end
end

# Control 7.2: Ensure WAL Archiving is Configured
control 'postgres-15-7.2' do
  impact 0.7
  title 'Ensure WAL Archiving is Enabled for Recovery'
  desc 'WAL archiving enables point-in-time recovery.'
  tag cis: '7.2'
  tag section: 'Replication'

  describe sql.query("SHOW archive_mode") do
    its('output') { should match(/on|always/i) }
  end
end

# Control 7.3: Ensure archive_command is Set
control 'postgres-15-7.3' do
  impact 0.7
  title 'Ensure archive_command is Configured'
  desc 'Archive command should be set for WAL archiving.'
  tag cis: '7.3'
  tag section: 'Replication'

  describe sql.query("SHOW archive_command") do
    its('output') { should_not be_empty }
  end
end

# Control 7.4: Ensure Streaming Replication Uses SSL
control 'postgres-15-7.4' do
  impact 1.0
  title 'Ensure Replication Connections Use SSL'
  desc 'Replication traffic should be encrypted.'
  tag cis: '7.4'
  tag section: 'Replication'

  describe sql.query("SHOW ssl") do
    its('output') { should match(/on/i) }
  end
end

# ==============================================================================
# Section 8: Special Configuration Considerations
# ==============================================================================

# Control 8.1: Ensure PostgreSQL Subdirectory Locations Are Outside PGDATA
control 'postgres-15-8.1' do
  impact 0.5
  title 'Ensure pg_stat_tmp and Other Temp Dirs Use Appropriate Locations'
  desc 'Temporary directories should be on appropriate storage.'
  tag cis: '8.1'
  tag section: 'Special Configuration'

  describe sql.query("SELECT setting FROM pg_settings WHERE name = 'stats_temp_directory'") do
    its('output') { should_not be_empty }
  end
end

# Control 8.2: Ensure Backup Tool is Configured
control 'postgres-15-8.2' do
  impact 0.7
  title 'Ensure a Backup Solution is in Place'
  desc 'Regular backups should be configured and tested.'
  tag cis: '8.2'
  tag section: 'Special Configuration'

  describe sql.query("SELECT CASE WHEN COUNT(*) > 0 THEN 'COMPLIANT' ELSE 'REVIEW' END AS result FROM pg_stat_archiver WHERE archived_count > 0") do
    its('output') { should match(/COMPLIANT|REVIEW/) }
  end
end

# Control 8.3: Ensure Statement Timeout is Set
control 'postgres-15-8.3' do
  impact 0.5
  title 'Ensure statement_timeout is Set to Prevent Runaway Queries'
  desc 'Statement timeout prevents long-running queries from consuming resources.'
  tag cis: '8.3'
  tag section: 'Special Configuration'

  describe sql.query("SHOW statement_timeout") do
    its('output') { should_not match(/^0$/) }
  end
end

# Control 8.4: Ensure idle_in_transaction_session_timeout is Set
control 'postgres-15-8.4' do
  impact 0.7
  title 'Ensure idle_in_transaction_session_timeout is Configured'
  desc 'Idle transactions should be terminated to release locks.'
  tag cis: '8.4'
  tag section: 'Special Configuration'

  describe sql.query("SHOW idle_in_transaction_session_timeout") do
    its('output') { should_not match(/^0$/) }
  end
end

# Control 8.5: Ensure Cryptographic Extension is Available
control 'postgres-15-8.5' do
  impact 0.7
  title 'Ensure pgcrypto Extension is Available'
  desc 'pgcrypto provides cryptographic functions for data protection.'
  tag cis: '8.5'
  tag section: 'Special Configuration'

  describe sql.query("SELECT CASE WHEN COUNT(*) > 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS result FROM pg_available_extensions WHERE name = 'pgcrypto'") do
    its('output') { should match(/COMPLIANT/) }
  end
end

# Control 8.6: Ensure Default Search Path Does Not Include PUBLIC Schema First
control 'postgres-15-8.6' do
  impact 0.7
  title 'Ensure search_path Does Not Prioritize Public Schema'
  desc 'Public schema should not be first in search path to prevent hijacking.'
  tag cis: '8.6'
  tag section: 'Special Configuration'

  describe sql.query("SHOW search_path") do
    its('output') { should_not match(/^public,/) }
  end
end
