# Database Compliance Scanning Framework - JIRA Delivery Tickets

**Project:** Database Compliance Scanning Framework
**Epic:** Implement Ansible InSpec Roles for NIST Compliance Scanning
**Sprint Planning Document**
**Created:** 2026-01-09
**Updated:** 2026-01-25
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

# Epic: DCS-600 - Database Platform Roles Production Completion

**Epic Summary:** Complete all three database platform InSpec roles (MSSQL, Oracle, Sybase) to production-ready status with comprehensive NIST-mapped controls, full testing coverage, and documentation.

**Business Value:**
- 90% reduction in manual compliance effort
- Monthly scanning capability (vs. quarterly)
- 100% database coverage across all platforms
- Auditable, repeatable NIST compliance process

**Epic Acceptance Criteria:**
- [ ] MSSQL scanning operational with 50+ controls per version
- [ ] Oracle scanning operational with 65+ controls per version
- [ ] Sybase scanning operational with 60+ controls per version
- [ ] All controls have NIST SP 800-53 mappings
- [ ] Azure-based testing validates all controls
- [ ] Documentation complete for operations handover

**Labels:** `compliance`, `inspec`, `nist`, `production-ready`
**Components:** `mssql_inspec`, `oracle_inspec`, `sybase_inspec`

---

## DCS-610: MSSQL InSpec Role - Production Completion

**Type:** Story
**Epic:** DCS-600
**Priority:** Must Have
**Story Points:** 21

### Description
Complete the MSSQL InSpec role to production-ready status with comprehensive NIST-mapped controls for SQL Server 2016, 2017, 2018, and 2019.

**As a** Security Analyst,
**I want to** execute automated compliance scans against MSSQL databases,
**So that** I can generate audit-ready NIST compliance reports efficiently.

### Acceptance Criteria
- [ ] 50+ controls implemented for MSSQL 2019 (baseline version)
- [ ] Controls adapted for 2016, 2017, 2018 versions with version-specific handling
- [ ] Each control has NIST SP 800-53 and CIS mapping in metadata
- [ ] Pre-flight checks validate connectivity before scan execution
- [ ] JSON output matches standardized naming convention
- [ ] Summary report generated for each scan
- [ ] All controls tested against Azure infrastructure
- [ ] README updated with complete control inventory

### Technical Notes
- Role location: `roles/mssql_inspec/`
- Current status: 85% complete (role structure done, controls partial)
- InSpec resource: `mssql_session`
- Client requirement: `sqlcmd` on delegate host

### Dependencies
- Blocked by: None
- Blocks: DCS-650 (Multi-platform Playbook)

### Sub-Tasks

#### DCS-611: MSSQL 2019 InSpec Controls - Surface Area Reduction
**Story Points:** 3
**Labels:** `inspec`, `controls`, `mssql-2019`

Implement controls 2.01-2.17 for Surface Area Reduction:
- [ ] 2.01: Ad Hoc Distributed Queries disabled
- [ ] 2.02: CLR Enabled disabled
- [ ] 2.03: Cross DB Ownership Chaining disabled
- [ ] 2.04: Database Mail XPs disabled
- [ ] 2.05: Ole Automation Procedures disabled
- [ ] 2.06: Remote Access disabled
- [ ] 2.07: Remote Admin Connections disabled
- [ ] 2.08: Scan For Startup Procs disabled
- [ ] 2.09: Trustworthy Database
- [ ] 2.10: Server Network Packet Size
- [ ] 2.11: xp_cmdshell disabled
- [ ] 2.12: Auto Close disabled
- [ ] 2.13: SA Account Status
- [ ] 2.14: SA Account Renamed
- [ ] 2.15: External Scripts Enabled (version check)
- [ ] 2.16: Polybase Enabled (version check)
- [ ] 2.17: Hadoop Connectivity

**File:** `roles/mssql_inspec/files/MSSQL2019_ruby/controls/surface_area.rb`

---

#### DCS-612: MSSQL 2019 InSpec Controls - Authentication
**Story Points:** 2
**Labels:** `inspec`, `controls`, `mssql-2019`

Implement controls 3.01-3.08 for Authentication:
- [ ] 3.01: Windows Authentication Mode
- [ ] 3.02: Login Auditing
- [ ] 3.03: SQL Server Browser Service
- [ ] 3.04: No Blank Passwords
- [ ] 3.05: Password Policy Enforced
- [ ] 3.06: Password Expiration Enforced
- [ ] 3.07: MUST_CHANGE Option
- [ ] 3.08: CHECK_POLICY Enabled

**File:** `roles/mssql_inspec/files/MSSQL2019_ruby/controls/authentication.rb`

---

#### DCS-613: MSSQL 2019 InSpec Controls - Authorization
**Story Points:** 2
**Labels:** `inspec`, `controls`, `mssql-2019`

Implement controls 4.01-4.08 for Authorization:
- [ ] 4.01: Public Role Permissions
- [ ] 4.02: Guest User Status
- [ ] 4.03: Orphaned Users
- [ ] 4.04: SQL Agent Proxies
- [ ] 4.05: CONNECT Permission to Guest
- [ ] 4.06: msdb Permissions
- [ ] 4.07: EXECUTE on xp_* procedures
- [ ] 4.08: Sysadmin Role Members

**File:** `roles/mssql_inspec/files/MSSQL2019_ruby/controls/authorization.rb`

---

#### DCS-614: MSSQL 2019 InSpec Controls - Auditing
**Story Points:** 2
**Labels:** `inspec`, `controls`, `mssql-2019`

Implement controls 5.01-5.07 for Auditing:
- [ ] 5.01: Server Audit Enabled
- [ ] 5.02: Successful Logins Audited
- [ ] 5.03: Failed Logins Audited
- [ ] 5.04: Audit Specification Active
- [ ] 5.05: Audit Destination Configured
- [ ] 5.06: C2 Audit Mode
- [ ] 5.07: Common Criteria Compliance

**File:** `roles/mssql_inspec/files/MSSQL2019_ruby/controls/auditing.rb`

---

#### DCS-615: MSSQL 2019 InSpec Controls - Encryption
**Story Points:** 2
**Labels:** `inspec`, `controls`, `mssql-2019`

Implement controls 6.01-6.05 for Encryption:
- [ ] 6.01: TDE Enabled for Sensitive DBs
- [ ] 6.02: Backup Encryption
- [ ] 6.03: SSL/TLS Forced
- [ ] 6.04: Certificate Validity
- [ ] 6.05: Symmetric Key Protection

**File:** `roles/mssql_inspec/files/MSSQL2019_ruby/controls/encryption.rb`

---

#### DCS-616: MSSQL Version Adaptation (2016, 2017, 2018)
**Story Points:** 3
**Labels:** `inspec`, `controls`, `version-specific`

Copy and adapt MSSQL 2019 controls for earlier versions:
- [ ] Create MSSQL2016 controls with version-specific skips
- [ ] Create MSSQL2017 controls with version-specific handling
- [ ] Create MSSQL2018 controls with version-specific handling
- [ ] Handle feature availability differences:
  - Polybase (2017+)
  - External Scripts (2017+)
  - TDE in Standard Edition (2019+)
- [ ] Update inspec.yml for each version

**Version Differences Table:**
| Feature | 2016 | 2017 | 2018 | 2019 |
|---------|------|------|------|------|
| Polybase | No | Yes | Yes | Yes |
| External Scripts | No | Yes | Yes | Yes |
| TDE in Standard | No | No | No | Yes |

---

#### DCS-617: MSSQL Role Enhancements
**Story Points:** 2
**Labels:** `ansible`, `role-enhancement`

Enhance MSSQL role with additional features:
- [ ] Add version auto-detection (optional)
- [ ] Add control filtering by tags
- [ ] Add `skip_controls` variable for exclusion
- [ ] Add `control_tags` variable for inclusion filtering
- [ ] Validate enhancement works with existing workflow

**File:** `roles/mssql_inspec/defaults/main.yml`

```yaml
# Control execution options
run_all_controls: true
control_tags: []           # e.g., ['authentication', 'encryption']
skip_controls: []          # e.g., ['mssql-2019-6.01']
```

---

#### DCS-618: MSSQL Unit Testing
**Story Points:** 2
**Labels:** `testing`, `unit-tests`

Create unit tests for MSSQL controls:
- [ ] Create `tests/unit/mssql_controls_test.rb`
- [ ] Validate all control IDs match pattern `mssql-20XX-X.XX`
- [ ] Validate all controls have NIST tags
- [ ] Validate all controls have impact scores
- [ ] Run `inspec check` for all version profiles
- [ ] Document test execution process

