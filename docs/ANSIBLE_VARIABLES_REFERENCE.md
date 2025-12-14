# Ansible Variables Reference

## Authentication Variables - Correct Usage

### Delegate Host SSH Authentication (Layer 1: Ansible → Delegate/Bastion)

The delegate host functions as a **bastion server** where InSpec executes. You can authenticate to it using either SSH key or username/password.

#### SSH Key Authentication (Recommended)

```yaml
inspec_delegates:
  hosts:
    inspec-delegate-host:
      ansible_connection: ssh
      ansible_user: ansible-svc
      ansible_ssh_private_key_file: /path/to/ssh/key  # Path to private key
```

**Variables:**
- `ansible_connection: ssh` - Use SSH protocol
- `ansible_user` - SSH username (e.g., 'ansible-svc', 'bastion-user')
- `ansible_ssh_private_key_file` - Path to SSH private key

#### Password Authentication (Testing/Dev)

```yaml
inspec_delegates:
  hosts:
    inspec-delegate-host:
      ansible_connection: ssh
      ansible_user: ansible-svc
      ansible_password: "{{ vault_delegate_password }}"  # From vault
```

**Variables:**
- `ansible_connection: ssh` - Use SSH protocol
- `ansible_user` - SSH username
- `ansible_password` - SSH password (MUST be in vault!)

**Vault file:**
```yaml
---
# Delegate/Bastion SSH password (Layer 1)
vault_delegate_password: YourSecurePasswordHere
```

---

## SSH Host Key Checking

Control SSH host key verification behavior using `ansible_ssh_common_args`.

### Option A: Strict Host Key Checking (Recommended for Production)

```yaml
inspec_delegates:
  hosts:
    inspec-delegate-host:
      ansible_connection: ssh
      ansible_user: ansible-svc
      ansible_ssh_common_args: '-o StrictHostKeyChecking=yes'
```

**Behavior:**
- Requires host key to be in known_hosts
- Connection fails if host key is unknown
- Connection fails if host key has changed
- **Most secure option**

**Use case:** Production environments with stable infrastructure

**Setup:**
```bash
# Add host to known_hosts
ssh-keyscan delegate-host.example.com >> ~/.ssh/known_hosts

# Or connect manually once
ssh ansible-svc@delegate-host.example.com
```

### Option B: Accept New Host Keys Automatically

```yaml
inspec_delegates:
  hosts:
    inspec-delegate-host:
      ansible_connection: ssh
      ansible_user: ansible-svc
      ansible_ssh_common_args: '-o StrictHostKeyChecking=accept-new'
```

**Behavior:**
- Automatically accepts and saves new host keys
- Rejects if host key has changed (protection against MITM)
- Good balance between security and automation
- **Recommended for most use cases**

**Use case:** Dynamic environments with new hosts, but stable once deployed

### Option C: Disable Host Key Checking (NOT Recommended for Production)

```yaml
inspec_delegates:
  hosts:
    inspec-delegate-host:
      ansible_connection: ssh
      ansible_user: ansible-svc
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
```

**Behavior:**
- Never verifies host keys
- Accepts any host key
- Does not save host keys
- **⚠️ SECURITY RISK: Vulnerable to man-in-the-middle attacks**

**Use case:**
- Isolated test environments only
- Ephemeral containers/VMs
- Lab environments
- **NEVER use in production!**

### Default Behavior (No Option Specified)

If you don't specify `ansible_ssh_common_args`, SSH uses default behavior:
- Prompts for confirmation on first connection
- Fails on host key mismatch
- Uses `~/.ssh/known_hosts` for verification

This is suitable for manual operations but may cause issues in automation.

---

## Database Credentials (Layer 2: InSpec → Database)

Database credentials are **separate** from SSH credentials and are passed to InSpec via environment variables.

### MSSQL

```yaml
mssql_databases:
  hosts:
    mssql-server01:
      mssql_username: "{{ vault_mssql_username }}"
      mssql_password: "{{ vault_mssql_password }}"
```

