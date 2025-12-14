# Local Testing Infrastructure - MacBook Setup

## Overview
This guide helps you set up local MSSQL databases on your MacBook using Docker to test the compliance scanning solution.

## Prerequisites
1. **Docker Desktop for Mac** - Download from https://www.docker.com/products/docker-desktop
2. **Homebrew** - Package manager for macOS
3. **InSpec** - Compliance automation framework

## Quick Setup

### 1. One-Command Setup
```bash
./test_local_setup.sh
```
This script will:
- Check Docker installation
- Start MSSQL containers (2017 & 2019)
- Create databases and scanning users
- Generate test inventory
- Check InSpec installation

### 2. Manual Installation (if needed)

#### Install InSpec
```bash
# Option 1: Via Homebrew (recommended)
brew install chef/chef/inspec

# Option 2: Direct download
curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec
```

#### Verify Installation
```bash
inspec --version
```

## Local Infrastructure

### MSSQL Containers
The setup creates two MSSQL Server containers:

**MSSQL 2019:**
- Container: `mssql2019_test`
- Host: `localhost`
- Port: `1433`
- Database: `TestDB2019`
- SA Password: `TestPassword123!`
- Scan User: `nist_scan_user` / `ScanPassword123!`

**MSSQL 2017:**
- Container: `mssql2017_test`
- Host: `localhost`
- Port: `1734` (mapped from 1433)
- Database: `TestDB2017`
- SA Password: `TestPassword456!`
- Scan User: `nist_scan_user` / `ScanPassword456!`

### Generated Files
- `local_databases.txt` - Flat file with connection details
- `local_inventory.yml` - Ansible inventory
- `local_vault.yml` - Unencrypted vault with passwords

## Testing the Solution

### 1. Start Infrastructure
```bash
./test_local_setup.sh
```

### 2. Run Compliance Scans
```bash
# Test with local databases
ansible-playbook -i local_inventory.yml run_mssql_inspec.yml -e @local_vault.yml

# Debug mode
ansible-playbook -i local_inventory.yml run_mssql_inspec.yml -e @local_vault.yml -e enable_debug=true -vv

# Test specific database
ansible-playbook -i local_inventory.yml run_mssql_inspec.yml -e @local_vault.yml --limit "localhost_TestDB2019_1433"
```

### 3. View Results
```bash
# Check results directory
ls -la /tmp/compliance_scans/

# View specific results
cat /tmp/compliance_scans/*/MSSQL_NIST_*_*.json
```

## Manual Testing Commands

### Connect to Databases
```bash
# MSSQL 2019
docker exec -it mssql2019_test /opt/mssql-tools/bin/sqlcmd -S localhost -U nist_scan_user -P 'ScanPassword123!'

# MSSQL 2017
docker exec -it mssql2017_test /opt/mssql-tools/bin/sqlcmd -S localhost -U nist_scan_user -P 'ScanPassword456!'
```

### Test InSpec Controls Manually
```bash
# Test a single control file
inspec exec mssql_inspec/files/MSSQL2019_ruby/trusted.rb \
  --input usernm=nist_scan_user passwd=ScanPassword123! hostnm=localhost port=1433 \
  --reporter=json-min --no-color
```

### Monitor Containers
```bash
# View container status
docker-compose ps

# View logs
docker-compose logs -f

# Check resource usage
docker stats
```

## Troubleshooting

### Common Issues

**1. Port Already in Use**
```bash
# Check what's using port 1433
lsof -i :1433

# Stop conflicting services
sudo launchctl unload -w /System/Library/LaunchDaemons/com.microsoft.sqlserver.plist
```

**2. Container Won't Start**
```bash
# Check Docker resources
docker system df

# Restart Docker Desktop
# Clean up old containers
docker system prune -a
```

**3. SQL Connection Failures**
```bash
# Test connection manually
docker exec -it mssql2019_test /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'TestPassword123!' -Q "SELECT 1"

# Check container health
docker-compose ps
```

**4. InSpec Not Found**
```bash
# Add to PATH if needed
export PATH="/opt/inspec/bin:$PATH"

# Or use full path
/opt/inspec/bin/inspec --version
```

## Performance Considerations

### Resource Requirements
- **RAM**: 4GB minimum for both containers
- **Disk**: 2GB for container images and data
- **CPU**: 2 cores recommended

### Optimization
```bash
# Limit container resources
docker update --memory=2g --cpus=1 mssql2019_test
docker update --memory=2g --cpus=1 mssql2017_test
```

## Cleanup

### Complete Cleanup
```bash
./cleanup_test_infra.sh
```

### Manual Cleanup
```bash
# Stop containers
docker-compose down -v

# Remove test files
rm -f local_*.yml local_databases.txt

# Clean results
rm -rf /tmp/compliance_scans
```

## Integration with Main Solution

This local setup exactly mirrors the production workflow:

1. **Flat File Input** - Same 6-field format
2. **Inventory Generation** - Same conversion process
3. **Vault Management** - Same password structure
4. **Playbook Execution** - Same Ansible commands
5. **Results Format** - Same JSON output structure

The only differences are:
- Local Docker containers vs remote MSSQL servers
- Unencrypted vault vs encrypted vault
- Test passwords vs production credentials

## Next Steps

After successful local testing:
1. Test with encrypted vault: `ansible-vault encrypt local_vault.yml`
2. Test with production-like credentials
3. Validate result forwarding to Splunk (if available)
4. Test with larger database inventories
5. Deploy to AAP environment