---

#### DCS-619: MSSQL Azure Integration Testing
**Story Points:** 3
**Labels:** `testing`, `integration`, `azure`

Create and execute Azure-based integration tests:
- [ ] Deploy MSSQL container via Terraform
- [ ] Create `tests/integration/test_mssql_azure.yml`
- [ ] Test preflight connectivity check
- [ ] Test full InSpec scan execution
- [ ] Validate JSON output structure
- [ ] Validate summary report generation
- [ ] Test failure scenarios (wrong credentials, unreachable)
- [ ] Destroy Azure infrastructure after tests

---

## DCS-620: Oracle InSpec Role - Production Completion

**Type:** Story
**Epic:** DCS-600
**Priority:** Must Have
**Story Points:** 23

### Description
Complete the Oracle InSpec role to production-ready status with comprehensive NIST-mapped controls for Oracle 11g, 12c, 18c, and 19c.

**As a** Security Analyst,
**I want to** execute automated compliance scans against Oracle databases,
**So that** I can generate audit-ready NIST compliance reports for Oracle environments.

### Acceptance Criteria
- [ ] 65+ controls implemented for Oracle 19c (baseline version)
- [ ] Controls adapted for 11g, 12c, 18c with version-specific handling
- [ ] Each control has NIST SP 800-53 and CIS mapping in metadata
- [ ] Both Easy Connect and TNS naming methods supported
- [ ] CDB/PDB support for 12c+ versions
- [ ] JSON output matches standardized naming convention
- [ ] All controls tested against Azure infrastructure
- [ ] README updated with complete control inventory

### Technical Notes
- Role location: `roles/oracle_inspec/`
- Current status: 80% complete (role structure done, controls partial)
- InSpec resource: `oracledb_session`
- Client requirement: `sqlplus` on delegate host

### Dependencies
- Blocked by: None
- Blocks: DCS-650 (Multi-platform Playbook)

### Sub-Tasks

#### DCS-621: Oracle 19c InSpec Controls - Installation & Configuration
**Story Points:** 2
**Labels:** `inspec`, `controls`, `oracle-19c`

Implement controls 1.01-1.08 for Installation & Configuration:
- [ ] 1.01: Latest Critical Patch Applied
- [ ] 1.02: Default Listener Port Changed
- [ ] 1.03: Database Version Supported
- [ ] 1.04: ORACLE_HOME Permissions
- [ ] 1.05: Audit File Destination Set
- [ ] 1.06: Control File Protection
- [ ] 1.07: Redo Log Protection
- [ ] 1.08: SPFILE in Use

**File:** `roles/oracle_inspec/files/ORACLE19c_ruby/controls/installation.rb`

---

#### DCS-622: Oracle 19c InSpec Controls - User Account Management
**Story Points:** 3
**Labels:** `inspec`, `controls`, `oracle-19c`

Implement controls 2.01-2.14 for User Account Management:
- [ ] 2.01: Default Users Locked
- [ ] 2.02: Default Passwords Changed
- [ ] 2.03: SYS Password Secure
- [ ] 2.04: SYSTEM Password Secure
- [ ] 2.05: DBSNMP Account Locked
- [ ] 2.06: Sample Schema Users Removed
- [ ] 2.07: Proxy User Authentication
- [ ] 2.08: External User Authentication
- [ ] 2.09: OS Authentication Disabled
- [ ] 2.10: Password File Protection
- [ ] 2.11: REMOTE_LOGIN_PASSWORDFILE
- [ ] 2.12: Failed Login Attempts Tracked
- [ ] 2.13: Inactive Accounts Locked
- [ ] 2.14: Service Account Restrictions

**File:** `roles/oracle_inspec/files/ORACLE19c_ruby/controls/user_management.rb`

---

#### DCS-623: Oracle 19c InSpec Controls - Privilege Management
**Story Points:** 3
**Labels:** `inspec`, `controls`, `oracle-19c`

Implement controls 3.01-3.15 for Privilege Management:
- [ ] 3.01: PUBLIC Execute on UTL_FILE Revoked
- [ ] 3.02: PUBLIC Execute on UTL_HTTP Revoked
- [ ] 3.03: PUBLIC Execute on UTL_TCP Revoked
- [ ] 3.04: PUBLIC Execute on UTL_SMTP Revoked
- [ ] 3.05: PUBLIC Execute on DBMS_RANDOM Revoked
- [ ] 3.06: PUBLIC Execute on DBMS_LOB Revoked
- [ ] 3.07: PUBLIC Execute on DBMS_SQL Revoked
- [ ] 3.08: PUBLIC Execute on DBMS_XMLGEN Revoked
- [ ] 3.09: DBA Role Membership Limited
- [ ] 3.10: SYSDBA Privilege Restricted
- [ ] 3.11: SYSOPER Privilege Restricted
- [ ] 3.12: ANY Privileges Restricted
- [ ] 3.13: Direct Table Grants Limited
- [ ] 3.14: WITH ADMIN OPTION Limited
- [ ] 3.15: WITH GRANT OPTION Limited

**File:** `roles/oracle_inspec/files/ORACLE19c_ruby/controls/privilege_management.rb`

---

#### DCS-624: Oracle 19c InSpec Controls - Auditing
**Story Points:** 3
**Labels:** `inspec`, `controls`, `oracle-19c`

Implement controls 4.01-4.12 for Auditing:
- [ ] 4.01: Unified Audit Enabled (12c+)
- [ ] 4.02: AUDIT_TRAIL Parameter Set
- [ ] 4.03: Successful Logins Audited
- [ ] 4.04: Failed Logins Audited
- [ ] 4.05: DDL Statements Audited
- [ ] 4.06: DML on Sensitive Tables Audited
- [ ] 4.07: GRANT/REVOKE Audited
- [ ] 4.08: Role Changes Audited
- [ ] 4.09: User Management Audited
- [ ] 4.10: Audit Trail Protected
- [ ] 4.11: Audit Policies Applied
- [ ] 4.12: FGA Policies Configured

**File:** `roles/oracle_inspec/files/ORACLE19c_ruby/controls/auditing.rb`

---

#### DCS-625: Oracle 19c InSpec Controls - Network & Password & Encryption
**Story Points:** 3
**Labels:** `inspec`, `controls`, `oracle-19c`

Implement controls for Network (5.xx), Password (6.xx), and Encryption (7.xx):

**Network Configuration (5.01-5.06):**
- [ ] 5.01: Listener Password Set
- [ ] 5.02: Listener Logging Enabled
- [ ] 5.03: External Procedure Restricted
- [ ] 5.04: Valid Node Checking Enabled
- [ ] 5.05: TCP Valid Nodes Configured
- [ ] 5.06: Admin Restrictions Enabled

**Password Management (6.01-6.08):**
- [ ] 6.01: Password Verification Function
- [ ] 6.02: Password Complexity Enforced
- [ ] 6.03: Password Minimum Length
- [ ] 6.04: Password Expiration Set
- [ ] 6.05: Password Reuse Limited
- [ ] 6.06: Password Lock Time Set
- [ ] 6.07: Password Grace Time Set
- [ ] 6.08: Password Life Time Set

**Encryption (7.01-7.07):**
- [ ] 7.01: TDE Tablespace Encryption
- [ ] 7.02: Network Encryption Enabled
- [ ] 7.03: SQLNET Encryption Server
- [ ] 7.04: SQLNET Checksum Server
- [ ] 7.05: Wallet Protection
- [ ] 7.06: HSM Integration (if applicable)
- [ ] 7.07: Backup Encryption

**Files:**
- `roles/oracle_inspec/files/ORACLE19c_ruby/controls/network.rb`
- `roles/oracle_inspec/files/ORACLE19c_ruby/controls/password.rb`
- `roles/oracle_inspec/files/ORACLE19c_ruby/controls/encryption.rb`

---

#### DCS-626: Oracle Version Adaptation (11g, 12c, 18c)
**Story Points:** 3
**Labels:** `inspec`, `controls`, `version-specific`

Copy and adapt Oracle 19c controls for earlier versions:
- [ ] Create ORACLE11g controls (traditional audit only)
- [ ] Create ORACLE12c controls (unified audit, CDB/PDB)
- [ ] Create ORACLE18c controls (enhanced features)
- [ ] Handle feature availability differences:
  - Unified Audit (12c+)
  - Data Redaction (12c+)
  - Privilege Analysis (12c+)
  - Container Database (12c+)
  - Gradual Password Rollover (19c only)

