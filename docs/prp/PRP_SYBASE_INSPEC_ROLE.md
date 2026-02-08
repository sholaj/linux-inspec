# PRP: Sybase InSpec Compliance Role

> **STATUS: COMPLETED** | Closed: 2026-02-08
>
> All requirements implemented. Role fully functional with CIS benchmark controls for Sybase ASE 15/16. Tested through Azure delegate host infrastructure.

## Product Requirement Prompt/Plan

**Purpose:** Complete the Sybase InSpec scanning role to production-ready status with comprehensive CIS-mapped controls for Sybase ASE 15 and 16, leveraging the custom `sybase_session_local` resource.

---

## 1. Product Requirements

### 1.1 Business Context
- **Project:** Database Compliance Scanning Modernization
- **Phase:** POC → MVP transition
- **Scope:** Sybase ASE compliance scanning via AAP2 delegate host pattern
- **Target Users:** Security/Compliance teams, DBAs, Audit teams
- **Compliance Framework:** NIST SP 800-53, CIS (adapted for Sybase)

### 1.2 Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-01 | Execute InSpec controls against Sybase ASE 15/16 | MUST |
| FR-02 | Support server-level configuration checks | MUST |
| FR-03 | Support database-level security checks | MUST |
| FR-04 | Multi-client support (SAP isql + FreeTDS tsql) | MUST |
| FR-05 | Auto-generate interfaces file | MUST |
| FR-06 | Pre-flight connectivity validation | MUST |
| FR-07 | Generate JSON results in standardized format | MUST |
| FR-08 | SSH tunnel support for network restrictions | MUST |
| FR-09 | SYBASE environment variable configuration | MUST |
| FR-10 | Optional Splunk HEC integration | SHOULD |

### 1.3 Control Categories Required

Based on Sybase security best practices and NIST SP 800-53 mapping:

| Category | Control Count | NIST Mapping |
|----------|---------------|--------------|
| Server Configuration | 10-15 | CM-6, CM-7 |
| Authentication | 10-15 | IA-2, IA-5 |
| Authorization | 12-18 | AC-3, AC-6 |
| Auditing | 8-12 | AU-2, AU-3 |
| Encryption | 5-8 | SC-8, SC-28 |
| Password Management | 8-10 | IA-5 |
| Network Security | 5-8 | SC-7, SC-8 |
| Stored Procedures | 5-8 | CM-7, AC-3 |

**Total Expected Controls:** 65-95 per version

### 1.4 Output Requirements

**File Naming Convention:**
```
SYBASE_NIST_{PID}_{SERVER}_{DATABASE}_{VERSION}_{TIMESTAMP}_{CONTROL}.json
```

**JSON Structure:**
```json
{
  "platform": { "name": "sybase", "release": "16" },
  "profiles": [...],
  "statistics": { "duration": 0.0 },
  "version": "5.x"
}
```

---

## 2. Codebase Analysis

### 2.1 Existing Implementation

**Role Location:** `roles/sybase_inspec/`

**Structure (80% Complete):**
```
sybase_inspec/
├── tasks/
│   ├── main.yml           ✅ Entry point
│   ├── validate.yml       ✅ Parameter validation
│   ├── setup.yml          ✅ Directories, interfaces, SYBASE.sh
│   ├── execute.yml        ✅ InSpec execution
│   ├── process_results.yml ✅ JSON result processing
│   ├── cleanup.yml        ✅ Report generation
│   ├── preflight.yml      ✅ Connectivity validation
│   ├── ssh_setup.yml      ✅ SSH tunnel setup
│   └── splunk_integration.yml ✅ Splunk HEC forwarding
├── defaults/main.yml      ✅ Default variables
├── vars/main.yml          ✅ Sybase SDK paths, SSH settings
├── templates/
│   ├── interfaces.j2      ✅ Sybase interfaces file
│   ├── SYBASE.sh.j2       ✅ Environment script
│   ├── sybase_summary_report.j2 ✅ Text summary
│   └── skip_report.j2     ✅ Failed connection report
├── files/
│   ├── SYBASE15_ruby/     ⚠️ Partial controls
│   │   ├── inspec.yml
│   │   └── controls/trusted.rb
│   └── SYBASE16_ruby/     ⚠️ Partial controls
│       ├── inspec.yml
│       ├── controls/trusted.rb
│       └── libraries/
│           └── sybase_session_local.rb ✅ Custom resource
└── README.md              ✅ Documentation
```

