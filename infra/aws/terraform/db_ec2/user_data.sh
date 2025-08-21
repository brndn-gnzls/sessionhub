#!/bin/bash
set -euo pipefail

DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"
VPC_CIDR="${VPC_CIDR}"

export DEBIAN_FRONTEND=noninteractive

# Basic updates
apt-get update -y
apt-get upgrade -y
apt-get install -y gnupg ca-certificates lsb-release curl jq rsync

# --- PostgreSQL 16 from PGDG ---
# Official PG Ubuntu page indicates Ubuntu ships a version, but we prefer PGDG for currency.
# Add the PGDG repo and key, then install PostgreSQL 16.
# :contentReference[oaicite:4]{index=4}
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor >/usr/share/keyrings/postgresql.gpg
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
  >/etc/apt/sources.list.d/pgdg.list
apt-get update -y
apt-get install -y postgresql-16

# Ensure Postgres starts at boot
systemctl enable postgresql

# --- Configure Postgres to listen only on localhost (force external clients through PgBouncer) ---
PGCONF="/etc/postgresql/16/main/postgresql.conf"
PGHBA="/etc/postgresql/16/main/pg_hba.conf"

sed -i "s/^#*listen_addresses.*/listen_addresses = '127.0.0.1'/g" "$PGCONF"
# Local access for Postgres and PgBouncer, and allow VPC CIDR *only via PgBouncer* later.
# Keep HBA strict: local md5 for app user; (scram also works if you prefer).
echo "local   all             all                                     md5" > "$PGHBA"
echo "host    all             all             127.0.0.1/32            md5" >> "$PGHBA"

# Initialize DB & create role/db
systemctl restart postgresql
sudo -u postgres psql -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${DB_USER}') THEN
      CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASSWORD}';
   END IF;
END\$\$;
CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
SQL

# --- PgBouncer install & config ---
apt-get install -y pgbouncer

# pgbouncer.ini
cat >/etc/pgbouncer/pgbouncer.ini <<'INI'
[databases]
; Route all connections to local Postgres
* = host=127.0.0.1 port=5432 dbname=postgres

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 6432
unix_socket_dir = /var/run/postgresql
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
server_reset_query = DISCARD ALL
max_client_conn = 1000
default_pool_size = 20
ignore_startup_parameters = extra_float_digits
log_connections = 1
log_disconnections = 1
admin_users = postgres
INI
# :contentReference[oaicite:5]{index=5}

# userlist.txt
echo "\"${DB_USER}\" \"${DB_PASSWORD}\"" >/etc/pgbouncer/userlist.txt
chown postgres:postgres /etc/pgbouncer/userlist.txt
chmod 600 /etc/pgbouncer/userlist.txt

# Allow PgBouncer from VPC CIDR; Postgres listens only on localhost.
# PgBouncer doesn’t use pg_hba; it authenticates via userlist.txt. The SG already restricts to Lambda SG.
# If you later want to allow your laptop temporarily: open SG rule for your IP on 6432.
systemctl enable pgbouncer
systemctl restart pgbouncer

# --- Optional: install & start the SSM agent for Session Manager ---
snap install amazon-ssm-agent --classic || true
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent || true
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent || true