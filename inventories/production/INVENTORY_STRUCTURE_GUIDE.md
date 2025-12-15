# Inventory Structure Guide - Delegate vs Localhost Execution

## Understanding the Error

The error you encountered:
```
"hostvars['actual-hostname']" is undefined
```

This happened because:
1. Your inventory defined `ansible_host: actual-hostname` for the host `inspec-runner`
2. But the code tried to access `hostvars['actual-hostname']` (the actual hostname)
3. In Ansible, `hostvars` uses **inventory hostnames**, not `ansible_host` values

## The Fix Applied

Changed this line in all three roles:
```yaml
# BEFORE (would fail if hostvars not populated):
_target_env: "{{ hostvars[inspec_execution_target].ansible_env }}"

# AFTER (provides safe defaults):
_target_env: "{{ hostvars[inspec_execution_target].ansible_env | default({'PATH': '', 'LD_LIBRARY_PATH': ''}) }}"
```

## Correct Inventory Structure

### Option 1: Delegate/Bastion Mode

```yaml
all:
  hosts:
    inspec-runner:                    # ← Use THIS name in inspec_delegate_host
      ansible_host: jumphost.example.com       # ← Actual server (NOT used in hostvars lookup)
      ansible_connection: ssh
      ansible_user: ansible_service
  
  children:
    mssql_databases:
      vars:
        inspec_delegate_host: "inspec-runner"  # ← Points to inventory name above
      hosts:
        MSSQL_DB01_1433:
          mssql_server: mssqldb01.example.com
          mssql_port: 1433
          mssql_username: "scan_user"
```

**Key Points:**
- ✅ `inspec_delegate_host: "inspec-runner"` (inventory name)
- ❌ NOT `inspec_delegate_host: "actual-hostname"` (actual hostname)
- Ansible translates: `inspec-runner` → `actual-hostname` using `ansible_host`
- Code accesses: `hostvars['inspec-runner']` ✅

### Option 2: Localhost Mode

```yaml
all:
  # No hosts section needed for localhost mode
  
  children:
    mssql_databases:
      vars:
        inspec_delegate_host: "localhost"  # or "" or undefined
      hosts:
        GDCTWVC0007_1733:
          mssql_server: GDCTWVC0007
          mssql_port: 1733
          mssql_username: "nist_scan_user"
```

**Key Points:**
- ✅ `inspec_delegate_host: "localhost"` (always available)
- ✅ `inspec_delegate_host: ""` (empty = localhost)
- ✅ No `inspec_delegate_host` defined (defaults to localhost)
- Code accesses: `hostvars['localhost']` ✅

## Execution Flow Comparison

### Delegate Mode Flow:
```
1. Playbook runs on AAP2 controller
2. Task has delegate_to: "{{ inspec_execution_target }}"
   → inspec_execution_target = "inspec-runner"
3. Ansible resolves "inspec-runner" → jumphost.example.com using ansible_host
4. Ansible SSHs to jumphost.example.com using ansible_user: ansible_service
5. InSpec runs on jumphost.example.com
6. InSpec connects to database using mssql_username/mssql_password
7. Code accesses hostvars['inspec-runner'].ansible_env
```

### Localhost Mode Flow:
```
1. Playbook runs on AAP2 controller
2. Task has delegate_to: "{{ inspec_execution_target }}"
   → inspec_execution_target = "localhost"
3. InSpec runs directly in AAP2 execution environment (EE)
4. InSpec connects to database using mssql_username/mssql_password
5. Code accesses hostvars['localhost'].ansible_env
```

## Variable Resolution Examples

### Delegate Mode:
```yaml
# Your inventory:
all:
  hosts:
    inspec-runner:
      ansible_host: jumphost.example.com

# Variable values at runtime:
inspec_delegate_host: "inspec-runner"
inspec_execution_target: "inspec-runner"
hostvars['inspec-runner']:        # ✅ Exists
  ansible_host: "jumphost.example.com"
  ansible_env:
    PATH: "/usr/local/bin:/usr/bin"
    HOME: "/home/ansible_service"

hostvars['jumphost.example.com']:          # ❌ Does NOT exist (not an inventory name)
```

### Localhost Mode:
```yaml
# Variable values at runtime:
inspec_delegate_host: "localhost"
inspec_execution_target: "localhost"
hostvars['localhost']:            # ✅ Always exists
  ansible_connection: "local"
  ansible_env:
    PATH: "/usr/local/bin:/usr/bin"
    HOME: "/root"
```

## Common Mistakes to Avoid

### ❌ WRONG: Using actual hostname in inventory variable
```yaml
mssql_databases:
  vars:
    inspec_delegate_host: "jumphost.example.com"  # ❌ This is ansible_host, not inventory name
```

### ✅ CORRECT: Using inventory hostname
```yaml
all:
  hosts:
    inspec-runner:              # Inventory name
      ansible_host: jumphost.example.com # Actual hostname

mssql_databases:
  vars:
    inspec_delegate_host: "inspec-runner"  # ✅ Use inventory name
```

### ❌ WRONG: Mixed delegate and localhost
```yaml
all:
  hosts:
    inspec-runner:
      ansible_host: jumphost.example.com

mssql_databases:
  vars:
    inspec_delegate_host: "localhost"  # ❌ Defined delegate but using localhost
```

### ✅ CORRECT: Choose one mode
```yaml
# Delegate mode - use the delegate host
all:
  hosts:
    inspec-runner:
      ansible_host: jumphost.example.com

mssql_databases:
  vars:
    inspec_delegate_host: "inspec-runner"  # ✅ Use the defined host
```

OR

```yaml
# Localhost mode - no delegate host needed
all:
  # No hosts section

mssql_databases:
  vars:
    inspec_delegate_host: "localhost"  # ✅ Explicit localhost
```

## Testing Your Inventory

### Verify inventory hostname resolution:
```bash
# List all inventory hostnames
ansible-inventory -i inventories/production/hosts.yml --list

# Check specific host variables
ansible-inventory -i inventories/production/hosts.yml --host=inspec-runner

# Test hostvars access
ansible localhost -i inventories/production/hosts.yml \
  -m debug \
  -a "msg={{ hostvars['inspec-runner'].ansible_host }}"
```

### Test delegate connection:
```bash
# Verify SSH to delegate host works
ansible inspec-runner -i inventories/production/hosts.yml -m ping

# Check environment on delegate host
ansible inspec-runner -i inventories/production/hosts.yml \
  -m setup \
  -a "gather_subset=env"
```

## Files Created

1. **inventories/production/hosts_delegate_example.yml**
   - Full example of delegate/bastion mode
   - Shows correct inventory structure
   - Includes all three database types (MSSQL, Oracle, Sybase)

2. **inventories/production/hosts_localhost_example.yml**
   - Full example of localhost/direct mode
   - Simplified structure (no delegate host)
   - Includes comparison and switching guide

3. **inventories/production/INVENTORY_STRUCTURE_GUIDE.md** (this file)
   - Detailed explanation of the error
   - Comparison of execution modes
   - Common mistakes and corrections
   - Testing procedures

## Summary

**The Root Cause:**
- Attempting to use `hostvars['actual-hostname']` where the value is an `ansible_host`, not an inventory hostname

**The Solution:**
- Always use inventory hostnames in `inspec_delegate_host`
- Code now has safe defaults if hostvars not populated: `| default({'PATH': '', 'LD_LIBRARY_PATH': ''})`

**Best Practice:**
- Delegate mode: `inspec_delegate_host: "inspec-runner"` (inventory name)
- Localhost mode: `inspec_delegate_host: "localhost"` (always available)
