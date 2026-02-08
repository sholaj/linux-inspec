# PRP: MSSQL InSpec Role - WinRM Enhancement & Large-Scale Scanning

> **STATUS: COMPLETED** | Closed: 2026-02-08
>
> WinRM mode integrated into main MSSQL role. Supports dual-mode execution
> (direct sqlcmd and WinRM), preflight checks, and batch error handling.

## Product Requirement Prompt/Plan

**Purpose:** Enhance the existing `mssql_inspec` role to support WinRM-based connectivity for Windows SQL Server scanning, with improvements for large-scale scanning across hundreds of servers.

---

## 1. Product Requirements

### 1.1 Business Context
- **Project:** Database Compliance Scanning Modernization
- **Phase:** POC Enhancement
- **Scope:** Add WinRM transport support to existing MSSQL InSpec role
- **Target Users:** Security/Compliance teams, DBAs, Audit teams
- **Scale:** ~100+ MSSQL servers across multiple affiliates

### 1.2 Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-01 | Conditional WinRM execution based on `use_winrm` variable | MUST |
| FR-02 | Accept WinRM credentials (username/password) as variables | MUST |
| FR-03 | Maintain existing direct connection mode (no regression) | MUST |
| FR-04 | Support batch processing for 100+ servers | MUST |
| FR-05 | Parallel execution with configurable concurrency | SHOULD |
| FR-06 | Comprehensive error handling for WinRM failures | MUST |
| FR-07 | Structured logging for troubleshooting | MUST |
| FR-08 | Idempotent execution (same results on re-run) | MUST |
| FR-09 | Minimize performance overhead | SHOULD |
| FR-10 | Support WinRM SSL (port 5986) option | SHOULD |

### 1.3 Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-01 | Scan 100 servers | < 2 hours with parallelism |
| NFR-02 | Single server scan | < 5 minutes |
| NFR-03 | Memory footprint per scan | < 500MB |
| NFR-04 | Error recovery | Continue on individual failure |
| NFR-05 | Logging verbosity | Configurable (debug/normal) |

---

## 2. Current State Analysis

### 2.1 Existing Implementation

**Role Location:** `roles/mssql_inspec/`

**Current Architecture:**
```
┌─────────────────────┐
│   Ansible Control   │
│   Node / AAP2       │
└──────────┬──────────┘
           │ SSH
           ▼
┌─────────────────────┐
│   Delegate Host     │
│   (Linux Runner)    │
│   - InSpec          │
│   - sqlcmd          │
└──────────┬──────────┘
           │ TDS Protocol (1433)
           ▼
┌─────────────────────┐
│   MSSQL Server      │
│   (Linux Container) │
└─────────────────────┘
```

**Current Flow:**
1. `main.yml` - Determines execution mode (localhost/delegate)
2. `validate.yml` - Validates MSSQL connection parameters
3. `preflight.yml` - Tests TCP port + auth connectivity
4. `setup.yml` - Creates directories, copies control files
5. `execute.yml` - Runs InSpec profile via `sqlcmd`
6. `process_results.yml` - Saves JSON results
7. `cleanup.yml` - Generates summary report

### 2.2 WinRM POC Implementation

**Existing WinRM Files:**
- `docs/WINRM_PREREQUISITES.md` - Setup documentation
- `test_playbooks/run_mssql_inspec_winrm.yml` - Standalone WinRM playbook

**WinRM Architecture (from POC):**
```
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│   Delegate Host     │     │    Windows VM       │     │   SQL Server        │
│   (Linux Runner)    │────▶│    (WinRM 5985)     │────▶│   (localhost:1433)  │
│   - InSpec          │     │                     │     │                     │
│   - train-winrm     │     │    mssql_session    │     │                     │
└─────────────────────┘     └─────────────────────┘     └─────────────────────┘
```

### 2.3 InSpec Profile Input Mismatch (CRITICAL)

**Current Profile Inputs** (`MSSQL2019_ruby/inspec.yml`):
```yaml
inputs:
  - name: usernm          # SQL username
  - name: passwd          # SQL password
  - name: hostnm          # SQL Server host (for direct: remote IP, for WinRM: localhost)
  - name: port            # SQL port (1433)
  - name: servicenm       # Named instance
```

**WinRM Playbook Environment Variables** (`run_mssql_inspec_winrm.yml`):
```bash
export MSSQL_HOST="{{ mssql_server }}"
export MSSQL_USER="{{ mssql_username }}"
export MSSQL_PASS="{{ mssql_password }}"
export MSSQL_PORT="{{ mssql_port }}"
export MSSQL_DB="{{ mssql_database }}"
```

**Problem:** Input names don't match. The WinRM playbook sets environment variables that the current profile doesn't read.

**Connection Context Difference:**

| Mode | InSpec Runs On | mssql_session Connects To | hostnm Value |
|------|----------------|---------------------------|--------------|
| Direct | Delegate Host (Linux) | Remote SQL Server | `10.0.2.4` (remote IP) |
| WinRM | Windows Target (via WinRM) | localhost | `localhost` or `.` |

### 2.4 Gap Analysis

