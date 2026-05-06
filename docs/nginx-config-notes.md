# Nginx Config Handling Notes

## Current Approach (in nginx.yml)
- Static `nginx.conf` is copied to `/opt/nginx/conf/` on the host
- Config is mounted as a volume into the container: `/opt/nginx/conf/nginx.conf:/etc/nginx/nginx.conf`
- To update: Edit the config file on the host, then reload nginx

## Config Update Workflow
```bash
# Edit config on target server
ssh user@server "vi /opt/nginx/conf/nginx.conf"

# Reload nginx without downtime
ansible servers -i inventory.ini -m shell -a "docker exec nginx nginx -s reload"
```

## Alternative Approaches

### 1. Ansible Template (Dynamic Config)
Use Jinja2 templates for environment-specific configs:
```yaml
- name: Generate nginx config from template
  template:
    src: nginx.conf.j2
    dest: "{{ nginx_dir }}/conf/nginx.conf"
    mode: '0644'
  notify: Reload nginx
```

### 2. Config Site Separately
Store site configs in a `sites-available/` directory:
```yaml
- name: Create sites directory
  file:
    path: "{{ nginx_dir }}/sites-available"
    state: directory

- name: Copy site config
  copy:
    src: files/my-site.conf
    dest: "{{ nginx_dir }}/sites-available/"
```

### 3. Sensitive Config Handling
For SSL certs/keys, use Ansible Vault:
```bash
ansible-vault encrypt nginx.conf
ansible-playbook nginx.yml -i inventory.ini --ask-vault-pass
```

## Recommended Next Steps
1. Use Ansible templates for multi-environment configs
2. Store custom configs in a `files/` directory
3. Add handlers to auto-reload nginx on config change
