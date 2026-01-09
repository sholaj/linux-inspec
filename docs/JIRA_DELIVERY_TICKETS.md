# Database Compliance Scanning Framework - JIRA Delivery Tickets

**Project:** Database Compliance Scanning Framework  
**Epic:** Implement Ansible InSpec Roles for NIST Compliance Scanning  
**Sprint Planning Document**  
**Created:** 2026-01-09  
**Target Audience:** Mid-Level DevOps Engineers  

---

## Overview

This document contains the JIRA tickets required to deliver the Database Compliance Scanning Framework. Each role follows a consistent implementation pattern:

1. **Connectivity Testing** - Validate network and client library connectivity
2. **Role Scaffolding** - Create the Ansible role directory structure
3. **Pre-flight Checks** - Implement port and authentication validation
4. **InSpec Profile Development** - Create compliance control files
5. **Execution Logic** - Implement scan execution and result handling
6. **Integration Testing** - End-to-end testing with sample databases
7. **Documentation** - Role-specific documentation and examples

**Estimated Story Points per Role:** 21-26 points  
**Total Estimated Effort:** 84-104 story points

---

## Epic: DBSCAN-001 - Database Compliance Scanning Framework

---

# MSSQL Role Implementation

## DBSCAN-100: MSSQL - Environment Setup and Connectivity Testing

### Purpose
**As a** DevOps engineer, **I want to** verify that the execution environment can connect to MSSQL databases using sqlcmd, **so that** I can confirm the infrastructure is ready for InSpec compliance scanning.

### Description
Set up the execution environment with MSSQL client tools and validate end-to-end connectivity to a sample MSSQL database. This is the foundation for all subsequent MSSQL compliance work.

### Acceptance Criteria
- [ ] sqlcmd (mssql-tools18) is installed on the execution environment
- [ ] ODBC drivers (unixODBC-devel) are installed and configured
- [ ] Can successfully run `telnet <mssql_host> 1433` and see connection established
- [ ] Can execute `sqlcmd -S <server>,<port> -U <user> -P <pass> -Q "SELECT 1"` successfully
- [ ] SSL/TLS connectivity works with self-signed certificates (using `-C` flag)
- [ ] Connection timeout behavior is documented (default vs custom timeout)
- [ ] Error messages for common failures are documented (port blocked, auth failed, db not found)

### Technical Tasks
1. Install mssql-tools18 from Microsoft repository
2. Create sqlcmd wrapper script at `/usr/local/bin/sqlcmd` with `-C` flag for SSL trust
3. Test connectivity to sample MSSQL 2019 database
4. Document PATH requirements (`/opt/mssql-tools18/bin`)
5. Verify connectivity from AAP2 execution environment container

### Test Cases
| Test | Expected Result |
|------|-----------------|
| `telnet mssql-host 1433` | Connection established |
| `sqlcmd -S host,1433 -U sa -P pass -Q "SELECT @@VERSION"` | Returns SQL Server version |
| `sqlcmd` with wrong password | "Login failed" error |
| `sqlcmd` to non-existent port | Connection timeout |

### Story Points: 3

---

## DBSCAN-101: MSSQL - Ansible Role Scaffolding

### Purpose
**As a** DevOps engineer, **I want to** create a well-structured Ansible role directory for MSSQL InSpec scanning, **so that** the codebase follows Ansible best practices and is maintainable.

### Description
Create the `mssql_inspec` role with proper directory structure, default variables, and metadata following Ansible Galaxy conventions.

### Acceptance Criteria
- [ ] Role directory structure created: `roles/mssql_inspec/{defaults,files,handlers,meta,tasks,templates,vars}`
- [ ] `defaults/main.yml` contains all configurable variables with sensible defaults
- [ ] `meta/main.yml` contains role metadata (author, license, dependencies, platforms)
- [ ] `README.md` documents role usage, variables, and examples
- [ ] `tasks/main.yml` has placeholder structure with tagged sections
- [ ] Role passes `ansible-lint` with no errors
- [ ] Role can be included in a playbook without errors (empty run)

### Technical Tasks
1. Create role directory structure using `ansible-galaxy role init`
2. Define default variables in `defaults/main.yml`:
   - `mssql_server`, `mssql_port`, `mssql_database`, `mssql_username`, `mssql_password`
   - `mssql_version` (supported: 2016, 2017, 2018, 2019)
   - `inspec_delegate_host`, `inspec_results_dir`
   - `preflight_enabled`, `preflight_port_timeout`, `preflight_auth_timeout`
3. Create role metadata in `meta/main.yml`
4. Document role in `README.md`

### Dependencies
- DBSCAN-100 (connectivity testing complete)

### Story Points: 2

---

## DBSCAN-102: MSSQL - Pre-flight Connectivity Check Implementation

### Purpose
**As a** DevOps engineer, **I want to** implement pre-flight checks that validate database connectivity before running InSpec, **so that** scans fail fast with clear error messages when databases are unreachable.

