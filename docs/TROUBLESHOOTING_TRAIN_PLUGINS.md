# Troubleshooting InSpec Train Plugin Issues

## Problem: "Can't find train plugin mssql"

This error occurs when InSpec cannot locate the required train plugin, even though it works when you run InSpec manually on the delegate host.

### Root Cause

The issue is typically caused by **environment differences** between:
1. **Your manual shell session**: Has proper Ruby gem paths configured
2. **Ansible's delegated shell**: May not have access to the same gem installation paths

### Diagnostic Steps

#### Step 1: Verify plugin installation for different users

On the delegate host, check plugin visibility:

```bash
# As your user
/usr/bin/inspec plugin list

# As root (how Ansible might run)
sudo /usr/bin/inspec plugin list

# Check which Ruby InSpec is using
/usr/bin/inspec --version
head -1 $(which /usr/bin/inspec)
```

#### Step 2: Check plugin installation

```bash
# IMPORTANT: Use 'inspec plugin list' instead of 'gem list'
# Enterprise InSpec bundles plugins as system plugins that won't appear in gem list

# Check installed plugins (correct method)
inspec plugin list | grep train

# Example output for Enterprise InSpec:
# train-winrm  0.2.13  gem (system)  train-1
# train-aws    0.2.0   gem (system)  train-1

# For comparison, check gem environment
gem environment

# NOTE: 'gem list | grep train' only shows standalone gem installs,
# NOT plugins bundled with Enterprise InSpec (shown as "gem (system)")
```

#### Step 3: Test InSpec execution with explicit paths

```bash
# Test without sudo (your manual test)
/usr/bin/inspec exec /path/to/control.rb --input usernm=test passwd=test hostnm=host port=1433

# Test with sudo (simulating Ansible's root execution)
sudo /usr/bin/inspec exec /path/to/control.rb --input usernm=test passwd=test hostnm=host port=1433

# Test with explicit gem path
sudo GEM_HOME=/home/youruser/.gem/ruby/3.0.0 GEM_PATH=/home/youruser/.gem/ruby/3.0.0:/usr/local/lib/ruby/gems/3.0.0 /usr/bin/inspec exec /path/to/control.rb
```

### Solution Options

#### Option 1: Install train plugins system-wide (Recommended)

```bash
# Install as root so all users can access
sudo gem install train-mssql train-oracle train-sybase

# Or use InSpec plugin manager as root
sudo /usr/bin/inspec plugin install train-mssql
sudo /usr/bin/inspec plugin install train-oracle
sudo /usr/bin/inspec plugin install train-sybase

# Verify system-wide installation
sudo /usr/bin/inspec plugin list
```

#### Option 2: Configure Ansible to use user's gem path

Add environment variables to the execution tasks. Update `roles/*/tasks/execute.yml`:

```yaml
- name: Get gem environment from target
  shell: gem environment | grep -E "GEM HOME|GEM PATH"
  register: gem_env
  delegate_to: "{{ inspec_execution_target }}"
  changed_when: false

- name: Parse gem paths
  set_fact:
    gem_home: "{{ gem_env.stdout_lines | select('search', 'GEM HOME') | first | regex_replace('.*: (.*)$', '\\1') }}"
    gem_path: "{{ gem_env.stdout_lines | select('search', 'GEM PATH') | first | regex_replace('.*: (.*)$', '\\1') }}"

- name: Execute InSpec controls
  shell: |
    /usr/bin/inspec exec {{ item.path }} \
      --input usernm="$INSPEC_DB_USERNAME" \
              passwd="$INSPEC_DB_PASSWORD" \
              hostnm="$INSPEC_DB_HOST" \
              servicenm="$INSPEC_DB_SERVICE" \
              port="$INSPEC_DB_PORT" \
      --reporter=json-min \
      --no-color
  environment:
    PATH: "{{ mssql_environment.PATH }}"
    LD_LIBRARY_PATH: "{{ mssql_environment.LD_LIBRARY_PATH }}"
    GEM_HOME: "{{ gem_home }}"
    GEM_PATH: "{{ gem_path }}"
    # ... other vars
```