**Version Differences Table:**
| Feature | 11g | 12c | 18c | 19c |
|---------|-----|-----|-----|-----|
| Unified Audit | No | Yes | Yes | Yes |
| Container DB | No | Yes | Yes | Yes |
| Data Redaction | No | Yes | Yes | Yes |
| Gradual Password Rollover | No | No | No | Yes |

---

#### DCS-627: Oracle Role Enhancements - PDB Support
**Story Points:** 2
**Labels:** `ansible`, `role-enhancement`

Add Container Database (CDB) and Pluggable Database (PDB) support:
- [ ] Add `container_type` variable (standalone, cdb, pdb)
- [ ] Add `pdb_name` variable for PDB-specific scanning
- [ ] Add `include_pdb_scan` variable for all-PDB scanning
- [ ] Implement PDB discovery for 12c+ versions
- [ ] Update preflight to handle CDB/PDB connections

**File:** `roles/oracle_inspec/defaults/main.yml`

```yaml
# Container database support
container_type: "standalone"  # standalone, cdb, pdb
pdb_name: ""                  # For PDB-specific scanning
include_pdb_scan: false       # Scan all PDBs in CDB
```

---

#### DCS-628: Oracle Unit Testing
**Story Points:** 2
**Labels:** `testing`, `unit-tests`

Create unit tests for Oracle controls:
- [ ] Create `tests/unit/oracle_controls_test.rb`
- [ ] Validate all control IDs match pattern `oracle-XXc-X.XX`
- [ ] Validate all controls have NIST tags
- [ ] Validate all controls have impact scores
- [ ] Validate all controls have descriptions
- [ ] Run `inspec check` for all version profiles

---

#### DCS-629: Oracle Azure Integration Testing
**Story Points:** 3
**Labels:** `testing`, `integration`, `azure`

Create and execute Azure-based integration tests:
- [ ] Deploy Oracle XE container via Terraform
- [ ] Create `tests/integration/test_oracle_azure.yml`
- [ ] Test Easy Connect method
- [ ] Test TNS naming method
- [ ] Test preflight connectivity check
- [ ] Test full InSpec scan execution
- [ ] Test CDB/PDB scanning (if applicable)
- [ ] Validate JSON output structure
- [ ] Test failure scenarios (ORA-01017, ORA-12514)
- [ ] Destroy Azure infrastructure after tests

---

## DCS-630: Sybase InSpec Role - Production Completion

**Type:** Story
**Epic:** DCS-600
**Priority:** Must Have
**Story Points:** 25

### Description
Complete the Sybase InSpec role to production-ready status with comprehensive NIST-mapped controls for Sybase ASE 15 and 16, leveraging the custom `sybase_session_local` resource.

**As a** Security Analyst,
**I want to** execute automated compliance scans against Sybase databases,
**So that** I can generate audit-ready NIST compliance reports for Sybase environments.

### Acceptance Criteria
- [ ] 60+ controls implemented for Sybase 16 (baseline version)
- [ ] Controls adapted for ASE 15 with version-specific handling
- [ ] Each control has NIST SP 800-53 mapping in metadata
- [ ] Both SAP isql and FreeTDS tsql clients supported
- [ ] SSH tunnel support functional for network-restricted environments
- [ ] Interfaces file auto-generation works
- [ ] JSON output matches standardized naming convention
- [ ] All controls tested against Azure infrastructure

### Technical Notes
- Role location: `roles/sybase_inspec/`
- Current status: 80% complete (role structure done, controls partial)
- InSpec resource: `sybase_session_local` (custom resource)
- Client requirement: `isql` (SAP) or `tsql` (FreeTDS) on delegate host

### Dependencies
- Blocked by: None
- Blocks: DCS-650 (Multi-platform Playbook)

### Sub-Tasks

#### DCS-631: Sybase 16 InSpec Controls - Server Configuration
**Story Points:** 3
**Labels:** `inspec`, `controls`, `sybase-16`

Implement controls 1.01-1.12 for Server Configuration:
- [ ] 1.01: Maximum Failed Logins
- [ ] 1.02: Password Expiration Interval
- [ ] 1.03: Minimum Password Length
- [ ] 1.04: Systemwide Password Expiration
- [ ] 1.05: Maximum Connection Timeout
- [ ] 1.06: Allow Remote Access
- [ ] 1.07: Allow Updates to System Tables
- [ ] 1.08: CIS Configuration Parameters
- [ ] 1.09: Print Recovery Info
- [ ] 1.10: Remote Server Pre-Read Packets
- [ ] 1.11: Secure Default Login
- [ ] 1.12: Allow Procedure Grouping

**File:** `roles/sybase_inspec/files/SYBASE16_ruby/controls/server_config.rb`

---

#### DCS-632: Sybase 16 InSpec Controls - Authentication
**Story Points:** 3
**Labels:** `inspec`, `controls`, `sybase-16`

Implement controls 2.01-2.12 for Authentication:
- [ ] 2.01: SA Account Password Set
- [ ] 2.02: SA Account Not Used for Apps
- [ ] 2.03: Guest User Disabled
- [ ] 2.04: Probe User Disabled
- [ ] 2.05: Default Passwords Changed
- [ ] 2.06: Login Lockout Enabled
- [ ] 2.07: External Authentication Configured
- [ ] 2.08: PAM/LDAP Integration Secure
- [ ] 2.09: SSL/TLS Enabled for Logins
- [ ] 2.10: Login Trigger Configured
- [ ] 2.11: Password Complexity Enabled
- [ ] 2.12: Password History Enforced

**File:** `roles/sybase_inspec/files/SYBASE16_ruby/controls/authentication.rb`

---

#### DCS-633: Sybase 16 InSpec Controls - Authorization
**Story Points:** 3
**Labels:** `inspec`, `controls`, `sybase-16`

Implement controls 3.01-3.15 for Authorization:
- [ ] 3.01: Public Role Permissions Limited
- [ ] 3.02: SA_ROLE Membership Restricted
- [ ] 3.03: SSO_ROLE Membership Restricted
- [ ] 3.04: OPER_ROLE Membership Restricted
- [ ] 3.05: SYBASE_TS_ROLE Limited
- [ ] 3.06: Database Owner Permissions
- [ ] 3.07: Object Permissions Reviewed
- [ ] 3.08: Execute Permissions on Sensitive SPs
- [ ] 3.09: Model Database Permissions
- [ ] 3.10: Tempdb Permissions
- [ ] 3.11: sybsystemprocs Permissions
- [ ] 3.12: Cross-Database Access Limited
- [ ] 3.13: Proxy User Configuration
- [ ] 3.14: Grantor Chain Limited
- [ ] 3.15: WITH GRANT OPTION Limited

**File:** `roles/sybase_inspec/files/SYBASE16_ruby/controls/authorization.rb`

---

#### DCS-634: Sybase 16 InSpec Controls - Auditing
**Story Points:** 2
**Labels:** `inspec`, `controls`, `sybase-16`

Implement controls 4.01-4.11 for Auditing:
- [ ] 4.01: Auditing Enabled
- [ ] 4.02: Audit Database Created
- [ ] 4.03: Login Events Audited
- [ ] 4.04: Logout Events Audited
- [ ] 4.05: Failed Logins Audited
- [ ] 4.06: Security Events Audited
- [ ] 4.07: DDL Events Audited
- [ ] 4.08: Role Changes Audited
- [ ] 4.09: Audit Queue Size Configured
- [ ] 4.10: Audit Trail Protected
- [ ] 4.11: Suspend Audit on Failure

**File:** `roles/sybase_inspec/files/SYBASE16_ruby/controls/auditing.rb`

---

#### DCS-635: Sybase 16 InSpec Controls - Encryption, Password, Network, Stored Procedures
**Story Points:** 3
**Labels:** `inspec`, `controls`, `sybase-16`

Implement remaining control categories:

**Encryption (5.01-5.06):**
- [ ] 5.01: SSL Enabled for Connections
- [ ] 5.02: Certificate Validation Enabled
- [ ] 5.03: Strong Cipher Suites Only
- [ ] 5.04: Column Encryption Configured
- [ ] 5.05: Encrypted Columns Protected
- [ ] 5.06: Master Key Protected

**Password Management (6.01-6.08):**
- [ ] 6.01: Password Complexity Function
- [ ] 6.02: Minimum Digits Required
- [ ] 6.03: Minimum Letters Required
- [ ] 6.04: Minimum Symbols Required
- [ ] 6.05: Password Not Username
- [ ] 6.06: Password Not Server Name
- [ ] 6.07: Password Expiration Warning
- [ ] 6.08: Expired Password Grace Logins

