# MSSQL 2016 InSpec Control - trusted.rb
# NIST compliance checks for SQL Server 2016

# Establish connection to MSSQL
sql = mssql_session(
  user: attribute('usernm'),
  password: attribute('passwd'),
  host: attribute('hostnm'),
  port: attribute('port'),
  instance: attribute('servicenm', default: ''),
  TrustServerCertificate: 'Yes'
)

# Control 2.01: Ad Hoc Distributed Queries
control '2.01' do
  impact 1.0
  title "Ensure 'Ad Hoc Distributed Queries' Server Configuration Option is set to '0'"
  desc "Enabling Ad Hoc Distributed Queries allows users to query data and execute statements on external data sources."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'Ad Hoc Distributed Queries'") do
    its('rows.first.Results') { should eq 'COMPLIANT' }
  end
end

# Control 2.02: CLR Enabled
control '2.02' do
  impact 1.0
  title "Ensure 'CLR Enabled' Server Configuration Option is set to '0'"
  desc "The clr enabled option specifies whether user assemblies can be run by SQL Server."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'clr enabled'") do
    its('rows.first.Results') { should eq 'COMPLIANT' }
  end
end

# Control 2.03: Cross DB Ownership Chaining
control '2.03' do
  impact 1.0
  title "Ensure 'Cross DB Ownership Chaining' Server Configuration Option is set to '0'"
  desc "Cross-database ownership chaining allows database objects to access objects in other databases."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'cross db ownership chaining'") do
    its('rows.first.Results') { should eq 'COMPLIANT' }
  end
end

# Control 2.04: Database Mail XPs
control '2.04' do
  impact 0.7
  title "Ensure 'Database Mail XPs' Server Configuration Option is set to '0'"
  desc "Database Mail XPs controls the ability to send mail from SQL Server."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'Database Mail XPs'") do
    its('rows.first.Results') { should eq 'COMPLIANT' }
  end
end

# Control 2.05: Ole Automation Procedures
control '2.05' do
  impact 1.0
  title "Ensure 'Ole Automation Procedures' Server Configuration Option is set to '0'"
  desc "The Ole Automation Procedures option controls whether OLE Automation objects can be instantiated within Transact-SQL batches."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'Ole Automation Procedures'") do
    its('rows.first.Results') { should eq 'COMPLIANT' }
  end
end

# Control 2.06: Remote Access
control '2.06' do
  impact 1.0
  title "Ensure 'Remote Access' Server Configuration Option is set to '0'"
  desc "The remote access option controls the execution of stored procedures from local or remote servers."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'remote access'") do
    its('rows.first.Results') { should eq 'COMPLIANT' }
  end
end

# Control 2.07: Remote Admin Connections
control '2.07' do
  impact 0.5
  title "Ensure 'Remote Admin Connections' Server Configuration Option is set to '0'"
  desc "The remote admin connections option allows client applications on remote computers to use the Dedicated Administrator Connection."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'remote admin connections'") do
    its('rows.first.Results') { should eq 'COMPLIANT' }
  end
end

# Control 2.08: Scan For Startup Procs
control '2.08' do
  impact 0.7
  title "Ensure 'Scan For Startup Procs' Server Configuration Option is set to '0'"
  desc "The scan for startup procs option causes SQL Server to scan for and automatically run all stored procedures that are set to execute upon service startup."

  describe sql.query("SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END AS Results FROM sys.configurations WHERE name = 'scan for startup procs'") do
    its('rows.first.Results') { should eq 'COMPLIANT' }
  end
end