| Feature | Current Role | WinRM POC | Target State |
|---------|--------------|-----------|--------------|
| Direct sqlcmd | ✅ | ❌ | ✅ (preserve) |
| WinRM transport | ❌ | ✅ (playbook) | ✅ (integrated) |
| Conditional mode | ❌ | Manual skip | ✅ (use_winrm var) |
| Batch processing | ❌ | ❌ | ✅ (serial/parallel) |
| Parallel execution | ❌ | ❌ | ✅ (configurable) |
| Error aggregation | Partial | ❌ | ✅ (full) |
| Preflight for WinRM | ❌ | Manual detect | ✅ (integrated) |
| **Unified profile inputs** | ❌ | ❌ | ✅ (dual-mode) |
| **WinRM profile exists** | ❌ | ❌ | ✅ (create) |

---

## 3. Target Architecture

### 3.1 Enhanced Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Ansible Control / AAP2                          │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │ mssql_inspec Role                                          │     │
│  │                                                            │     │
│  │  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐ │     │
│  │  │  Validation  │───▶│  Preflight   │───▶│   Execute    │ │     │
│  │  │              │    │  (mode-aware)│    │  (mode-aware)│ │     │
│  │  └──────────────┘    └──────────────┘    └──────────────┘ │     │
│  │                                                            │     │
│  │  Mode Detection: use_winrm ? WinRM_PATH : DIRECT_PATH      │     │
│  └────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
                    │                           │
    ┌───────────────┴───────────────┐           │
    │                               │           │
    ▼ use_winrm: false              ▼ use_winrm: true
┌─────────────────────┐     ┌─────────────────────────────────────────┐
│   Direct Mode       │     │   WinRM Mode                            │
│   (TDS 1433)        │     │                                         │
│                     │     │   Delegate ──WinRM 5985──▶ Windows VM   │
│   Delegate ─────────┼────▶│   Windows VM ──ADO.NET──▶ SQL Server    │
│        │            │     │                                         │
│        │ sqlcmd     │     │   Uses: mssql_session resource          │
│        ▼            │     │   Transport: train-winrm                │
│   SQL Server        │     └─────────────────────────────────────────┘
└─────────────────────┘
```

### 3.2 Variable Structure

```yaml
# Connection Mode Selection
use_winrm: false                    # NEW: Toggle WinRM mode

# Existing MSSQL Variables (unchanged)
mssql_server: ""                    # For direct mode: server IP
                                    # For WinRM mode: typically "localhost"
mssql_port: 1433
mssql_database: "master"
mssql_username: ""                  # SQL authentication
mssql_password: ""

# NEW: WinRM Connection Variables (only when use_winrm: true)
winrm_host: ""                      # Windows VM IP/hostname
winrm_port: 5985                    # WinRM HTTP port (or 5986 for HTTPS)
winrm_username: ""                  # Windows admin user
winrm_password: ""                  # Windows admin password
winrm_ssl: false                    # Use HTTPS (5986)
winrm_ssl_verify: true              # Verify SSL certificate
winrm_timeout: 60                   # Connection timeout (seconds)

# NEW: Batch Processing Variables
batch_size: 10                      # Hosts per batch (0 = all at once)
batch_delay: 5                      # Seconds between batches
parallel_scans: 5                   # Concurrent scans (forks)
scan_timeout: 300                   # Per-host timeout (seconds)

# NEW: Error Handling Variables
continue_on_winrm_failure: true     # Continue if WinRM connection fails
max_retry_attempts: 2               # Retry failed WinRM connections
retry_delay: 10                     # Seconds between retries
aggregate_errors: true              # Collect all errors for final report
```

---

## 4. Implementation Plan

### Phase 1: Core WinRM Integration (MUST)

#### Task 1.1: Update defaults/main.yml

**File:** `roles/mssql_inspec/defaults/main.yml`

```yaml
# Add to existing defaults

# ======================
# Connection Mode
# ======================
# When true, use WinRM transport to Windows VM
# When false, use direct TDS connection via sqlcmd
use_winrm: false

# ======================
# WinRM Configuration
# ======================
# Only used when use_winrm: true
winrm_host: ""
winrm_port: 5985
winrm_username: ""
winrm_password: ""
winrm_ssl: false
winrm_ssl_verify: true
winrm_timeout: 60

# ======================
# Batch Processing
# ======================
batch_size: 0                       # 0 = no batching
batch_delay: 5
scan_timeout: 300

# ======================
# Error Handling
# ======================
continue_on_winrm_failure: true
max_retry_attempts: 2
retry_delay: 10
```

#### Task 1.2: Create WinRM Preflight Task

**File:** `roles/mssql_inspec/tasks/preflight_winrm.yml`

```yaml
---
# WinRM-specific preflight checks
# Called from preflight.yml when use_winrm is true

- name: "[WinRM Preflight] Verify train-winrm gem installed"
  shell: gem list train-winrm | grep -q train-winrm
  args:
    executable: /bin/bash
  register: _winrm_gem_check
  changed_when: false
  failed_when: false
  delegate_to: "{{ _delegate_host }}"

