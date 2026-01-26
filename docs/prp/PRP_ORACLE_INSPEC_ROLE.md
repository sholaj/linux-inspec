# PRP: Oracle InSpec Compliance Role

## Product Requirement Prompt/Plan

**Purpose:** Complete the Oracle InSpec scanning role to production-ready status with comprehensive NIST-mapped controls for Oracle 11g, 12c, 18c, and 19c.

---

## 1. Product Requirements

### 1.1 Business Context
- **Project:** Database Compliance Scanning Modernization
- **Phase:** POC → MVP transition
- **Scope:** Oracle database compliance scanning via AAP2 delegate host pattern
- **Target Users:** Security/Compliance teams, DBAs, Audit teams
- **Compliance Framework:** NIST SP 800-53, CIS Oracle Database Benchmarks

### 1.2 Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-01 | Execute InSpec controls against Oracle 11g/12c/18c/19c | MUST |
| FR-02 | Support instance-level configuration checks | MUST |
| FR-03 | Support database/schema-level security checks | MUST |
| FR-04 | Support Easy Connect and TNS naming methods | MUST |
| FR-05 | Pre-flight connectivity validation (port + auth) | MUST |
| FR-06 | Generate JSON results in standardized format | MUST |
| FR-07 | Generate human-readable summary reports | MUST |
| FR-08 | Support both SID and SERVICE_NAME connections | MUST |
| FR-09 | Support RAC-aware scanning | SHOULD |
| FR-10 | Optional Splunk HEC integration | SHOULD |

### 1.3 Control Categories Required

Based on CIS Oracle Database Benchmark and NIST SP 800-53 mapping:

| Category | Control Count | NIST Mapping |
|----------|---------------|--------------|
| Installation & Configuration | 8-12 | CM-6, SI-2 |
| User Account Management | 15-20 | AC-2, IA-2 |
| Privilege Management | 15-20 | AC-6, AC-3 |
| Auditing | 12-15 | AU-2, AU-3, AU-12 |
| Network Configuration | 5-8 | SC-7, SC-8 |
| Password Management | 8-12 | IA-5 |
| Encryption | 8-10 | SC-8, SC-28 |
| Listener Security | 5-8 | SC-7, AC-3 |

**Total Expected Controls:** 75-105 per version

### 1.4 Output Requirements

**File Naming Convention:**
```
ORACLE_NIST_{PID}_{SERVER}_{DATABASE}_{VERSION}_{TIMESTAMP}_{CONTROL}.json
```

**JSON Structure:**
```json
{
  "platform": { "name": "oracle", "release": "19c" },
  "profiles": [...],
  "statistics": { "duration": 0.0 },
  "version": "5.x"
}
```

---

## 2. Codebase Analysis

### 2.1 Existing Implementation

**Role Location:** `roles/oracle_inspec/`

**Structure (100% Complete):**
```
oracle_inspec/
├── tasks/
│   ├── main.yml           ✅ Entry point with preflight flow
│   ├── validate.yml       ✅ Parameter validation
│   ├── setup.yml          ✅ Directories and control file setup
│   ├── execute.yml        ✅ InSpec execution
│   ├── process_results.yml ✅ JSON result processing
│   ├── cleanup.yml        ✅ Report generation
│   ├── preflight.yml      ✅ Port + auth validation
│   └── splunk_integration.yml ✅ Splunk HEC forwarding
├── defaults/main.yml      ✅ Default variables
├── vars/main.yml          ✅ Oracle environment paths
├── templates/
│   ├── oracle_summary_report.j2 ✅ Text summary
│   └── skip_report.j2     ✅ Failed connection report
├── files/
│   ├── ORACLE11g_ruby/    ✅ 91 controls with NIST tags (traditional audit)
│   ├── ORACLE12c_ruby/    ✅ 91 controls with NIST tags (unified audit)
│   ├── ORACLE18c_ruby/    ✅ 91 controls with NIST tags (unified audit)
│   └── ORACLE19c_ruby/    ✅ 91 controls with NIST tags (unified audit)
└── README.md              ✅ Documentation with tnsnames guide
```

**Status: PHASE 1 COMPLETE** - InSpec controls implemented for all versions

### 2.2 Existing Control Sample (ORACLE19c)

**File:** `files/ORACLE19c_ruby/controls/trusted.rb`

