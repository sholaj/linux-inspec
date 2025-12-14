# Delegate Execution Implementation Guide

**Author:** DevOps Team
**Date:** 2025-12-14
**Purpose:** Comprehensive guide for implementing delegate host execution with InSpec compliance scanning

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Modes](#architecture-modes)
3. [Credential Management](#credential-management)
4. [Inventory Configuration](#inventory-configuration)
5. [Role Behavior](#role-behavior)
6. [AAP Integration](#aap-integration)
7. [Troubleshooting](#troubleshooting)
8. [Testing Procedures](#testing-procedures)

---

## Overview

The database compliance scanning framework supports **two execution modes**:

- **LOCAL**: InSpec runs on AAP execution environment directly
- **DELEGATE**: InSpec runs on a remote delegate/bastion host via SSH

The system automatically detects which mode to use based on the `inspec_delegate_host` variable and handles credential passing appropriately for each mode.

### Key Principle: Credential Separation

**Different credentials serve different purposes:**

```
┌─────────────────────────────────────────────────┐
│          AAP / EXECUTION ENVIRONMENT             │
├─────────────────────────────────────────────────┤
│  Layer 1: SSH to Delegate Host (if delegate)   │
│  ├─ Credentials: ansible_user, ansible_password│
│  └─ Type: Ansible Machine Credential in AAP    │
│                                                  │
│  Layer 2: Execute InSpec on Local/Delegate     │
│  ├─ Credentials: mssql_username/password       │
│  ├─ Type: InSpec database credentials          │
│  └─ Transport: Environment variables (secure)  │
│                                                  │
│  Layer 3: InSpec Connects to Database          │
│  ├─ Uses credentials from Layer 2              │
│  └─ Never exposed in command line              │
└─────────────────────────────────────────────────┘
```

**IMPORTANT:**
- Layer 1 credentials = SSH access to delegate (Machine Credential)
- Layer 2 credentials = Database access via InSpec (Custom Credential)
- These are DIFFERENT and must not be confused

---

## Architecture Modes

### Mode 1: Local Execution

```
AAP Execution Environment
    │
    ├─ InSpec runs here
    ├─ Uses local database clients (sqlcmd, sqlplus, isql)
    └─ Connects directly to database
```

**When to use:**
- AAP execution environment has network access to databases
- Single execution environment
- No jump server available
- Development/testing

**Inventory Configuration:**
```yaml
all:
  children:
    mssql_databases:
      hosts:
        mssql_prod_01:
          mssql_server: prod-mssql.internal.com
          mssql_port: 1433
          mssql_version: "2019"
          database_platform: mssql
      vars:
        mssql_username: nist_scan_user
        # mssql_password: injected by AAP Custom Credential
        # inspec_delegate_host: NOT SET (defaults to localhost)
```

**Execution Flow:**
```
1. Playbook runs on AAP
2. Detects inspec_delegate_host is not defined → LOCAL mode
3. Uses control files from: {{ role_path }}/files/
4. Executes InSpec directly on AAP
5. Database credentials passed via environment variables
6. Results written to local results directory
```

### Mode 2: Remote Delegate Execution

```
AAP Execution Environment
    │
    └─ SSH to Delegate Host
         │
         ├─ InSpec runs here
         ├─ Has database clients
         └─ Connects to database
```

**When to use:**
- AAP cannot reach databases directly (firewall)
- Delegate host has network access to databases
- Multiple AAP instances share one delegate
- Production secure environment
- Organization requires jump server architecture

**Inventory Configuration:**
```yaml
all:
  # Define the delegate host
  hosts:
    inspec-runner:
      ansible_host: delegate.example.com
      ansible_connection: ssh
      ansible_user: ansible_svc
      # Use ONE authentication method:
      ansible_ssh_private_key_file: /path/to/key  # Recommended
      # ansible_password: "{{ vault_delegate_password }}"  # For testing

  children:
    mssql_databases:
      hosts:
        mssql_prod_01:
          mssql_server: prod-mssql.internal.com
          mssql_port: 1433
          mssql_version: "2019"
          database_platform: mssql
      vars:
        mssql_username: nist_scan_user
        # mssql_password: injected by AAP Custom Credential
        inspec_delegate_host: inspec-runner  # SSH to this host
```

**Execution Flow:**
```
1. Playbook runs on AAP
2. Detects inspec_delegate_host: inspec-runner → DELEGATE mode
3. Copies control files to delegate host
4. SSH to inspec-runner
5. Executes InSpec on delegate host
6. Database credentials passed via environment variables
7. Results written to results directory on delegate
8. Results copied back to AAP (optional)
```

### Mode 3: AAP Mesh Execution (Distributed)

```
AAP Controller (Orchestration)
    │
    ├─ AAP Mesh Node 1 (Region A)
    │   └─ Executes jobs locally
    │
    ├─ AAP Mesh Node 2 (Region B)
    │   └─ Executes jobs locally
    │
    └─ AAP Mesh Node 3 (Region C)
        └─ Executes jobs locally
```

**Difference from delegate:**
- No separate delegate host needed
- Mesh nodes ARE execution nodes
- Jobs run on nearest node automatically
- No SSH delegation layer

**When to use:**
- Enterprise scale (3+ regions)
- High availability required
- Distributed organizations
- Mesh infrastructure already in place

**Note:** This is configured at AAP infrastructure level, not in playbooks. Your roles work unchanged with AAP Mesh.

---

## Credential Management

### SSH Credentials (Layer 1: Ansible → Delegate Host)

Used **only when using delegate mode**.

#### Option A: SSH Key Authentication (Recommended)

**In Inventory:**
```yaml
all:
  hosts:
    inspec-runner:
      ansible_host: delegate.example.com
      ansible_connection: ssh
      ansible_user: ansible_svc
      ansible_ssh_private_key_file: /path/to/ansible/key
```

**In AAP:**
1. Create or upload SSH key pair
2. Store private key in AAP credentials
3. Assign to Job Template → Credentials
4. AAP injects `ansible_ssh_private_key_file` automatically

**Advantages:**
- More secure than passwords
- No password typed interactively
- Industry standard for production
- Supports SSH agent forwarding

#### Option B: Password Authentication (Testing Only)

**In Inventory:**
```yaml
all:
  hosts:
    inspec-runner:
      ansible_host: delegate.example.com
      ansible_connection: ssh
      ansible_user: ansible_svc
      ansible_password: "{{ vault_delegate_password }}"
```

**In Vault File (for local testing):**
```yaml
vault_delegate_password: "actual_password_here"
```

**In AAP:**
1. Create Machine Credential type: SSH
2. Set Username: ansible_svc
3. Set Password: actual_password
4. Assign to Job Template
5. AAP injects `ansible_password`

**Important:** Vault file MUST NOT be in version control. AAP credentials are always preferred in production.

### Database Credentials (Layer 2: InSpec → Database)

Used in **both local and delegate modes**.

#### MSSQL

```yaml
mssql_databases:
  hosts:
    mssql_prod_01:
      mssql_server: prod-mssql.internal.com
      mssql_port: 1433
      mssql_version: "2019"
      database_platform: mssql
  vars:
    mssql_username: nist_scan_user
    # mssql_password: INJECTED BY AAP (do not set in inventory)
```

**AAP Setup:**
1. Create Custom Credential Type: MSSQL Database
2. Field: username → `mssql_username`
3. Field: password → `mssql_password`
4. Set value: nist_scan_user / actual_password
5. Assign to Job Template → Credentials
6. AAP injects both variables at runtime

#### Oracle

```yaml
oracle_databases:
  hosts:
    oracle_prod_01:
      oracle_server: prod-oracle.internal.com
      oracle_port: 1521
      oracle_database: ORCL
      oracle_service: ORCL
      oracle_version: "19"
      database_platform: oracle
  vars:
    oracle_username: nist_scan_user
    # oracle_password: INJECTED BY AAP
```

**AAP Setup:** Same pattern as MSSQL, create Oracle Database credential type.

#### Sybase (Complex: 3 Credential Layers)

Sybase requires credentials at **three levels**:

```yaml
sybase_databases:
  hosts:
    sybase_prod_01:
      sybase_server: prod-sybase.internal.com
      sybase_port: 5000
      sybase_database: master
      sybase_version: "16"
      database_platform: sybase
  vars:
    # Layer 1: SSH to Delegate (ansible layer - handled separately)

    # Layer 2: SSH Tunnel (InSpec to Sybase server)
    sybase_ssh_user: sybase_admin
    sybase_use_ssh: true
    # sybase_ssh_password: INJECTED BY AAP

    # Layer 3: Database Login (isql)
    sybase_username: nist_scan_user
    # sybase_password: INJECTED BY AAP
```

**AAP Setup:**
1. Create Machine Credential for Sybase SSH
   - Username: sybase_admin
   - Injected as: `sybase_ssh_user` (override inventory)

2. Create Custom Credential for Sybase Database
   - Fields: `sybase_ssh_password`, `sybase_password`
   - Injected at runtime

**Flow:**
```
Ansible SSH → Delegate
  └─ InSpec SSH Tunnel → Sybase Server (sybase_ssh_user/sybase_ssh_password)
       └─ isql Login → Database (sybase_username/sybase_password)
```

---

## Inventory Configuration

### Complete Example: Multi-Mode Inventory

```yaml
---
# Complete inventory supporting local, delegate, and AAP modes

# ============================================
# GROUP 1: Delegate Host (for remote execution)
# ============================================
all:
  hosts:
    inspec-runner:
      # Delegate host where InSpec will execute
      ansible_host: delegate.example.com
      ansible_connection: ssh
      ansible_user: ansible_svc

      # SSH Authentication - Choose ONE:

      # Option A: SSH Key (Recommended for Production)
      ansible_ssh_private_key_file: /path/to/ansible_rsa
      # Managed by: SSH Key stored in AAP, injected at runtime

      # Option B: Password (Recommended for Testing/Dev)
      # ansible_password: "{{ vault_delegate_password }}"
      # Managed by: Vault file for local testing
      #            AAP Machine Credential for AAP execution

      # SSH Host Key Management
      ansible_ssh_common_args: '-o StrictHostKeyChecking=accept-new'
      # Options:
      #   accept-new = automatically accept new host keys (recommended)
      #   yes = require host key in known_hosts (most secure)
      #   no = never verify (insecure - don't use)

  # ============================================
  # GROUP 2: MSSQL Database Servers
  # ============================================
  children:
    mssql_databases:
      hosts:
        # Production MSSQL Server
        mssql_prod_01:
          mssql_server: prod-mssql.internal.com
          mssql_port: 1433
          mssql_version: "2019"
          database_platform: mssql
          # Optional: Can specify custom results directory
          # inspec_results_dir: "/tmp/mssql_results"

        # Development MSSQL Server
        mssql_dev_01:
          mssql_server: dev-mssql.internal.com
          mssql_port: 1433
          mssql_version: "2017"
          database_platform: mssql

      vars:
        # Execution Mode Selection
        # Option 1: Local Execution (comment out for local mode)
        inspec_delegate_host: "inspec-runner"

        # Option 2: For local execution, use this instead:
        # inspec_delegate_host: ""  # Empty string = local mode

        # Database Credentials (Layer 2)
        mssql_username: nist_scan_user
        # mssql_password: NOT in inventory - injected by AAP Custom Credential

        # Execution Parameters
        base_results_dir: "/tmp/compliance_scans"
        enable_debug: false

        # Timeouts
        inspec_command_timeout: 1800  # 30 minutes per control
        async_scan_timeout: 3600       # 1 hour total async

    # ============================================
    # GROUP 3: Oracle Database Servers
    # ============================================
    oracle_databases:
      hosts:
        oracle_prod_01:
          oracle_server: prod-oracle.internal.com
          oracle_port: 1521
          oracle_database: ORCL
          oracle_service: ORCL
          oracle_version: "19"
          database_platform: oracle

        oracle_dev_01:
          oracle_server: dev-oracle.internal.com
          oracle_port: 1521
          oracle_database: DEVDB
          oracle_service: DEVDB
          oracle_version: "12"
          database_platform: oracle

      vars:
        # Execution Mode
        inspec_delegate_host: "inspec-runner"

        # Database Credentials (Layer 2)
        oracle_username: nist_scan_user
        # oracle_password: injected by AAP

        # Execution Parameters
        base_results_dir: "/tmp/compliance_scans"

    # ============================================
    # GROUP 4: Sybase Database Servers
    # (Complex: 3-layer authentication)
    # ============================================
    sybase_databases:
      hosts:
        sybase_prod_01:
          sybase_server: prod-sybase.internal.com
          sybase_port: 5000
          sybase_database: master
          sybase_version: "16"
          database_platform: sybase

      vars:
        # Execution Mode
        inspec_delegate_host: "inspec-runner"

        # Layer 2: SSH Tunnel to Sybase
        sybase_use_ssh: true  # Enable SSH tunnel
        sybase_ssh_user: sybase_admin
        # sybase_ssh_password: injected by AAP

        # Layer 3: Database Login
        sybase_username: nist_scan_user
        # sybase_password: injected by AAP

        # Execution Parameters
        base_results_dir: "/tmp/compliance_scans"
```

### Switching Between Modes

**To switch from LOCAL to DELEGATE:**

Change this line:
```yaml
mssql_databases:
  vars:
    inspec_delegate_host: ""  # LOCAL - InSpec runs on AAP
```

To this:
```yaml
mssql_databases:
  vars:
    inspec_delegate_host: "inspec-runner"  # DELEGATE - InSpec runs on delegate
```

**To switch from DELEGATE to LOCAL:**

Do the opposite. The role automatically detects based on the value.

---

## Role Behavior

### Automatic Detection Logic

All three roles (mssql_inspec, oracle_inspec, sybase_inspec) use identical detection:

```yaml
# In execute.yml
- name: Determine execution mode
  set_fact:
    use_delegate_host: "{{ (inspec_delegate_host | default('')) not in ['', 'localhost'] }}"
```

**Result:**

| inspec_delegate_host Value | Mode | Execution Location |
|---|---|---|
| Undefined | LOCAL | AAP execution environment |
| Empty string `""` | LOCAL | AAP execution environment |
| `"localhost"` | LOCAL | AAP execution environment |
| `"inspec-runner"` | DELEGATE | Remote host (via SSH) |
| `"bastion.example.com"` | DELEGATE | Remote host (via SSH) |

### Task Delegation Logic

```yaml
# This is how delegation is applied:
- name: Execute InSpec controls
  shell: |
    /usr/bin/inspec exec {{ control_file }} ...
  delegate_to: "{{ inspec_delegate_host if use_delegate_host | bool else omit }}"
```

**Interpretation:**

- If `use_delegate_host` is true: Execute on `inspec_delegate_host` via SSH
- If `use_delegate_host` is false: Execute locally (omit delegation)

### Control File Handling

**LOCAL MODE:**
```yaml
mssql_controls_path: "{{ role_path }}/files"
# Uses: /path/to/roles/mssql_inspec/files/MSSQL2019_ruby/controls.rb
```

**DELEGATE MODE:**
```yaml
mssql_controls_path: "/tmp/mssql_controls_abc123/MSSQL2019_ruby/"
# 1. Creates temp directory on delegate
# 2. Copies control files to delegate
# 3. Uses temp path for execution
# 4. Cleans up temp files after execution
```

### Password Protection

**All passwords are protected via environment variables:**

```yaml
- name: Execute InSpec controls
  shell: |
    /usr/bin/inspec exec {{ control_file }} \
      --input usernm="$INSPEC_DB_USERNAME" \
              passwd="$INSPEC_DB_PASSWORD" \
              ...
  environment:
    INSPEC_DB_USERNAME: "{{ mssql_username }}"
    INSPEC_DB_PASSWORD: "{{ mssql_password }}"
  no_log: true  # ALWAYS true - never conditional
```

**Benefits:**

1. ✅ Password NOT in command-line arguments
2. ✅ Password NOT in ansible output/logs
3. ✅ Password NOT visible in `ps aux`
4. ✅ Only visible to InSpec process

---

## AAP Integration

### AAP Credential Types Required

#### 1. Machine Credential (SSH to Delegate)

**When to use:** If delegate host execution is enabled

**Type:** Machine

**Fields to set:**
- Username: `ansible_svc` (or your SSH username)
- Password: [delegate host SSH password] (if password auth)
- OR SSH Private Key: [your RSA key] (if key auth - recommended)

**How it's used:**
```
AAP (Machine Credential) → ansible_user, ansible_password
                          ↓
                    Ansible Variable Injection
                          ↓
                 Ansible connects to inspec_delegate_host
```

**AAP Job Template Setup:**
1. Credentials tab → Add Machine Credential
2. Select credential you created
3. AAP automatically injects `ansible_user` and `ansible_password` (or key path)

#### 2. Custom Credential Type (Database Access)

**When to use:** Always (both local and delegate modes)

**Type:** Custom

**Create for each database type you use:**

**MSSQL Custom Credential:**
```
Name: MSSQL Database
Fields:
  - username (required)
  - password (required, secret)
Input variables:
  - mssql_username
  - mssql_password
```

**Oracle Custom Credential:**
```
Name: Oracle Database
Fields:
  - username (required)
  - password (required, secret)
Input variables:
  - oracle_username
  - oracle_password
```

**Sybase Custom Credential:**
```
Name: Sybase Database
Fields:
  - ssh_password (required, secret)
  - database_password (required, secret)
Input variables:
  - sybase_ssh_password
  - sybase_password
```

**AAP Job Template Setup:**
1. Credentials tab → Add Custom Credential
2. Select credential type you created
3. Set values (username: nist_scan_user, password: actual_password)
4. AAP automatically injects `mssql_password`, `oracle_password`, etc.

### AAP Job Template Configuration

**Example Job Template: Run MSSQL Compliance Scan**

```
Name: MSSQL Compliance Scan
Inventory: Your Inventory with mssql_databases group
Project: Linux InSpec Project
Playbook: test_playbooks/run_mssql_inspec.yml
Credential(s):
  ✓ Machine Credential (for delegate SSH)
  ✓ MSSQL Custom Credential (for DB access)

Extra Variables:
{
  "base_results_dir": "/tmp/compliance_scans",
  "enable_debug": false,
  "execution_strategy": "linear",
  "batch_size": 5
}

Execution Environment:
  Select EE that has InSpec and sqlcmd installed

Job Tags:
  (optional) validate, execute, process, cleanup
```

### AAP Credential Flow

```
┌──────────────────────────────┐
│   AAP Job Execution          │
└──────────────┬───────────────┘
               │
    ┌──────────┴──────────┐
    │                     │
    ▼                     ▼
Machine Credential   Custom Credential
(SSH to delegate)    (DB access)
    │                     │
    ├─ ansible_user       ├─ mssql_username
    ├─ ansible_password   └─ mssql_password
    └─ (or SSH key)

    │                     │
    └──────────┬──────────┘
               │
    ┌──────────▼──────────────────────────────┐
    │  Ansible Playbook (run_mssql_inspec.yml)│
    │                                          │
    │  Detects execution mode                 │
    │  Calls mssql_inspec role                │
    │  Passes all credentials                 │
    └──────────────────────────────────────────┘
```

---

## Troubleshooting

### Issue 1: "Could not resolve hostname"

**Symptom:** SSH connection fails to delegate host

**Root Causes:**
1. Delegate hostname is incorrect
2. Delegate host not reachable from AAP
3. DNS not resolving hostname

**Solution:**
```yaml
# Step 1: Verify inventory has correct hostname
all:
  hosts:
    inspec-runner:
      ansible_host: delegate.example.com  # Check spelling

# Step 2: Test DNS resolution
nslookup delegate.example.com

# Step 3: Test SSH manually
ssh -v ansible_svc@delegate.example.com

# Step 4: If manual SSH works but Ansible fails:
# - Check ansible_user matches SSH username
# - Verify SSH key path is correct
# - Check SSH key permissions: chmod 600
```

### Issue 2: "Permission denied (publickey,password)"

**Symptom:** SSH authentication fails to delegate

**Root Causes:**
1. SSH key not authorized on delegate
2. SSH username incorrect
3. SSH password wrong

**Solution:**
```bash
# For key authentication:
# 1. Ensure public key on delegate:
ssh-copy-id -i ~/.ssh/ansible_rsa.pub ansible_svc@delegate.example.com

# 2. Verify key permissions on delegate:
# On delegate host:
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# For password authentication:
# 1. Verify username is correct
# 2. Verify password in AAP Machine Credential
# 3. Test manually: ssh -v ansible_svc@delegate.example.com
```

### Issue 3: "InSpec not found on delegate host"

**Symptom:** Role executes, but InSpec command fails

**Root Causes:**
1. InSpec not installed on delegate
2. InSpec in non-standard path
3. PATH environment variable doesn't include InSpec

**Solution:**
```bash
# On delegate host:
# 1. Check if InSpec installed:
which inspec

# 2. If not installed:
sudo gem install inspec

# 3. If in non-standard path, add to PATH:
export PATH=/custom/path/bin:$PATH

# 4. Test InSpec works:
inspec --version
```

### Issue 4: "Database connection failed"

**Symptom:** InSpec connects but database login fails

**Root Causes:**
1. Database credentials incorrect
2. Database not reachable from execution location
3. Database username doesn't have required permissions

**Solution:**
```bash
# On execution location (local or delegate):

# For MSSQL:
sqlcmd -S mssql_server -U nist_scan_user -P password

# For Oracle:
sqlplus nist_scan_user/password@ORCL

# For Sybase (via SSH tunnel):
ssh sybase_admin@sybase_server "isql -Unist_scan_user -Ppassword"

# If credentials work manually but fail in Ansible:
# - Check credentials injected correctly in AAP
# - Verify environment variables are set: echo $INSPEC_DB_PASSWORD
# - Check special characters in password need escaping
```

### Issue 5: "Execution mode not detected correctly"

**Symptom:** Playbook runs in wrong mode (should delegate but ran local)

**Root Causes:**
1. `inspec_delegate_host` not defined in inventory
2. Value is typo (e.g., spaces or case mismatch)
3. Variable overridden by extra vars

**Solution:**
```yaml
# Step 1: Verify inventory definition
mssql_databases:
  vars:
    inspec_delegate_host: "inspec-runner"  # Must be exact name

# Step 2: Check for typos
# ✗ WRONG: "inspec-Runner" (capital R)
# ✗ WRONG: "inspec_runner" (underscore not dash)
# ✗ WRONG: " inspec-runner" (leading space)
# ✓ CORRECT: "inspec-runner"

# Step 3: Check AAP extra vars don't override
# In Job Template Extra Variables, ensure:
# ✓ inspec_delegate_host not redefined
# or
# ✓ if redefined, value is correct

# Step 4: Add debug task to verify
- name: Verify execution mode
  debug:
    msg: "Delegate host: {{ inspec_delegate_host }}"
  register: mode_check

- name: Assert correct mode
  assert:
    that:
      - mode_check.msg | regex_search('inspec-runner')
    fail_msg: "Delegate host not set correctly"
```

### Issue 6: Delegate host defined but SSH not happening

**Symptom:** Playbook detects delegate mode, but task runs locally

**Root Causes:**
1. Delegate host in inventory but `ansible_connection` not set to `ssh`
2. Using `localhost` as delegate (treated as local mode)
3. Variable value is exactly "localhost"

**Solution:**
```yaml
# Ensure delegate host has correct connection:
all:
  hosts:
    inspec-runner:
      ansible_host: delegate.example.com
      ansible_connection: ssh  # MUST be ssh, not local
      ansible_user: ansible_svc

# Verify inspec_delegate_host value:
mssql_databases:
  vars:
    inspec_delegate_host: "inspec-runner"  # Must match hosts key above
    # NOT "localhost" - that triggers local mode
```

---

## Testing Procedures

### Test 1: Verify Execution Mode Detection

```yaml
---
# test_execution_mode_detection.yml
- name: Test Execution Mode Detection
  hosts: mssql_databases
  gather_facts: no

  tasks:
    - name: Display detected execution mode
      debug:
        msg: |
          inspec_delegate_host: {{ inspec_delegate_host | default('NOT_DEFINED') }}
          use_delegate_host: {{ (inspec_delegate_host | default('')) not in ['', 'localhost'] }}
          Expected Mode: {{ 'DELEGATE' if (inspec_delegate_host | default('')) not in ['', 'localhost'] else 'LOCAL' }}

    - name: Show execution target
      debug:
        msg: "{{ inventory_hostname }}"

    - name: Show where this task runs (local)
      shell: hostname
      register: local_hostname
      changed_when: false

    - name: Show where task runs on delegate
      shell: hostname
      delegate_to: "{{ inspec_delegate_host }}"
      register: delegate_hostname
      when:
        - (inspec_delegate_host | default('')) not in ['', 'localhost']
      changed_when: false

    - name: Display results
      debug:
        msg: |
          Local execution: {{ local_hostname.stdout }}
          Delegate execution: {{ delegate_hostname.stdout | default('N/A - local mode') }}
```

### Test 2: Verify SSH Connectivity

```yaml
---
# test_delegate_ssh_connectivity.yml
- name: Test Delegate SSH Connectivity
  hosts: localhost
  gather_facts: no

  vars:
    delegate_host: "inspec-runner"

  tasks:
    - name: Test ping to delegate
      ping:
      delegate_to: "{{ delegate_host }}"
      register: ping_result

    - name: Test SSH connectivity
      raw: echo "SSH works"
      delegate_to: "{{ delegate_host }}"
      register: ssh_test

    - name: Get delegate host info
      shell: |
        echo "Hostname: $(hostname)"
        echo "OS: $(uname -a)"
      delegate_to: "{{ delegate_host }}"
      register: delegate_info

    - name: Display results
      debug:
        msg: |
          Ping Result: {{ ping_result.ping | default('failed') }}
          SSH Test: {{ ssh_test.stdout | default('failed') }}
          Delegate Info:
          {{ delegate_info.stdout }}
```

### Test 3: Verify Database Credentials

```yaml
---
# test_database_credentials.yml
- name: Test Database Credentials
  hosts: mssql_databases
  gather_facts: no

  tasks:
    - name: Display database configuration
      debug:
        msg: |
          Server: {{ mssql_server }}
          Port: {{ mssql_port }}
          Username: {{ mssql_username }}
          Password: [PROTECTED]

    - name: Test MSSQL connection (if local mode)
      shell: sqlcmd -S {{ mssql_server }},{{ mssql_port }} -U {{ mssql_username }} -P "{{ mssql_password }}" -Q "SELECT @@VERSION"
      register: mssql_version
      changed_when: false
      when:
        - (inspec_delegate_host | default('')) in ['', 'localhost']

    - name: Test MSSQL connection (if delegate mode)
      shell: sqlcmd -S {{ mssql_server }},{{ mssql_port }} -U {{ mssql_username }} -P "{{ mssql_password }}" -Q "SELECT @@VERSION"
      delegate_to: "{{ inspec_delegate_host }}"
      register: mssql_version_delegate
      changed_when: false
      when:
        - (inspec_delegate_host | default('')) not in ['', 'localhost']

    - name: Display connection test results
      debug:
        msg: |
          MSSQL Version: {{ mssql_version.stdout | default(mssql_version_delegate.stdout) }}
```

---

## Best Practices

1. **Always use SSH keys in production** (not passwords)
2. **Store SSH key in AAP** (not in inventory)
3. **Use separate AAP credential for each database type**
4. **Test delegate connectivity before running scans**
5. **Monitor delegate host resources** (CPU, disk, memory)
6. **Keep InSpec and database clients updated on delegate**
7. **Use strong passwords** (if password auth required)
8. **Regularly rotate credentials** (both SSH and DB)
9. **Document your execution mode choice** (why delegate vs. local)
10. **Implement result archival** (don't rely on temp directories)

---

## References

- `DELEGATE_EXECUTION_ANALYSIS.md` - Technical analysis and gaps
- `ANSIBLE_VARIABLES_REFERENCE.md` - Variable definitions
- `SECURITY_PASSWORD_HANDLING.md` - Password protection details
- `DATABASE_COMPLIANCE_SCANNING_DESIGN.md` - Overall architecture