### 2.2 Custom Resource: sybase_session_local.rb

**Key Feature:** Dual-client support with auto-detection

```ruby
# Auto-detects available client:
# 1. SAP ASE isql (native, preferred)
# 2. FreeTDS tsql (open-source alternative)

# Handles different output formats:
# - isql: Standard tabular output
# - tsql: Header-based output with different parsing

# Features:
# - Temporary SQL file creation/cleanup
# - Error handling per client type
# - Local execution optimization
```

### 2.3 Key Variables

```yaml
# From defaults/main.yml
sybase_server: ""          # Target server hostname
sybase_port: 5000          # Sybase ASE port
sybase_user: ""            # Database username
sybase_password: ""        # Database password
sybase_database: "master"  # Target database
sybase_version: "16"       # Sybase ASE version
sybase_home: "/opt/sap"    # SYBASE environment variable
sybase_ocs: "OCS-16_0"     # Open Client version
use_ssh_tunnel: false      # Enable SSH tunnel
ssh_tunnel_host: ""        # SSH jump server
ssh_tunnel_user: ""        # SSH username
ssh_local_port: 15000      # Local tunnel port
```

### 2.4 InSpec Resource Used

```ruby
sybase_session_local(
  server: input('sybase_interface_name'),
  username: input('sybase_user'),
  password: input('sybase_password'),
  database: input('sybase_database'),
  sybase_home: input('sybase_home'),
  sybase_ocs: input('sybase_ocs')
)
```

---

## 3. Execution Tasks

### Phase 1: Complete InSpec Controls

#### Task 1.1: SYBASE 16 Controls (Full Set)

**File:** `files/SYBASE16_ruby/controls/trusted.rb`

**Controls to Implement:**