- name: "[WinRM Preflight] Fail if train-winrm not installed"
  fail:
    msg: |
      train-winrm gem is not installed on {{ _delegate_host }}.
      Install with: gem install train-winrm --no-document
  when: _winrm_gem_check.rc != 0

- name: "[WinRM Preflight] Test WinRM connectivity"
  shell: |
    inspec detect \
      -t winrm://{{ winrm_username }}@{{ winrm_host }}:{{ winrm_port }} \
      --password '{{ winrm_password }}' \
      --ssl={{ winrm_ssl | lower }} \
      --self-signed={{ (not winrm_ssl_verify) | lower }}
  args:
    executable: /bin/bash
  register: _winrm_detect
  changed_when: false
  failed_when: false
  delegate_to: "{{ _delegate_host }}"
  no_log: true
  timeout: "{{ winrm_timeout }}"

- name: "[WinRM Preflight] Set preflight results"
  set_fact:
    preflight_passed: "{{ _winrm_detect.rc == 0 }}"
    preflight_skip_reason: "{{ 'WinRM connection failed: ' + (_winrm_detect.stderr | default('Unknown error')) if _winrm_detect.rc != 0 else '' }}"
    preflight_error_code: "{{ 'WINRM_CONNECTION_FAILED' if _winrm_detect.rc != 0 else '' }}"
    winrm_platform_detected: "{{ _winrm_detect.stdout | default('') }}"

- name: "[WinRM Preflight] Display WinRM detection"
  debug:
    msg: |
      WinRM Detection Result:
      {{ winrm_platform_detected }}
  when: preflight_passed and inspec_debug_mode | default(false)
```

#### Task 1.3: Update preflight.yml with Mode Detection

**File:** `roles/mssql_inspec/tasks/preflight.yml` (modify existing)

Add mode detection at the beginning:

```yaml
---
# Pre-flight connectivity checks
# Supports both direct (sqlcmd) and WinRM modes

# Determine connection mode
- name: "[Preflight] Determine connection mode"
  set_fact:
    _connection_mode: "{{ 'winrm' if (use_winrm | default(false) | bool) else 'direct' }}"

- name: "[Preflight] Display connection mode"
  debug:
    msg: "Connection mode: {{ _connection_mode | upper }}"
  when: inspec_debug_mode | default(false)

# Route to appropriate preflight based on mode
- name: "[Preflight] Run WinRM preflight checks"
  include_tasks: preflight_winrm.yml
  when: _connection_mode == 'winrm'

- name: "[Preflight] Run direct connection preflight checks"
  include_tasks: preflight_direct.yml
  when: _connection_mode == 'direct'
```

#### Task 1.4: Rename Existing Preflight to preflight_direct.yml

Move current preflight logic to `tasks/preflight_direct.yml`:
- TCP port check via `wait_for`
- sqlcmd authentication test
- Existing error code mapping

#### Task 1.5: Create WinRM Execute Task

**File:** `roles/mssql_inspec/tasks/execute_winrm.yml`

```yaml
---
# WinRM-based InSpec execution
# Called from execute.yml when use_winrm is true

- name: "[WinRM Execute] Verify InSpec binary"
  shell: command -v inspec
  args:
    executable: /bin/bash
  register: _inspec_check
  changed_when: false
  failed_when: _inspec_check.rc != 0
  delegate_to: "{{ _delegate_host }}"

- name: "[WinRM Execute] Build WinRM InSpec command"
  set_fact:
    _winrm_inspec_cmd: |
      export CHEF_LICENSE=accept
      export MSSQL_HOST="{{ mssql_server }}"
      export MSSQL_PORT="{{ mssql_port }}"
      export MSSQL_USER="{{ mssql_username }}"
      export MSSQL_PASS="{{ mssql_password }}"
      export MSSQL_DB="{{ mssql_database }}"

      inspec exec "{{ _remote_controls_path }}" \
        -t winrm://{{ winrm_username }}@{{ winrm_host }}:{{ winrm_port }} \
        --password '{{ winrm_password }}' \
        --ssl={{ winrm_ssl | lower }} \
        --self-signed={{ (not winrm_ssl_verify) | lower }} \
        --reporter=json-min \
        --no-color \
        --chef-license=accept

- name: "[WinRM Execute] Run InSpec via WinRM"
  shell: "{{ _winrm_inspec_cmd }}"
  args:
    executable: /bin/bash
  register: _inspec_profile_result
  changed_when: false
  failed_when: _inspec_profile_result.rc not in [0, 100, 101]
  delegate_to: "{{ _delegate_host }}"
  timeout: "{{ scan_timeout | default(300) }}"
  no_log: true

- name: "[WinRM Execute] Wrap InSpec result for processing"
  set_fact:
    inspec_results:
      results:
        - stdout: "{{ _inspec_profile_result.stdout }}"
          rc: "{{ _inspec_profile_result.rc }}"
          item:
            path: "{{ _remote_controls_path }}"
            connection_mode: "winrm"
            winrm_host: "{{ winrm_host }}"
```

#### Task 1.6: Update execute.yml with Mode Routing

**File:** `roles/mssql_inspec/tasks/execute.yml` (modify existing)

```yaml
---
# InSpec execution - routes to appropriate mode

