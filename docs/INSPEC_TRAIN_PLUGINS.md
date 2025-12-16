# InSpec Train Plugin Requirements

## Overview

The InSpec roles require specific Train plugins to be installed on the delegate host (InSpec runner) to connect to different database backends. InSpec automatically detects which backend to use based on the resource types in the control files (e.g., `mssql_session`, `oracledb_session`, `sybase_session`).

## Required Train Plugins

The following Train plugins must be installed on the delegate host where InSpec executes:

### MS SQL Server
```bash
gem install train-mssql
# or
inspec plugin install train-mssql
```

**Package**: `train-mssql`  
**Resource**: `mssql_session`  
**Required for**: `mssql_inspec` role

### Oracle Database
```bash
gem install train-oracle
# or
inspec plugin install train-oracle
```

**Package**: `train-oracle`  
**Resource**: `oracledb_session`  
**Required for**: `oracle_inspec` role

### Sybase Database
```bash
gem install train-sybase
# or
inspec plugin install train-sybase
```

**Package**: `train-sybase`  
**Resource**: `sybase_session`  
**Required for**: `sybase_inspec` role

## Verification

To verify that train plugins are installed:

```bash
# List installed InSpec plugins
inspec plugin list

# Expected output should include:
# train-mssql
# train-oracle
# train-sybase
```

## Automatic Backend Detection

InSpec automatically determines which backend to use based on the resource types in your control files:

- Control files using `mssql_session` → uses MSSQL backend
- Control files using `oracledb_session` → uses Oracle backend
- Control files using `sybase_session` → uses Sybase backend

**No `--backend` flag is needed** - the train plugins handle backend detection automatically.

## Error Messages

If a train plugin is missing, you'll see errors like:

```
Can't find train plugin mssql. Please install it first.
```

This indicates the `train-mssql` plugin needs to be installed on the InSpec runner host.

## Installation in AAP2 Execution Environment

For AAP2 execution environments, train plugins should be installed in the execution environment image:

### Option 1: Add to execution-environment.yml

```yaml
dependencies:
  galaxy: requirements.yml
  python: requirements.txt
  system: bindep.txt

additional_build_steps:
  append:
    - RUN gem install train-mssql train-oracle train-sybase
```

### Option 2: Pre-install on delegate host

If using a dedicated InSpec runner (delegate host), install plugins directly:

```bash
# On the InSpec runner host
gem install train-mssql train-oracle train-sybase

# Or using InSpec plugin manager
inspec plugin install train-mssql
inspec plugin install train-oracle
inspec plugin install train-sybase
```

## Related Documentation

- [InSpec Plugins](https://www.inspec.io/docs/reference/plugins/)
- [Train Transports](https://github.com/inspec/train)
- [DELEGATE_EXECUTION_FLOW.md](DELEGATE_EXECUTION_FLOW.md)
- [LOCAL_TESTING_GUIDE.md](LOCAL_TESTING_GUIDE.md)

## Troubleshooting

### Plugin not found after installation

```bash
# Check gem environment
gem environment

# Verify InSpec can see the plugin
inspec detect --backend mssql --help
```

### Permission errors

If you get permission errors during installation:

```bash
# Install as user (not root)
gem install --user-install train-mssql

# Or use sudo if installing system-wide
sudo gem install train-mssql
```

### Multiple Ruby versions

If you have multiple Ruby versions, ensure plugins are installed for the Ruby version InSpec uses:

```bash
# Check InSpec's Ruby version
inspec --version

# Check which Ruby InSpec uses
which inspec
head -1 $(which inspec)  # Shows Ruby shebang
```
