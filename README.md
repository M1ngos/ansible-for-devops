# Docker & Container Services with Ansible

This project automates the installation of Docker Engine, Docker Compose, and containerized services (Prometheus, Nginx) on Ubuntu servers using Ansible.

## Files

- **docker.yml** - Ansible playbook that installs Docker and Docker Compose
- **prometheus.yml** - Ansible playbook that deploys Prometheus as a Docker container
- **nginx.yml** - Ansible playbook that deploys Nginx as a Docker container
- **nginx-config-notes.md** - Documentation on Nginx configuration handling approaches
- **mysql.yml** - Ansible playbook that installs MySQL 8.0 and configures remote access
- **mysql-change-credentials.yml** - Ansible playbook to update MySQL user credentials per host
- **host_vars/** - Per-host variable files (used by mysql-change-credentials.yml)
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
... 
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
ssh user@10.23.5.11
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

## Report & Tracking System

After each playbook run, update the tracking files:

- **results/tracker.yml** - Host status (success/failed/unreachable) and common issues
- **reports/docker/run-YYYYMMDD-HHMM.yml** - Detailed reports per run
- **results/status.sh** - Quick status viewer

```bash
# View quick status
bash results/status.sh

# After a run, update tracker with results
vi results/tracker.yml
```

See `reports/README.md` for full documentation.

---

## MySQL Playbooks

### 4. MySQL Installation (mysql.yml)

Installs MySQL Community Server 8.0 on Ubuntu servers, configures remote access, and creates a named database per host.

```bash
ansible-playbook mysql.yml -i inventory.ini
```

**What it does:**
- Installs `mysql-server-8.0` and `mysql-client-8.0`
- Starts and enables the MySQL service
- Configures MySQL to listen on all interfaces (`bind-address = 0.0.0.0`)
- Allows port 3306 in UFW (skipped if UFW is not installed)
- Creates a database named after the inventory hostname
- Creates a remote user with full privileges

**Variables** (set in `mysql.yml` vars section):

| Variable | Default | Description |
|---|---|---|
| `mysql_bind_address` | `0.0.0.0` | Interface MySQL listens on |
| `mysql_port` | `3306` | MySQL port |
| `mysql_remote_user` | `remote_admin` | Remote user to create |
| `mysql_remote_password` | *(set in file)* | Remote user password |

---

### 5. MySQL Change Credentials (mysql-change-credentials.yml)

Changes MySQL user credentials per host. Each host can have different new credentials defined in its own `host_vars` file. **Idempotent** — skips hosts where credentials are already up to date.

#### Setup: host_vars

Create a file for each host under `host_vars/<hostname>.yml`:

```yaml
# host_vars/bd-replica.yml
mysql_user: "remote_admin"        # current username
mysql_new_username: "remote_admin" # new username (can be same to keep it)
mysql_new_password: "newpassword"  # new password
```

The filename must match the host alias in your inventory exactly.

#### Run on all hosts

```bash
ansible-playbook mysql-change-credentials.yml -i inventory.ini
```

#### Run on a single host

```bash
ansible-playbook mysql-change-credentials.yml -i inventory.ini --limit bd-replica
```

#### How idempotency works

1. Tries logging in with the **new** credentials first
2. If login succeeds → credentials already updated, **all steps skipped**
3. If login fails → checks old user exists, renames if needed, then changes password

#### Notes

- Passwords are never printed in output (`no_log: true`)
- Renaming is skipped if `mysql_new_username` equals `mysql_user`
- Safe to re-run any number of times

---

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
