# Delegate Execution (Local vs. Delegate) – Confluence-Ready

## What This Covers
- How the InSpec roles run in two modes: **Delegate host** or **Localhost**.
- Exactly how to switch between the two with a single variable change.
- Credential flow and what each layer is used for.
- Minimal steps to run and troubleshoot.

## Execution Modes
- **Local Mode**: InSpec runs on the AAP/runner host (no SSH to a delegate). Use when the runner can reach DBs directly.
- **Delegate Mode**: InSpec runs on a remote delegate/bastion via SSH. Use when DBs are only reachable from that host.

## One-Line Switch (Delegate ↔ Local)
Set `inspec_delegate_host`:
- Delegate mode: `inspec_delegate_host: "inspec-runner"` (or any non-empty, non-`localhost` value)
- Local mode: `inspec_delegate_host: ""` **or** remove the variable **or** set to `localhost`

**Inventory example:**
```yaml
mssql_databases:
  hosts:
    <db_host>:
      mssql_server: <db_host>
      mssql_port: 1733
  vars:
    inspec_delegate_host: "inspec-runner"   # delegate mode
    # inspec_delegate_host: ""              # uncomment for LOCAL mode
```

## Credential Separation (never mix these)
- **SSH (delegate hop)**: `ansible_user`, `ansible_password` or `ansible_ssh_private_key_file` (only needed in delegate mode).
- **Database (InSpec to DB)**: `mssql_username/mssql_password`, `oracle_username/oracle_password`, `sybase_username/sybase_password` (needed in both modes).
- **Sybase extra (SSH into DB host)**: `sybase_ssh_user`, `sybase_ssh_password` (used by InSpec SSH transport to Sybase).

## Minimal Steps – Delegate Mode
1) Inventory: set `inspec_delegate_host: "inspec-runner"` and define DB vars.
2) AAP/Ansible credentials:
   - Machine credential for SSH to delegate (ansible_user + key/password).
   - Custom DB credential for the target DB type (injects `*_password`).
3) Run playbook/job template. InSpec executes on the delegate host.

## Minimal Steps – Local Mode
1) Inventory: set `inspec_delegate_host: ""` (or omit / set to `localhost`).
2) Ensure the runner has required clients (sqlcmd/sqlplus/isql) and InSpec in PATH.
3) Run playbook/job template. InSpec executes locally.

## What the Roles Already Do
- Auto-detect mode from `inspec_delegate_host` (non-empty/non-`localhost` → delegate; otherwise local).
- Export PATH/LD_LIBRARY_PATH for DB clients (sqlcmd/sqlplus/isql) and InSpec.
- Use absolute binary detection for reliability (e.g., sqlcmd, inspec).
- Pass passwords via environment; `no_log: true` to keep secrets out of logs and process args.

## Quick Troubleshooting
- **Runs local but you expected delegate**: `inspec_delegate_host` is empty/localhost/undefined; set to your delegate hostname.
- **Runs delegate but you expected local**: remove/blank `inspec_delegate_host`.
- **SSH failure to delegate**: verify Machine credential, host reachability, and `ansible_user`.
- **DB login failure**: verify DB credentials (Custom Credential in AAP) and network path from the execution host in use.
- **Binary not found**: ensure InSpec and DB client are installed on the host that is executing (delegate or local) and in PATH.

## Safe Defaults
- Keep passwords in AAP Custom Credentials (preferred) or vault for local testing; never in plain inventory.
- Use SSH keys for delegate access in production.
- Leave `no_log: true` on all password-bearing tasks.

## Reference
- Switching modes: change **one line** `inspec_delegate_host` as shown above.
- Roles: `roles/mssql_inspec`, `roles/oracle_inspec`, `roles/sybase_inspec`.
- Docs (detailed): `DELEGATE_EXECUTION_IMPLEMENTATION_GUIDE.md`, `AAP_CREDENTIAL_MAPPING_GUIDE.md`, `DELEGATE_EXECUTION_SUMMARY.md`.