- name: "[Execute] Determine connection mode"
  set_fact:
    _connection_mode: "{{ 'winrm' if (use_winrm | default(false) | bool) else 'direct' }}"

- name: "[Execute] Run WinRM-based execution"
  include_tasks: execute_winrm.yml
  when: _connection_mode == 'winrm'

- name: "[Execute] Run direct execution"
  include_tasks: execute_direct.yml
  when: _connection_mode == 'direct'

# Common post-execution tasks
- name: "[Execute] Parse InSpec results"
  set_fact:
    _parsed_results: "{{ _parsed_results | default([]) + [item.stdout if item.stdout is mapping else (item.stdout | from_json)] }}"
  loop: "{{ inspec_results.results | default([]) }}"
  loop_control:
    label: "{{ item.item.path | basename }}"
  when: item.stdout is defined and item.stdout != ''
  no_log: true

# Display summary (unchanged)
- name: "[Execute] Display scan summary"
  debug:
    msg: |
      ═══════════════════════════════════════════════════════════════════
       MSSQL InSpec Compliance Scan Results
       Database: {{ mssql_server }}:{{ mssql_port }}/{{ mssql_database }}
       Mode: {{ _connection_mode | upper }}
       {% if _connection_mode == 'winrm' %}WinRM Target: {{ winrm_host }}:{{ winrm_port }}{% endif %}
      ═══════════════════════════════════════════════════════════════════
      ...
```

#### Task 1.7: Rename Existing Execute Logic

Move current execute logic to `tasks/execute_direct.yml`:
- sqlcmd verification
- Direct InSpec execution
- Current result wrapping

### Phase 1B: InSpec Profile Dual-Mode Support (MUST)

#### Task 1B.1: Create Unified Input Schema

The InSpec profile must support both connection modes with a unified input interface.

**Option A: Environment Variable Fallback (Recommended)**

Update `files/MSSQL2019_ruby/inspec.yml`:

```yaml
name: mssql-2019-cis
title: CIS Microsoft SQL Server 2019 Benchmark
maintainer: InSpec Compliance Team
version: 1.1.0

inputs:
  # SQL Authentication - supports both naming conventions
  - name: mssql_user
    description: MSSQL username (alias: usernm)
    type: string
    value: ""
  - name: usernm
    description: MSSQL username (legacy, use mssql_user)
    type: string
    value: ""

  - name: mssql_password
    description: MSSQL password (alias: passwd)
    sensitive: true
    type: string
    value: ""
  - name: passwd
    description: MSSQL password (legacy, use mssql_password)
    sensitive: true
    type: string
    value: ""

  - name: mssql_host
    description: MSSQL host (alias: hostnm). For WinRM mode use 'localhost'
    type: string
    value: "localhost"
  - name: hostnm
    description: MSSQL host (legacy, use mssql_host)
    type: string
    value: ""

  - name: mssql_port
    description: MSSQL port (alias: port)
    type: numeric
    value: 1433
  - name: port
    description: MSSQL port (legacy, use mssql_port)
    type: numeric
    value: 1433

  - name: mssql_instance
    description: MSSQL named instance (alias: servicenm)
    type: string
    value: ""
  - name: servicenm
    description: MSSQL instance (legacy, use mssql_instance)
    type: string
    value: ""

  # Connection mode indicator
  - name: connection_mode
    description: Connection mode (direct or winrm)
    type: string
    value: "direct"
```

#### Task 1B.2: Create Helper Library for Input Resolution

**File:** `files/MSSQL2019_ruby/libraries/input_helper.rb`

```ruby
# Helper module to resolve inputs with fallback support
# Supports both legacy (usernm/passwd/hostnm) and new (mssql_*) naming

module MSSQLInputHelper
  def self.resolve_user(inspec_context)
    # Priority: mssql_user > usernm > ENV['MSSQL_USER']
    user = inspec_context.input('mssql_user', value: '')
    user = inspec_context.input('usernm', value: '') if user.to_s.empty?
    user = ENV['MSSQL_USER'] if user.to_s.empty?
    user
  end

  def self.resolve_password(inspec_context)
    pass = inspec_context.input('mssql_password', value: '')
    pass = inspec_context.input('passwd', value: '') if pass.to_s.empty?
    pass = ENV['MSSQL_PASS'] if pass.to_s.empty?
    pass
  end

  def self.resolve_host(inspec_context)
    host = inspec_context.input('mssql_host', value: '')
    host = inspec_context.input('hostnm', value: '') if host.to_s.empty?
    host = ENV['MSSQL_HOST'] if host.to_s.empty?
    host = 'localhost' if host.to_s.empty?
    host
  end

  def self.resolve_port(inspec_context)
    port = inspec_context.input('mssql_port', value: nil)
    port = inspec_context.input('port', value: nil) if port.nil?
    port = ENV['MSSQL_PORT']&.to_i if port.nil?
    port || 1433
  end

  def self.resolve_instance(inspec_context)
    instance = inspec_context.input('mssql_instance', value: '')
    instance = inspec_context.input('servicenm', value: '') if instance.to_s.empty?
    instance
  end