```ruby
# Server Configuration (1.xx series)
control 'sybase-16-1.01' # Maximum Failed Logins
control 'sybase-16-1.02' # Password Expiration Interval
control 'sybase-16-1.03' # Minimum Password Length
control 'sybase-16-1.04' # Systemwide Password Expiration
control 'sybase-16-1.05' # Maximum Connection Timeout
control 'sybase-16-1.06' # Allow Remote Access
control 'sybase-16-1.07' # Allow Updates to System Tables
control 'sybase-16-1.08' # CIS Configuration Parameters
control 'sybase-16-1.09' # Print Recovery Info
control 'sybase-16-1.10' # Remote Server Pre-Read Packets
control 'sybase-16-1.11' # Secure Default Login
control 'sybase-16-1.12' # Allow Procedure Grouping

# Authentication (2.xx series)
control 'sybase-16-2.01' # SA Account Password Set
control 'sybase-16-2.02' # SA Account Not Used for Apps
control 'sybase-16-2.03' # Guest User Disabled
control 'sybase-16-2.04' # Probe User Disabled
control 'sybase-16-2.05' # Default Passwords Changed
control 'sybase-16-2.06' # Login Lockout Enabled
control 'sybase-16-2.07' # External Authentication Configured
control 'sybase-16-2.08' # PAM/LDAP Integration Secure
control 'sybase-16-2.09' # SSL/TLS Enabled for Logins
control 'sybase-16-2.10' # Login Trigger Configured
control 'sybase-16-2.11' # Password Complexity Enabled
control 'sybase-16-2.12' # Password History Enforced

# Authorization (3.xx series)
control 'sybase-16-3.01' # Public Role Permissions Limited
control 'sybase-16-3.02' # SA_ROLE Membership Restricted
control 'sybase-16-3.03' # SSO_ROLE Membership Restricted
control 'sybase-16-3.04' # OPER_ROLE Membership Restricted
control 'sybase-16-3.05' # SYBASE_TS_ROLE Limited
control 'sybase-16-3.06' # Database Owner Permissions
control 'sybase-16-3.07' # Object Permissions Reviewed
control 'sybase-16-3.08' # Execute Permissions on Sensitive SPs
control 'sybase-16-3.09' # Model Database Permissions
control 'sybase-16-3.10' # Tempdb Permissions
control 'sybase-16-3.11' # sybsystemprocs Permissions
control 'sybase-16-3.12' # Cross-Database Access Limited
control 'sybase-16-3.13' # Proxy User Configuration
control 'sybase-16-3.14' # Grantor Chain Limited
control 'sybase-16-3.15' # WITH GRANT OPTION Limited

# Auditing (4.xx series)
control 'sybase-16-4.01' # Auditing Enabled
control 'sybase-16-4.02' # Audit Database Created
control 'sybase-16-4.03' # Login Events Audited
control 'sybase-16-4.04' # Logout Events Audited
control 'sybase-16-4.05' # Failed Logins Audited
control 'sybase-16-4.06' # Security Events Audited
control 'sybase-16-4.07' # DDL Events Audited
control 'sybase-16-4.08' # Role Changes Audited
control 'sybase-16-4.09' # Audit Queue Size Configured
control 'sybase-16-4.10' # Audit Trail Protected
control 'sybase-16-4.11' # Suspend Audit on Failure

# Encryption (5.xx series)
control 'sybase-16-5.01' # SSL Enabled for Connections
control 'sybase-16-5.02' # Certificate Validation Enabled
control 'sybase-16-5.03' # Strong Cipher Suites Only
control 'sybase-16-5.04' # Column Encryption Configured
control 'sybase-16-5.05' # Encrypted Columns Protected
control 'sybase-16-5.06' # Master Key Protected

# Password Management (6.xx series)
control 'sybase-16-6.01' # Password Complexity Function
control 'sybase-16-6.02' # Minimum Digits Required
control 'sybase-16-6.03' # Minimum Letters Required
control 'sybase-16-6.04' # Minimum Symbols Required
control 'sybase-16-6.05' # Password Not Username
control 'sybase-16-6.06' # Password Not Server Name
control 'sybase-16-6.07' # Password Expiration Warning
control 'sybase-16-6.08' # Expired Password Grace Logins

# Network Security (7.xx series)
control 'sybase-16-7.01' # Named Pipe Disabled if Unused
control 'sybase-16-7.02' # TCP Keepalive Configured
control 'sybase-16-7.03' # Max Network Packet Size
control 'sybase-16-7.04' # Allow Netbios Disabled
control 'sybase-16-7.05' # Stack Size Configured
control 'sybase-16-7.06' # RPC Security Enabled

# Stored Procedures (8.xx series)
control 'sybase-16-8.01' # xp_cmdshell Disabled
control 'sybase-16-8.02' # xp_freedll Restricted
control 'sybase-16-8.03' # xp_logevent Restricted
control 'sybase-16-8.04' # xp_sendmail Restricted
control 'sybase-16-8.05' # sp_addlogin Audited
control 'sybase-16-8.06' # sp_droplogin Audited
control 'sybase-16-8.07' # sp_modifylogin Audited
control 'sybase-16-8.08' # Dangerous Procedures Restricted
```

#### Task 1.2: Version-Specific Controls (ASE 15)

**File:** `files/SYBASE15_ruby/controls/trusted.rb`

Copy and adapt controls for ASE 15 differences:

| Feature | ASE 15 | ASE 16 |
|---------|--------|--------|
| Row-level Access Control | Limited | Full |
| Full-Text Search | Basic | Enhanced |
| In-Memory Databases | No | Yes |
| Compression | Basic | Enhanced |
| Partitioning | Limited | Full |

### Phase 2: Custom Resource Enhancement

#### Task 2.1: Improve Error Handling

**File:** `files/SYBASE16_ruby/libraries/sybase_session_local.rb`

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

# Add timeout handling
def execute_query_with_timeout(query, timeout = 30)
  Timeout.timeout(timeout) do
    execute_query(query)
  end
rescue Timeout::Error
  { error: "Query timed out after #{timeout} seconds" }
end
```

#### Task 2.2: Add Query Result Caching

```ruby
# Cache repeated queries within same control run
def query(sql)
  @query_cache ||= {}
  @query_cache[sql] ||= execute_query(sql)
