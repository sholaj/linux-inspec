# Ansible Variables Reference

## Execution Modes

### Local Execution (Default)

InSpec runs on the AAP2 execution node or localhost. No SSH delegation needed.

```yaml
all:
  children:
    mssql_databases:
      hosts:
        mssql-server01_1433:
          mssql_server: mssql-db.example.com
          mssql_port: 1433
          mssql_version: "2019"
          database_platform: mssql
      vars:
        mssql_username: nist_scan_user
        # mssql_password: injected by AAP2
        # inspec_delegate_host defaults to "localhost"
```

### Remote Delegate Execution

InSpec runs on a remote delegate host via SSH.

```yaml
all:
  # Define delegate host for remote execution
  hosts:
    inspec-runner:
      ansible_host: delegate.example.com
      ansible_connection: ssh
      ansible_user: ansible-svc
      # Choose ONE authentication method:
      ansible_ssh_private_key_file: /path/to/key  # SSH key (recommended)
      # ansible_password: "{{ vault_delegate_password }}"  # Password (testing)

  children:
    mssql_databases:
      hosts:
        mssql-server01_1433:
          mssql_server: mssql-db.example.com
          mssql_port: 1433
          mssql_version: "2019"
          database_platform: mssql
      vars:
        mssql_username: nist_scan_user
        inspec_delegate_host: inspec-runner  # SSH to this host
```

---

## SSH Authentication for Delegate Host

### SSH Key Authentication (Recommended)

```yaml
all:
  hosts:
    inspec-runner:
      ansible_host: delegate.example.com
      ansible_connection: ssh
      ansible_user: ansible-svc
      ansible_ssh_private_key_file: /path/to/ssh/key
```

**Variables:**
- `ansible_connection: ssh` - Use SSH protocol
- `ansible_user` - SSH username (e.g., 'ansible-svc')
- `ansible_ssh_private_key_file` - Path to SSH private key

### Password Authentication (Testing/Dev)

```yaml
all:
  hosts:
    inspec-runner:
      ansible_host: delegate.example.com
      ansible_connection: ssh
      ansible_user: ansible-svc
      ansible_password: "{{ vault_delegate_password }}"
```

**Variables:**
- `ansible_connection: ssh` - Use SSH protocol
- `ansible_user` - SSH username
- `asnible_password` - SSH password (MUST be in vau§lt!)

---

## SSH Host Key Checking

Control SSH host key verification using `ansible_ssh_common_args`.

### Option A: Strict Host Key Checking (Recommended for Production)

```yaml
all:
  hosts:
    inspec-runner:
      ansible_connection: ssh
      ansible_user: ansible-svc
      ansible_ssh_common_args: '-o StrictHostKeyChecking=yes'
```

**Behavior:**
- Requires host key to be in known_hosts
- Connection fails if host key is unknown or changed
- **Most secure option**

**Setup:**
```bash
# Add host to known_hosts
ssh-keyscan delegate-host.example.com >> ~/.ssh/known_hosts
```

### Option B: Accept New Host Keys Automatically

```yaml
all:
  hosts:
    inspec-runner:
      ansible_connection: ssh
      ansible_user: ansible-svc
      ansible_ssh_common_args: '-o StrictHostKeyChecking=accept-new'
```

**Behavior:**
- Automatically accepts and saves new host keys
- Rejects if host key has changed (MITM protection)
- **Recommended for most use cases**

### Option C: Disable Host Key Checking (NOT Recommended)

```yaml
all:
  hosts:
    inspec-runner:
      ansible_connection: ssh
      ansible_user: ansible-svc
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
```

**Behavior:**
- Never verifies host keys
- **SECURITY RISK: Vulnerable to MITM attacks**
- Use only for isolated test environments

---

## Database Credentials

Database credentials are passed to InSpec via environment variables. AAP2 injects these as extra vars at runtime.

### MSSQL

```yaml
mssql_databases:
  hosts:
    mssql-server01_1433:
      mssql_server: mssql-db.example.com
      mssql_port: 1433
      mssql_version: "2019"
      database_platform: mssql
  vars:
    mssql_username: nist_scan_user
    # mssql_password: injected by AAP2 (single credential for all DBs with RBAC)
```

### Oracle

```yaml
oracle_databases:
  hosts:
    oracle-db01_1521:
      oracle_server: oracle-db.example.com
      oracle_database: ORCL
      oracle_service: ORCL
      oracle_port: 1521
      oracle_version: "19"
      database_platform: oracle
  vars:
    oracle_username: nist_scan_user
    # oracle_password: injected by AAP2
```

### Sybase

Sybase has an additional SSH layer for InSpec transport:

```yaml
sybase_databases:
  hosts:
    sybase-db01_5000:
      sybase_server: sybase-db.example.com
      sybase_database: master
      sybase_port: 5000
      sybase_version: "16"
      database_platform: sybase
  vars:
    sybase_username: nist_scan_user
    sybase_use_ssh: true
    sybase_ssh_user: oracle
    # sybase_password: injected by AAP2
    # sybase_ssh_password: injected by AAP2
```

---

## Variable Names Summary

