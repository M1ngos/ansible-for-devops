# Docker & Container Services with Ansible

This project automates the installation of Docker Engine, Docker Compose, and containerized services (Prometheus, Nginx) on Ubuntu servers using Ansible.

## Files

- **docker.yml** - Ansible playbook that installs Docker and Docker Compose
- **prometheus.yml** - Ansible playbook that deploys Prometheus as a Docker container
- **nginx.yml** - Ansible playbook that deploys Nginx as a Docker container
- **nginx-config-notes.md** - Documentation on Nginx configuration handling approaches
- **inventory.ini** - Inventory file containing server list and connection details (21 servers with custom SSH ports)

## Prerequisites

- Ansible installed on your local machine
- Ubuntu servers (target machines)
- SSH access to the servers (with custom ports supported)
- Sudo privileges on the servers

### Install Ansible

```bash
# On Ubuntu/Debian
sudo apt update
sudo apt install ansible

# On macOS
brew install ansible
```

## Available Playbooks

### 1. Docker Installation (docker.yml)
Installs Docker Engine and Docker Compose on Ubuntu servers.

```bash
ansible-playbook docker.yml -i inventory.ini
```

### 2. Prometheus (prometheus.yml)
Deploys Prometheus monitoring as a Docker container.

- Config location: `/opt/prometheus/prometheus.yml`
- Data location: `/opt/prometheus/data`
- Web UI: `http://<server-ip>:9090`

```bash
ansible-playbook prometheus.yml -i inventory.ini
```

### 3. Nginx (nginx.yml)
Deploys Nginx web server as a Docker container.

- Config location: `/opt/nginx/conf/nginx.conf`
- HTML files: `/opt/nginx/html/`
- Logs: `/opt/nginx/logs/`
- Web UI: `http://<server-ip>:80`

```bash
ansible-playbook nginx.yml -i inventory.ini
```

See `nginx-config-notes.md` for configuration management options.

## Configuration

### inventory.ini

The inventory file contains your server list with custom SSH ports for each server:

```ini
[servers]
app1 ansible_host=10.23.5.11 ansible_port=2201
app2 ansible_host=10.23.5.12 ansible_port=2202
app3 ansible_host=10.23.5.31 ansible_port=2203
... (21 servers total)
```

**Server Naming**: You can use any alias (app1, web1, db1, etc.) - the `ansible_host` and `ansible_port` are what matter for connections.

**Common Variables** (applied to all servers):
- `ansible_user` - SSH username
- `ansible_port` - Custom SSH port per server
- `ansible_become` - Enable privilege escalation
- `ansible_ssh_common_args` - SSH options (StrictHostKeyChecking disabled)

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

### Deploy Prometheus

```bash
ansible-playbook prometheus.yml -i inventory.ini
```

### Deploy Nginx

```bash
ansible-playbook nginx.yml -i inventory.ini
```

### Run on specific servers

```bash
# Single server
ansible-playbook docker.yml -i inventory.ini --limit app1

# Multiple servers
ansible-playbook docker.yml -i inventory.ini --limit app1,app2,app3

# Server group (if using groups)
ansible-playbook docker.yml -i inventory.ini --limit web_servers
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
ssh adilsongomes@10.23.5.11
docker --version
docker compose version
docker run hello-world
```

3. Verify Prometheus (after running prometheus.yml):

```bash
# Check container status
docker ps --filter name=prometheus

# Access web UI at http://<server-ip>:9090
```

4. Verify Nginx (after running nginx.yml):

```bash
# Check container status
docker ps --filter name=nginx

# Access web UI at http://<server-ip>:80
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