end
```

### Phase 3: Role Enhancements

#### Task 3.1: Add Client Auto-Detection

**File:** `tasks/preflight.yml`

```yaml
- name: Detect available Sybase clients
  block:
    - name: Check for SAP isql
      command: which isql
      register: isql_check
      failed_when: false

    - name: Check for FreeTDS tsql
      command: which tsql
      register: tsql_check
      failed_when: false

    - name: Set client preference
      set_fact:
        sybase_client: "{{ 'isql' if isql_check.rc == 0 else ('tsql' if tsql_check.rc == 0 else 'none') }}"

    - name: Fail if no client found
      fail:
        msg: "No Sybase client found. Install SAP Open Client or FreeTDS."
      when: sybase_client == 'none'
```

#### Task 3.2: Add SSH Tunnel Validation

**File:** `tasks/ssh_setup.yml`

```yaml
- name: Validate SSH tunnel is functional
  wait_for:
    host: localhost
    port: "{{ ssh_local_port }}"
    timeout: 30
  when: use_ssh_tunnel | bool

- name: Test database connectivity through tunnel
  shell: |
    isql -S {{ sybase_interface_name }} -U {{ sybase_user }} \
      -P {{ sybase_password }} -o /dev/null <<EOF
    SELECT 1
    go
    EOF
  register: tunnel_test
  failed_when: tunnel_test.rc != 0
  when: use_ssh_tunnel | bool
```

### Phase 4: Testing & Validation

#### Task 4.1: Create Test Inventory

**File:** `tests/inventory/sybase_test.yml`

```yaml
sybase_databases:
  hosts:
    test_sybase_16:
      sybase_server: "[DB_SERVER]"
      sybase_port: 5000
      sybase_database: "master"
      sybase_version: "16"
      sybase_user: "{{ vault_sybase_user }}"
      sybase_password: "{{ vault_sybase_password }}"
      sybase_home: "/opt/sap"
      sybase_ocs: "OCS-16_0"
      use_ssh_tunnel: false
```

#### Task 4.2: Test Both Client Types

```bash
# Test with SAP isql
SYBASE_CLIENT=isql ansible-playbook test_playbooks/run_sybase_inspec.yml \
  -i tests/inventory/sybase_test.yml \
  -e @vault.yml

# Test with FreeTDS tsql
SYBASE_CLIENT=tsql ansible-playbook test_playbooks/run_sybase_inspec.yml \
  -i tests/inventory/sybase_test.yml \
  -e @vault.yml
```

---

## 4. Acceptance Criteria

- [ ] All 60+ controls implemented for Sybase 16
- [ ] Controls adapted for ASE 15 version
- [ ] Each control has NIST mapping in metadata
- [ ] Both SAP isql and FreeTDS tsql clients work
- [ ] SSH tunnel support functional
- [ ] interfaces file auto-generation works
- [ ] SYBASE environment properly configured
- [ ] JSON output matches required format
- [ ] Summary report generated successfully
- [ ] No sensitive data in control files
- [ ] README updated with control inventory

---

## 5. Implementation Notes

### 5.1 InSpec Control Template

```ruby
control 'sybase-16-X.XX' do
  impact 1.0
  title 'Descriptive Title'
  desc 'Full description of what this control checks'

  tag nist: ['XX-X', 'XX-X(x)']
  tag severity: 'high'

  sql = sybase_session_local(
    server: input('sybase_interface_name'),
    username: input('sybase_user'),
    password: input('sybase_password'),
    database: input('sybase_database'),
    sybase_home: input('sybase_home'),
    sybase_ocs: input('sybase_ocs')
  )

  describe sql.query("SELECT ... FROM ...") do
    its('output') { should match /expected_pattern/ }
  end
end
```

### 5.2 Common Queries Reference

```sql
-- Server Configuration
SELECT name, value FROM master..sysconfigures WHERE name = 'xxx'
go

-- Login Information
SELECT name, status, accdate FROM master..syslogins
go

-- Roles and Permissions
SELECT name FROM master..syssrvroles
go

-- Audit Settings
SELECT * FROM sybsecurity..sysaudits
go