end
```

#### Task 1B.3: Update Controls to Use Helper

**File:** `files/MSSQL2019_ruby/controls/trusted.rb`

```ruby
# MSSQL 2019 InSpec Control - trusted.rb
# Supports both direct and WinRM connection modes

require_relative '../libraries/input_helper'

# Resolve connection parameters with fallback support
mssql_user = MSSQLInputHelper.resolve_user(self)
mssql_pass = MSSQLInputHelper.resolve_password(self)
mssql_host = MSSQLInputHelper.resolve_host(self)
mssql_port = MSSQLInputHelper.resolve_port(self)
mssql_instance = MSSQLInputHelper.resolve_instance(self)

# Establish connection to MSSQL
sql = mssql_session(
  user: mssql_user,
  password: mssql_pass,
  host: mssql_host,
  port: mssql_port,
  instance: mssql_instance
)

# Controls remain unchanged below this point
control '2.01' do
  # ... existing control code
end
```

#### Task 1B.4: Create WinRM-Specific Profile (Alternative Approach)

If modifying existing profiles is too risky, create a separate WinRM profile:

**Directory:** `files/MSSQL2019_winrm/`

```
files/MSSQL2019_winrm/
├── inspec.yml              # WinRM-specific inputs
├── libraries/
│   └── mssql_helper.rb     # Connection helper
└── controls/
    └── trusted.rb          # Controls (symlink or copy from MSSQL2019_ruby)
```

**File:** `files/MSSQL2019_winrm/inspec.yml`

```yaml
name: mssql-2019-cis-winrm
title: CIS Microsoft SQL Server 2019 Benchmark (WinRM)
version: 1.0.0

inputs:
  - name: mssql_host
    description: SQL Server host (typically localhost for WinRM)
    type: string
    value: "localhost"
  - name: mssql_port
    description: SQL Server port
    type: numeric
    value: 1433
  - name: mssql_user
    description: SQL Server username
    type: string
  - name: mssql_password
    description: SQL Server password
    sensitive: true
    type: string
  - name: mssql_instance
    description: SQL Server named instance
    type: string
    value: ""
```

#### Task 1B.5: Update Role to Select Correct Profile

**File:** `roles/mssql_inspec/tasks/setup.yml` (modify)

```yaml
- name: Determine profile directory based on mode
  set_fact:
    _profile_suffix: "{{ '_winrm' if (use_winrm | default(false) | bool) else '_ruby' }}"
    _profile_base: "MSSQL{{ mssql_version }}"

- name: Set profile path
  set_fact:
    _controls_source: "{{ role_path }}/files/{{ _profile_base }}{{ _profile_suffix }}"
```

#### Task 1B.6: Update execute_winrm.yml Input Passing

**File:** `roles/mssql_inspec/tasks/execute_winrm.yml`

```yaml
- name: "[WinRM Execute] Build InSpec command with inputs"
  set_fact:
    _winrm_inspec_cmd: |
      export CHEF_LICENSE=accept

      inspec exec "{{ _remote_controls_path }}" \
        -t winrm://{{ winrm_username }}@{{ winrm_host }}:{{ winrm_port }} \
        --password '{{ winrm_password }}' \
        --ssl={{ winrm_ssl | lower }} \
        --input mssql_user='{{ mssql_username }}' \
        --input mssql_password='{{ mssql_password }}' \
        --input mssql_host='{{ mssql_server }}' \
        --input mssql_port='{{ mssql_port }}' \
        --input mssql_instance='{{ mssql_service | default("") }}' \
        --input connection_mode='winrm' \
        --reporter=json-min \
        --no-color \
        --chef-license=accept
```

### Phase 2: Batch Processing & Parallelism (SHOULD)

#### Task 2.1: Create Batch Processing Playbook

**File:** `test_playbooks/run_mssql_inspec_batch.yml`

```yaml
---
# Batch MSSQL InSpec Compliance Scanning
# Supports parallel execution with configurable concurrency

- name: MSSQL Batch Compliance Scanning
  hosts: mssql_databases
  gather_facts: false
  serial: "{{ batch_size | default(10) }}"

  vars:
    parallel_scans: 5
    scan_timeout: 300
    aggregate_results: []

  strategy: free  # Allows parallel execution within batch

  tasks:
    - name: Include mssql_inspec role
      include_role:
        name: mssql_inspec
      vars:
        preflight_continue_on_failure: true

  post_tasks:
    - name: Aggregate results to controller
      set_fact:
        _host_result:
          host: "{{ inventory_hostname }}"
          status: "{{ 'success' if preflight_passed else 'skipped' }}"
          error: "{{ preflight_skip_reason | default('') }}"
      delegate_to: localhost
      delegate_facts: true
```

#### Task 2.2: Add Ansible Configuration for Parallelism

**File:** `ansible.cfg` (project root)

```ini
[defaults]
forks = 10
strategy = free
timeout = 300
gathering = smart
fact_caching = memory

[ssh_connection]
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r