### Description
Implement the `preflight.yml` task file that performs TCP port connectivity and database authentication checks before InSpec execution.

### Acceptance Criteria
- [ ] TCP port check uses `wait_for` module with configurable timeout
- [ ] Authentication check executes `sqlcmd` with `SELECT 1` query
- [ ] Pre-flight sets facts: `preflight_passed`, `preflight_skip_reason`, `preflight_error_code`
- [ ] Error codes are standardized: `PORT_UNREACHABLE`, `AUTH_FAILED`, `DB_NOT_FOUND`, `SQLCMD_NOT_FOUND`, `TIMEOUT`
- [ ] Pre-flight runs on delegate host (not control node)
- [ ] Configurable behavior: `preflight_continue_on_failure` to skip vs fail
- [ ] Debug mode shows detailed connection attempt output
- [ ] Passwords are hidden in logs (`no_log: true` when not in debug mode)

### Technical Tasks
1. Create `tasks/preflight.yml` with port connectivity check
2. Implement authentication check using shell module with sqlcmd
3. Parse sqlcmd output to detect specific error conditions
4. Set standardized facts for downstream consumption
5. Implement skip logic with informative banner display

### Test Cases
| Scenario | Expected Behavior |
|----------|-------------------|
| Port open, auth valid | `preflight_passed: true` |
| Port closed | `preflight_passed: false`, code: `PORT_UNREACHABLE` |
| Port open, wrong password | `preflight_passed: false`, code: `AUTH_FAILED` |
| Port open, database not found | `preflight_passed: false`, code: `DB_NOT_FOUND` |
| Timeout waiting for response | `preflight_passed: false`, code: `TIMEOUT` |

### Story Points: 5

---

## DBSCAN-103: MSSQL - InSpec Profile Structure and First Control

### Purpose
**As a** DevOps engineer, **I want to** create the InSpec profile structure for MSSQL compliance scanning, **so that** I have a working foundation to add NIST compliance controls.

### Description
Create the InSpec profile directory structure with `inspec.yml` metadata and implement the first compliance control as a proof of concept.

### Acceptance Criteria
- [ ] InSpec profile created at `files/MSSQL2019_ruby/` with proper structure
- [ ] `inspec.yml` contains profile metadata (name, version, maintainer, supports)
- [ ] `controls/` directory created for Ruby control files
- [ ] First control implemented: database version check or basic security setting
- [ ] Control uses external inputs for connection parameters
- [ ] Control can be executed standalone: `inspec exec . --input-file inputs.yml`
- [ ] Control produces JSON output with pass/fail status
- [ ] Profile structure is version-specific (MSSQL2016, MSSQL2017, etc.)

### Technical Tasks
1. Create `files/MSSQL2019_ruby/inspec.yml` profile metadata
2. Create `files/MSSQL2019_ruby/controls/` directory
3. Implement first control in `controls/trusted.rb` or similar
4. Define input variables for database connection
5. Test profile execution locally with InSpec CLI
6. Replicate structure for other supported versions (2016, 2017, 2018)

### Sample Control Structure
```ruby
# controls/trusted.rb
control 'mssql-version-check' do
  impact 1.0
  title 'Verify MSSQL Version'
  desc 'Ensure database version is supported'
  
  sql = mssql_session(
    user: input('mssql_username'),
    password: input('mssql_password'),
    host: input('mssql_server'),
    port: input('mssql_port')
  )
  
  describe sql.query("SELECT @@VERSION") do
    its('output') { should include '2019' }
  end
end
```

### Story Points: 5

---

## DBSCAN-104: MSSQL - Setup and Execute Task Implementation

### Purpose
**As a** DevOps engineer, **I want to** implement the setup and execution tasks that run InSpec profiles against MSSQL databases, **so that** compliance scans produce structured JSON results.

### Description
Implement `setup.yml` and `execute.yml` task files that prepare the execution environment and run InSpec compliance profiles.

### Acceptance Criteria
- [ ] `setup.yml` creates results directory on execution host
- [ ] `setup.yml` copies control files to delegate host (if remote execution)
- [ ] `setup.yml` validates control files exist for specified MSSQL version
- [ ] `execute.yml` verifies InSpec and sqlcmd binaries are available
- [ ] `execute.yml` runs InSpec profile with correct input parameters
- [ ] InSpec output is captured as JSON in results directory
- [ ] Execution supports both localhost and remote delegate modes
- [ ] Temporary files are cleaned up after execution
- [ ] Execution timeout is configurable

### Technical Tasks
1. Create `tasks/setup.yml` with directory creation and file copy logic
2. Create `tasks/execute.yml` with InSpec execution logic
3. Build InSpec command with all required inputs
4. Handle JSON output capture and storage
5. Implement cleanup logic for temporary files
6. Support execution mode detection (localhost vs delegate)