-- Database Users
SELECT name, uid FROM sysusers
go

-- Object Permissions
SELECT * FROM sysprotects
go
```

### 5.3 Client-Specific Notes

**SAP isql:**
```bash
isql -S SERVERNAME -U username -P password -D database
# Commands end with 'go'
# Batch mode: isql -S ... < script.sql
```

**FreeTDS tsql:**
```bash
tsql -S SERVERNAME -U username -P password
# Commands end with 'go'
# Different output format - header-based
```

### 5.4 Data Sensitivity Reminder

**DO NOT include in controls:**
- Real server names
- Actual credentials
- Production database names
- IP addresses
- Interfaces file entries with real hosts

**USE placeholders:**
- `input('sybase_server')`
- `input('sybase_user')`
- `[DB_SERVER]` in documentation

---

## 6. Dependencies

- InSpec 5.x
- Custom `sybase_session_local` resource (included)
- SAP Open Client SDK OR FreeTDS
- `isql` or `tsql` binary in PATH
- Network connectivity to Sybase port (default 5000)
- SSH access if using tunnel mode
- Service account with SA_ROLE or equivalent

---

## 7. Sybase-Specific Considerations

### Interfaces File Format
```
[SERVER_NAME]
    master tcp ether [HOST] [PORT]
    query tcp ether [HOST] [PORT]
```

### Environment Variables Required
```bash
export SYBASE=/opt/sap
export SYBASE_OCS=OCS-16_0
export PATH=$SYBASE/$SYBASE_OCS/bin:$PATH
export LD_LIBRARY_PATH=$SYBASE/$SYBASE_OCS/lib:$LD_LIBRARY_PATH
```

### SSH Tunnel Setup
```bash
ssh -L [LOCAL_PORT]:[DB_HOST]:[DB_PORT] [SSH_USER]@[JUMP_SERVER] -N -f
```

---

## 8. Testing Requirements

### 8.1 Azure Test Infrastructure

**All changes MUST be tested in Azure before merging.** Use the Terraform templates in `terraform/` directory.

```bash
# Deploy Sybase test infrastructure
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Terraform provisions:
# - sybase-container.tf: Sybase ASE container (Azure Container Instance)
```

**Test Environment Variables (from Terraform outputs):**

```bash
export SYBASE_HOST=$(terraform output -raw sybase_container_fqdn)
export SYBASE_PORT=5000
export SYBASE_USER="sa"
export SYBASE_PASSWORD=$(terraform output -raw sybase_sa_password)
export SYBASE_DATABASE="master"
```

### 8.2 Test Categories

#### 8.2.1 InSpec Profile Syntax Validation

```bash
# Validate InSpec profile syntax (no connectivity required)
cd roles/sybase_inspec/files/SYBASE16_ruby
inspec check .

# Expected output: "Valid profile"

# Validate all versions
for ver in SYBASE15 SYBASE16; do
  echo "Checking $ver..."
  inspec check roles/sybase_inspec/files/${ver}_ruby/
done
```

#### 8.2.2 Custom Resource Tests

**File:** `tests/unit/sybase_session_local_test.rb`

```ruby
# Test custom sybase_session_local resource
require 'inspec'
require_relative '../../roles/sybase_inspec/files/SYBASE16_ruby/libraries/sybase_session_local'

describe SybaseSessionLocal do
  describe '#detect_client' do
    it 'should detect isql when available' do
      allow_any_instance_of(described_class).to receive(:which).with('isql').and_return('/usr/bin/isql')
      session = described_class.new(server: 'test', username: 'sa', password: 'pass')
      expect(session.client_type).to eq(:isql)
    end

    it 'should fall back to tsql when isql unavailable' do
      allow_any_instance_of(described_class).to receive(:which).with('isql').and_return(nil)
      allow_any_instance_of(described_class).to receive(:which).with('tsql').and_return('/usr/bin/tsql')
      session = described_class.new(server: 'test', username: 'sa', password: 'pass')
      expect(session.client_type).to eq(:tsql)
    end
  end

  describe '#detect_connection_error' do
    let(:session) { described_class.new(server: 'test', username: 'sa', password: 'pass') }

    it 'should detect login failures' do
      expect(session.detect_connection_error('Login failed for user')).to be true
    end

    it 'should detect server not found' do
      expect(session.detect_connection_error('Server TESTSERVER not found')).to be true
    end

    it 'should return false for valid output' do
      expect(session.detect_connection_error('1 row affected')).to be false
    end
  end
