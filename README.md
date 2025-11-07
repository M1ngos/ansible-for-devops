# Docker Installation with Ansible

This project automates the installation of Docker Engine and Docker Compose on Ubuntu servers using Ansible.

## Files

- **docker.yml** - Ansible playbook that installs Docker and Docker Compose
- **inventory.ini** - Inventory file containing server list and connection details

## Prerequisites

- Ansible installed on your local machine
- Ubuntu servers (target machines)
- SSH access to the servers
- Sudo privileges on the servers

### Install Ansible

```bash
# On Ubuntu/Debian
sudo apt update
sudo apt install ansible

# On macOS
brew install ansible
```

## Configuration

### inventory.ini

The inventory file contains your server list and connection settings:

```ini
[servers]
server1 ansible_host=10.23.202.29 ansible_connection=ssh
server2 ansible_host=10.23.202.30 ansible_connection=ssh

[servers:vars]
ansible_user=adgomes
ansible_password='%!AGm$#2o25'
ansible_become=yes
ansible_become_user=root
ansible_become_pass='%!AGm$#2o25'
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3
```

To add more servers, simply add new lines under `[servers]`:

```ini
[servers]
server1 ansible_host=10.23.202.29 ansible_connection=ssh
server2 ansible_host=10.23.202.30 ansible_connection=ssh
server3 ansible_host=10.23.202.31 ansible_connection=ssh
```

### docker.yml

The playbook performs the following tasks:

1. Updates apt package cache
2. Installs required system packages
3. Adds Docker's official GPG key
4. Adds Docker's apt repository
5. Installs Docker Engine (docker-ce, docker-ce-cli, containerd.io)
6. Installs Docker Compose plugin and buildx plugin
7. Starts and enables Docker service
8. Adds the user to the docker group
9. Verifies installation

## Usage

### Install Docker on all servers

```bash
ansible-playbook docker.yml -i inventory.ini
```

### Install Docker on specific servers

```bash
# Single server
ansible-playbook docker.yml -i inventory.ini --limit server1

# Multiple servers
ansible-playbook docker.yml -i inventory.ini --limit server1,server2
```

### Check playbook syntax

```bash
ansible-playbook docker.yml -i inventory.ini --syntax-check
```

### Dry run (check mode)

```bash
ansible-playbook docker.yml -i inventory.ini --check
```

### Verbose output

```bash
ansible-playbook docker.yml -i inventory.ini -v   # verbose
ansible-playbook docker.yml -i inventory.ini -vv  # more verbose
ansible-playbook docker.yml -i inventory.ini -vvv # very verbose
```

## Post-Installation

After the playbook completes:

1. Users need to log out and back in for docker group membership to take effect
2. Verify Docker is working:

```bash
ssh adgomes@10.23.202.29
docker --version
docker compose version
docker run hello-world
```

## Security Notes

- The inventory file contains passwords in plain text
- Consider using Ansible Vault to encrypt sensitive data:

```bash
# Encrypt inventory file
ansible-vault encrypt inventory.ini

# Run playbook with encrypted inventory
ansible-playbook docker.yml -i inventory.ini --ask-vault-pass
```

## Troubleshooting

### Connection issues

```bash
# Test connectivity
ansible servers -i inventory.ini -m ping

# Test with verbose output
ansible servers -i inventory.ini -m ping -vvv
```

### Docker service not starting

```bash
# Check Docker service status
ansible servers -i inventory.ini -m shell -a "systemctl status docker"

# Check Docker logs
ansible servers -i inventory.ini -m shell -a "journalctl -u docker -n 50"
```

## What Gets Installed

- **Docker Engine** - Latest stable version from Docker's official repository
- **Docker CLI** - Command-line interface for Docker
- **containerd** - Container runtime
- **Docker Compose** - Plugin for defining multi-container applications
- **Docker Buildx** - Plugin for extended build capabilities

## License

This project is provided as-is for infrastructure automation purposes.
