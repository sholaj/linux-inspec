# AAP2 Parallel Execution Guide

This guide covers optimizing MSSQL compliance scanning for large-scale environments (300+ hosts) using AAP2.

## Performance Baseline

| Hosts | Sequential Time | With Optimization |
|-------|-----------------|-------------------|
| 2 | 17 min | 17 min |
| 100 | ~14 hours | ~45 min |
| 300 | ~42 hours | ~1.5 hours |

## AAP2 Job Template Settings

### Recommended Configuration

```yaml
# Job Template Settings
Name: MSSQL Compliance Scan
Job Type: Run
Inventory: mssql_databases
Project: compliance-scanning
Playbook: run_mssql_inspec.yml

# Parallel Execution Settings
Forks: 25                    # Concurrent hosts per job
Job Slicing: 10              # Parallel job instances
Timeout: 3600                # 1 hour per slice

# Instance Group
Instance Groups: [compliance-runners]  # Multiple execution nodes
```

### How It Works

```
                    AAP2 Controller
                          │
            ┌─────────────┼─────────────┐
            │             │             │
         Slice 1       Slice 2      Slice 3  ... (10 slices)
         30 hosts      30 hosts     30 hosts
            │             │             │
      ┌─────┴─────┐ ┌─────┴─────┐ ┌─────┴─────┐
      │ 25 forks  │ │ 25 forks  │ │ 25 forks  │
      │ parallel  │ │ parallel  │ │ parallel  │
      └───────────┘ └───────────┘ └───────────┘
```

**Result:** 300 hosts / 10 slices = 30 hosts per slice × 25 forks = **up to 250 concurrent scans**

## Role Variables for Parallel Execution

```yaml
# group_vars/mssql_databases.yml
scan_throttle: 10              # Max concurrent scans per delegate host
scan_timeout: 600              # Per-host timeout (10 min)
preflight_continue_on_failure: true  # Don't stop on failures
```

## Inventory Structure

```yaml
# inventories/production/hosts.yml
all:
  children:
    # Delegate hosts (InSpec runners)
    inspec_runners:
      hosts:
        runner-01:
          ansible_host: runner01.example.com
        runner-02:
          ansible_host: runner02.example.com

    # Target databases
    mssql_databases:
      children:
        mssql_prod_winrm:
          hosts:
            SQLPROD001: { mssql_server: sqlprod001.example.com }
            SQLPROD002: { mssql_server: sqlprod002.example.com }
            # ... 300+ hosts
          vars:
            use_winrm: true
            winrm_username: "svc_inspec@corp.example.com"
            winrm_password: "{{ vault_ad_password }}"
            inspec_delegate_host: runner-01
```

## Load Balancing Across Runners

For very large environments, distribute load across multiple delegate hosts:

```yaml
# Split by server name prefix
mssql_prod_a_to_m:
  vars:
    inspec_delegate_host: runner-01
  hosts:
    SQLPROD_A001: {}
    SQLPROD_B001: {}
    # ...

mssql_prod_n_to_z:
  vars:
    inspec_delegate_host: runner-02
  hosts:
    SQLPROD_N001: {}
    SQLPROD_P001: {}
    # ...
```

## Workflow Template (Optional)

For scheduled scanning with approval gates:

```yaml
Workflow: Weekly MSSQL Compliance
├── Node 1: Pre-flight Validation (approval required)
├── Node 2: Production Scan (Job Slicing: 10)
├── Node 3: Generate Reports
└── Node 4: Notify Teams (on failure)
```

## Monitoring Progress

### AAP2 UI
- View parallel job slices in Jobs → [Job Name] → Job Slices
- Monitor instance group utilization

### CLI
```bash
# Check running jobs
awx jobs list --status running

# View job slice details
awx jobs get <job_id> --format json | jq '.job_slice_count, .job_slice_number'
```

## Tuning Guidelines

| Environment Size | Forks | Job Slices | Estimated Time |
|-----------------|-------|------------|----------------|
| 50 hosts | 10 | 1 | 45 min |
| 100 hosts | 20 | 5 | 45 min |
| 300 hosts | 25 | 10 | 1.5 hours |
| 500 hosts | 30 | 15 | 1.5 hours |

## Troubleshooting

### Job Slice Failures
- Check individual slice logs in AAP2 UI
- Failed hosts are logged in `failed_hosts_summary.json`
- Use `preflight_continue_on_failure: true` to complete other hosts

### Delegate Host Overload
- Reduce `scan_throttle` value
- Add more delegate hosts
- Increase delegate host resources (CPU/RAM)

### Timeout Issues
- Increase `scan_timeout` for slow networks
- Increase Job Template timeout
- Check WinRM connectivity

## Best Practices

1. **Start small** - Test with 10 hosts before scaling
2. **Use job slicing** - More effective than high fork count alone
3. **Multiple delegates** - Distribute load across runners
4. **Monitor resources** - Watch delegate host CPU/memory
5. **Schedule off-peak** - Run large scans during maintenance windows
6. **Incremental rollout** - Scan by environment tier (Dev → UAT → Prod)