### Test Cases
| Test | Expected Result |
|------|-----------------|
| Run against reachable database | JSON results in results directory |
| Run with missing InSpec binary | Clear error message |
| Run with invalid version | Validation error |
| Cleanup enabled | Temp files removed |
| Cleanup disabled | Temp files preserved for debugging |

### Story Points: 5

---

## DBSCAN-105: MSSQL - Result Processing and Reporting

### Purpose
**As a** DevOps engineer, **I want to** implement result processing that generates human-readable summaries and optional Splunk integration, **so that** compliance results are actionable and auditable.

### Description
Implement result processing tasks that parse InSpec JSON output, generate summary reports, and optionally send results to Splunk.

### Acceptance Criteria
- [ ] JSON results are parsed to extract pass/fail counts
- [ ] Summary report generated with timestamp, database info, and results
- [ ] Results filename follows convention: `<db_type>_<server>_<database>_<timestamp>.json`
- [ ] Failed controls are highlighted in summary output
- [ ] Optional Splunk HEC integration sends results to configured endpoint
- [ ] Results are fetched back to control node (if remote delegate execution)
- [ ] Aggregate summary available for multi-database scans

### Technical Tasks
1. Create `tasks/results.yml` or add to `execute.yml`
2. Parse InSpec JSON output using `from_json` filter
3. Generate summary statistics (passed, failed, skipped, total)
4. Create summary report template
5. Implement Splunk HEC integration (optional, behind feature flag)
6. Fetch results from delegate host to control node

### Story Points: 3

---

## DBSCAN-106: MSSQL - Integration Testing and Validation

### Purpose
**As a** DevOps engineer, **I want to** perform end-to-end integration testing of the MSSQL role against a real database, **so that** I can verify the complete workflow functions correctly.

### Description
Create test playbooks and validate the complete MSSQL scanning workflow against test infrastructure.

### Acceptance Criteria
- [ ] Test playbook `test_playbooks/run_mssql_inspec.yml` executes successfully
- [ ] Test inventory includes sample MSSQL database(s)
- [ ] All pre-flight scenarios tested (success, port failure, auth failure)
- [ ] InSpec controls execute and produce valid JSON output
- [ ] Results directory contains expected output files
- [ ] Role works in both localhost and delegate execution modes
- [ ] Role handles multiple databases in single playbook run
- [ ] Documentation updated with tested examples

### Test Infrastructure
- Azure MSSQL container (Terraform-provisioned)
- Test credentials stored in vault
- Network connectivity from runner host

### Story Points: 3

---

# Oracle Role Implementation

## DBSCAN-200: Oracle - Environment Setup and Connectivity Testing

### Purpose
**As a** DevOps engineer, **I want to** verify that the execution environment can connect to Oracle databases using sqlplus, **so that** I can confirm the infrastructure is ready for InSpec compliance scanning.

### Description
Set up the execution environment with Oracle Instant Client and validate end-to-end connectivity to a sample Oracle database.

### Acceptance Criteria
- [ ] Oracle Instant Client 19c (basic + sqlplus) installed at `/opt/oracle/instantclient_19_16`
- [ ] Environment variables configured: `ORACLE_HOME`, `LD_LIBRARY_PATH`, `TNS_ADMIN`
- [ ] Symbolic links created for library compatibility (`libclntsh.so`)
- [ ] Can successfully run `telnet <oracle_host> 1521` and see connection established
- [ ] Can execute `sqlplus user/pass@//host:port/service` and connect
- [ ] Connection string formats documented (Easy Connect, TNS)
- [ ] Error messages for common failures documented (TNS errors, ORA-xxxxx codes)

### Technical Tasks
1. Download and install Oracle Instant Client 19c
2. Configure environment variables in profile script
3. Create symbolic links for shared libraries
4. Test connectivity to sample Oracle 19c database
5. Document Oracle-specific connection requirements
6. Verify connectivity from AAP2 execution environment container

### Test Cases
| Test | Expected Result |
|------|-----------------|
| `telnet oracle-host 1521` | Connection established |
| `sqlplus user/pass@//host:1521/ORCL` | SQL> prompt |
| `sqlplus` with wrong password | ORA-01017: invalid username/password |
| `sqlplus` to non-existent service | ORA-12514: TNS listener error |

### Story Points: 3

---

## DBSCAN-201: Oracle - Ansible Role Scaffolding

### Purpose
**As a** DevOps engineer, **I want to** create a well-structured Ansible role directory for Oracle InSpec scanning, **so that** the codebase follows Ansible best practices and is maintainable.

### Description
Create the `oracle_inspec` role with proper directory structure, following the same pattern established by the MSSQL role.

### Acceptance Criteria
- [ ] Role directory structure created: `roles/oracle_inspec/{defaults,files,tasks,templates,vars}`
- [ ] `defaults/main.yml` contains Oracle-specific variables
- [ ] Variables include: `oracle_server`, `oracle_port`, `oracle_service`, `oracle_database`, `oracle_username`, `oracle_password`, `oracle_version`
- [ ] Supported versions defined: 11g, 12c, 18c, 19c
- [ ] `README.md` documents Oracle-specific usage and connection string formats
- [ ] Role passes `ansible-lint` with no errors