**Network Security (7.01-7.06):**
- [ ] 7.01: Named Pipe Disabled if Unused
- [ ] 7.02: TCP Keepalive Configured
- [ ] 7.03: Max Network Packet Size
- [ ] 7.04: Allow Netbios Disabled
- [ ] 7.05: Stack Size Configured
- [ ] 7.06: RPC Security Enabled

**Stored Procedures (8.01-8.08):**
- [ ] 8.01: xp_cmdshell Disabled
- [ ] 8.02: xp_freedll Restricted
- [ ] 8.03: xp_logevent Restricted
- [ ] 8.04: xp_sendmail Restricted
- [ ] 8.05: sp_addlogin Audited
- [ ] 8.06: sp_droplogin Audited
- [ ] 8.07: sp_modifylogin Audited
- [ ] 8.08: Dangerous Procedures Restricted

**Files:**
- `roles/sybase_inspec/files/SYBASE16_ruby/controls/encryption.rb`
- `roles/sybase_inspec/files/SYBASE16_ruby/controls/password.rb`
- `roles/sybase_inspec/files/SYBASE16_ruby/controls/network.rb`
- `roles/sybase_inspec/files/SYBASE16_ruby/controls/stored_procedures.rb`

---

#### DCS-636: Sybase Version Adaptation (ASE 15)
**Story Points:** 2
**Labels:** `inspec`, `controls`, `version-specific`

Copy and adapt Sybase 16 controls for ASE 15:
- [ ] Create SYBASE15 controls with version-specific handling
- [ ] Handle feature availability differences:
  - Row-level Access Control (16 only)
  - In-Memory Databases (16 only)
  - Enhanced Compression (16 only)
- [ ] Update inspec.yml for ASE 15
- [ ] Test controls against ASE 15 if available

---

#### DCS-637: Sybase Custom Resource Enhancement
**Story Points:** 2
**Labels:** `inspec`, `custom-resource`

Enhance the `sybase_session_local` custom resource:
- [ ] Add better error detection patterns
- [ ] Add query timeout handling
- [ ] Add query result caching for repeated queries
- [ ] Improve output parsing for both isql and tsql clients
- [ ] Document custom resource usage

**File:** `roles/sybase_inspec/files/SYBASE16_ruby/libraries/sybase_session_local.rb`

```ruby
# Add better error detection
def detect_connection_error(output)
  error_patterns = [
    /Login failed/i,
    /Server .* not found/i,
    /Cannot connect/i,
    /Timeout expired/i,
    /Network error/i
  ]
  error_patterns.any? { |pattern| output.match?(pattern) }
end
```

---

#### DCS-638: Sybase Role Enhancements - Client Detection
**Story Points:** 2
**Labels:** `ansible`, `role-enhancement`

Add client auto-detection and SSH tunnel validation:
- [ ] Auto-detect available Sybase clients (isql vs tsql)
- [ ] Add `preferred_client` variable to override auto-detection
- [ ] Validate SSH tunnel functionality before scan
- [ ] Add SSH tunnel connectivity test
- [ ] Update preflight to report client type used

**Files:**
- `roles/sybase_inspec/tasks/preflight.yml`
- `roles/sybase_inspec/tasks/ssh_setup.yml`

---

#### DCS-639: Sybase Unit Testing
**Story Points:** 2
**Labels:** `testing`, `unit-tests`

Create unit tests for Sybase controls and custom resource:
- [ ] Create `tests/unit/sybase_session_local_test.rb`
- [ ] Test client detection (isql/tsql)
- [ ] Test connection error detection
- [ ] Create `tests/unit/sybase_controls_test.rb`
- [ ] Validate all control IDs match pattern `sybase-XX-X.XX`
- [ ] Validate all controls have NIST tags
- [ ] Validate custom resource loads correctly
- [ ] Run `inspec check` for all version profiles

---

#### DCS-640: Sybase Azure Integration Testing
**Story Points:** 3
**Labels:** `testing`, `integration`, `azure`

Create and execute Azure-based integration tests:
- [ ] Deploy Sybase container via Terraform
- [ ] Create `tests/integration/test_sybase_azure.yml`
- [ ] Test interfaces file generation
- [ ] Test preflight connectivity check
- [ ] Test full InSpec scan execution with isql
- [ ] Test full InSpec scan execution with tsql
- [ ] Create `tests/integration/test_sybase_clients.yml`
- [ ] Validate JSON output structure
- [ ] Test failure scenarios (wrong credentials, unreachable)
- [ ] Create `tests/integration/test_sybase_ssh_tunnel.yml` (if SSH jump available)
- [ ] Destroy Azure infrastructure after tests

---

## DCS-650: Multi-Platform Playbook and Documentation

**Type:** Story
**Epic:** DCS-600
**Priority:** Should Have
**Story Points:** 8

### Description
Create a unified multi-platform compliance scanning playbook and comprehensive documentation for all three database platform roles.

**As a** DevOps Engineer,
**I want to** run compliance scans across multiple database platforms in a single execution,
**So that** I can efficiently scan heterogeneous database environments.

### Acceptance Criteria
- [ ] Multi-platform playbook `run_compliance_scans.yml` orchestrates all platforms
- [ ] Platform-specific execution based on inventory groups
- [ ] Unified output directory structure
- [ ] Aggregate summary report across all platforms
- [ ] README files updated for all three roles
- [ ] Control inventory documented per platform
- [ ] Troubleshooting guide created
- [ ] Azure test workflow documented

### Dependencies
- Blocked by: DCS-610, DCS-620, DCS-630
- Blocks: None

### Sub-Tasks

#### DCS-651: Multi-Platform Orchestration Playbook
**Story Points:** 3
**Labels:** `ansible`, `playbook`

Create unified multi-platform playbook:
- [ ] Create `playbooks/run_compliance_scans.yml`
- [ ] Support platform selection via inventory groups
- [ ] Implement parallel execution where possible
- [ ] Aggregate results from all platforms
- [ ] Generate combined summary report

---

#### DCS-652: Documentation Updates
**Story Points:** 3
**Labels:** `documentation`

Update all documentation:
- [ ] Update `roles/mssql_inspec/README.md` with control inventory
- [ ] Update `roles/oracle_inspec/README.md` with control inventory
- [ ] Update `roles/sybase_inspec/README.md` with control inventory
- [ ] Create control mapping table (control ID -> NIST -> CIS)
- [ ] Document Azure testing workflow

---

#### DCS-653: Troubleshooting Guide
**Story Points:** 2
**Labels:** `documentation`

Create troubleshooting documentation:
- [ ] Document common error codes per platform
- [ ] Create decision tree for connectivity issues
- [ ] Document client installation requirements
- [ ] Create FAQ section
- [ ] Add debugging tips (verbose mode, log analysis)

**File:** `docs/TROUBLESHOOTING_GUIDE.md`

---

# Summary - Story Point Breakdown

## By Database Type (Original + New Epic)

| Database | Original Tickets | New Epic Tickets | Total Story Points |
|----------|------------------|------------------|---------------------|
| **MSSQL** | DBSCAN-100 to 106 (26 pts) | DCS-610 to 619 (21 pts) | 47 |
| **Oracle** | DBSCAN-200 to 205 (23 pts) | DCS-620 to 629 (23 pts) | 46 |
| **Sybase** | DBSCAN-300 to 305 (23 pts) | DCS-630 to 640 (25 pts) | 48 |
| **PostgreSQL** | DBSCAN-400 to 403 (11 pts) | - | 11 |
| **Cross-Cutting** | DBSCAN-500 to 503 (14 pts) | DCS-650 to 653 (8 pts) | 22 |
| **Total** | 97 points | 77 points | **174 points** |

## Epic DCS-600 Summary

| Story | Description | Story Points |
|-------|-------------|--------------|
| DCS-610 | MSSQL Production Completion | 21 |
| DCS-620 | Oracle Production Completion | 23 |
| DCS-630 | Sybase Production Completion | 25 |
| DCS-650 | Multi-Platform & Documentation | 8 |
| **Total** | | **77 points** |

## Recommended Sprint Planning for Epic DCS-600

### Sprint 6 (Week 11-12): MSSQL Controls
- DCS-611: MSSQL Surface Area Controls (3 pts)
- DCS-612: MSSQL Authentication Controls (2 pts)
- DCS-613: MSSQL Authorization Controls (2 pts)
- DCS-614: MSSQL Auditing Controls (2 pts)
- DCS-615: MSSQL Encryption Controls (2 pts)
- DCS-616: MSSQL Version Adaptation (3 pts)
- DCS-617: MSSQL Role Enhancements (2 pts)
- **Sprint Total: 16 points**

