# MSSQL 2019 InSpec Control - trusted.rb
# NIST compliance checks for SQL Server 2019
# Uses sqlcmd with -C flag to bypass SSL certificate validation

# Get connection parameters (these are accessible within control blocks)
hostnm = attribute('hostnm')
port = attribute('port', default: '1433')
usernm = attribute('usernm')
passwd = attribute('passwd')

# Control 2.01: Ad Hoc Distributed Queries
control '2.01' do
  impact 1.0
  title "Ensure 'Ad Hoc Distributed Queries' Server Configuration Option is set to '0'"
  desc "Enabling Ad Hoc Distributed Queries allows users to query data and execute statements on external data sources."

  sql_query = "SET NOCOUNT ON; SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END FROM sys.configurations WHERE name = 'Ad Hoc Distributed Queries'"

  describe command("sqlcmd -S '#{hostnm},#{port}' -U '#{usernm}' -P '#{passwd}' -C -h -1 -W -Q \"#{sql_query}\"") do
    its('stdout.strip') { should eq 'COMPLIANT' }
    its('exit_status') { should eq 0 }
  end
end

# Control 2.02: CLR Enabled
control '2.02' do
  impact 1.0
  title "Ensure 'CLR Enabled' Server Configuration Option is set to '0'"
  desc "The clr enabled option specifies whether user assemblies can be run by SQL Server."

  sql_query = "SET NOCOUNT ON; SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END FROM sys.configurations WHERE name = 'clr enabled'"

  describe command("sqlcmd -S '#{hostnm},#{port}' -U '#{usernm}' -P '#{passwd}' -C -h -1 -W -Q \"#{sql_query}\"") do
    its('stdout.strip') { should eq 'COMPLIANT' }
    its('exit_status') { should eq 0 }
  end
end

# Control 2.03: Cross DB Ownership Chaining
control '2.03' do
  impact 1.0
  title "Ensure 'Cross DB Ownership Chaining' Server Configuration Option is set to '0'"
  desc "Cross-database ownership chaining allows database objects to access objects in other databases."

  sql_query = "SET NOCOUNT ON; SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END FROM sys.configurations WHERE name = 'cross db ownership chaining'"

  describe command("sqlcmd -S '#{hostnm},#{port}' -U '#{usernm}' -P '#{passwd}' -C -h -1 -W -Q \"#{sql_query}\"") do
    its('stdout.strip') { should eq 'COMPLIANT' }
    its('exit_status') { should eq 0 }
  end
end

# Control 2.04: Database Mail XPs
control '2.04' do
  impact 0.7
  title "Ensure 'Database Mail XPs' Server Configuration Option is set to '0'"
  desc "Database Mail XPs controls the ability to send mail from SQL Server."

  sql_query = "SET NOCOUNT ON; SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END FROM sys.configurations WHERE name = 'Database Mail XPs'"

  describe command("sqlcmd -S '#{hostnm},#{port}' -U '#{usernm}' -P '#{passwd}' -C -h -1 -W -Q \"#{sql_query}\"") do
    its('stdout.strip') { should eq 'COMPLIANT' }
    its('exit_status') { should eq 0 }
  end
end

# Control 2.05: Ole Automation Procedures
control '2.05' do
  impact 1.0
  title "Ensure 'Ole Automation Procedures' Server Configuration Option is set to '0'"
  desc "The Ole Automation Procedures option controls whether OLE Automation objects can be instantiated within Transact-SQL batches."

  sql_query = "SET NOCOUNT ON; SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END FROM sys.configurations WHERE name = 'Ole Automation Procedures'"

  describe command("sqlcmd -S '#{hostnm},#{port}' -U '#{usernm}' -P '#{passwd}' -C -h -1 -W -Q \"#{sql_query}\"") do
    its('stdout.strip') { should eq 'COMPLIANT' }
    its('exit_status') { should eq 0 }
  end
end

# Control 2.06: Remote Access
control '2.06' do
  impact 1.0
  title "Ensure 'Remote Access' Server Configuration Option is set to '0'"
  desc "The remote access option controls the execution of stored procedures from local or remote servers."

  sql_query = "SET NOCOUNT ON; SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END FROM sys.configurations WHERE name = 'remote access'"

  describe command("sqlcmd -S '#{hostnm},#{port}' -U '#{usernm}' -P '#{passwd}' -C -h -1 -W -Q \"#{sql_query}\"") do
    its('stdout.strip') { should eq 'COMPLIANT' }
    its('exit_status') { should eq 0 }
  end
end

# Control 2.07: Remote Admin Connections
control '2.07' do
  impact 0.5
  title "Ensure 'Remote Admin Connections' Server Configuration Option is set to '0'"
  desc "The remote admin connections option allows client applications on remote computers to use the Dedicated Administrator Connection."

  sql_query = "SET NOCOUNT ON; SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END FROM sys.configurations WHERE name = 'remote admin connections'"

  describe command("sqlcmd -S '#{hostnm},#{port}' -U '#{usernm}' -P '#{passwd}' -C -h -1 -W -Q \"#{sql_query}\"") do
    its('stdout.strip') { should eq 'COMPLIANT' }
    its('exit_status') { should eq 0 }
  end
end

# Control 2.08: Scan For Startup Procs
control '2.08' do
  impact 0.7
  title "Ensure 'Scan For Startup Procs' Server Configuration Option is set to '0'"
  desc "The scan for startup procs option causes SQL Server to scan for and automatically run all stored procedures that are set to execute upon service startup."

  sql_query = "SET NOCOUNT ON; SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END FROM sys.configurations WHERE name = 'scan for startup procs'"

  describe command("sqlcmd -S '#{hostnm},#{port}' -U '#{usernm}' -P '#{passwd}' -C -h -1 -W -Q \"#{sql_query}\"") do
    its('stdout.strip') { should eq 'COMPLIANT' }
    its('exit_status') { should eq 0 }
  end
end

# Control 2.09: External Scripts Enabled (SQL Server 2019 specific)
control '2.09' do
  impact 1.0
  title "Ensure 'External Scripts Enabled' is set to '0'"
  desc "The external scripts enabled option allows execution of scripts with certain remote language extensions."

  sql_query = "SET NOCOUNT ON; SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END FROM sys.configurations WHERE name = 'external scripts enabled'"

  describe command("sqlcmd -S '#{hostnm},#{port}' -U '#{usernm}' -P '#{passwd}' -C -h -1 -W -Q \"#{sql_query}\"") do
    its('stdout.strip') { should eq 'COMPLIANT' }
    its('exit_status') { should eq 0 }
  end
end

# Control 2.10: Contained Database Authentication
control '2.10' do
  impact 0.7
  title "Ensure 'Contained Database Authentication' is set to '0'"
  desc "Contained database authentication allows users to connect without authenticating at the Database Engine level."

  sql_query = "SET NOCOUNT ON; SELECT CASE WHEN value_in_use = 0 AND value = 0 THEN 'COMPLIANT' ELSE 'NOT COMPLIANT' END FROM sys.configurations WHERE name = 'contained database authentication'"

  describe command("sqlcmd -S '#{hostnm},#{port}' -U '#{usernm}' -P '#{passwd}' -C -h -1 -W -Q \"#{sql_query}\"") do
    its('stdout.strip') { should eq 'COMPLIANT' }
    its('exit_status') { should eq 0 }
  end
end