### Technical Tasks
1. Create role directory structure
2. Define Oracle-specific default variables
3. Include Oracle environment paths in defaults
4. Document Oracle Easy Connect vs TNS naming
5. Create role metadata

### Dependencies
- DBSCAN-200 (connectivity testing complete)

### Story Points: 2

---

## DBSCAN-202: Oracle - Pre-flight Connectivity Check Implementation

### Purpose
**As a** DevOps engineer, **I want to** implement pre-flight checks that validate Oracle database connectivity before running InSpec, **so that** scans fail fast with clear error messages.

### Description
Implement Oracle-specific pre-flight checks handling Oracle's unique connection methods and error codes.

### Acceptance Criteria
- [ ] TCP port check validates listener port (default 1521)
- [ ] Authentication check uses sqlplus with `SELECT 1 FROM DUAL`
- [ ] Oracle-specific error codes parsed: ORA-01017 (auth), ORA-12514 (service), ORA-12541 (no listener)
- [ ] Easy Connect string format supported: `//host:port/service`
- [ ] Pre-flight sets standardized facts matching MSSQL pattern
- [ ] Environment variables set correctly for sqlplus execution

### Technical Tasks
1. Create `tasks/preflight.yml` for Oracle
2. Implement port check using `wait_for` module
3. Implement sqlplus authentication check
4. Parse ORA-xxxxx error codes to set `preflight_error_code`
5. Handle Oracle-specific timeout scenarios

### Oracle Error Code Mapping
| ORA Code | Error Code Fact | Description |
|----------|-----------------|-------------|
| ORA-01017 | `AUTH_FAILED` | Invalid username/password |
| ORA-12514 | `SERVICE_NOT_FOUND` | TNS listener doesn't know of service |
| ORA-12541 | `PORT_UNREACHABLE` | No listener at host:port |
| ORA-12170 | `TIMEOUT` | TNS connect timeout |

### Story Points: 5

---

## DBSCAN-203: Oracle - InSpec Profile Structure and Controls

### Purpose
**As a** DevOps engineer, **I want to** create InSpec profiles for Oracle compliance scanning with version-specific controls, **so that** NIST controls can be executed against Oracle databases.

### Description
Create InSpec profile structure for Oracle with version-specific directories and implement compliance controls.

### Acceptance Criteria
- [ ] InSpec profiles created: `files/ORACLE11g_ruby/`, `files/ORACLE12c_ruby/`, `files/ORACLE18c_ruby/`, `files/ORACLE19c_ruby/`
- [ ] Each profile has `inspec.yml` and `controls/` directory
- [ ] Controls use `oracledb_session` InSpec resource
- [ ] At least one working control implemented per version
- [ ] Controls accept inputs for connection parameters
- [ ] Profiles can be executed standalone with InSpec CLI

### Technical Tasks
1. Create profile directory structure for each Oracle version
2. Create `inspec.yml` metadata for each version
3. Implement baseline controls using `oracledb_session` resource
4. Handle Oracle-specific SQL syntax in controls
5. Test profiles with InSpec CLI

### Story Points: 5

---

## DBSCAN-204: Oracle - Setup and Execute Task Implementation

### Purpose
**As a** DevOps engineer, **I want to** implement setup and execution tasks for Oracle InSpec scanning, **so that** compliance scans can be run against Oracle databases.

### Description
Implement Oracle-specific setup and execution logic, handling Oracle environment requirements.

### Acceptance Criteria
- [ ] `setup.yml` configures Oracle environment (ORACLE_HOME, LD_LIBRARY_PATH)
- [ ] `setup.yml` copies Oracle control files to delegate host
- [ ] `execute.yml` runs InSpec with Oracle-specific inputs
- [ ] Easy Connect string built from input variables
- [ ] JSON results captured in standard format
- [ ] Cleanup removes temporary files

### Technical Tasks
1. Create `tasks/setup.yml` for Oracle environment setup
2. Create `tasks/execute.yml` for InSpec execution
3. Build Oracle connection string from variables
4. Handle Oracle library path requirements
5. Implement result capture and cleanup

### Story Points: 5

---

## DBSCAN-205: Oracle - Integration Testing and Validation

### Purpose
**As a** DevOps engineer, **I want to** perform end-to-end integration testing of the Oracle role, **so that** I can verify the complete workflow functions correctly.

### Description
Create test playbooks and validate the complete Oracle scanning workflow.

### Acceptance Criteria
- [ ] Test playbook `test_playbooks/run_oracle_inspec.yml` executes successfully
- [ ] Tests cover Oracle 19c (primary test target)
- [ ] Pre-flight scenarios tested (success, listener down, auth failure)
- [ ] Results directory contains valid JSON output
- [ ] Role works in both localhost and delegate modes