### Sprint 7 (Week 13-14): MSSQL Testing + Oracle Controls Start
- DCS-618: MSSQL Unit Testing (2 pts)
- DCS-619: MSSQL Azure Integration Testing (3 pts)
- DCS-621: Oracle Installation Controls (2 pts)
- DCS-622: Oracle User Management Controls (3 pts)
- DCS-623: Oracle Privilege Management Controls (3 pts)
- **Sprint Total: 13 points**

### Sprint 8 (Week 15-16): Oracle Controls Complete
- DCS-624: Oracle Auditing Controls (3 pts)
- DCS-625: Oracle Network/Password/Encryption Controls (3 pts)
- DCS-626: Oracle Version Adaptation (3 pts)
- DCS-627: Oracle PDB Support (2 pts)
- DCS-628: Oracle Unit Testing (2 pts)
- DCS-629: Oracle Azure Integration Testing (3 pts)
- **Sprint Total: 16 points**

### Sprint 9 (Week 17-18): Sybase Controls
- DCS-631: Sybase Server Config Controls (3 pts)
- DCS-632: Sybase Authentication Controls (3 pts)
- DCS-633: Sybase Authorization Controls (3 pts)
- DCS-634: Sybase Auditing Controls (2 pts)
- DCS-635: Sybase Encryption/Password/Network/SP Controls (3 pts)
- DCS-636: Sybase Version Adaptation (2 pts)
- **Sprint Total: 16 points**

### Sprint 10 (Week 19-20): Sybase Testing + Multi-Platform
- DCS-637: Sybase Custom Resource Enhancement (2 pts)
- DCS-638: Sybase Client Detection Enhancement (2 pts)
- DCS-639: Sybase Unit Testing (2 pts)
- DCS-640: Sybase Azure Integration Testing (3 pts)
- DCS-651: Multi-Platform Playbook (3 pts)
- DCS-652: Documentation Updates (3 pts)
- DCS-653: Troubleshooting Guide (2 pts)
- **Sprint Total: 17 points**

---

## Dependencies Graph for Epic DCS-600

```
DCS-610 (MSSQL Production)
    │
    ├── DCS-611 ──▶ DCS-612 ──▶ DCS-613 ──▶ DCS-614 ──▶ DCS-615
    │                                                        │
    │                            ┌───────────────────────────┘
    │                            ▼
    └── DCS-616 ──▶ DCS-617 ──▶ DCS-618 ──▶ DCS-619 ──────────┐
                                                               │
DCS-620 (Oracle Production)                                    │
    │                                                          │
    ├── DCS-621 ──▶ DCS-622 ──▶ DCS-623 ──▶ DCS-624 ──▶ DCS-625│
    │                                                        │ │
    │                            ┌───────────────────────────┘ │
    │                            ▼                             │
    └── DCS-626 ──▶ DCS-627 ──▶ DCS-628 ──▶ DCS-629 ──────────┤
                                                               │
DCS-630 (Sybase Production)                                    │
    │                                                          │
    ├── DCS-631 ──▶ DCS-632 ──▶ DCS-633 ──▶ DCS-634 ──▶ DCS-635│
    │                                                        │ │
    │                            ┌───────────────────────────┘ │
    │                            ▼                             │
    └── DCS-636 ──▶ DCS-637 ──▶ DCS-638 ──▶ DCS-639 ──▶ DCS-640┤
                                                               │
                                                               ▼
DCS-650 (Multi-Platform & Docs) ◀──────────────────────────────┘
    │
    └── DCS-651 ──▶ DCS-652 ──▶ DCS-653
```

---

## Labels Reference

| Label | Description |
|-------|-------------|
| `compliance` | Compliance framework related |
| `inspec` | InSpec profile or control work |
| `nist` | NIST SP 800-53 mapping |
| `production-ready` | Production readiness milestone |
| `controls` | InSpec control development |
| `mssql-2019` | MSSQL 2019 specific |
| `oracle-19c` | Oracle 19c specific |
| `sybase-16` | Sybase 16 specific |
| `version-specific` | Version adaptation work |
| `ansible` | Ansible role development |
| `role-enhancement` | Role feature enhancement |
| `testing` | Testing related |
| `unit-tests` | Unit test development |
| `integration` | Integration testing |
| `azure` | Azure infrastructure testing |
| `custom-resource` | InSpec custom resource |
| `playbook` | Ansible playbook development |
| `documentation` | Documentation work |

---

---

# Epic: DBSCAN-600 - MSSQL InSpec Role WinRM Enhancement

**Epic Summary:** Enhance the existing `mssql_inspec` role to support WinRM-based connectivity for Windows SQL Server scanning, with improvements for large-scale batch processing across 100+ servers.

**Business Value:**
- Enable Windows SQL Server compliance scanning via WinRM transport
- Support scanning 100+ servers with batch processing and parallelism
- Maintain backward compatibility with existing direct (sqlcmd) mode
- Provide comprehensive error handling for enterprise-scale operations

**Epic Acceptance Criteria:**
- [ ] WinRM mode connects and executes InSpec scans on Windows SQL Server
- [ ] Direct mode (sqlcmd) unchanged - no regression
- [ ] Batch processing supports configurable batch sizes and parallelism
- [ ] Error aggregation provides actionable reports for failed scans
- [ ] InSpec profiles support dual-mode inputs (legacy and new naming)
- [ ] Documentation updated with WinRM configuration and troubleshooting

**Labels:** `winrm`, `mssql`, `enhancement`, `large-scale`, `windows`
**Components:** `mssql_inspec`

**Related PRP:** `docs/prp/PRP_MSSQL_WINRM_ENHANCEMENT.md`

---

## DBSCAN-601: Phase 1 - Core WinRM Integration

**Type:** Story
**Epic:** DBSCAN-600
**Priority:** Must Have
**Story Points:** 13

### Description
Implement conditional WinRM execution mode in the MSSQL InSpec role, enabling scans against Windows SQL Server instances via WinRM transport while preserving existing direct connection mode.

**As a** DevOps Engineer,
**I want to** scan Windows SQL Server instances via WinRM transport,
**So that** I can run compliance scans on Windows servers where direct sqlcmd access is not available.

### Acceptance Criteria
- [ ] `use_winrm` variable toggles between WinRM and direct modes
- [ ] WinRM mode uses `train-winrm` gem for InSpec transport
- [ ] Direct mode behavior unchanged (no regression)
- [ ] Pre-flight checks validate WinRM connectivity before scan
- [ ] Execute tasks route to mode-specific implementations
- [ ] WinRM credentials (username/password) accepted via variables
- [ ] WinRM SSL option supported (port 5986)
- [ ] Connection timeout configurable

### Technical Notes
- Role location: `roles/mssql_inspec/`
- New variable: `use_winrm: false` (default maintains existing behavior)
- WinRM variables: `winrm_host`, `winrm_port`, `winrm_username`, `winrm_password`, `winrm_ssl`
- Pre-flight uses `inspec detect` to validate WinRM connectivity

### Dependencies
- Blocked by: None
- Blocks: DBSCAN-602, DBSCAN-603, DBSCAN-604

### Sub-Tasks

#### DBSCAN-601a: Update defaults/main.yml with WinRM Variables
**Story Points:** 1
**Labels:** `ansible`, `configuration`

Add WinRM and batch processing variables to role defaults:
- [ ] Add `use_winrm: false` connection mode toggle
- [ ] Add WinRM connection variables (`winrm_host`, `winrm_port`, `winrm_username`, `winrm_password`)
- [ ] Add WinRM SSL variables (`winrm_ssl`, `winrm_ssl_verify`, `winrm_timeout`)
- [ ] Add batch processing variables (`batch_size`, `batch_delay`, `scan_timeout`)
- [ ] Add error handling variables (`continue_on_winrm_failure`, `max_retry_attempts`, `retry_delay`)

**File:** `roles/mssql_inspec/defaults/main.yml`

---

#### DBSCAN-601b: Create WinRM Preflight Task
**Story Points:** 3
**Labels:** `ansible`, `winrm`, `preflight`

Create WinRM-specific preflight connectivity checks:
- [ ] Create `tasks/preflight_winrm.yml`
- [ ] Verify `train-winrm` gem installed on delegate host
- [ ] Test WinRM connectivity using `inspec detect`
- [ ] Set preflight facts: `preflight_passed`, `preflight_skip_reason`, `preflight_error_code`
- [ ] Support both HTTP (5985) and HTTPS (5986) ports
- [ ] Handle SSL verification options
- [ ] Timeout handling for unresponsive Windows hosts

**File:** `roles/mssql_inspec/tasks/preflight_winrm.yml`