#### Option 3: Use become_user to run as the user who has plugins

```yaml
- name: Execute InSpec controls
  shell: |
    /usr/bin/inspec exec {{ item.path }} ...
  become: yes
  become_user: youruser  # User who has train plugins installed
  delegate_to: "{{ inspec_execution_target }}"
```

#### Option 4: Install in execution environment (AAP2)

If using AAP2 execution environments, build plugins into the image:

```dockerfile
# In execution-environment.yml or Containerfile
RUN gem install train-mssql train-oracle train-sybase
```

### Quick Test Playbook

Create `test_train_plugin.yml` to diagnose the issue:

```yaml
---
- name: Test InSpec Train Plugin Access
  hosts: your_delegate_host
  gather_facts: yes
  tasks:
    - name: Test 1 - InSpec version
      command: /usr/bin/inspec --version
      register: inspec_ver
      
    - name: Test 2 - List plugins
      command: /usr/bin/inspec plugin list
      register: inspec_plugins
      
    - name: Test 3 - Check gem environment
      command: gem environment
      register: gem_env
      
    - name: Test 4 - List train gems
      command: gem list train
      register: train_gems
      
    - name: Test 5 - Same test with sudo
      command: sudo /usr/bin/inspec plugin list
      register: inspec_plugins_sudo
      
    - name: Display all results
      debug:
        msg: |
          InSpec Version: {{ inspec_ver.stdout }}
          
          Plugins (normal):
          {{ inspec_plugins.stdout }}
          
          Plugins (sudo):
          {{ inspec_plugins_sudo.stdout }}
          
          Gem Environment:
          {{ gem_env.stdout }}
          
          Train Gems:
          {{ train_gems.stdout }}
```

Run it:
```bash
ansible-playbook test_train_plugin.yml -i inventories/production/hosts.yml --limit your_delegate_host
```

### Verification After Fix

Once you've applied a solution, verify:

```bash
# On delegate host - use 'inspec plugin list' (NOT gem list)
sudo /usr/bin/inspec plugin list | grep -E "train-mssql|train-oracle|train-sybase|train-winrm"

# Expected output for Enterprise InSpec (bundled plugins):
# train-winrm   0.2.13  gem (system)  train-1

# Expected output for Community InSpec (installed plugins):
# train-mssql   0.x.x   gem (user)
# train-oracle  0.x.x   gem (user)

# NOTE: Enterprise InSpec shows "gem (system)" for bundled plugins
# Community InSpec shows "gem (user)" for manually installed plugins
# Both are detected correctly via 'inspec plugin list'

# Test actual control execution
sudo /usr/bin/inspec exec /tmp/ansible.*/MSSQL2019_ruby/trusted.rb \
  --input usernm=testuser passwd=testpass hostnm=testhost port=1433 \
  --reporter json-min
```

### Common Mistakes

1. **Installing plugins as user, running Ansible as root**
   - Solution: Install as root/system-wide

2. **Multiple Ruby versions**
   - InSpec might be using a different Ruby than where you installed gems
   - Solution: Check `which ruby` vs InSpec's shebang

3. **Ansible SSH user != manual test user**
   - Manual test: You use your user with gems in `~/.gem`
   - Ansible: Uses `ansible_user` from inventory who may not have gems
   - Solution: Install system-wide or use become_user

4. **SELinux/AppArmor restrictions**
   - May prevent accessing user-specific gem paths
   - Solution: Install system-wide or adjust security policies

### Related Documentation

- [INSPEC_TRAIN_PLUGINS.md](INSPEC_TRAIN_PLUGINS.md) - Plugin installation guide
- [DELEGATE_EXECUTION_FLOW.md](DELEGATE_EXECUTION_FLOW.md) - Execution flow details
- [LOCAL_TESTING_GUIDE.md](LOCAL_TESTING_GUIDE.md) - Local testing procedures