**Vault file:**
```yaml
---
# MSSQL Database credentials (Layer 2)
vault_mssql_username: nist_user_scan
vault_mssql_password: YourDatabasePassword
```

### Oracle

```yaml
oracle_databases:
  hosts:
    oracle-server01:
      oracle_username: "{{ vault_oracle_username }}"
      oracle_password: "{{ vault_oracle_password }}"
```

**Vault file:**
```yaml
---
# Oracle Database credentials (Layer 2)
vault_oracle_username: nist_user_scan
vault_oracle_password: YourDatabasePassword
```

### Sybase

Sybase has **THREE** authentication layers:

```yaml
sybase_databases:
  hosts:
    sybase-server01:
      # Layer 2: SSH to Sybase server (InSpec SSH transport)
      sybase_ssh_user: oracle
      sybase_ssh_password: "{{ vault_sybase_ssh_password }}"
      # Layer 3: Database connection
      sybase_username: "{{ vault_sybase_username }}"
      sybase_password: "{{ vault_sybase_password }}"
```

**Vault file:**
```yaml
---
# Sybase SSH transport (Layer 2 - Delegate → Sybase Server)
vault_sybase_ssh_user: oracle
vault_sybase_ssh_password: SybaseSSHPassword

# Sybase Database credentials (Layer 3 - InSpec → Database)
vault_sybase_username: nist_user_scan
vault_sybase_password: YourDatabasePassword
```

---

## Variable Names - Summary

### ✅ Correct Variable Names

**Layer 1 (Ansible → Delegate/Bastion):**
- `ansible_user` - SSH username
- `ansible_password` - SSH password ✓ **Use this**
- `ansible_ssh_private_key_file` - SSH key path

**Layer 2 (InSpec → Database):**
- `mssql_username`, `mssql_password`
- `oracle_username`, `oracle_password`
- `sybase_username`, `sybase_password`

**Vault Variables:**
- `vault_delegate_password` - Bastion/delegate SSH password
- `vault_mssql_username`, `vault_mssql_password`
- `vault_oracle_username`, `vault_oracle_password`
- `vault_sybase_username`, `vault_sybase_password`

### ❌ Deprecated/Incorrect Variables

- ~~`ansible_ssh_pass`~~ - Use `ansible_password` instead
- ~~`vault_delegate_ssh_password`~~ - Use `vault_delegate_password` instead

---

## Authentication Flow Diagram

```
┌─────────────┐                    ┌──────────────────┐                    ┌──────────────┐
│   AAP2 /    │  Layer 1 (SSH)     │  Delegate Host   │  Layer 2 (DB)      │   Database   │
│   Ansible   ├───────────────────>│  (Bastion)       ├───────────────────>│   Server     │
│             │                     │  Where InSpec    │                    │              │
│             │                     │  executes        │                    │              │
└─────────────┘                    └──────────────────┘                    └──────────────┘

Layer 1 Variables:              Layer 2 Variables:              Usage:
─────────────────              ─────────────────              ──────
ansible_user                   mssql_username                 Passed via
ansible_password               mssql_password                 environment
  OR                             OR                           variables
ansible_ssh_private_key_file   oracle_username                (secure)
                               oracle_password
                                 OR
                               sybase_username
                               sybase_password
```

---

## Why `ansible_password` and not `ansible_ssh_pass`?

### `ansible_password` (Recommended)
- **Standard Ansible variable** for authentication
- Works for SSH, WinRM, and privilege escalation
- Clear and consistent naming
- Recommended in current Ansible documentation

### `ansible_ssh_pass` (Deprecated)
- Older notation specific to SSH
- Still works but not recommended
- Being phased out in favor of `ansible_password`

**Best Practice:** Use `ansible_password` for SSH password authentication.

---

## Complete Inventory Example

