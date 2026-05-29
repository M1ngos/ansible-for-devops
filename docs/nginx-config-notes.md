# Nginx Configuration Guide

The playbook deploys Nginx inside a Docker container. All configuration is done on the **host machine** — not inside the container. The directories under `/opt/nginx/` are volume-mounted into the container, so changes made on the host are immediately reflected.

## Volume Mounts

| Host path | Container path | Purpose |
|---|---|---|
| `/opt/nginx/conf/nginx.conf` | `/etc/nginx/nginx.conf` | Main Nginx config |
| `/opt/nginx/html/` | `/usr/share/nginx/html/` | Web content (served files) |
| `/opt/nginx/logs/` | `/var/log/nginx/` | Access and error logs |

---

## Serving Content

Drop files into `/opt/nginx/html/` on the target server. No restart needed — the volume is live.

```bash
# Copy a file to the server
scp -P <port> index.html user@<server-ip>:/opt/nginx/html/

# Or write directly on the server
ssh -p <port> user@<server-ip>
sudo cp mysite/* /opt/nginx/html/
```

---

## Editing the Config

SSH into the server and edit the config file on the host:

```bash
ssh -p <port> user@<server-ip>
sudo vi /opt/nginx/conf/nginx.conf
```

Validate before reloading:

```bash
docker exec nginx nginx -t
```

Reload without downtime:

```bash
docker exec nginx nginx -s reload
```

### Apply to all servers via Ansible

```bash
# Reload nginx on all servers
ansible all -i inventory.ini -m shell -a "docker exec nginx nginx -s reload"

# Single server
ansible all -i inventory.ini -m shell -a "docker exec nginx nginx -s reload" --limit app1
```

---

## Common Config Changes

### Reverse proxy

Replace the `location /` block in `/opt/nginx/conf/nginx.conf`:

```nginx
location / {
    proxy_pass http://<backend-ip>:<port>;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

Then reload:

```bash
docker exec nginx nginx -s reload
```

### SSL

Place your cert and key in `/opt/nginx/conf/` on the host. Reference them using the container-side path (`/etc/nginx/conf/`):

```nginx
server {
    listen 443 ssl;
    ssl_certificate     /etc/nginx/conf/fullchain.pem;
    ssl_certificate_key /etc/nginx/conf/privkey.pem;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
}
```

Then reload:

```bash
docker exec nginx nginx -s reload
```

### Change the listening port

Edit the `listen` directive in `/opt/nginx/conf/nginx.conf`, then re-run the playbook with the new port — Docker port bindings cannot be changed on a running container:

```bash
ansible-playbook nginx.yml -i inventory.ini -e "nginx_port=8080"
```

Note: the playbook currently hardcodes `80:80`. To make the port configurable, add a `nginx_port` variable to `nginx.yml` and replace the ports value with `"{{ nginx_port }}:80"`.

---

## Viewing Logs

Logs are written to `/opt/nginx/logs/` on the host:

```bash
tail -f /opt/nginx/logs/access.log
tail -f /opt/nginx/logs/error.log
```

Or via Docker:

```bash
docker logs nginx
docker logs -f nginx   # follow live output
```

---

## Container Management

```bash
# Check status
docker ps --filter name=nginx

# Stop / start / restart
docker stop nginx
docker start nginx
docker restart nginx
```

---

## Re-running the Playbook

The playbook is idempotent. Re-running it will overwrite `/opt/nginx/conf/nginx.conf` and `/opt/nginx/html/index.html` with the defaults defined in `nginx.yml`. Back up any custom config before re-running:

```bash
cp /opt/nginx/conf/nginx.conf /opt/nginx/conf/nginx.conf.bak
```