### Test Infrastructure
- Azure Oracle container (Terraform-provisioned)
- Oracle XE or Oracle Free tier for testing

### Story Points: 3

---

# Sybase Role Implementation

## DBSCAN-300: Sybase - Environment Setup and Connectivity Testing

### Purpose
**As a** DevOps engineer, **I want to** verify that the execution environment can connect to Sybase databases using FreeTDS/tsql, **so that** I can confirm the infrastructure is ready for InSpec compliance scanning.

### Description
Set up the execution environment with FreeTDS client and validate end-to-end connectivity to a sample Sybase database.

### Acceptance Criteria
- [ ] FreeTDS package installed (`freetds` and `freetds-utils`)
- [ ] `tsql` command-line tool available in PATH
- [ ] `freetds.conf` configured with server definitions
- [ ] Can successfully run `telnet <sybase_host> 5000` (default Sybase port)
- [ ] Can execute `tsql -S <server> -U <user> -P <pass>` and connect
- [ ] Sybase environment script created at `/opt/sap/SYBASE.sh`
- [ ] Error messages for common failures documented

### Technical Tasks
1. Install FreeTDS package via package manager
2. Configure `freetds.conf` for Sybase connectivity
3. Create Sybase environment compatibility layer at `/opt/sap/`
4. Test connectivity to sample Sybase 16 database
5. Document FreeTDS configuration options
6. Verify connectivity from AAP2 execution environment

### Test Cases
| Test | Expected Result |
|------|-----------------|
| `telnet sybase-host 5000` | Connection established |
| `tsql -S server -U user -P pass` | 1> prompt |
| `tsql` with wrong password | Login failed |
| `tsql` to non-existent host | Connection refused |

### Notes
- Sybase ASE uses TDS protocol (same as MSSQL historically)
- FreeTDS provides open-source TDS implementation
- Default Sybase port is 5000 (configurable)

### Story Points: 3

---

## DBSCAN-301: Sybase - Ansible Role Scaffolding

### Purpose
**As a** DevOps engineer, **I want to** create a well-structured Ansible role directory for Sybase InSpec scanning, **so that** the codebase follows Ansible best practices.

### Description
Create the `sybase_inspec` role with proper directory structure and Sybase-specific configurations.

### Acceptance Criteria
- [ ] Role directory structure created: `roles/sybase_inspec/{defaults,files,tasks,templates,vars}`
- [ ] `defaults/main.yml` contains Sybase-specific variables
- [ ] Variables include: `sybase_server`, `sybase_port`, `sybase_service`, `sybase_database`, `sybase_username`, `sybase_password`, `sybase_version`
- [ ] SSH tunnel support variables: `sybase_use_ssh`, `sybase_ssh_user`, `sybase_ssh_key`
- [ ] Supported versions defined: 15, 16
- [ ] Role includes SSH key handling for Sybase environments

### Technical Tasks
1. Create role directory structure
2. Define Sybase-specific default variables
3. Create `files/SSH_keys/` directory for SSH key management
4. Document Sybase-specific connectivity patterns
5. Create role metadata

### Dependencies
- DBSCAN-300 (connectivity testing complete)

### Story Points: 2

---

## DBSCAN-302: Sybase - Pre-flight Connectivity Check Implementation

### Purpose
**As a** DevOps engineer, **I want to** implement pre-flight checks for Sybase databases including SSH tunnel support, **so that** connectivity is validated before InSpec execution.

### Description
Implement Sybase-specific pre-flight checks with support for direct and SSH-tunneled connections.

### Acceptance Criteria
- [ ] TCP port check validates Sybase port (default 5000)
- [ ] Authentication check uses tsql or isql
- [ ] SSH tunnel setup supported for secure environments
- [ ] Pre-flight handles FreeTDS-specific error messages
- [ ] Error codes mapped: connection refused, auth failed, server not found
- [ ] SSH connection validated when `sybase_use_ssh: true`

### Technical Tasks
1. Create `tasks/preflight.yml` for Sybase
2. Create `tasks/ssh_setup.yml` for SSH tunnel management
3. Implement port and auth checks using tsql
4. Parse FreeTDS error output
5. Handle SSH key-based authentication

### Story Points: 5

---

## DBSCAN-303: Sybase - InSpec Profile Structure and Controls

### Purpose
**As a** DevOps engineer, **I want to** create InSpec profiles for Sybase compliance scanning, **so that** NIST controls can be executed against Sybase databases.

### Description
Create InSpec profile structure for Sybase versions 15 and 16 with compliance controls.

### Acceptance Criteria
- [ ] InSpec profiles created: `files/SYBASE15_ruby/`, `files/SYBASE16_ruby/`
- [ ] Each profile has `inspec.yml` and `controls/` directory
- [ ] Controls use shell commands or custom resource for Sybase queries
- [ ] At least one working control implemented per version
- [ ] Controls handle Sybase-specific SQL syntax