end
```

#### 8.2.3 Unit Tests - Control Logic

**File:** `tests/unit/sybase_controls_test.rb`

```ruby
# Test control metadata
describe 'Sybase 16 Controls' do
  let(:profile) { Inspec::Profile.for_target('roles/sybase_inspec/files/SYBASE16_ruby') }

  it 'should have valid control IDs' do
    profile.controls.each do |control|
      expect(control.id).to match(/^sybase-16-\d+\.\d+$/)
    end
  end

  it 'should have NIST tags on all controls' do
    profile.controls.each do |control|
      expect(control.tags[:nist]).not_to be_nil
    end
  end

  it 'should have impact scores' do
    profile.controls.each do |control|
      expect(control.impact).to be_between(0.0, 1.0)
    end
  end

  it 'should load custom resource' do
    expect(profile.libraries).to include('sybase_session_local')
  end
end
```

#### 8.2.4 Integration Tests - Azure Container

**File:** `tests/integration/test_sybase_azure.yml`

```yaml
---
# Integration test playbook for Sybase against Azure container
- name: Sybase Integration Tests
  hosts: localhost
  gather_facts: false
  vars:
    test_results_dir: "/tmp/sybase_integration_tests"

  tasks:
    - name: Create test results directory
      file:
        path: "{{ test_results_dir }}"
        state: directory

    - name: Test 1 - Preflight connectivity check
      include_role:
        name: sybase_inspec
        tasks_from: preflight
      vars:
        sybase_server: "{{ lookup('env', 'SYBASE_HOST') }}"
        sybase_port: 5000
        sybase_user: "{{ lookup('env', 'SYBASE_USER') }}"
        sybase_password: "{{ lookup('env', 'SYBASE_PASSWORD') }}"
        sybase_database: "master"
      register: preflight_result

    - name: Assert preflight passed
      assert:
        that:
          - preflight_result is success
        fail_msg: "Preflight connectivity check failed"

    - name: Test 2 - Interfaces file generation
      include_role:
        name: sybase_inspec
        tasks_from: setup
      vars:
        sybase_server: "{{ lookup('env', 'SYBASE_HOST') }}"
        sybase_port: 5000
        sybase_interface_name: "TESTSERVER"
      register: setup_result

    - name: Verify interfaces file created
      stat:
        path: "{{ sybase_home }}/interfaces"
      register: interfaces_file

    - name: Assert interfaces file exists
      assert:
        that:
          - interfaces_file.stat.exists
        fail_msg: "Interfaces file not generated"

    - name: Test 3 - Full InSpec scan execution
      include_role:
        name: sybase_inspec
      vars:
        sybase_server: "{{ lookup('env', 'SYBASE_HOST') }}"
        sybase_port: 5000
        sybase_user: "{{ lookup('env', 'SYBASE_USER') }}"
        sybase_password: "{{ lookup('env', 'SYBASE_PASSWORD') }}"
        sybase_database: "master"
        sybase_version: "16"
        inspec_output_dir: "{{ test_results_dir }}"
      register: scan_result

    - name: Test 4 - Validate JSON output exists
      find:
        paths: "{{ test_results_dir }}"
        patterns: "SYBASE_NIST_*.json"
      register: json_files

    - name: Assert JSON output created
      assert:
        that:
          - json_files.matched > 0
        fail_msg: "JSON output file not created"

    - name: Test 5 - Validate JSON structure
      shell: |
        jq -e '.platform.name == "sybase"' {{ json_files.files[0].path }}
      register: json_validation
      when: json_files.matched > 0

    - name: Test 6 - Summary report exists
      find:
        paths: "{{ test_results_dir }}"
        patterns: "*_summary.txt"
      register: summary_files

    - name: Assert summary report created
      assert:
        that:
          - summary_files.matched > 0
        fail_msg: "Summary report not created"
