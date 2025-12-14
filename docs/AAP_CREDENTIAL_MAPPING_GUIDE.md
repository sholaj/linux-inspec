# AAP Credential Mapping & Job Template Configuration

**Author:** DevOps Team  
**Date:** 2025-12-14  
**Purpose:** Step-by-step guide to configure Ansible Automation Platform credentials and job templates

---

## Table of Contents

1. [Credential Types Overview](#credential-types-overview)
2. [Creating Credentials in AAP](#creating-credentials-in-aap)
3. [Job Template Configuration](#job-template-configuration)
4. [Credential Injection Examples](#credential-injection-examples)
5. [Testing Credential Setup](#testing-credential-setup)
6. [Troubleshooting Credential Issues](#troubleshooting-credential-issues)

---

## Credential Types Overview

Your InSpec compliance scanning uses **TWO credential types**:

### Type 1: Machine Credential (SSH to Delegate)

| Property | Value |
|---|---|
| **Purpose** | SSH access to delegate host |
| **Used For** | Ansible → Delegate Host connection |
| **When Needed** | Only if using delegate host execution mode |
| **Injected As** | `ansible_user`, `ansible_password`, or `ansible_ssh_private_key_file` |
| **Authentication Methods** | SSH Key or Password |

**Layer in Architecture:**
```
AAP (Machine Credential) 
  ↓
Ansible SSHs to delegate
  ↓
Ansible executes tasks on delegate
```

### Type 2: Custom Credential (Database Access)

| Property | Value |
|---|---|
| **Purpose** | Database access credentials for InSpec |
| **Used For** | InSpec → Database connection |
| **When Needed** | Always (both local and delegate modes) |
| **Injected As** | `mssql_password`, `oracle_password`, etc. |
| **Authentication Methods** | Username + Password |

**Layer in Architecture:**
```
InSpec (Custom Credential)
  ↓
InSpec connects to database
  ↓
Compliance controls execute
```

---

## Creating Credentials in AAP

### Step 1: Create SSH Key Credential (for Delegate Host)

**Why:** Secure way to SSH to delegate without passwords

**Instructions:**

1. **Generate SSH key (one-time):**
```bash
# On your local machine
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_inspec_rsa -N ""
# Creates:
#   ~/.ssh/ansible_inspec_rsa (private key - keep secure!)
#   ~/.ssh/ansible_inspec_rsa.pub (public key - copy to delegate)
```

2. **Copy public key to delegate host:**
```bash
# From your local machine
ssh-copy-id -i ~/.ssh/ansible_inspec_rsa.pub ansible_svc@delegate.example.com

# Or manually on delegate:
# 1. SSH to delegate
# 2. mkdir -p ~/.ssh
# 3. Add your public key content to ~/.ssh/authorized_keys
# 4. chmod 700 ~/.ssh
# 5. chmod 600 ~/.ssh/authorized_keys
```

3. **In AAP Web UI:**
   - Go to **Credentials**
   - Click **Create**
   - Fill form:
     ```
     Name:               Delegate Host SSH Key
     Organization:       (select your org)
     Credential Type:    Machine
     Username:           ansible_svc
     SSH Private Key:    [paste content of ~/.ssh/ansible_inspec_rsa]
     Passphrase:         [leave empty unless key has passphrase]
     ```
   - Click **Save**

### Step 2: Create MSSQL Database Credential

**First, create the custom credential type (one-time):**

1. **In AAP Web UI:**
   - Go to **Credential Types**
   - Click **Create**
   - Fill form:
     ```
     Name:                       MSSQL Database
     Kind:                       Cloud
     Inputs:
     {
       "fields": [
         {
           "id": "username",
           "type": "string",
           "label": "Database Username"
         },
         {
           "id": "password",
           "type": "string",
           "label": "Database Password",
           "secret": true
         }
       ],
       "required": ["username", "password"]
     }
     
     Injectors:
     {
       "env": {
         "MSSQL_USERNAME": "{{ username }}",
         "MSSQL_PASSWORD": "{{ password }}"
       },
       "extra_vars": {
         "mssql_username": "{{ username }}",
         "mssql_password": "{{ password }}"
       }
     }
     ```
   - Click **Save**

2. **Create the credential instance:**
   - Go to **Credentials**
   - Click **Create**
   - Fill form:
     ```
     Name:               MSSQL Compliance Scan Account
     Organization:       (select your org)
     Credential Type:    MSSQL Database
     Database Username:  nist_scan_user
     Database Password:  [actual password from your vault]
     ```
   - Click **Save**

### Step 3: Create Oracle Database Credential

**First, create the custom credential type (one-time):**

1. **In AAP Web UI:**
   - Go to **Credential Types**
   - Click **Create**
   - Fill form:
     ```
     Name:                       Oracle Database
     Kind:                       Cloud
     Inputs:
     {
       "fields": [
         {
           "id": "username",
           "type": "string",
           "label": "Database Username"
         },
         {
           "id": "password",
           "type": "string",
           "label": "Database Password",
           "secret": true
         }
       ],
       "required": ["username", "password"]
     }
     
     Injectors:
     {
       "env": {
         "ORACLE_USERNAME": "{{ username }}",
         "ORACLE_PASSWORD": "{{ password }}"
       },
       "extra_vars": {
         "oracle_username": "{{ username }}",
         "oracle_password": "{{ password }}"
       }
     }
     ```
   - Click **Save**

2. **Create the credential instance:**
   - Go to **Credentials**
   - Click **Create**
   - Fill form:
     ```
     Name:               Oracle Compliance Scan Account
     Organization:       (select your org)
     Credential Type:    Oracle Database
     Database Username:  nist_scan_user
     Database Password:  [actual password]
     ```
   - Click **Save**

### Step 4: Create Sybase Database Credential

Sybase is special - it needs TWO password fields (SSH tunnel + database):

1. **Create the custom credential type (one-time):**
   - Go to **Credential Types**
   - Click **Create**
   - Fill form:
     ```
     Name:                       Sybase Database
     Kind:                        Cloud
     Inputs:
     {
       "fields": [
         {
           "id": "ssh_password",
           "type": "string",
           "label": "Sybase SSH Tunnel Password",
           "secret": true
         },
         {
           "id": "password",
           "type": "string",
           "label": "Sybase Database Password",
           "secret": true
         }
       ],
       "required": ["ssh_password", "password"]
     }
     
     Injectors:
     {
       "env": {
         "SYBASE_SSH_PASSWORD": "{{ ssh_password }}",
         "SYBASE_PASSWORD": "{{ password }}"
       },
       "extra_vars": {
         "sybase_ssh_password": "{{ ssh_password }}",
         "sybase_password": "{{ password }}"
       }
     }
     ```
   - Click **Save**

2. **Create the credential instance:**
   - Go to **Credentials**
   - Click **Create**
   - Fill form:
     ```
     Name:                           Sybase Compliance Scan Account
     Organization:                   (select your org)
     Credential Type:                Sybase Database
     Sybase SSH Tunnel Password:     [SSH tunnel password]
     Sybase Database Password:       [Database password]
     ```
   - Click **Save**

---

## Job Template Configuration

### Example: MSSQL Compliance Scan Job Template

**Step 1: Create Job Template**

Go to **Templates** → **Create** → **Job Template**

**Step 2: Fill General Information**

```
Name:                   MSSQL Compliance Scan - Production
Description:            Run InSpec compliance scans on MSSQL production servers
Organization:           (select your org)
Execution Environment:  (select EE with InSpec installed)
```

**Step 3: Configure Job**

```
Inventory:              Your Inventory (with mssql_databases group)
Project:                linux-inspec (or your project name)
Playbook:               test_playbooks/run_mssql_inspec.yml
```

**Step 4: Configure Credentials**

Click **Credentials** tab, then **Select Credentials**:

1. **Add Machine Credential** (for delegate SSH):
   - Click **Select Credentials**
   - Search for: "Delegate Host SSH Key"
   - Click to select
   - Status shows "✓ Machine"

2. **Add MSSQL Custom Credential** (for DB access):
   - Click **Select Credentials**
   - Search for: "MSSQL Compliance Scan Account"
   - Click to select
   - Status shows "✓ MSSQL Database"

**Result - Credentials section should show:**
```
✓ Delegate Host SSH Key (Machine)
✓ MSSQL Compliance Scan Account (MSSQL Database)
```

**Step 5: Configure Options**

```
Limit:                  [leave empty - scans all mssql_databases]
Verbosity:              0 (Normal) or 1 (Verbose for debug)
Privilege Escalation:   Off (unless needed)
```

**Step 6: Add Extra Variables (Optional)**

```json
{
  "base_results_dir": "/tmp/compliance_scans",
  "enable_debug": false,
  "batch_size": 5,
  "execution_strategy": "linear"
}
```

**Step 7: Save**

Click **Save** button

---

## Credential Injection Examples

### How AAP Injects Machine Credential

When you attach "Delegate Host SSH Key" Machine Credential to job template:

**AAP automatically:**
1. Extracts credentials from credential object
2. Creates environment variables
3. Passes to Ansible playbook
4. Ansible uses for delegation

**Result - Available in playbook:**
```yaml
ansible_user: ansible_svc              # From credential username
ansible_password: [not used - key auth]
ansible_ssh_private_key_file: /tmp/ansible_key_12345
```

**Usage in delegate_to:**
```yaml
- name: Task on delegate
  shell: echo "Running on delegate"
  delegate_to: "{{ inspec_delegate_host }}"
  # Uses: ansible_user, ansible_ssh_private_key_file from credential
```

### How AAP Injects Custom Credential (MSSQL)

When you attach "MSSQL Compliance Scan Account" Custom Credential:

**AAP automatically:**
1. Executes custom credential injectors
2. Reads configuration from credential type
3. Sets environment variables (if "env" in injector)
4. Sets extra vars (if "extra_vars" in injector)
5. Passes to Ansible playbook

**Result - Available in playbook:**

From injector `"extra_vars"`:
```yaml
mssql_username: nist_scan_user           # From credential field
mssql_password: [actual_password_value]  # From credential field
```

From injector `"env"`:
```bash
export MSSQL_USERNAME=nist_scan_user
export MSSQL_PASSWORD=[actual_password_value]
```

**Usage in role:**
```yaml
# In variables
- debug:
    msg: "User: {{ mssql_username }}"
    # Output: User: nist_scan_user

# In environment
- shell: echo $MSSQL_PASSWORD
  environment:
    MSSQL_PASSWORD: "{{ mssql_password }}"
    # Passes injected password securely
```

### Credential Precedence

When the same variable could come from multiple sources:

```
1. Job Template Extra Variables (highest)
   Example: extra_vars: { "mssql_password": "override123" }
   
2. Credential Injection
   Example: MSSQL Custom Credential injects mssql_password
   
3. Inventory Variables (lowest)
   Example: inventory has mssql_password: "vault_value"
```

**Practical Example:**

```yaml
# Inventory (loaded first)
all:
  children:
    mssql_databases:
      vars:
        mssql_username: nist_scan_user
        mssql_password: "{{ vault_db_password }}"  # value: password123

# AAP Credential Injection (overrides inventory)
mssql_username: nist_scan_user
mssql_password: prod_password_987        # ← OVERRIDES vault_db_password

# Job Template Extra Variables (overrides both)
{
  "mssql_password": "emergency_override"  # ← FINAL VALUE USED
}

# Final result in playbook
mssql_password = "emergency_override"
```

---

## Testing Credential Setup

### Test 1: Verify Machine Credential Works

```yaml
---
# test_machine_credential.yml
- name: Test Machine Credential (SSH to Delegate)
  hosts: localhost
  gather_facts: no
  
  vars:
    delegate_host: "inspec-runner"
  
  tasks:
    - name: Ping delegate host
      ping:
      delegate_to: "{{ delegate_host }}"
      register: ping_result
      
    - name: Get delegate hostname
      shell: hostname
      delegate_to: "{{ delegate_host }}"
      register: delegate_info
      changed_when: false
      
    - name: Display results
      debug:
        msg: |
          ✓ Delegate host reachable: {{ ping_result.ping }}
          ✓ Delegate hostname: {{ delegate_info.stdout }}
```

**Run in AAP:**
1. Create template using "test_machine_credential.yml"
2. Attach Machine Credential
3. Run job
4. If successful, credential is working

### Test 2: Verify Custom Credential Injection

```yaml
---
# test_custom_credential.yml
- name: Test Custom Credential (Database Access)
  hosts: localhost
  gather_facts: no
  
  tasks:
    - name: Display injected username
      debug:
        msg: "Username injected: {{ mssql_username | default('NOT_INJECTED') }}"
      
    - name: Display injected password (masked)
      debug:
        msg: "Password injected: [PROTECTED]"
      no_log: true
      when:
        - mssql_password is defined
      
    - name: Test MSSQL connection
      shell: |
        sqlcmd -S localhost,1433 \
               -U "{{ mssql_username }}" \
               -P "{{ mssql_password }}" \
               -Q "SELECT @@VERSION"
      register: sql_result
      changed_when: false
      no_log: true
      
    - name: Display connection result
      debug:
        msg: |
          ✓ Database connection successful
          Version: {{ sql_result.stdout }}
```

**Run in AAP:**
1. Create template using test playbook
2. Attach Custom Credential (MSSQL)
3. Run job
4. If successful, credential injection works

### Test 3: Verify Credential Precedence

```yaml
---
# test_credential_precedence.yml
- name: Test Credential Precedence
  hosts: localhost
  gather_facts: no
  
  tasks:
    - name: Show where mssql_password comes from
      debug:
        msg: |
          mssql_password value: {{ mssql_password | default('NOT_DEFINED') }}
          
          If this is:
          - "vault_value" → Loaded from inventory
          - "prod_password" → Loaded from credential injection
          - "override_val" → Loaded from extra vars
      
    - name: Assert credential injection worked
      assert:
        that:
          - mssql_password is defined
          - mssql_password | length > 0
        fail_msg: |
          Custom credential not injected!
          Check:
          1. Custom credential attached to template
          2. Credential type has 'extra_vars' in injector
          3. Credential instance has password value set
```

---

## Troubleshooting Credential Issues

### Issue 1: "Machine Credential Not Working"

**Symptom:** Delegate host SSH fails

**Diagnostic Steps:**

```bash
# Step 1: Verify SSH key manually
ssh -i ~/.ssh/ansible_inspec_rsa ansible_svc@delegate.example.com "hostname"

# If manual SSH works but Ansible fails:

# Step 2: Check AAP credential has correct key
# - In AAP: Credentials → Delegate Host SSH Key
# - Check: SSH Private Key field has content
# - Check: It matches the key you generated

# Step 3: Verify key in AAP is complete
# AAP should show: [Content hidden for security]
# Not: [empty] or [invalid]

# Step 4: Check delegate host has public key
ssh ansible_svc@delegate.example.com "grep $(cat ~/.ssh/ansible_inspec_rsa.pub | awk '{print $2}') .ssh/authorized_keys"

# Step 5: Check AAP can read credential
# In AAP UI: Try viewing credential detail page
# If error: "Permission denied" → Check AAP permissions
```

### Issue 2: "Custom Credential Not Injecting"

**Symptom:** `mssql_password` not defined in playbook

**Diagnostic Steps:**

```yaml
# Step 1: Add debug task to see what's injected
- name: Check injected variables
  debug:
    msg: |
      Variables available:
      mssql_username: {{ mssql_username | default('NOT_INJECTED') }}
      mssql_password: {{ mssql_password | default('NOT_INJECTED') }}
      ansible_user: {{ ansible_user | default('NOT_INJECTED') }}

# Step 2: Check in AAP:
# - Job Template → Credentials tab
# - Look for custom credential
# - Status should show: "✓ MSSQL Database"

# Step 3: Verify credential type has injector
# - Credential Types → MSSQL Database
# - Check "Injectors" tab
# - Should have "extra_vars" section

# Step 4: Verify credential instance has values
# - Credentials → MSSQL Compliance Scan Account
# - All fields should be filled (not empty)

# Step 5: Check credential type matches
# - In job template, ensure you select correct credential type
# - ✗ WRONG: Select "Machine" credential instead of "MSSQL Database"
# - ✓ CORRECT: Select credential type that matches
```

### Issue 3: "Wrong Password Injected"

**Symptom:** Playbook gets old or wrong password value

**Root Causes:**
1. Multiple credentials with same type
2. Credential precedence confusion
3. Extra vars override

**Solution:**

```yaml
# Step 1: Check which credential is attached
# - Job Template → Credentials
# - Should see exactly ONE custom credential of each type
# - If multiple: Remove extras

# Step 2: Add debug to see source
- name: Identify password source
  debug:
    msg: |
      This password came from:
      
      1. Job Template Extra Variables? → Check JSON section
      2. Custom Credential? → Check attached credentials
      3. Inventory? → Check inventory file
      
      Current mssql_password: {{ mssql_password }}
  no_log: true  # Hide actual password

# Step 3: If extra vars overriding:
# - Job Template → Variables section
# - Remove/fix mssql_password if present
# - Or use it intentionally for override

# Step 4: Verify credential instance value
# - Credentials → MSSQL Compliance Scan Account
# - Edit → Check password value is correct
# - Save if updated
```

### Issue 4: "Delegate Host Unreachable"

**Symptom:** Machine credential defined but SSH fails

**Diagnostic:**

```bash
# Step 1: Verify delegate hostname is correct
# In inventory:
# all:
#   hosts:
#     inspec-runner:
#       ansible_host: delegate.example.com  ← Check spelling

# Step 2: Test DNS
nslookup delegate.example.com

# Step 3: Test network connectivity
ping -c 3 delegate.example.com

# Step 4: Test SSH port
nc -zv delegate.example.com 22

# Step 5: Check ansible_connection
# In inventory, ensure:
# ansible_connection: ssh  ← Not "local"

# Step 6: Test SSH with correct key
ssh -i ~/.ssh/ansible_inspec_rsa -v ansible_svc@delegate.example.com
```

### Issue 5: "Database Connection Fails"

**Symptom:** Credentials injected but database login fails

**Diagnostic:**

```bash
# Step 1: Verify database is reachable
sqlcmd -S mssql_server,1433 -Q "SELECT @@VERSION" 2>&1 | head

# Step 2: Verify credentials are correct
# - Check password: Does it have special characters?
# - If yes: May need escaping in shell
# - Test locally: sqlcmd -S server -U user -P 'password' -Q "SELECT 1"

# Step 3: Check user has connect permission
# - On database: Does nist_scan_user exist?
# - Does user have CONNECT permission?
# - Run: SELECT name FROM sys.sysusers WHERE name = 'nist_scan_user'

# Step 4: Check network access
# - From delegate/AAP: Can reach database port?
# - telnet mssql_server 1433
# - Should connect (port is open)

# Step 5: Verify Ansible passes credentials to InSpec
# - Add debug task in execute.yml
# - Print (masked): "Connecting with user: $INSPEC_DB_USERNAME"
# - Verify environment variables are set
```

---

## Quick Reference: Credential Setup Checklist

### For Local Execution (No Delegate)

- [ ] Create MSSQL Custom Credential
  - [ ] Name: "MSSQL Compliance Scan Account"
  - [ ] Type: "MSSQL Database"
  - [ ] Username: nist_scan_user
  - [ ] Password: [actual password]
  
- [ ] Create Job Template
  - [ ] Playbook: run_mssql_inspec.yml
  - [ ] Inventory: (select yours)
  - [ ] Credentials: Attach MSSQL Custom Credential
  - [ ] Extra Variables: { "base_results_dir": "/tmp/compliance_scans" }

### For Delegate Execution

- [ ] Create Machine Credential (SSH Key)
  - [ ] Name: "Delegate Host SSH Key"
  - [ ] Type: "Machine"
  - [ ] Username: ansible_svc
  - [ ] SSH Private Key: [your RSA private key content]

- [ ] Create MSSQL Custom Credential
  - [ ] (Same as above)

- [ ] Create Job Template
  - [ ] (Same as above, but now Machine Credential is also attached)
  - [ ] Credentials: Attach BOTH Machine + Custom

- [ ] Verify Inventory
  - [ ] Has `inspec-runner` in all.hosts
  - [ ] Has `ansible_connection: ssh`
  - [ ] Has `inspec_delegate_host: inspec-runner` in group vars

---

## References

- `DELEGATE_EXECUTION_IMPLEMENTATION_GUIDE.md` - Inventory and role configuration
- `ANSIBLE_VARIABLES_REFERENCE.md` - Variable definitions
- `SECURITY_PASSWORD_HANDLING.md` - Password protection best practices
- AAP Documentation: https://docs.ansible.com/automation-controller/latest/