### Technical Tasks
1. Create profile directory structure for Sybase 15 and 16
2. Create `inspec.yml` metadata
3. Implement controls using `command` resource with tsql
4. Handle Sybase-specific output parsing
5. Test profiles with InSpec CLI

### Notes
- InSpec doesn't have native Sybase resource
- Use `command` resource with tsql/isql for queries
- Parse output using Ruby regex or string methods

### Story Points: 5

---

## DBSCAN-304: Sybase - Setup and Execute Task Implementation

### Purpose
**As a** DevOps engineer, **I want to** implement setup and execution tasks for Sybase InSpec scanning, **so that** compliance scans can be run against Sybase databases.

### Description
Implement Sybase-specific setup and execution logic including SSH tunnel handling.

### Acceptance Criteria
- [ ] `setup.yml` configures Sybase environment
- [ ] `ssh_setup.yml` establishes SSH tunnel when required
- [ ] `execute.yml` runs InSpec with Sybase-specific inputs
- [ ] FreeTDS configuration generated dynamically if needed
- [ ] SSH tunnel cleanup on completion/failure

### Technical Tasks
1. Create `tasks/setup.yml` for environment setup
2. Create `tasks/ssh_setup.yml` for SSH tunnel
3. Create `tasks/execute.yml` for InSpec execution
4. Create `tasks/cleanup.yml` for resource cleanup
5. Handle SSH tunnel lifecycle

### Story Points: 5

---

## DBSCAN-305: Sybase - Integration Testing and Validation

### Purpose
**As a** DevOps engineer, **I want to** perform end-to-end integration testing of the Sybase role, **so that** I can verify the complete workflow functions correctly.

### Description
Create test playbooks and validate the complete Sybase scanning workflow.

### Acceptance Criteria
- [ ] Test playbook `test_playbooks/run_sybase_inspec.yml` executes successfully
- [ ] Tests cover Sybase 16 (primary test target)
- [ ] SSH tunnel mode tested separately
- [ ] Pre-flight scenarios tested
- [ ] Results contain valid JSON output

### Test Infrastructure
- Azure Sybase container (Terraform-provisioned)
- SSH tunnel test environment

### Story Points: 3

---

# PostgreSQL Role Implementation

## DBSCAN-400: PostgreSQL - Environment Setup and Connectivity Testing

### Purpose
**As a** DevOps engineer, **I want to** verify that the execution environment can connect to PostgreSQL databases using psql, **so that** I can confirm the infrastructure is ready for InSpec compliance scanning.

### Description
Set up the execution environment with PostgreSQL client and validate end-to-end connectivity.

### Acceptance Criteria
- [ ] PostgreSQL client (`postgresql`) package installed
- [ ] `psql` command available in PATH
- [ ] Can successfully run `telnet <pg_host> 5432`
- [ ] Can execute `psql -h host -p port -U user -d database -c "SELECT 1"`
- [ ] SSL connectivity options documented
- [ ] `.pgpass` file usage documented for password management
- [ ] Common error messages documented

### Technical Tasks
1. Install postgresql client package
2. Test connectivity to sample PostgreSQL database
3. Document connection string formats
4. Document SSL options (`sslmode=require`, etc.)
5. Verify connectivity from AAP2 execution environment

### Test Cases
| Test | Expected Result |
|------|-----------------|
| `telnet pg-host 5432` | Connection established |
| `psql -h host -U user -d db -c "SELECT 1"` | Returns 1 |
| `psql` with wrong password | authentication failed |
| `psql` to non-existent db | database does not exist |

### Story Points: 2

---

## DBSCAN-401: PostgreSQL - Ansible Role Scaffolding

### Purpose
**As a** DevOps engineer, **I want to** create a well-structured Ansible role directory for PostgreSQL InSpec scanning, **so that** the codebase is maintainable and consistent.

### Description
Create the `postgres_inspec` role with proper directory structure.

### Acceptance Criteria
- [ ] Role directory structure created: `roles/postgres_inspec/{defaults,files,tasks,templates,vars}`
- [ ] `defaults/main.yml` contains PostgreSQL-specific variables
- [ ] Variables include: `postgres_server`, `postgres_port`, `postgres_database`, `postgres_username`, `postgres_password`
- [ ] SSL mode variable: `postgres_sslmode` (disable, allow, prefer, require, verify-ca, verify-full)
- [ ] Role passes `ansible-lint`

### Technical Tasks
1. Create role directory structure
2. Define PostgreSQL-specific default variables
3. Create role metadata
4. Document PostgreSQL connection patterns

### Dependencies
- DBSCAN-400 (connectivity testing complete)

### Story Points: 2

---

## DBSCAN-402: PostgreSQL - Pre-flight and Execution Implementation