```ruby
# Current controls (partial):
# oracle-19c-01: Audit trail enabled
# oracle-19c-02: Password verification function
# oracle-19c-03: Default users locked/removed
# oracle-19c-04: Remote login password file
# oracle-19c-05: SQL92 security enabled
# oracle-19c-06: PUBLIC privileges on dangerous packages
# oracle-19c-07: Default tablespace not SYSTEM
# oracle-19c-08: Password expiration configured
```

### 2.3 Key Variables

```yaml
# From defaults/main.yml
oracle_host: ""            # Target server hostname
oracle_port: 1521          # Oracle listener port
oracle_user: ""            # Database username
oracle_password: ""        # Database password
oracle_service: ""         # Service name or SID
oracle_version: "19c"      # Oracle version
connection_method: "easy_connect"  # or "tns"
oracle_home: "/u01/app/oracle/product/19c/dbhome_1"
inspec_output_dir: "/tmp/compliance_scans"
```

### 2.4 InSpec Resource Used

```ruby
oracledb_session(
  user: input('oracle_user'),
  password: input('oracle_password'),
  host: input('oracle_host'),
  port: input('oracle_port'),
  service: input('oracle_service')
)
```

---

## 3. Execution Tasks

### Phase 1: Complete InSpec Controls

#### Task 1.1: ORACLE 19c Controls (Full Set)

**File:** `files/ORACLE19c_ruby/controls/trusted.rb`

**Controls to Implement:**

```ruby
# Installation & Configuration (1.xx series)
control 'oracle-19c-1.01' # Latest Critical Patch Applied
control 'oracle-19c-1.02' # Default Listener Port Changed
control 'oracle-19c-1.03' # Database Version Supported
control 'oracle-19c-1.04' # ORACLE_HOME Permissions
control 'oracle-19c-1.05' # Audit File Destination Set
control 'oracle-19c-1.06' # Control File Protection
control 'oracle-19c-1.07' # Redo Log Protection
control 'oracle-19c-1.08' # SPFILE in Use

# User Account Management (2.xx series)
control 'oracle-19c-2.01' # Default Users Locked
control 'oracle-19c-2.02' # Default Passwords Changed
control 'oracle-19c-2.03' # SYS Password Secure
control 'oracle-19c-2.04' # SYSTEM Password Secure
control 'oracle-19c-2.05' # DBSNMP Account Locked
control 'oracle-19c-2.06' # Sample Schema Users Removed
control 'oracle-19c-2.07' # Proxy User Authentication
control 'oracle-19c-2.08' # External User Authentication
control 'oracle-19c-2.09' # OS Authentication Disabled
control 'oracle-19c-2.10' # Password File Protection
control 'oracle-19c-2.11' # REMOTE_LOGIN_PASSWORDFILE
control 'oracle-19c-2.12' # Failed Login Attempts Tracked
control 'oracle-19c-2.13' # Inactive Accounts Locked
control 'oracle-19c-2.14' # Service Account Restrictions

# Privilege Management (3.xx series)
control 'oracle-19c-3.01' # PUBLIC Execute on UTL_FILE Revoked
control 'oracle-19c-3.02' # PUBLIC Execute on UTL_HTTP Revoked
control 'oracle-19c-3.03' # PUBLIC Execute on UTL_TCP Revoked
control 'oracle-19c-3.04' # PUBLIC Execute on UTL_SMTP Revoked
control 'oracle-19c-3.05' # PUBLIC Execute on DBMS_RANDOM Revoked
control 'oracle-19c-3.06' # PUBLIC Execute on DBMS_LOB Revoked
control 'oracle-19c-3.07' # PUBLIC Execute on DBMS_SQL Revoked
control 'oracle-19c-3.08' # PUBLIC Execute on DBMS_XMLGEN Revoked
control 'oracle-19c-3.09' # DBA Role Membership Limited
control 'oracle-19c-3.10' # SYSDBA Privilege Restricted
control 'oracle-19c-3.11' # SYSOPER Privilege Restricted
control 'oracle-19c-3.12' # ANY Privileges Restricted
control 'oracle-19c-3.13' # Direct Table Grants Limited
control 'oracle-19c-3.14' # WITH ADMIN OPTION Limited
control 'oracle-19c-3.15' # WITH GRANT OPTION Limited

# Auditing (4.xx series)
control 'oracle-19c-4.01' # Unified Audit Enabled
control 'oracle-19c-4.02' # AUDIT_TRAIL Parameter Set
control 'oracle-19c-4.03' # Successful Logins Audited
control 'oracle-19c-4.04' # Failed Logins Audited
control 'oracle-19c-4.05' # DDL Statements Audited
control 'oracle-19c-4.06' # DML on Sensitive Tables Audited
control 'oracle-19c-4.07' # GRANT/REVOKE Audited
control 'oracle-19c-4.08' # Role Changes Audited
control 'oracle-19c-4.09' # User Management Audited
control 'oracle-19c-4.10' # Audit Trail Protected
control 'oracle-19c-4.11' # Audit Policies Applied
control 'oracle-19c-4.12' # FGA Policies Configured

# Network Configuration (5.xx series)
control 'oracle-19c-5.01' # Listener Password Set
control 'oracle-19c-5.02' # Listener Logging Enabled
control 'oracle-19c-5.03' # External Procedure Restricted
control 'oracle-19c-5.04' # Valid Node Checking Enabled
control 'oracle-19c-5.05' # TCP Valid Nodes Configured
control 'oracle-19c-5.06' # Admin Restrictions Enabled

# Password Management (6.xx series)
control 'oracle-19c-6.01' # Password Verification Function
control 'oracle-19c-6.02' # Password Complexity Enforced
control 'oracle-19c-6.03' # Password Minimum Length
control 'oracle-19c-6.04' # Password Expiration Set
control 'oracle-19c-6.05' # Password Reuse Limited
control 'oracle-19c-6.06' # Password Lock Time Set
control 'oracle-19c-6.07' # Password Grace Time Set
control 'oracle-19c-6.08' # Password Life Time Set

# Encryption (7.xx series)
control 'oracle-19c-7.01' # TDE Tablespace Encryption
control 'oracle-19c-7.02' # Network Encryption Enabled
control 'oracle-19c-7.03' # SQLNET Encryption Server
control 'oracle-19c-7.04' # SQLNET Checksum Server
control 'oracle-19c-7.05' # Wallet Protection
control 'oracle-19c-7.06' # HSM Integration (if applicable)
control 'oracle-19c-7.07' # Backup Encryption
```

