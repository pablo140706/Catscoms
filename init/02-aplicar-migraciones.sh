#!/bin/sh
# =====================================================================
#  02 · Aplica las migraciones numeradas, en orden
# =====================================================================
#  Lo corre solo el contenedor de Postgres la primera vez (cuando el
#  volumen está vacío), después de 00 y 01. Cada migración es un archivo
#  de migraciones/ (001-…, 002-…) y va en su propia transacción.
# =====================================================================
set -e
for f in /migraciones/*.sql; do
    echo "== Aplicando migración $(basename "$f")"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$f"
done