### Delegate Host SSH (Ansible to Delegate)
- `ansible_user` - SSH username
- `ansible_password` - SSH password (use this, not `ansible_ssh_pass`)
- `ansible_ssh_private_key_file` - SSH key path

### Database Credentials (InSpec to Database)
- `mssql_username`, `mssql_password`
- `oracle_username`, `oracle_password`
- `sybase_username`, `sybase_password`, `sybase_ssh_password`

### Execution Control
- `inspec_delegate_host` - Where InSpec runs
  - `"localhost"` or empty = local execution
  - `"<hostname>"` = SSH to that host

---

## Authentication Flow Diagram

```
┌─────────────┐                    ┌──────────────────┐                    ┌──────────────┐
│   AAP2 /    │  Layer 1 (SSH)     │  Delegate Host   │  Layer 2 (DB)      │   Database   │
│   Ansible   ├───────────────────>│  (where InSpec   ├───────────────────>│   Server     │
│             │                    │   executes)      │                    │              │
└─────────────┘                    └──────────────────┘                    └──────────────┘

Layer 1 Variables:              Layer 2 Variables:
─────────────────              ─────────────────
ansible_user                   mssql_username / mssql_password
ansible_password               oracle_username / oracle_password
  OR                           sybase_username / sybase_password
ansible_ssh_private_key_file   sybase_ssh_user / sybase_ssh_password
```

---

## Complete Inventory Example

```yaml
---
all:
  # OPTIONAL: Remote delegate host (uncomment for SSH delegation)
  # hosts:
  #   inspec-runner:
  #     ansible_host: delegate.example.com
  #     ansible_connection: ssh
  #     ansible_user: ansible-svc
  #     ansible_ssh_private_key_file: ~/.ssh/id_rsa_delegate

  children:
    mssql_databases:
      hosts:
        mssql-server01_1433:
          mssql_server: mssql-db.example.com
          mssql_port: 1433
          mssql_version: "2019"
          database_platform: mssql
      vars:
        mssql_username: nist_scan_user
        # mssql_password: injected by AAP2
        # inspec_delegate_host: "inspec-runner"  # Uncomment for remote delegate

    oracle_databases:
      hosts:
        oracle-db01_1521:
          oracle_server: oracle-db.example.com
          oracle_database: ORCL
          oracle_service: ORCL
          oracle_port: 1521
          oracle_version: "19"
          database_platform: oracle
      vars:
        oracle_username: nist_scan_user

    sybase_databases:
      hosts:
        sybase-db01_5000:
          sybase_server: sybase-db.example.com
          sybase_database: master
          sybase_port: 5000
          sybase_version: "16"
          database_platform: sybase
      vars:
        sybase_username: nist_scan_user
        sybase_use_ssh: true
        sybase_ssh_user: oracle

  vars:
    base_results_dir: /var/lib/inspec/results
```

---

## Testing Connection

### Test SSH to Delegate Host

```bash
# With SSH Key
ansible all -i inventory.yml -m ping --limit inspec-runner

# With Password
ansible all -i inventory.yml -m ping --limit inspec-runner \
  -e @vault.yml --vault-password-file .vaultpass
```

### Expected Output
```
inspec-runner | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

---

## Security Recommendations

### Delegate Host SSH
- Use SSH key authentication in production
- If using password, store in Ansible Vault
- Use strong passwords (16+ characters)
- Rotate credentials regularly

### Database Credentials
- AAP2 injects credentials via extra vars
- Use RBAC: single service account per platform
- Grant minimum required privileges
- Never hardcode passwords in inventory

---

## AAP2 Credential Mapping

### Machine Credential (SSH to Delegate Host)

AAP2 machine credentials handle delegate host SSH authentication automatically.

**For SSH Key:**
- Username: ansible-svc
- SSH Private Key: (paste key content)
- AAP2 injects: `ansible_user`, `ansible_ssh_private_key_file`

**For Password:**
- Username: ansible-svc
- Password: (enter password)
- AAP2 injects: `ansible_user`, `ansible_password`

The delegate host in inventory only needs `ansible_host` and `ansible_connection`.
AAP2 supplies the authentication automatically.

### Custom Credential Types (Database Passwords)

Create custom credential types in AAP2:
- `mssql_password` - Single password for all MSSQL DBs
- `oracle_password` - Single password for all Oracle DBs
- `sybase_password` - Single password for all Sybase DBs
- `sybase_ssh_password` - SSH tunnel password for Sybase

AAP2 injects these as extra vars at job runtime.

### Local Testing (Without AAP2)

For local testing, use Ansible Vault:

```yaml
# vault.yml (encrypted)
vault_delegate_password: YourSSHPassword
vault_mssql_password: YourDBPassword
```

Reference in inventory:
```yaml
all:
  hosts:
    inspec-runner:
      ansible_host: delegate.example.com
      ansible_connection: ssh
      ansible_user: ansible_svc
      ansible_password: "{{ vault_delegate_password }}"
```

Run with vault:
```bash
ansible-playbook -i inventory.yml playbook.yml -e @vault.yml --vault-password-file .vaultpass
```

---

**Last Updated:** 2025-12-14
**Applies To:** All InSpec scan playbooks