#### Task 1.2: Version-Specific Controls

Copy and adapt controls for:
- `files/ORACLE11g_ruby/controls/trusted.rb`
- `files/ORACLE12c_ruby/controls/trusted.rb`
- `files/ORACLE18c_ruby/controls/trusted.rb`

**Version Differences to Handle:**
| Feature | 11g | 12c | 18c | 19c |
|---------|-----|-----|-----|-----|
| Unified Audit | No | Yes | Yes | Yes |
| Data Redaction | No | Yes | Yes | Yes |
| Privilege Analysis | No | Yes | Yes | Yes |
| Gradual Password Rollover | No | No | No | Yes |
| Automatic Indexing | No | No | No | Yes |
| Container Database | No | Yes | Yes | Yes |

### Phase 2: Role Enhancements

#### Task 2.1: Add PDB Support (12c+)

**File:** `defaults/main.yml`

```yaml
# Container database support
container_type: "standalone"  # standalone, cdb, pdb
pdb_name: ""                  # For PDB-specific scanning
include_pdb_scan: false       # Scan all PDBs in CDB
```

**File:** `tasks/setup.yml`

```yaml
- name: Discover PDBs in Container Database
  shell: |
    sqlplus -S {{ oracle_user }}/{{ oracle_password }}@{{ oracle_host }}:{{ oracle_port }}/{{ oracle_service }} <<EOF
    SET HEADING OFF FEEDBACK OFF
    SELECT pdb_name FROM cdb_pdbs WHERE status = 'NORMAL';
    EOF
  register: pdb_list
  when:
    - oracle_version in ['12c', '18c', '19c']
    - include_pdb_scan | bool
```

#### Task 2.2: Add TNS Support Enhancement

**File:** `templates/tnsnames.ora.j2`

```
{{ oracle_service }} =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = {{ oracle_host }})(PORT = {{ oracle_port }}))
    (CONNECT_DATA =
      {% if connection_type == 'service_name' %}
      (SERVICE_NAME = {{ oracle_service }})
      {% else %}
      (SID = {{ oracle_service }})
      {% endif %}
    )
  )
```

### Phase 3: Testing & Validation

#### Task 3.1: Create Test Inventory

**File:** `tests/inventory/oracle_test.yml`

```yaml
oracle_databases:
  hosts:
    test_oracle_19c:
      oracle_host: "[DB_SERVER]"
      oracle_port: 1521
      oracle_service: "ORCL"
      oracle_version: "19c"
      oracle_user: "{{ vault_oracle_user }}"
      oracle_password: "{{ vault_oracle_password }}"
      connection_method: "easy_connect"
```