### Purpose
**As a** DevOps engineer, **I want to** implement pre-flight checks and InSpec execution for PostgreSQL, **so that** compliance scans can be run against PostgreSQL databases.

### Description
Implement complete PostgreSQL role including pre-flight, setup, and execute tasks.

### Acceptance Criteria
- [ ] Pre-flight validates port connectivity and authentication
- [ ] PostgreSQL-specific error codes parsed
- [ ] InSpec `postgres_session` resource used for controls
- [ ] JSON results captured in standard format
- [ ] Role supports localhost and delegate execution modes

### Technical Tasks
1. Create `tasks/preflight.yml` for PostgreSQL
2. Create `tasks/setup.yml` for environment setup
3. Create `tasks/execute.yml` for InSpec execution
4. Create InSpec profile in `files/` directory
5. Implement controls using `postgres_session` resource

### Story Points: 5

---

## DBSCAN-403: PostgreSQL - Integration Testing and Validation

### Purpose
**As a** DevOps engineer, **I want to** perform end-to-end integration testing of the PostgreSQL role, **so that** I can verify the complete workflow functions correctly.

### Description
Create test playbooks and validate the complete PostgreSQL scanning workflow.

### Acceptance Criteria
- [ ] Test playbook `test_playbooks/run_postgres_inspec.yml` executes successfully
- [ ] Pre-flight scenarios tested
- [ ] Results contain valid JSON output
- [ ] Role works in both localhost and delegate modes

### Test Infrastructure
- Azure PostgreSQL container (Terraform-provisioned)

### Story Points: 2

---

# Cross-Cutting Concerns

## DBSCAN-500: Execution Environment Container Build

### Purpose
**As a** DevOps engineer, **I want to** create a custom AAP2 Execution Environment container with all database clients, **so that** InSpec scans can connect to all supported database platforms.

### Description
Build custom Execution Environment with MSSQL, Oracle, PostgreSQL, and Sybase client tools.

### Acceptance Criteria
- [ ] `execution-environment.yml` defines EE build specification
- [ ] `scripts/install-db-clients.sh` installs all database clients
- [ ] All client binaries in PATH: `sqlcmd`, `sqlplus`, `psql`, `tsql`
- [ ] InSpec installed with required plugins
- [ ] EE builds successfully with `ansible-builder build`
- [ ] EE pushed to container registry (ACR)
- [ ] EE tested with sample playbook execution

### Technical Tasks
1. Create `execution-environment.yml` specification
2. Create `scripts/install-db-clients.sh`
3. Define Python requirements in `requirements.txt`
4. Define Ansible collections in `requirements.yml`
5. Define system packages in `bindep.txt`
6. Build and test EE locally
7. Push to Azure Container Registry

### Story Points: 5

---

## DBSCAN-501: Inventory Converter Tool

### Purpose
**As a** DevOps engineer, **I want to** convert flat file database lists to Ansible inventory format, **so that** existing database catalogs can be used with the compliance framework.

### Description
Create a tool to convert legacy flat file database lists to structured Ansible inventory YAML.

### Acceptance Criteria
- [ ] Python script `convert_flatfile_to_inventory.py` created
- [ ] Ansible playbook wrapper `convert_flatfile_to_inventory.yml` available
- [ ] Script handles MSSQL, Oracle, Sybase, PostgreSQL entries
- [ ] Output is valid Ansible inventory YAML
- [ ] Host variables populated from flat file fields
- [ ] Groups created by database type and environment

### Technical Tasks
1. Define flat file input format
2. Create Python conversion script
3. Create Ansible playbook wrapper
4. Handle field mapping and validation
5. Generate grouped inventory output
6. Document usage and examples

### Story Points: 3

---

## DBSCAN-502: AAP2 Job Template Configuration

### Purpose
**As a** DevOps engineer, **I want to** create AAP2 job templates for each database compliance scan, **so that** scans can be triggered via AAP2 UI or API.

### Description
Define and configure AAP2 job templates, credentials, and inventories for production deployment.

### Acceptance Criteria
- [ ] Job template for each database role (MSSQL, Oracle, Sybase, PostgreSQL)
- [ ] Credential types defined for database authentication
- [ ] Execution Environment linked to custom EE
- [ ] Survey configured for runtime parameters
- [ ] Job template tested via AAP2 UI
- [ ] API trigger documented

### Technical Tasks
1. Create credential type definitions in `aap2-config/credential-types/`
2. Create job template definitions in `aap2-config/job-templates/`
3. Create inventory definitions in `aap2-config/inventories/`
4. Document AAP2 setup process
5. Test job template execution

### Story Points: 3

---

## DBSCAN-503: Documentation and Runbook

### Purpose
**As a** DevOps engineer, **I want to** comprehensive documentation for the compliance scanning framework, **so that** other engineers can operate and troubleshoot the system.

### Description
Create documentation including architecture guides, troubleshooting runbooks, and operational procedures.