```yaml
---
all:
  children:
    # Database servers (metadata only)
    mssql_databases:
      hosts:
        mssql-server01:
          mssql_server: mssql-db.example.com
          mssql_port: 1433
          mssql_database: master
          # Layer 2: Database credentials
          mssql_username: "{{ vault_mssql_username }}"
          mssql_password: "{{ vault_mssql_password }}"
      vars:
        ansible_connection: local  # No SSH to database servers

    # Delegate/Bastion host (where InSpec runs)
    inspec_delegates:
      hosts:
        inspec-delegate-host:
          ansible_host: delegate.example.com
          ansible_connection: ssh  # SSH to bastion
          # Layer 1: SSH credentials
          ansible_user: ansible-svc
          # CHOOSE ONE:
          # Option A: SSH Key (production)
          ansible_ssh_private_key_file: ~/.ssh/id_rsa_delegate
          # Option B: Password (testing/dev)
          # ansible_password: "{{ vault_delegate_password }}"

  vars:
    inspec_delegate_host: inspec-delegate-host
    base_results_dir: /var/lib/inspec/results
```

**Vault file:**
```yaml
---
# Layer 1: Bastion/Delegate SSH password
vault_delegate_password: BastionSSHPassword123

# Layer 2: Database credentials
vault_mssql_username: nist_user_scan
vault_mssql_password: DatabasePassword123
```

---

## Testing Connection

### Test SSH to Delegate/Bastion

**With SSH Key:**
```bash
ansible inspec_delegates -i inventory.yml -m ping
```

**With Password:**
```bash
ansible inspec_delegates -i inventory.yml -m ping \
  -e @vault.yml --vault-password-file .vaultpass
```

### Expected Output
```
inspec-delegate-host | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

---

## Security Recommendations

### Layer 1 (Bastion SSH)
✓ Use SSH key authentication in production
✓ If using password, store in Ansible Vault
✓ Use strong passwords (16+ characters)
✓ Rotate credentials regularly
✓ Never hardcode passwords

### Layer 2 (Database)
✓ **Always** store in Ansible Vault
✓ Use read-only database accounts when possible
✓ Grant minimum required privileges
✓ Passwords passed via environment variables (never command-line)
✓ See `SECURITY_PASSWORD_HANDLING.md` for details

---

## Common Mistakes

### ❌ Wrong: Confusing SSH and DB credentials

```yaml
# WRONG - Using database user for SSH
ansible_user: nist_user_scan  # This is a DB user, not SSH user!
```

### ✅ Correct: Separate credentials

```yaml
# Layer 1: SSH to bastion
ansible_user: ansible-svc          # SSH user
ansible_password: "{{ vault_delegate_password }}"

# Layer 2: Database connection
mssql_username: nist_user_scan     # DB user
mssql_password: "{{ vault_mssql_password }}"
```

### ❌ Wrong: Using deprecated variable

```yaml
# Deprecated
ansible_ssh_pass: "{{ vault_delegate_ssh_password }}"
```

### ✅ Correct: Using standard variable

```yaml
# Current standard
ansible_password: "{{ vault_delegate_password }}"
```

---

## AAP2 Credential Mapping

### Machine Credential (Layer 1 - SSH to Bastion)

**For SSH Key:**
- Username: ansible-svc
- SSH Private Key: (paste key content)

**For Password:**
- Username: ansible-svc
- Password: (enter password)

**Maps to:**
- `ansible_user` (from credential username)
- `ansible_password` OR `ansible_ssh_private_key_file` (from credential)

### Vault Credential (Layer 2 - Database Passwords)

**Vault Credential:**
- Vault Password: (ansible-vault password)

**Decrypts:**
- `vault_mssql_username`, `vault_mssql_password`
- `vault_oracle_username`, `vault_oracle_password`
- `vault_sybase_username`, `vault_sybase_password`

---

**Last Updated:** 2025-11-30
**Applies To:** All InSpec scan playbooks
**Critical:** `ansible_password` for SSH password authentication (not `ansible_ssh_pass`)