#### Task 3.2: Validate All Controls Execute

```bash
# Test execution
ansible-playbook test_playbooks/run_oracle_inspec.yml \
  -i tests/inventory/oracle_test.yml \
  -e @vault.yml \
  --check
```

---

## 4. Acceptance Criteria

- [ ] All 65+ controls implemented for Oracle 19c
- [ ] Controls adapted for 11g, 12c, 18c versions
- [ ] Each control has NIST mapping in metadata
- [ ] Both Easy Connect and TNS methods work
- [ ] CDB/PDB support for 12c+ versions
- [ ] JSON output matches required format
- [ ] Summary report generated successfully
- [ ] No sensitive data in control files
- [ ] README updated with control inventory

---

## 5. Implementation Notes

### 5.1 InSpec Control Template

```ruby
control 'oracle-19c-X.XX' do
  impact 1.0
  title 'Descriptive Title'
  desc 'Full description of what this control checks'

  tag nist: ['XX-X', 'XX-X(x)']
  tag cis: 'X.X.X'
  tag severity: 'high'

  sql = oracledb_session(
    user: input('oracle_user'),
    password: input('oracle_password'),
    host: input('oracle_host'),
    port: input('oracle_port'),
    service: input('oracle_service')
  )

  describe sql.query("SELECT ... FROM ...").row(0).column('VALUE') do
    it { should cmp 'expected_value' }
  end
end
```

### 5.2 Common Queries Reference

```sql
-- Database Parameters
SELECT name, value FROM v$parameter WHERE name = 'xxx';

-- Audit Settings
SELECT policy_name, enabled_opt FROM audit_unified_enabled_policies;

-- User Status
SELECT username, account_status FROM dba_users;

-- Privilege Checks
SELECT grantee, privilege FROM dba_sys_privs WHERE grantee = 'PUBLIC';

-- Password Profile
SELECT profile, resource_name, limit FROM dba_profiles;

-- Encryption Status
SELECT tablespace_name, encrypted FROM dba_tablespaces;
```

### 5.3 Data Sensitivity Reminder

**DO NOT include in controls:**
- Real server names
- Actual credentials
- Production database names
- IP addresses
- TNS entries with real hosts

**USE placeholders:**
- `input('oracle_host')`
- `input('oracle_user')`
- `[DB_SERVER]` in documentation

---

## 6. Dependencies

- InSpec 5.x with `oracledb_session` resource
- Oracle Instant Client or full client on delegate host
- `sqlplus` binary in PATH
- Network connectivity to Oracle listener port (default 1521)
- Service account with DBA or SELECT ANY DICTIONARY privilege

---

## 7. Oracle Version Notes

### 11g Specific
- Traditional audit only (no unified audit)
- Use `AUDIT_TRAIL` parameter
- `dba_audit_trail` for audit records

### 12c+ Specific
- Unified audit available
- Container database support
- Use `audit_unified_policies` views
- PDB-specific scanning option

### 19c Specific
- Gradual password rollover
- Automatic indexing
- Enhanced unified audit
- Quarantine for SQL statements

---

## 8. Testing Requirements

### 8.1 Azure Test Infrastructure

**All changes MUST be tested in Azure before merging.** Use the Terraform templates in `terraform/` directory.

```bash
# Deploy Oracle test infrastructure
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Terraform provisions:
# - oracle-container.tf: Oracle XE container (Azure Container Instance)
```

**Test Environment Variables (from Terraform outputs):**

```bash
export ORACLE_HOST=$(terraform output -raw oracle_container_fqdn)
export ORACLE_PORT=1521
export ORACLE_SERVICE="XEPDB1"
export ORACLE_USER="system"
export ORACLE_PASSWORD=$(terraform output -raw oracle_system_password)
```

### 8.2 Test Categories

#### 8.2.1 InSpec Profile Syntax Validation

```bash
# Validate InSpec profile syntax (no connectivity required)
cd roles/oracle_inspec/files/ORACLE19c_ruby
inspec check .

# Expected output: "Valid profile"

# Validate all versions
for ver in ORACLE11g ORACLE12c ORACLE18c ORACLE19c; do
  echo "Checking $ver..."
  inspec check roles/oracle_inspec/files/${ver}_ruby/
done
```

#### 8.2.2 Unit Tests - Control Logic

**File:** `tests/unit/oracle_controls_test.rb`