---

#### DBSCAN-601c: Update preflight.yml with Mode Routing
**Story Points:** 2
**Labels:** `ansible`, `refactor`

Refactor preflight.yml to support both connection modes:
- [ ] Add mode detection logic based on `use_winrm` variable
- [ ] Route to `preflight_winrm.yml` when `use_winrm: true`
- [ ] Route to `preflight_direct.yml` when `use_winrm: false`
- [ ] Rename existing preflight logic to `preflight_direct.yml`
- [ ] Display connection mode in debug output
- [ ] Ensure consistent fact names across both modes

**Files:**
- `roles/mssql_inspec/tasks/preflight.yml` (modify)
- `roles/mssql_inspec/tasks/preflight_direct.yml` (rename from existing logic)

---

#### DBSCAN-601d: Create WinRM Execute Task
**Story Points:** 3
**Labels:** `ansible`, `winrm`, `execution`

Create WinRM-specific InSpec execution task:
- [ ] Create `tasks/execute_winrm.yml`
- [ ] Verify InSpec binary available on delegate host
- [ ] Build InSpec command with WinRM transport (`-t winrm://...`)
- [ ] Pass SQL credentials as InSpec inputs (not environment variables)
- [ ] Handle SSL options in InSpec command
- [ ] Capture JSON output for result processing
- [ ] Implement scan timeout handling
- [ ] Set consistent result structure for downstream processing

**File:** `roles/mssql_inspec/tasks/execute_winrm.yml`

---

#### DBSCAN-601e: Update execute.yml with Mode Routing
**Story Points:** 2
**Labels:** `ansible`, `refactor`

Refactor execute.yml to support both connection modes:
- [ ] Add mode detection logic based on `use_winrm` variable
- [ ] Route to `execute_winrm.yml` when `use_winrm: true`
- [ ] Route to `execute_direct.yml` when `use_winrm: false`
- [ ] Rename existing execute logic to `execute_direct.yml`
- [ ] Add connection mode to scan summary display
- [ ] Ensure JSON result parsing works for both modes

**Files:**
- `roles/mssql_inspec/tasks/execute.yml` (modify)
- `roles/mssql_inspec/tasks/execute_direct.yml` (rename from existing logic)

---

#### DBSCAN-601f: Unit Testing - Mode Detection
**Story Points:** 2
**Labels:** `testing`, `unit-tests`

Create unit tests for connection mode detection:
- [ ] Test mode detection with `use_winrm: false` returns `direct`
- [ ] Test mode detection with `use_winrm: true` returns `winrm`
- [ ] Test WinRM preflight with valid credentials passes
- [ ] Test WinRM preflight with invalid credentials fails with correct error code
- [ ] Test direct preflight unchanged (regression test)
- [ ] Test port check with unreachable host fails appropriately

---

## DBSCAN-602: Phase 1B - InSpec Profile Dual-Mode Support

**Type:** Story
**Epic:** DBSCAN-600
**Priority:** Must Have
**Story Points:** 10

### Description
Update InSpec profiles to support both direct and WinRM connection modes with unified input handling, ensuring backward compatibility with legacy input names while supporting new naming conventions.

**As a** DevOps Engineer,
**I want** InSpec profiles to work seamlessly in both connection modes,
**So that** I can use the same compliance controls regardless of transport method.

### Acceptance Criteria
- [ ] Legacy inputs (`usernm`, `passwd`, `hostnm`) work for direct mode (backward compatible)
- [ ] New inputs (`mssql_user`, `mssql_password`, `mssql_host`) work for WinRM mode
- [ ] Environment variable fallback works (`MSSQL_USER`, `MSSQL_PASS`, etc.)
- [ ] Input helper library resolves inputs with priority: new > legacy > env var
- [ ] `inspec check` passes for all modified profiles
- [ ] Controls execute correctly on Windows target via WinRM
- [ ] Controls execute correctly on Linux delegate via direct mode
- [ ] All MSSQL version profiles updated (2016, 2017, 2018, 2019)

### Technical Notes
- Input mismatch identified in PRP Section 2.3
- WinRM mode: `hostnm` should be `localhost` (SQL runs on same Windows host)
- Direct mode: `hostnm` is remote SQL Server IP
- Helper library provides unified resolution logic

### Dependencies
- Blocked by: DBSCAN-601
- Blocks: DBSCAN-603

### Sub-Tasks

#### DBSCAN-602a: Create Input Helper Library
**Story Points:** 3
**Labels:** `inspec`, `ruby`, `library`

Create Ruby helper library for unified input resolution:
- [ ] Create `libraries/input_helper.rb` in MSSQL2019_ruby profile
- [ ] Implement `resolve_user` with fallback: `mssql_user` > `usernm` > `ENV['MSSQL_USER']`
- [ ] Implement `resolve_password` with same fallback pattern
- [ ] Implement `resolve_host` with fallback to `localhost` for WinRM
- [ ] Implement `resolve_port` with default 1433
- [ ] Implement `resolve_instance` for named instances
- [ ] Document helper usage in code comments

**File:** `roles/mssql_inspec/files/MSSQL2019_ruby/libraries/input_helper.rb`

---

#### DBSCAN-602b: Update inspec.yml with Dual-Mode Inputs
**Story Points:** 2
**Labels:** `inspec`, `configuration`

Update profile metadata with dual-mode input definitions:
- [ ] Add new input names (`mssql_user`, `mssql_password`, `mssql_host`, `mssql_port`, `mssql_instance`)
- [ ] Keep legacy input names (`usernm`, `passwd`, `hostnm`, `port`, `servicenm`) for backward compatibility
- [ ] Add `connection_mode` input (direct/winrm) for controls to detect context
- [ ] Mark password inputs as sensitive
- [ ] Update profile version to reflect changes

**File:** `roles/mssql_inspec/files/MSSQL2019_ruby/inspec.yml`

---

#### DBSCAN-602c: Update Controls to Use Input Helper
**Story Points:** 2
**Labels:** `inspec`, `controls`, `refactor`

Refactor control files to use the input helper library:
- [ ] Update `controls/trusted.rb` to use `MSSQLInputHelper.resolve_*` methods
- [ ] Update all other control files in MSSQL2019_ruby profile
- [ ] Ensure `mssql_session` resource receives resolved inputs
- [ ] Add require statement for helper library
- [ ] Test controls work with legacy inputs (regression)
- [ ] Test controls work with new inputs

**Files:** `roles/mssql_inspec/files/MSSQL2019_ruby/controls/*.rb`

---

#### DBSCAN-602d: Replicate Changes to Other MSSQL Versions
**Story Points:** 2
**Labels:** `inspec`, `version-specific`

Apply dual-mode support to all MSSQL version profiles:
- [ ] Copy `libraries/input_helper.rb` to MSSQL2018_ruby, MSSQL2017_ruby, MSSQL2016_ruby
- [ ] Update `inspec.yml` in each version profile
- [ ] Update control files in each version profile
- [ ] Run `inspec check` on all profiles
- [ ] Verify no syntax errors or missing dependencies

**Files:**
- `roles/mssql_inspec/files/MSSQL2018_ruby/`
- `roles/mssql_inspec/files/MSSQL2017_ruby/`
- `roles/mssql_inspec/files/MSSQL2016_ruby/`

---

#### DBSCAN-602e: Update setup.yml Profile Selection
**Story Points:** 1
**Labels:** `ansible`, `role-enhancement`

Update setup task to select correct profile based on mode (if using separate WinRM profiles):
- [ ] Add profile suffix logic based on `use_winrm` variable
- [ ] Update `_controls_source` path construction
- [ ] Validate selected profile exists before copy
- [ ] Document profile selection in debug output

**File:** `roles/mssql_inspec/tasks/setup.yml`

---

## DBSCAN-603: Phase 2 - Batch Processing and Parallelism

**Type:** Story
**Epic:** DBSCAN-600
**Priority:** Should Have
**Story Points:** 5

### Description
Implement batch processing capabilities to efficiently scan 100+ SQL Server instances with configurable concurrency and serial execution control.

**As a** DevOps Engineer,
**I want to** scan large numbers of SQL Servers efficiently,
**So that** I can complete enterprise-wide compliance scans within reasonable timeframes.

### Acceptance Criteria
- [ ] Batch processing playbook executes hosts in configurable batches
- [ ] Serial execution limits concurrent hosts per batch
- [ ] Parallel execution respects Ansible `forks` setting
- [ ] Batch delay configurable between batches
- [ ] Per-host scan timeout prevents hanging scans
- [ ] Batch of 10 hosts completes in < 15 minutes (parallel)
- [ ] Single WinRM scan completes in < 5 minutes