[inventory]
enable_plugins = yaml, host_list
```

### Phase 3: Error Handling & Logging (MUST)

#### Task 3.1: Create Error Aggregation Task

**File:** `roles/mssql_inspec/tasks/error_handling.yml`

```yaml
---
# Error aggregation and reporting

- name: "[Error] Initialize error tracking"
  set_fact:
    _scan_errors: "{{ _scan_errors | default([]) }}"
  run_once: true
  delegate_to: localhost

- name: "[Error] Record scan failure"
  set_fact:
    _scan_errors: "{{ _scan_errors + [_error_record] }}"
  vars:
    _error_record:
      timestamp: "{{ ansible_date_time.iso8601 }}"
      host: "{{ inventory_hostname }}"
      mssql_server: "{{ mssql_server }}"
      connection_mode: "{{ _connection_mode }}"
      error_code: "{{ preflight_error_code | default('UNKNOWN') }}"
      error_message: "{{ preflight_skip_reason | default('Unknown error') }}"
      winrm_host: "{{ winrm_host | default('N/A') }}"
  when: not preflight_passed
  delegate_to: localhost
  delegate_facts: true

- name: "[Error] Generate error summary report"
  template:
    src: error_summary.j2
    dest: "{{ inspec_results_dir }}/error_summary_{{ _timestamp }}.txt"
  delegate_to: localhost
  run_once: true
  when: _scan_errors | length > 0
```

#### Task 3.2: Create Error Summary Template

**File:** `roles/mssql_inspec/templates/error_summary.j2`

```jinja2
═══════════════════════════════════════════════════════════════════
 MSSQL InSpec Compliance Scan - Error Summary
 Generated: {{ ansible_date_time.iso8601 }}
═══════════════════════════════════════════════════════════════════

Total Errors: {{ _scan_errors | length }}

{% for error in _scan_errors %}
───────────────────────────────────────────────────────────────────
Error {{ loop.index }}:
  Timestamp:      {{ error.timestamp }}
  Inventory Host: {{ error.host }}
  MSSQL Server:   {{ error.mssql_server }}
  Connection:     {{ error.connection_mode | upper }}
  {% if error.connection_mode == 'winrm' %}WinRM Target:   {{ error.winrm_host }}{% endif %}
  Error Code:     {{ error.error_code }}
  Message:        {{ error.error_message }}
{% endfor %}

═══════════════════════════════════════════════════════════════════
 Recommended Actions:
───────────────────────────────────────────────────────────────────
{% for error in _scan_errors | unique(attribute='error_code') %}
{{ error.error_code }}:
{% if error.error_code == 'WINRM_CONNECTION_FAILED' %}
  - Verify WinRM is enabled on target: winrm quickconfig -force
  - Check firewall rules for port {{ winrm_port | default(5985) }}
  - Verify credentials: winrm_username / winrm_password
{% elif error.error_code == 'PORT_UNREACHABLE' %}
  - Verify SQL Server is running
  - Check firewall rules for port 1433
  - Test with: telnet {{ error.mssql_server }} 1433
{% elif error.error_code == 'AUTH_FAILED' %}
  - Verify SQL credentials
  - Check SQL authentication mode (Mixed Mode required)
{% endif %}
{% endfor %}
═══════════════════════════════════════════════════════════════════
```

### Phase 4: Documentation Updates (MUST)

#### Task 4.1: Update Role README

**File:** `roles/mssql_inspec/README.md`

Add sections for:
- WinRM mode configuration
- Variable reference (new WinRM variables)
- Batch processing usage
- Troubleshooting WinRM issues

#### Task 4.2: Update WINRM_PREREQUISITES.md

Add section for:
- Role-based WinRM usage (not standalone playbook)
- Inventory configuration examples
- Large-scale deployment considerations

---

## 5. File Structure Changes

### 5.1 New Files

```
roles/mssql_inspec/
├── tasks/
│   ├── preflight_winrm.yml      # NEW: WinRM connectivity checks
│   ├── preflight_direct.yml     # RENAMED: from current preflight.yml logic
│   ├── execute_winrm.yml        # NEW: WinRM-based InSpec execution
│   ├── execute_direct.yml       # RENAMED: from current execute.yml logic
│   └── error_handling.yml       # NEW: Error aggregation
├── templates/
│   └── error_summary.j2         # NEW: Error report template
├── files/
│   ├── MSSQL2019_ruby/
│   │   └── libraries/
│   │       └── input_helper.rb  # NEW: Input resolution helper
│   ├── MSSQL2019_winrm/         # NEW: WinRM-specific profile (Option B)
│   │   ├── inspec.yml
│   │   ├── libraries/
│   │   │   └── mssql_helper.rb
│   │   └── controls/
│   │       └── trusted.rb       # Symlink to _ruby version
│   ├── MSSQL2017_winrm/         # NEW: WinRM profile for 2017
│   ├── MSSQL2016_winrm/         # NEW: WinRM profile for 2016
│   └── MSSQL2018_winrm/         # NEW: WinRM profile for 2018
└── defaults/main.yml            # MODIFIED: Add WinRM/batch variables
```

### 5.2 Modified Files

```
roles/mssql_inspec/
├── tasks/
│   ├── main.yml                 # MODIFIED: Mode detection
│   ├── preflight.yml            # MODIFIED: Route to mode-specific task
│   ├── execute.yml              # MODIFIED: Route to mode-specific task
│   └── setup.yml                # MODIFIED: Profile selection logic
├── files/
│   ├── MSSQL2019_ruby/
│   │   ├── inspec.yml           # MODIFIED: Add dual-mode inputs
│   │   └── controls/
│   │       └── trusted.rb       # MODIFIED: Use input helper
│   ├── MSSQL2017_ruby/          # MODIFIED: Same changes
│   ├── MSSQL2016_ruby/          # MODIFIED: Same changes
│   └── MSSQL2018_ruby/          # MODIFIED: Same changes
├── README.md                    # MODIFIED: WinRM documentation
test_playbooks/
└── run_mssql_inspec_batch.yml   # NEW: Batch processing playbook
docs/
└── WINRM_PREREQUISITES.md       # MODIFIED: Role integration docs
```

---

## 6. Acceptance Criteria

### 6.1 Functional Acceptance

- [ ] `use_winrm: false` - Existing direct mode works unchanged (no regression)
- [ ] `use_winrm: true` - WinRM mode connects and executes InSpec
- [ ] WinRM credentials accepted via variables
- [ ] Pre-flight validates both connection modes appropriately
- [ ] JSON output format identical for both modes
- [ ] Summary report generated for both modes
- [ ] Error aggregation captures all failures
- [ ] Batch processing executes hosts in configurable batches
- [ ] Parallel execution respects `forks` setting

### 6.2 InSpec Profile Acceptance

- [ ] Legacy inputs (`usernm`, `passwd`, `hostnm`) work for direct mode (backward compatible)
- [ ] New inputs (`mssql_user`, `mssql_password`, `mssql_host`) work for WinRM mode
- [ ] Environment variable fallback works (`MSSQL_USER`, `MSSQL_PASS`, etc.)
- [ ] `inspec check` passes for all modified profiles
- [ ] Controls execute correctly on Windows target via WinRM
- [ ] Controls execute correctly on Linux delegate via direct mode
- [ ] Profile selection based on `use_winrm` variable works

### 6.3 Performance Acceptance

- [ ] Single WinRM scan completes in < 5 minutes
- [ ] Batch of 10 hosts completes in < 15 minutes (parallel)
- [ ] Memory usage < 500MB per concurrent scan
- [ ] No connection leaks after scan completion

### 6.3 Documentation Acceptance

- [ ] README updated with WinRM configuration
- [ ] All new variables documented
- [ ] Troubleshooting guide for WinRM issues
- [ ] Example inventory for mixed mode (direct + WinRM)

---

## 7. Testing Requirements

### 7.1 Unit Tests

| Test | Mode | Expected Result |
|------|------|-----------------|
| Mode detection | use_winrm=false | _connection_mode='direct' |
| Mode detection | use_winrm=true | _connection_mode='winrm' |
| WinRM preflight | Valid credentials | preflight_passed=true |
| WinRM preflight | Invalid credentials | preflight_passed=false |
| Direct preflight | Port open | preflight_passed=true |
| Direct preflight | Port closed | preflight_passed=false |

### 7.2 Integration Tests (Azure)

```bash
# Deploy test infrastructure
cd terraform
terraform apply -var="deploy_windows_mssql=true"

# Test 1: Direct mode (Linux container)
ansible-playbook test_playbooks/run_mssql_inspec.yml \
  -e "use_winrm=false" \
  -e "mssql_server=$(terraform output -raw mssql_container_ip)"

# Test 2: WinRM mode (Windows VM)
ansible-playbook test_playbooks/run_mssql_inspec.yml \
  -e "use_winrm=true" \
  -e "winrm_host=$(terraform output -raw windows_mssql_private_ip)"

# Test 3: Batch processing (mixed inventory)
ansible-playbook test_playbooks/run_mssql_inspec_batch.yml \
  -e "batch_size=5"
