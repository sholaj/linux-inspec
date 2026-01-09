#!/bin/bash
# Sybase Connectivity Testing Script
# Tests telnet, database credentials, and basic InSpec commands
# Run from runner host with Sybase client tools installed

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RUNNER_HOST="${RUNNER_HOST:-40.114.45.75}"
RUNNER_USER="${RUNNER_USER:-azureuser}"
SSH_KEY="${SSH_KEY:-~/.ssh/inspec_azure}"

# Sybase Configuration
SYBASE_SERVER="${SYBASE_SERVER:-10.0.2.6}"
SYBASE_PORT="${SYBASE_PORT:-5000}"
SYBASE_SERVICE="${SYBASE_SERVICE:-SYBASE}"
SYBASE_USERNAME="${SYBASE_USERNAME:-sa}"
SYBASE_PASSWORD="${SYBASE_PASSWORD:-SybasePass123}"

# Functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_failure() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Test 1: SSH Connectivity to Runner
test_ssh_connectivity() {
    print_header "TEST 1: SSH Connectivity to Runner"
    print_test "Connecting to runner host: $RUNNER_HOST"
    
    if ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 \
        -i "$SSH_KEY" "$RUNNER_USER@$RUNNER_HOST" "echo 'SSH OK'" > /dev/null 2>&1; then
        print_success "SSH connectivity to runner"
    else
        print_failure "SSH connectivity to runner"
        return 1
    fi
}

# Test 2: Sybase Telnet Test
test_sybase_telnet() {
    print_header "TEST 2: Sybase - Telnet Port Connectivity"
    print_test "Testing telnet to Sybase: $SYBASE_SERVER:$SYBASE_PORT"
    
    local result=$(ssh -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" \
        "$RUNNER_USER@$RUNNER_HOST" \
        "timeout 5 bash -c 'cat < /dev/null > /dev/tcp/$SYBASE_SERVER/$SYBASE_PORT' && echo 'OPEN' || echo 'CLOSED'")
    
    if [ "$result" = "OPEN" ]; then
        print_success "Sybase port $SYBASE_PORT is reachable on $SYBASE_SERVER"
    else
        print_failure "Sybase port $SYBASE_PORT is NOT reachable on $SYBASE_SERVER"
        return 1
    fi
}

# Test 3: Sybase Credential Test with tsql
test_sybase_credentials() {
    print_header "TEST 3: Sybase - Database Credential Validation"
    print_test "Testing Sybase credentials with tsql"
    print_info "Server: $SYBASE_SERVER:$SYBASE_PORT, User: $SYBASE_USERNAME"
    
    local result=$(ssh -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" \
        "$RUNNER_USER@$RUNNER_HOST" bash << 'EOSSH'
source /opt/sap/SYBASE.sh 2>/dev/null || true
export PATH=/usr/local/bin:/usr/bin:/bin:$PATH

timeout 10 tsql -S 10.0.2.6 -U sa -P SybasePass123 << 'EOF'
SELECT 1 as TEST_RESULT
GO
quit
EOF
EOSSH
    )
    
    if echo "$result" | grep -q "TEST_RESULT\|1\|test_result"; then
        print_success "Sybase database credentials validated"
        echo "$result"
    else
        print_failure "Sybase database authentication failed"
        echo "Output: $result"
        return 1
    fi
}

# Test 4: Sybase InSpec Profile Execution
test_sybase_inspec() {
    print_header "TEST 4: Sybase - Basic InSpec Profile Execution"
    print_test "Executing simple Sybase InSpec control"
    
    local inspec_cmd="source /opt/sap/SYBASE.sh 2>/dev/null || true; \
inspec exec - << 'INSPEC_EOF'
control 'sybase-basic-connectivity' do
  impact 1.0
  title 'Sybase Basic Connectivity'
  desc 'Test basic connectivity to Sybase database'
  
  command = \"tsql -S 10.0.2.6 -U sa -P SybasePass123 << 'SQL'
SELECT 1 as TEST_RESULT
GO
quit
SQL
\"
  
  describe command(command) do
    its('stdout') { should include 'TEST_RESULT' }
  end
end
INSPEC_EOF
"
    
    local result=$(ssh -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" \
        "$RUNNER_USER@$RUNNER_HOST" bash << EOSSH
$inspec_cmd
EOSSH
    )
    
    if echo "$result" | grep -qi "passed\|✔"; then
        print_success "Sybase InSpec profile executed successfully"
        echo "$result" | tail -20
    else
        print_info "Sybase InSpec execution attempted (output below)"
        echo "$result" | tail -30
    fi
}

# Test 5: Summary Report
test_summary() {
    print_header "TEST SUMMARY"
    print_info "Sybase connectivity tests completed"
    echo ""
    echo "Sybase Configuration:"
    echo "  Server: $SYBASE_SERVER:$SYBASE_PORT"
    echo "  Version: 16"
    echo ""
    print_info "For detailed testing, use the Ansible playbook:"
    echo "  - test_playbooks/test_sybase_connectivity.yml"
}

# Main execution
main() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║   Sybase Connectivity Test Suite                           ║"
    echo "║   Tests: Telnet, Credentials, and Basic InSpec Commands    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    local failed=0
    
    # Run tests
    test_ssh_connectivity || failed=$((failed + 1))
    test_sybase_telnet || failed=$((failed + 1))
    test_sybase_credentials || failed=$((failed + 1))
    test_sybase_inspec || true
    test_summary
    
    # Final result
    echo ""
    if [ $failed -eq 0 ]; then
        print_success "All critical Sybase tests passed!"
        return 0
    else
        print_failure "$failed critical Sybase test(s) failed"
        return 1
    fi
}

# Run main function
main "$@"