### Acceptance Criteria
- [ ] Architecture diagram created
- [ ] Quick start guide for new users
- [ ] Troubleshooting guide for common issues
- [ ] Variable reference documentation
- [ ] AAP2 deployment guide
- [ ] Security and credential handling documentation

### Deliverables
- `docs/QUICK_START_GUIDE.md`
- `docs/TROUBLESHOOTING_GUIDE.md`
- `docs/ANSIBLE_VARIABLES_REFERENCE.md`
- `docs/AAP2_DEPLOYMENT_GUIDE.md`
- `docs/SECURITY_PASSWORD_HANDLING.md`

### Story Points: 3

---

# Summary - Story Point Breakdown

## By Database Type

| Database | Tickets | Story Points |
|----------|---------|--------------|
| **MSSQL** | DBSCAN-100 to 106 | 26 |
| **Oracle** | DBSCAN-200 to 205 | 23 |
| **Sybase** | DBSCAN-300 to 305 | 23 |
| **PostgreSQL** | DBSCAN-400 to 403 | 11 |
| **Cross-Cutting** | DBSCAN-500 to 503 | 14 |
| **Total** | 27 tickets | **97 points** |

## Recommended Sprint Planning

### Sprint 1 (Week 1-2): Foundation
- DBSCAN-500: Execution Environment Build (5 pts)
- DBSCAN-100: MSSQL Connectivity Testing (3 pts)
- DBSCAN-101: MSSQL Role Scaffolding (2 pts)
- **Sprint Total: 10 points**

### Sprint 2 (Week 3-4): MSSQL Complete
- DBSCAN-102: MSSQL Pre-flight (5 pts)
- DBSCAN-103: MSSQL InSpec Profile (5 pts)
- DBSCAN-104: MSSQL Execute (5 pts)
- DBSCAN-105: MSSQL Results (3 pts)
- DBSCAN-106: MSSQL Integration Test (3 pts)
- **Sprint Total: 21 points**

### Sprint 3 (Week 5-6): Oracle Complete
- DBSCAN-200: Oracle Connectivity (3 pts)
- DBSCAN-201: Oracle Scaffolding (2 pts)
- DBSCAN-202: Oracle Pre-flight (5 pts)
- DBSCAN-203: Oracle InSpec Profile (5 pts)
- DBSCAN-204: Oracle Execute (5 pts)
- DBSCAN-205: Oracle Integration Test (3 pts)
- **Sprint Total: 23 points**

### Sprint 4 (Week 7-8): Sybase Complete
- DBSCAN-300: Sybase Connectivity (3 pts)
- DBSCAN-301: Sybase Scaffolding (2 pts)
- DBSCAN-302: Sybase Pre-flight (5 pts)
- DBSCAN-303: Sybase InSpec Profile (5 pts)
- DBSCAN-304: Sybase Execute (5 pts)
- DBSCAN-305: Sybase Integration Test (3 pts)
- **Sprint Total: 23 points**

### Sprint 5 (Week 9-10): PostgreSQL + Finalization
- DBSCAN-400: PostgreSQL Connectivity (2 pts)
- DBSCAN-401: PostgreSQL Scaffolding (2 pts)
- DBSCAN-402: PostgreSQL Implementation (5 pts)
- DBSCAN-403: PostgreSQL Integration Test (2 pts)
- DBSCAN-501: Inventory Converter (3 pts)
- DBSCAN-502: AAP2 Job Templates (3 pts)
- DBSCAN-503: Documentation (3 pts)
- **Sprint Total: 20 points**

---

## Dependencies Graph

```
DBSCAN-500 (Execution Environment)
    │
    ├──▶ DBSCAN-100 (MSSQL Connectivity)
    │        └──▶ DBSCAN-101 ──▶ DBSCAN-102 ──▶ DBSCAN-103 ──▶ DBSCAN-104 ──▶ DBSCAN-105 ──▶ DBSCAN-106
    │
    ├──▶ DBSCAN-200 (Oracle Connectivity)
    │        └──▶ DBSCAN-201 ──▶ DBSCAN-202 ──▶ DBSCAN-203 ──▶ DBSCAN-204 ──▶ DBSCAN-205
    │
    ├──▶ DBSCAN-300 (Sybase Connectivity)
    │        └──▶ DBSCAN-301 ──▶ DBSCAN-302 ──▶ DBSCAN-303 ──▶ DBSCAN-304 ──▶ DBSCAN-305
    │
    └──▶ DBSCAN-400 (PostgreSQL Connectivity)
             └──▶ DBSCAN-401 ──▶ DBSCAN-402 ──▶ DBSCAN-403

DBSCAN-501 (Inventory Converter) ──▶ No dependencies
DBSCAN-502 (AAP2 Job Templates) ──▶ All role integration tests complete
DBSCAN-503 (Documentation) ──▶ All roles complete
```

---

*Document generated for project planning purposes. Ticket IDs are placeholders - update with actual JIRA ticket numbers upon creation.*