### Technical Notes
- Uses Ansible `serial` directive for batch sizing
- Uses `strategy: free` for parallel execution within batch
- Default: `batch_size: 10`, `parallel_scans: 5`, `scan_timeout: 300`
- Memory target: < 500MB per concurrent scan

### Dependencies
- Blocked by: DBSCAN-601, DBSCAN-602
- Blocks: DBSCAN-604

### Sub-Tasks

#### DBSCAN-603a: Create Batch Processing Playbook
**Story Points:** 3
**Labels:** `ansible`, `playbook`, `batch`

Create dedicated batch processing playbook:
- [ ] Create `test_playbooks/run_mssql_inspec_batch.yml`
- [ ] Implement `serial` directive for batch sizing
- [ ] Implement `strategy: free` for parallel execution
- [ ] Include mssql_inspec role with `preflight_continue_on_failure: true`
- [ ] Aggregate results to controller in post_tasks
- [ ] Add batch progress display between batches
- [ ] Implement `batch_delay` between batches

**File:** `test_playbooks/run_mssql_inspec_batch.yml`

---

#### DBSCAN-603b: Ansible Configuration for Parallelism
**Story Points:** 1
**Labels:** `ansible`, `configuration`

Create/update Ansible configuration for optimal parallelism:
- [ ] Create/update `ansible.cfg` in project root
- [ ] Set `forks = 10` for concurrent execution
- [ ] Set `strategy = free` as default
- [ ] Set `timeout = 300` for scan timeout
- [ ] Enable SSH pipelining for performance
- [ ] Configure fact caching for memory efficiency

**File:** `ansible.cfg`

---

#### DBSCAN-603c: Performance Testing
**Story Points:** 1
**Labels:** `testing`, `performance`

Validate performance targets are met:
- [ ] Test single WinRM scan completes < 5 minutes
- [ ] Test batch of 10 hosts completes < 15 minutes
- [ ] Monitor memory usage during parallel scans
- [ ] Document observed performance metrics
- [ ] Identify and document any bottlenecks

---

## DBSCAN-604: Phase 3 - Error Handling and Aggregation

**Type:** Story
**Epic:** DBSCAN-600
**Priority:** Must Have
**Story Points:** 5

### Description
Implement comprehensive error handling with aggregation and reporting for large-scale scanning operations, enabling actionable troubleshooting.

**As a** DevOps Engineer,
**I want** comprehensive error reports from batch scans,
**So that** I can quickly identify and remediate connectivity or configuration issues across many servers.

### Acceptance Criteria
- [ ] Error aggregation collects all failures across batch execution
- [ ] Error summary report generated with all failed hosts
- [ ] Error codes standardized for WinRM failures
- [ ] Recommended actions included in error report
- [ ] Error report saved to results directory
- [ ] Individual host errors don't stop batch execution
- [ ] Retry logic attempts failed connections configurable times

### Technical Notes
- Error codes: `WINRM_CONNECTION_FAILED`, `PORT_UNREACHABLE`, `AUTH_FAILED`, `TIMEOUT`
- Report format: Text file with structured sections
- Retry: Default 2 attempts with 10-second delay

### Dependencies
- Blocked by: DBSCAN-601
- Blocks: DBSCAN-605

### Sub-Tasks

#### DBSCAN-604a: Create Error Handling Task
**Story Points:** 2
**Labels:** `ansible`, `error-handling`

Create error aggregation task file:
- [ ] Create `tasks/error_handling.yml`
- [ ] Initialize error tracking fact list
- [ ] Record scan failures with timestamp, host, error code, message
- [ ] Include connection mode and WinRM host in error record
- [ ] Delegate error collection to localhost
- [ ] Handle retry logic for transient failures

**File:** `roles/mssql_inspec/tasks/error_handling.yml`

---

#### DBSCAN-604b: Create Error Summary Template
**Story Points:** 2
**Labels:** `ansible`, `templates`

Create Jinja2 template for error summary report:
- [ ] Create `templates/error_summary.j2`
- [ ] Include header with generation timestamp
- [ ] List total error count
- [ ] Detail each error with full context
- [ ] Group recommended actions by error code
- [ ] Include remediation commands for common issues
- [ ] Format for readability

**File:** `roles/mssql_inspec/templates/error_summary.j2`

---

#### DBSCAN-604c: Integrate Error Handling into Cleanup
**Story Points:** 1
**Labels:** `ansible`, `integration`

Integrate error aggregation into cleanup phase:
- [ ] Call error_handling.yml from cleanup.yml
- [ ] Generate error summary when errors exist
- [ ] Save error report to results directory
- [ ] Display error count in final summary
- [ ] Set playbook exit status based on errors (configurable)

**File:** `roles/mssql_inspec/tasks/cleanup.yml`

---

## DBSCAN-605: Phase 4 - Documentation Updates

**Type:** Story
**Epic:** DBSCAN-600
**Priority:** Must Have
**Story Points:** 3

### Description
Update all relevant documentation to cover WinRM mode configuration, batch processing usage, and troubleshooting guidance.

**As a** DevOps Engineer,
**I want** comprehensive documentation for WinRM scanning,
**So that** I can configure, execute, and troubleshoot WinRM-based compliance scans.

### Acceptance Criteria
- [ ] Role README updated with WinRM configuration section
- [ ] All new variables documented with descriptions and defaults
- [ ] Batch processing usage documented
- [ ] Troubleshooting guide for WinRM issues created
- [ ] Example inventory for mixed mode (direct + WinRM) provided
- [ ] Input naming conventions documented (legacy vs new)
- [ ] Prerequisites (train-winrm, pywinrm) documented

### Dependencies
- Blocked by: DBSCAN-601, DBSCAN-602, DBSCAN-603, DBSCAN-604
- Blocks: None

### Sub-Tasks

#### DBSCAN-605a: Update Role README
**Story Points:** 1
**Labels:** `documentation`

Update mssql_inspec role README with WinRM documentation:
- [ ] Add WinRM Mode Configuration section
- [ ] Document all WinRM variables with examples
- [ ] Document batch processing variables
- [ ] Add example playbook invocations
- [ ] Add mixed inventory example
- [ ] Update variable reference table

**File:** `roles/mssql_inspec/README.md`

---

#### DBSCAN-605b: Update WINRM_PREREQUISITES.md
**Story Points:** 1
**Labels:** `documentation`

Update WinRM prerequisites documentation:
- [ ] Add section for role-based WinRM usage (not standalone playbook)
- [ ] Update inventory configuration examples
- [ ] Add large-scale deployment considerations
- [ ] Document train-winrm gem installation
- [ ] Document Windows host preparation steps
- [ ] Add network requirements (ports 5985/5986)

**File:** `docs/WINRM_PREREQUISITES.md`

---

#### DBSCAN-605c: Create WinRM Troubleshooting Section
**Story Points:** 1
**Labels:** `documentation`

Create troubleshooting content for WinRM issues:
- [ ] Document common WinRM error codes and causes
- [ ] Add decision tree for WinRM connectivity issues
- [ ] Document debugging steps (`inspec detect` usage)
- [ ] Add Windows host configuration verification steps
- [ ] Document firewall and network troubleshooting
- [ ] Add FAQ for WinRM-specific questions

**File:** `docs/WINRM_PREREQUISITES.md` (troubleshooting section)

---

## DBSCAN-606: Azure Integration Testing - WinRM Mode

**Type:** Story
**Epic:** DBSCAN-600
**Priority:** Must Have
**Story Points:** 5

### Description
Create and execute Azure-based integration tests for WinRM mode, validating the complete workflow against Windows SQL Server infrastructure.

**As a** DevOps Engineer,
**I want** validated integration tests for WinRM scanning,
**So that** I have confidence the solution works in real Windows environments.

### Acceptance Criteria
- [ ] Windows SQL Server VM deployed via Terraform
- [ ] WinRM enabled and accessible on test VM
- [ ] Direct mode test passes against Linux container
- [ ] WinRM mode test passes against Windows VM
- [ ] Batch processing test executes multiple hosts
- [ ] Error handling test validates failure scenarios
- [ ] All test results documented

### Technical Notes
- Use existing Terraform infrastructure in `terraform/` directory
- Windows VM: `windows-mssql-vm.tf`
- Linux container: `mssql-container.tf`
- Test both HTTP (5985) and HTTPS (5986) WinRM ports

### Dependencies
- Blocked by: DBSCAN-601, DBSCAN-602, DBSCAN-603, DBSCAN-604
- Blocks: None

