#!/usr/bin/env bash
set -euo pipefail

: "${DB_HOST:=bareos-db}"
: "${DB_PORT:=5432}"
: "${DB_NAME:=bareos}"
: "${DB_USER:=bareos}"
: "${DB_PASSWORD:=bareos}"
: "${DB_ADMIN_USER:=postgres}"
: "${DB_ADMIN_PASSWORD:=postgres}"
: "${DB_INIT:=true}"
: "${DB_UPDATE:=false}"

catalog_conf="/etc/bareos/bareos-dir.d/catalog/MyCatalog.conf"
storage_conf="/etc/bareos/bareos-dir.d/storage/File.conf"
client_conf="/etc/bareos/bareos-dir.d/client/bareos-fd.conf"
admin_conf="/etc/bareos/bareos-dir.d/console/admin.conf"

if [ -f "${catalog_conf}" ]; then
  sed -i '/^[[:space:]]*dbdriver[[:space:]]*=.*/d' "${catalog_conf}"
  sed -i "s#^[[:space:]]*dbname[[:space:]]*=.*#  dbname = \"${DB_NAME}\"#" "${catalog_conf}"
  sed -i "s#^[[:space:]]*dbaddress[[:space:]]*=.*#  dbaddress = \"${DB_HOST}\"#" "${catalog_conf}"
  sed -i "s#^[[:space:]]*dbport[[:space:]]*=.*#  dbport = \"${DB_PORT}\"#" "${catalog_conf}"
  sed -i "s#^[[:space:]]*dbuser[[:space:]]*=.*#  dbuser = \"${DB_USER}\"#" "${catalog_conf}"
  sed -i "s#^[[:space:]]*dbpassword[[:space:]]*=.*#  dbpassword = \"${DB_PASSWORD}\"#" "${catalog_conf}"
fi

if [ -f "${storage_conf}" ] && [ -n "${BAREOS_SD_HOST:-}" ]; then
  sed -i "s#^[[:space:]]*Address[[:space:]]*=.*#  Address = \"${BAREOS_SD_HOST}\"#" "${storage_conf}"
fi
if [ -f "${storage_conf}" ] && [ -n "${BAREOS_SD_PASSWORD:-}" ]; then
  sed -i "s#^[[:space:]]*Password[[:space:]]*=.*#  Password = \"${BAREOS_SD_PASSWORD}\"#" "${storage_conf}"
fi
if [ -f "${client_conf}" ] && [ -n "${BAREOS_FD_HOST:-}" ]; then
  sed -i "s#^[[:space:]]*Address[[:space:]]*=.*#  Address = \"${BAREOS_FD_HOST}\"#" "${client_conf}"
fi
if [ -f "${client_conf}" ] && [ -n "${BAREOS_FD_PASSWORD:-}" ]; then
  sed -i "s#^[[:space:]]*Password[[:space:]]*=.*#  Password = \"${BAREOS_FD_PASSWORD}\"#" "${client_conf}"
fi
if [ -f "${admin_conf}" ] && [ -n "${BAREOS_WEBUI_PASSWORD:-}" ]; then
  sed -i "s#^[[:space:]]*Password[[:space:]]*=.*#  Password = \"${BAREOS_WEBUI_PASSWORD}\"#" "${admin_conf}"
fi

if [[ -z ${CI_TEST:-} ]]; then
  until pg_isready --host="${DB_HOST}" --port="${DB_PORT}" --user="${DB_ADMIN_USER}"; do
    echo "Waiting for postgresql..."
    sleep 3
  done
fi

export PGUSER="${DB_ADMIN_USER}"
export PGHOST="${DB_HOST}"
export PGPASSWORD="${DB_ADMIN_PASSWORD}"
export PGPORT="${DB_PORT}"

if [ "${DB_INIT}" = "true" ]; then
  psql -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${DB_USER}') THEN
    CREATE ROLE "${DB_USER}" LOGIN CREATEDB CREATEROLE PASSWORD '${DB_PASSWORD}';
  ELSE
    ALTER ROLE "${DB_USER}" LOGIN PASSWORD '${DB_PASSWORD}';
  END IF;
END
\$\$;
SQL

  if ! psql -tAc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1; then
    psql -v ON_ERROR_STOP=1 -c "CREATE DATABASE \"${DB_NAME}\" OWNER \"${DB_USER}\";"
  fi

  /usr/lib/bareos/scripts/create_bareos_database 2>/dev/null || true
  /usr/lib/bareos/scripts/make_bareos_tables 2>/dev/null || true
  /usr/lib/bareos/scripts/grant_bareos_privileges 2>/dev/null || true
fi

if [ "${DB_UPDATE}" = "true" ]; then
  /usr/lib/bareos/scripts/update_bareos_tables 2>/dev/null || true
  /usr/lib/bareos/scripts/grant_bareos_privileges 2>/dev/null || true
fi

if id bareos >/dev/null 2>&1; then
  find /etc/bareos ! -user bareos -exec chown bareos {} \; || true
  chown -R bareos:bareos /var/lib/bareos || true
fi

exec "$@"
