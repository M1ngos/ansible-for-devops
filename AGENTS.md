# AGENTS.md

## Inventory

- `inventory.ini` is **gitignored** (contains live passwords). Never commit it.
- Copy `inventory-example.ini` to create a new one.
- All 21 servers use **custom SSH ports** (2201–7520) and `ansible_become=yes`.
- Current `ansible_user=andre`; some hosts like `dmz-portalveiculos` may need a different user.

## Running Playbooks

```bash
# Preferred: wrapper with auto-report generation
bash run-playbook.sh [path/to/playbook.yml] [inventory.ini]

# Manual equivalents
ansible-playbook system/docker.yml -i inventory.ini -v
ansible-playbook system/docker.yml -i inventory.ini --limit app1
ansible-playbook system/docker.yml -i inventory.ini --check
ansible-playbook system/docker.yml -i inventory.ini --syntax-check
```

The wrapper saves timestamped reports under `reports/<playbook>/run-<timestamp>.yml`.

## Playbooks

| Playbook | Purpose | Port |
|----------|---------|------|
| `system/docker.yml` | Install Docker Engine + Compose on Ubuntu | — |
| `system/crontab.yml` | Set up cron jobs | — |
| `system/rsync.yml` | Install rsync | — |
| `databases/mysql.yml` | Install MySQL Community Server 8.0.45 on Ubuntu | 3306 |
| `databases/metabase.yml` | Deploy Metabase BI container | 3000 |
| `databases/change-credentials/mysql-change-credentials.yml` | Change MySQL user credentials per host | — |
| `monitoring/prometheus.yml` | Deploy Prometheus container | 9090 |
| `monitoring/node-exporter.yml` | Remove Prometheus + deploy Node Exporter container | 9100 |
| `monitoring/grafana.yml` | Deploy Grafana container | 3001 |
| `web/nginx.yml` | Deploy Nginx container | 80 |
| `web/nginx-gestor-processos.yml` | Deploy Nginx for gestor-processos | 80 |
| `web/nginx-gestor-processos-externo.yml` | Deploy Nginx for gestor-processos-externo | 80 |
| `web/nginx-middleware-network.yml` | Deploy Nginx middleware network | 80 |
| `web/nginx-portal-funcionario.yml` | Deploy Nginx for portal-funcionario | 80 |
| `web/nginx-portal-utentes.yml` | Deploy Nginx for combined portals | 80 |
| `web/php-fpm.yml` | Install PHP-FPM and extensions | — |
| `web/php-fpm-purge.yml` | Remove PHP-FPM and extensions | — |

`system/docker.yml` has network connectivity prechecks (ping 8.8.8.8, DNS resolution) that will **fail** on minimal images missing `iputils-ping`. This is a known issue affecting 15/21 hosts (see `results/tracker.yml`).

## Reports & Tracking

```bash
bash results/status.sh                # quick status summary
results/tracker.yml                   # master run tracker (host status, known issues)
reports/<playbook>/run-YYMMDD-HHMM.yml  # detailed per-run reports
```

## Security

- Inventory contains plaintext passwords. Use `ansible-vault encrypt inventory.ini` for production.
- `docker.yml` adds `ansible_user` to the `docker` group (log out/in required).

## Post-Install Verification

```bash
# on target host
docker --version
docker compose version
docker run hello-world

# check container
docker ps --filter name=<prometheus|nginx>
```

## Miscellaneous

- `whereTO.md` is a stale scratch file (not part of any workflow). Ignore it.
- Nginx config notes in `docs/nginx-config-notes.md` document alternative config strategies.