### Sub-Tasks

#### DBSCAN-606a: Deploy Azure Test Infrastructure
**Story Points:** 1
**Labels:** `testing`, `azure`, `terraform`

Deploy test infrastructure for WinRM testing:
- [ ] Verify `terraform/windows-mssql-vm.tf` provisions correctly
- [ ] Enable WinRM on Windows VM during provisioning
- [ ] Configure SQL Server with test database
- [ ] Document WinRM connectivity from delegate host
- [ ] Capture infrastructure outputs for test playbooks

---

#### DBSCAN-606b: Create WinRM Integration Test Playbook
**Story Points:** 2
**Labels:** `testing`, `integration`

Create integration test playbook for WinRM mode:
- [ ] Create `tests/integration/test_mssql_winrm.yml`
- [ ] Test WinRM preflight passes with valid credentials
- [ ] Test WinRM preflight fails with invalid credentials
- [ ] Test full InSpec scan execution via WinRM
- [ ] Validate JSON output structure
- [ ] Test error aggregation for failures

**File:** `tests/integration/test_mssql_winrm.yml`

---

#### DBSCAN-606c: Create Regression Test Playbook
**Story Points:** 1
**Labels:** `testing`, `regression`

Create regression test playbook for direct mode:
- [ ] Create `tests/integration/test_mssql_direct_regression.yml`
- [ ] Test direct mode unchanged after WinRM enhancement
- [ ] Validate all preflight scenarios work as before
- [ ] Validate JSON output identical to pre-enhancement
- [ ] Validate cleanup tasks work

**File:** `tests/integration/test_mssql_direct_regression.yml`

---

#### DBSCAN-606d: Create Batch Processing Test Playbook
**Story Points:** 1
**Labels:** `testing`, `batch`

Create test playbook for batch processing:
- [ ] Create `tests/integration/test_mssql_batch.yml`
- [ ] Test batch execution with multiple hosts
- [ ] Verify serial execution respects batch_size
- [ ] Verify parallel execution within batch
- [ ] Test error aggregation across batch
- [ ] Validate performance targets

**File:** `tests/integration/test_mssql_batch.yml`

---

# Summary - DBSCAN-600 Epic Story Point Breakdown

## By Phase

| Phase | Tickets | Story Points |
|-------|---------|--------------|
| **Phase 1: Core WinRM Integration** | DBSCAN-601 (a-f) | 13 |
| **Phase 1B: InSpec Profile Dual-Mode** | DBSCAN-602 (a-e) | 10 |
| **Phase 2: Batch Processing** | DBSCAN-603 (a-c) | 5 |
| **Phase 3: Error Handling** | DBSCAN-604 (a-c) | 5 |
| **Phase 4: Documentation** | DBSCAN-605 (a-c) | 3 |
| **Integration Testing** | DBSCAN-606 (a-d) | 5 |
| **Total** | | **41 points** |

## Sprint Planning Recommendation

### Sprint X (Week 1-2): Core WinRM Integration
- DBSCAN-601a: Update defaults/main.yml (1 pt)
- DBSCAN-601b: Create WinRM Preflight Task (3 pts)
- DBSCAN-601c: Update preflight.yml Mode Routing (2 pts)
- DBSCAN-601d: Create WinRM Execute Task (3 pts)
- DBSCAN-601e: Update execute.yml Mode Routing (2 pts)
- DBSCAN-601f: Unit Testing - Mode Detection (2 pts)
- **Sprint Total: 13 points**

### Sprint X+1 (Week 3-4): InSpec Profile + Batch Processing
- DBSCAN-602a: Create Input Helper Library (3 pts)
- DBSCAN-602b: Update inspec.yml Dual-Mode Inputs (2 pts)
- DBSCAN-602c: Update Controls to Use Input Helper (2 pts)
- DBSCAN-602d: Replicate to Other MSSQL Versions (2 pts)
- DBSCAN-602e: Update setup.yml Profile Selection (1 pt)
- DBSCAN-603a: Create Batch Processing Playbook (3 pts)
- DBSCAN-603b: Ansible Configuration (1 pt)
- DBSCAN-603c: Performance Testing (1 pt)
- **Sprint Total: 15 points**

### Sprint X+2 (Week 5): Error Handling + Documentation + Testing
- DBSCAN-604a: Create Error Handling Task (2 pts)
- DBSCAN-604b: Create Error Summary Template (2 pts)
- DBSCAN-604c: Integrate Error Handling into Cleanup (1 pt)
- DBSCAN-605a: Update Role README (1 pt)
- DBSCAN-605b: Update WINRM_PREREQUISITES.md (1 pt)
- DBSCAN-605c: Create Troubleshooting Section (1 pt)
- DBSCAN-606a: Deploy Azure Test Infrastructure (1 pt)
- DBSCAN-606b: Create WinRM Integration Test (2 pts)
- DBSCAN-606c: Create Regression Test (1 pt)
- DBSCAN-606d: Create Batch Processing Test (1 pt)
- **Sprint Total: 13 points**

## Dependencies Graph

```
DBSCAN-601 (Core WinRM Integration)
    │
    ├── DBSCAN-601a (defaults) ─────────────┐
    │                                        │
    ├── DBSCAN-601b (preflight_winrm) ──────┤
    │                                        │
    ├── DBSCAN-601c (preflight routing) ────┤
    │                                        │
    ├── DBSCAN-601d (execute_winrm) ────────┤
    │                                        │
    ├── DBSCAN-601e (execute routing) ──────┤
    │                                        │
    └── DBSCAN-601f (unit tests) ───────────┘
                    │
                    ▼
DBSCAN-602 (InSpec Dual-Mode)
    │
    ├── DBSCAN-602a (input_helper.rb) ──────┐
    │                                        │
    ├── DBSCAN-602b (inspec.yml) ───────────┤
    │                                        │
    ├── DBSCAN-602c (controls update) ──────┤
    │                                        │
    ├── DBSCAN-602d (version replication) ──┤
    │                                        │
    └── DBSCAN-602e (setup.yml) ────────────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
DBSCAN-603 (Batch)      DBSCAN-604 (Error Handling)
    │                           │
    └───────────┬───────────────┘
                │
                ▼
        DBSCAN-605 (Documentation)
                │
                ▼
        DBSCAN-606 (Integration Testing)
```

## Files Created/Modified Summary

### New Files
| File | Ticket | Purpose |
|------|--------|---------|
| `tasks/preflight_winrm.yml` | DBSCAN-601b | WinRM preflight checks |
| `tasks/preflight_direct.yml` | DBSCAN-601c | Renamed from existing preflight logic |
| `tasks/execute_winrm.yml` | DBSCAN-601d | WinRM InSpec execution |
| `tasks/execute_direct.yml` | DBSCAN-601e | Renamed from existing execute logic |
| `tasks/error_handling.yml` | DBSCAN-604a | Error aggregation |
| `templates/error_summary.j2` | DBSCAN-604b | Error report template |
| `files/MSSQL2019_ruby/libraries/input_helper.rb` | DBSCAN-602a | Input resolution helper |
| `test_playbooks/run_mssql_inspec_batch.yml` | DBSCAN-603a | Batch processing playbook |
| `tests/integration/test_mssql_winrm.yml` | DBSCAN-606b | WinRM integration test |
| `tests/integration/test_mssql_direct_regression.yml` | DBSCAN-606c | Direct mode regression test |
| `tests/integration/test_mssql_batch.yml` | DBSCAN-606d | Batch processing test |

### Modified Files
| File | Ticket | Changes |
|------|--------|---------|
| `defaults/main.yml` | DBSCAN-601a | Add WinRM/batch variables |
| `tasks/preflight.yml` | DBSCAN-601c | Add mode routing |
| `tasks/execute.yml` | DBSCAN-601e | Add mode routing |
| `tasks/setup.yml` | DBSCAN-602e | Add profile selection logic |
| `tasks/cleanup.yml` | DBSCAN-604c | Integrate error handling |
| `files/MSSQL2019_ruby/inspec.yml` | DBSCAN-602b | Add dual-mode inputs |
| `files/MSSQL2019_ruby/controls/*.rb` | DBSCAN-602c | Use input helper |
| `README.md` | DBSCAN-605a | Add WinRM documentation |
| `docs/WINRM_PREREQUISITES.md` | DBSCAN-605b/c | Role-based usage, troubleshooting |
| `ansible.cfg` | DBSCAN-603b | Parallelism configuration |

---

*Document generated for project planning purposes. Ticket IDs are placeholders - update with actual JIRA ticket numbers upon creation.*
*Last Updated: 2026-01-25*