```

#### 8.2.5 Client Type Tests

**File:** `tests/integration/test_sybase_clients.yml`

```yaml
---
# Test both SAP isql and FreeTDS tsql clients
- name: Sybase Client Type Tests
  hosts: localhost
  gather_facts: false
  vars:
    test_results_dir: "/tmp/sybase_client_tests"

  tasks:
    - name: Check for SAP isql
      command: which isql
      register: isql_check
      failed_when: false

    - name: Check for FreeTDS tsql
      command: which tsql
      register: tsql_check
      failed_when: false

    - name: Test with SAP isql (if available)
      include_role:
        name: sybase_inspec
      vars:
        sybase_server: "{{ lookup('env', 'SYBASE_HOST') }}"
        sybase_port: 5000
        sybase_user: "{{ lookup('env', 'SYBASE_USER') }}"
        sybase_password: "{{ lookup('env', 'SYBASE_PASSWORD') }}"
        sybase_version: "16"
        preferred_client: "isql"
        inspec_output_dir: "{{ test_results_dir }}/isql"
      when: isql_check.rc == 0
      register: isql_result

    - name: Test with FreeTDS tsql (if available)
      include_role:
        name: sybase_inspec
      vars:
        sybase_server: "{{ lookup('env', 'SYBASE_HOST') }}"
        sybase_port: 5000
        sybase_user: "{{ lookup('env', 'SYBASE_USER') }}"
        sybase_password: "{{ lookup('env', 'SYBASE_PASSWORD') }}"
        sybase_version: "16"
        preferred_client: "tsql"
        inspec_output_dir: "{{ test_results_dir }}/tsql"
      when: tsql_check.rc == 0
      register: tsql_result

    - name: Report client test results
      debug:
        msg: |
          SAP isql available: {{ 'YES' if isql_check.rc == 0 else 'NO' }}
          SAP isql test: {{ 'PASS' if isql_result is success else 'SKIP/FAIL' }}
          FreeTDS tsql available: {{ 'YES' if tsql_check.rc == 0 else 'NO' }}
          FreeTDS tsql test: {{ 'PASS' if tsql_result is success else 'SKIP/FAIL' }}
```

#### 8.2.6 SSH Tunnel Tests

**File:** `tests/integration/test_sybase_ssh_tunnel.yml`

```yaml
---
# Test SSH tunnel functionality
- name: Sybase SSH Tunnel Tests
  hosts: localhost
  gather_facts: false
  vars:
    test_results_dir: "/tmp/sybase_ssh_tests"
    # These would be set for actual SSH tunnel testing
    ssh_jump_host: "{{ lookup('env', 'SSH_JUMP_HOST') | default('skip', true) }}"

  tasks:
    - name: Skip if no SSH jump host configured
      meta: end_play
      when: ssh_jump_host == 'skip'

    - name: Test SSH tunnel setup
      include_role:
        name: sybase_inspec
        tasks_from: ssh_setup
      vars:
        use_ssh_tunnel: true
        ssh_tunnel_host: "{{ ssh_jump_host }}"
        ssh_tunnel_user: "{{ lookup('env', 'SSH_USER') }}"
        ssh_local_port: 15000
        sybase_server: "{{ lookup('env', 'SYBASE_HOST') }}"
        sybase_port: 5000
      register: tunnel_setup

    - name: Verify tunnel is listening
      wait_for:
        host: localhost
        port: 15000
        timeout: 10
      register: tunnel_port

    - name: Test database connectivity through tunnel
      include_role:
        name: sybase_inspec
        tasks_from: preflight
      vars:
        sybase_server: "localhost"
        sybase_port: 15000
        use_ssh_tunnel: true
      register: tunnel_connectivity

    - name: Report tunnel test results
      debug:
        msg: |
          Tunnel setup: {{ 'PASS' if tunnel_setup is success else 'FAIL' }}
          Tunnel port listening: {{ 'PASS' if tunnel_port is success else 'FAIL' }}
          DB connectivity via tunnel: {{ 'PASS' if tunnel_connectivity is success else 'FAIL' }}