```

### 7.3 Regression Tests

- [ ] All existing test playbooks pass unchanged
- [ ] Direct mode produces identical output to pre-enhancement
- [ ] Pre-flight error codes unchanged for direct mode
- [ ] Cleanup tasks work for both modes

### 7.4 Test Matrix

| Test Scenario | Direct Mode | WinRM Mode | Expected |
|---------------|-------------|------------|----------|
| Valid connection | ✅ | ✅ | Scan completes, JSON generated |
| Invalid SQL creds | ✅ | ✅ | AUTH_FAILED, skip report |
| Unreachable server | ✅ | N/A | PORT_UNREACHABLE |
| WinRM unavailable | N/A | ✅ | WINRM_CONNECTION_FAILED |
| Timeout | ✅ | ✅ | TIMEOUT error code |
| Batch execution | ✅ | ✅ | All hosts processed |
| Parallel (forks=5) | ✅ | ✅ | 5 concurrent scans |

---

## 8. Rollback Plan

If enhancement causes issues:

1. **Immediate:** Set `use_winrm: false` for all hosts
2. **Short-term:** Revert to standalone `run_mssql_inspec_winrm.yml` playbook
3. **Long-term:** Git revert enhancement commits

**Feature Flags:**
- `use_winrm` - Disable WinRM entirely
- `batch_size: 0` - Disable batching
- `preflight_continue_on_failure: false` - Fail-fast mode

---

## 9. Implementation Checklist

### Phase 1: Core WinRM Integration
- [ ] Update `defaults/main.yml` with WinRM variables
- [ ] Create `tasks/preflight_winrm.yml`
- [ ] Create `tasks/execute_winrm.yml`
- [ ] Rename existing preflight logic to `preflight_direct.yml`
- [ ] Rename existing execute logic to `execute_direct.yml`
- [ ] Update `preflight.yml` with mode routing
- [ ] Update `execute.yml` with mode routing
- [ ] Test: Direct mode unchanged
- [ ] Test: WinRM mode functional

### Phase 1B: InSpec Profile Dual-Mode Support
- [ ] Create `libraries/input_helper.rb` for input resolution
- [ ] Update `MSSQL2019_ruby/inspec.yml` with dual-mode inputs
- [ ] Update `MSSQL2019_ruby/controls/trusted.rb` to use helper
- [ ] Create `MSSQL2019_winrm/` profile directory (Option B)
- [ ] Copy/symlink controls to WinRM profile
- [ ] Update `setup.yml` with profile selection logic
- [ ] Replicate changes to MSSQL2016, 2017, 2018 profiles
- [ ] Test: Direct mode with legacy inputs (`usernm`, `passwd`)
- [ ] Test: WinRM mode with new inputs (`mssql_user`, `mssql_password`)
- [ ] Test: Environment variable fallback

### Phase 2: Batch Processing
- [ ] Create `run_mssql_inspec_batch.yml` playbook
- [ ] Add `serial` and `strategy` configuration
- [ ] Test: Batch of 10 hosts
- [ ] Test: Parallel execution (forks=5)

### Phase 3: Error Handling
- [ ] Create `error_handling.yml` task
- [ ] Create `error_summary.j2` template
- [ ] Integrate error aggregation into cleanup
- [ ] Test: Multiple failure scenarios

### Phase 4: Documentation
- [ ] Update `roles/mssql_inspec/README.md`
- [ ] Update `docs/WINRM_PREREQUISITES.md`
- [ ] Create troubleshooting examples
- [ ] Document input naming conventions (legacy vs new)

---

## 10. Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| Ansible | 2.12+ | Core automation |
| InSpec | 5.x | Compliance scanning |
| train-winrm | latest | WinRM transport |
| pywinrm | latest | Ansible WinRM |
| sqlcmd | 18.x | Direct MSSQL connection |

---

## 11. Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| WinRM security concerns | High | Medium | Document HTTPS option, restrict network |
| Performance degradation | Medium | Low | Benchmark, optimize connection pooling |
| Breaking existing direct mode | High | Low | Comprehensive regression testing |
| WinRM gem conflicts | Low | Medium | Pin gem versions, test EE container |

---

## 12. Appendix: Control File Changes Detail

### Current Control Structure (`trusted.rb`)

```ruby
# Current - direct mode only
sql = mssql_session(
  user: input('usernm'),
  password: input('passwd'),
  host: input('hostnm'),
  port: input('port', value: 1433),
  instance: input('servicenm', value: '')
)
```

### Target Control Structure (`trusted.rb`)

```ruby
# Target - dual mode support
require_relative '../libraries/input_helper'

# Resolve inputs with fallback (new > legacy > env var)
sql = mssql_session(
  user: MSSQLInputHelper.resolve_user(self),
  password: MSSQLInputHelper.resolve_password(self),
  host: MSSQLInputHelper.resolve_host(self),
  port: MSSQLInputHelper.resolve_port(self),
  instance: MSSQLInputHelper.resolve_instance(self)
)

# Controls below remain unchanged
```

### Files Requiring Control Updates

| Profile Directory | Files to Update |
|-------------------|-----------------|
| `MSSQL2019_ruby/` | `controls/trusted.rb`, `inspec.yml` |
| `MSSQL2018_ruby/` | `controls/trusted.rb`, `inspec.yml` |
| `MSSQL2017_ruby/` | `controls/trusted.rb`, `inspec.yml` |
| `MSSQL2016_ruby/` | `controls/trusted.rb`, `inspec.yml` |
| `MSSQL2014_ruby/` | `controls/trusted.rb`, `inspec.yml` |
| `MSSQL2012_ruby/` | `controls/trusted.rb`, `inspec.yml` |
| `MSSQL2008_ruby/` | `controls/trusted.rb`, `inspec.yml` |

### New Files to Create Per Profile

| File | Purpose |
|------|---------|
| `libraries/input_helper.rb` | Input resolution with fallback |

---

*PRP Version: 1.1*
*Created: 2026-01-25*
*Updated: 2026-01-25 - Added InSpec Profile Dual-Mode Support (Phase 1B)*
*Target Completion: POC Phase*
*Estimated Effort: 7-10 days*