```ruby
# Test control metadata
describe 'Oracle 19c Controls' do
  let(:profile) { Inspec::Profile.for_target('roles/oracle_inspec/files/ORACLE19c_ruby') }

  it 'should have valid control IDs' do
    profile.controls.each do |control|
      expect(control.id).to match(/^oracle-19c-\d+\.\d+$/)
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

  it 'should have descriptions' do
    profile.controls.each do |control|
      expect(control.desc).not_to be_empty
    end
  end
end
```

#### 8.2.3 Integration Tests - Azure Container

**File:** `tests/integration/test_oracle_azure.yml`

```yaml
---
# Integration test playbook for Oracle against Azure container
- name: Oracle Integration Tests
  hosts: localhost
  gather_facts: false
  vars:
    test_results_dir: "/tmp/oracle_integration_tests"

  tasks:
    - name: Create test results directory
      file:
        path: "{{ test_results_dir }}"
        state: directory

    - name: Test 1 - Preflight connectivity check (Easy Connect)
      include_role:
        name: oracle_inspec
        tasks_from: preflight
      vars:
        oracle_host: "{{ lookup('env', 'ORACLE_HOST') }}"
        oracle_port: 1521
        oracle_service: "{{ lookup('env', 'ORACLE_SERVICE') }}"
        oracle_user: "{{ lookup('env', 'ORACLE_USER') }}"
        oracle_password: "{{ lookup('env', 'ORACLE_PASSWORD') }}"
        connection_method: "easy_connect"
      register: preflight_result

    - name: Assert preflight passed
      assert:
        that:
          - preflight_result is success
        fail_msg: "Preflight connectivity check failed"

    - name: Test 2 - Full InSpec scan execution
      include_role:
        name: oracle_inspec
      vars:
        oracle_host: "{{ lookup('env', 'ORACLE_HOST') }}"
        oracle_port: 1521
        oracle_service: "{{ lookup('env', 'ORACLE_SERVICE') }}"
        oracle_user: "{{ lookup('env', 'ORACLE_USER') }}"
        oracle_password: "{{ lookup('env', 'ORACLE_PASSWORD') }}"
        oracle_version: "19c"
        connection_method: "easy_connect"
        inspec_output_dir: "{{ test_results_dir }}"
      register: scan_result

    - name: Test 3 - Validate JSON output exists
      find:
        paths: "{{ test_results_dir }}"
        patterns: "ORACLE_NIST_*.json"
      register: json_files

    - name: Assert JSON output created
      assert:
        that:
          - json_files.matched > 0
        fail_msg: "JSON output file not created"

    - name: Test 4 - Validate JSON structure
      shell: |
        jq -e '.platform.name == "oracle"' {{ json_files.files[0].path }}
      register: json_validation
      when: json_files.matched > 0

    - name: Test 5 - Summary report exists
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

#### 8.2.4 Connection Method Tests

**File:** `tests/integration/test_oracle_connection_methods.yml`

```yaml
---
# Test both Easy Connect and TNS connection methods
- name: Oracle Connection Method Tests
  hosts: localhost
  gather_facts: false

  tasks:
    - name: Test Easy Connect method
      include_role:
        name: oracle_inspec
        tasks_from: preflight
      vars:
        oracle_host: "{{ lookup('env', 'ORACLE_HOST') }}"
        oracle_port: 1521
        oracle_service: "{{ lookup('env', 'ORACLE_SERVICE') }}"
        connection_method: "easy_connect"
      register: easy_connect_result

    - name: Test TNS method (requires tnsnames.ora)
      include_role:
        name: oracle_inspec
        tasks_from: preflight
      vars:
        oracle_host: "{{ lookup('env', 'ORACLE_HOST') }}"
        oracle_port: 1521
        oracle_service: "{{ lookup('env', 'ORACLE_SERVICE') }}"
        connection_method: "tns"
        tns_admin: "/tmp/tns_test"
      register: tns_result
      ignore_errors: true

    - name: Report connection method results
      debug:
        msg: |
          Easy Connect: {{ 'PASS' if easy_connect_result is success else 'FAIL' }}
          TNS Method: {{ 'PASS' if tns_result is success else 'FAIL/SKIP' }}
```

#### 8.2.5 PDB/CDB Tests (12c+)

**File:** `tests/integration/test_oracle_pdb.yml`

```yaml
---
# Test Container Database scanning (12c+)
- name: Oracle PDB/CDB Tests
  hosts: localhost
  gather_facts: false

  tasks:
    - name: Test CDB root scan
      include_role:
        name: oracle_inspec
      vars:
        oracle_version: "19c"
        container_type: "cdb"
        oracle_service: "XE"
      register: cdb_result

    - name: Test PDB scan
      include_role:
        name: oracle_inspec
      vars:
        oracle_version: "19c"
        container_type: "pdb"
        pdb_name: "XEPDB1"
      register: pdb_result