```

### 8.3 Test Execution Workflow

```bash
# 1. Deploy Azure infrastructure
cd terraform && terraform apply -auto-approve

# 2. Export connection details
export SYBASE_HOST=$(terraform output -raw sybase_container_fqdn)
export SYBASE_PASSWORD=$(terraform output -raw sybase_sa_password)
export SYBASE_USER="sa"
export SYBASE_DATABASE="master"

# 3. Wait for Sybase to be ready (container startup)
echo "Waiting for Sybase to initialize..."
sleep 90

# 4. Run syntax validation
for ver in SYBASE15 SYBASE16; do
  inspec check roles/sybase_inspec/files/${ver}_ruby/
done

# 5. Run custom resource unit tests
cd tests
ruby -Ilib:test unit/sybase_session_local_test.rb

# 6. Run control unit tests
ruby -Ilib:test unit/sybase_controls_test.rb

# 7. Run integration tests
ansible-playbook integration/test_sybase_azure.yml

# 8. Test both client types (if available)
ansible-playbook integration/test_sybase_clients.yml

# 9. Run full compliance scan test
ansible-playbook ../test_playbooks/run_sybase_inspec.yml \
  -e "sybase_server=$SYBASE_HOST" \
  -e "sybase_user=$SYBASE_USER" \
  -e "sybase_password=$SYBASE_PASSWORD" \
  -e "sybase_version=16"

# 10. Validate results
ls -la /tmp/compliance_scans/SYBASE_*.json
jq '.statistics' /tmp/compliance_scans/SYBASE_*.json

# 11. Destroy Azure infrastructure (avoid costs)
cd ../terraform && terraform destroy -auto-approve
```

### 8.4 Test Matrix

| Test Type | Target | Client | Feature | Expected Result |
|-----------|--------|--------|---------|-----------------|
| Syntax | Local | N/A | Profile validation | Valid profile |
| Unit | Local | N/A | Custom resource | Client detection works |
| Unit | Local | N/A | Control metadata | NIST tags present |
| Integration | Azure Container | isql | Full scan | JSON + Summary |
| Integration | Azure Container | tsql | Full scan | JSON + Summary |
| Integration | Azure Container | auto | Client detection | Auto-selects available |
| SSH Tunnel | Jump Server | isql | Tunnel mode | Connectivity works |
| Failure | Invalid creds | isql | Auth failure | Graceful skip report |
| Failure | Wrong port | isql | Connection | Timeout + skip report |
| Version | Azure Container | isql | ASE 15 | Version-specific controls |
| Interfaces | Local | N/A | File generation | Valid interfaces format |
| Environment | Local | N/A | SYBASE.sh | Variables exported |

### 8.5 Acceptance Test Checklist

- [ ] `inspec check` passes for all version profiles (ASE 15, ASE 16)
- [ ] Custom `sybase_session_local` resource loads without errors
- [ ] Client auto-detection works (isql preferred, tsql fallback)
- [ ] SAP isql client execution works
- [ ] FreeTDS tsql client execution works
- [ ] Interfaces file auto-generation works
- [ ] SYBASE environment variables set correctly
- [ ] All controls have NIST tag metadata
- [ ] Preflight detects unreachable servers
- [ ] Preflight detects authentication failures
- [ ] SSH tunnel setup works (when configured)
- [ ] SSH tunnel connectivity validation works
- [ ] JSON output matches naming convention
- [ ] JSON contains valid InSpec structure
- [ ] Summary report generated on success
- [ ] Skip report generated on connection failure
- [ ] Controls execute without Ruby errors
- [ ] Query result parsing works for both clients
- [ ] Batch processing works with multiple targets
- [ ] Delegate host execution mode works
- [ ] Localhost execution mode works

---

## 9. Rollback Plan

If controls cause issues:
1. Revert to sample controls in `trusted.rb`
2. Use `skip_controls` variable to exclude problematic controls
3. Switch between isql and tsql clients
4. Disable SSH tunnel if network issues
5. Use basic interfaces file if auto-generation fails

---

*PRP Version: 1.1*
*Created: 2025-01-25*
*Updated: 2025-01-25 - Added Testing Requirements*
*Target Completion: POC Phase*