```

### 8.3 Test Execution Workflow

```bash
# 1. Deploy Azure infrastructure
cd terraform && terraform apply -auto-approve

# 2. Export connection details
export ORACLE_HOST=$(terraform output -raw oracle_container_fqdn)
export ORACLE_PASSWORD=$(terraform output -raw oracle_system_password)
export ORACLE_USER="system"
export ORACLE_SERVICE="XEPDB1"

# 3. Wait for Oracle to be ready (container startup)
echo "Waiting for Oracle to initialize..."
sleep 120

# 4. Run syntax validation
for ver in ORACLE11g ORACLE12c ORACLE18c ORACLE19c; do
  inspec check roles/oracle_inspec/files/${ver}_ruby/
done

# 5. Run unit tests
cd tests
ruby -Ilib:test unit/oracle_controls_test.rb

# 6. Run integration tests
ansible-playbook integration/test_oracle_azure.yml

# 7. Test connection methods
ansible-playbook integration/test_oracle_connection_methods.yml

# 8. Run full compliance scan test
ansible-playbook ../test_playbooks/run_oracle_inspec.yml \
  -e "oracle_host=$ORACLE_HOST" \
  -e "oracle_user=$ORACLE_USER" \
  -e "oracle_password=$ORACLE_PASSWORD" \
  -e "oracle_service=$ORACLE_SERVICE" \
  -e "oracle_version=19c"

# 9. Validate results
ls -la /tmp/compliance_scans/ORACLE_*.json
jq '.statistics' /tmp/compliance_scans/ORACLE_*.json

# 10. Destroy Azure infrastructure (avoid costs)
cd ../terraform && terraform destroy -auto-approve
```

### 8.4 Test Matrix

| Test Type | Target | Version | Connection | Expected Result |
|-----------|--------|---------|------------|-----------------|
| Syntax | Local | All | N/A | Valid profile |
| Unit | Local | 19c | N/A | NIST tags present |
| Integration | Azure Container | 19c | Easy Connect | JSON + Summary |
| Integration | Azure Container | 19c | TNS | JSON + Summary |
| CDB/PDB | Azure Container | 19c | Easy Connect | Both scan types work |
| Failure | Invalid creds | 19c | Easy Connect | Graceful skip report |
| Failure | Wrong service | 19c | Easy Connect | ORA-12514 handled |
| Version | Azure Container | 12c | Easy Connect | Unified audit controls |
| Version | Azure Container | 11g | Easy Connect | Traditional audit only |

### 8.5 Acceptance Test Checklist

- [ ] `inspec check` passes for all version profiles (11g, 12c, 18c, 19c)
- [ ] All controls have NIST tag metadata
- [ ] Easy Connect method works
- [ ] TNS naming method works
- [ ] Preflight detects unreachable listeners
- [ ] Preflight detects authentication failures (ORA-01017)
- [ ] Preflight detects invalid service name (ORA-12514)
- [ ] JSON output matches naming convention
- [ ] JSON contains valid InSpec structure
- [ ] Summary report generated on success
- [ ] Skip report generated on connection failure
- [ ] Controls execute without Ruby errors
- [ ] Version-specific controls work (unified audit for 12c+)
- [ ] CDB scanning works (12c+)
- [ ] PDB scanning works (12c+)
- [ ] Batch processing works with multiple targets
- [ ] Delegate host execution mode works
- [ ] Localhost execution mode works

---

## 9. Rollback Plan

If controls cause issues:
1. Revert to sample controls in `trusted.rb`
2. Use `skip_controls` variable to exclude problematic controls
3. Tag-based filtering to run subset of controls
4. Fall back to Easy Connect if TNS issues

---

*PRP Version: 1.2*
*Created: 2025-01-25*
*Updated: 2026-01-25 - Phase 1 Complete (InSpec controls implemented)*
*Status: PHASE 1 COMPLETE*

## Implementation Summary

| Version | Controls | NIST Tags | Audit Type |
|---------|----------|-----------|------------|
| Oracle 11g | 91 | 91 | Traditional |
| Oracle 12c | 91 | 91 | Unified |
| Oracle 18c | 91 | 91 | Unified |
| Oracle 19c | 91 | 91 | Unified |

**Total: 364 controls across all versions**
