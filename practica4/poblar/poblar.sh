#!/bin/bash
# ============================================================
# Script de carga — Proyecto propio (Gestor académico ESCOM)
# Prácticas 4 y 5 — Bases de Datos
# ============================================================
# Requisitos:
#   - PostgreSQL 14+ en localhost:5432
#   - BD vacía: catscoms_p4 (o catscoms_p5)
#   - Variables de entorno: PG_USER, PG_PASS, PG_DB, PG_HOST
#
# Uso:
#   export PG_APP_PASS="clave_app"
#   bash poblar.sh
# ============================================================

set -e  # Salir en cualquier error

# Configuración
DB_HOST="${PG_HOST:-localhost}"
DB_PORT="${PG_PORT:-5432}"
DB_NAME="${PG_DB:-catscoms_p4}"
DB_USER="${PG_APP_USER:-app_user}"
DB_PASS="${PG_APP_PASS:-default_pass}"

SCHEMA_DIR="sql"
DATA_DIR="datos"
LOG_FILE="carga_$(date +%Y%m%d_%H%M%S).log"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
  echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
  exit 1
}

warning() {
  echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

# Verificaciones previas
log "=== Verificación de entorno ==="
command -v psql >/dev/null || error "psql no instalado"
log "✓ psql disponible"

if [ -z "$DB_PASS" ]; then
  warning "PG_APP_PASS no establecida; usando 'default_pass'"
fi

# Crear BD si no existe
log "=== Creación de BD ==="
export PGPASSWORD="${PG_ADMIN_PASS:-postgres}"
psql -h "$DB_HOST" -U postgres -lq | grep -q "^ *$DB_NAME" && {
  log "BD $DB_NAME ya existe; se asume vacía"
} || {
  log "Creando BD $DB_NAME..."
  createdb -h "$DB_HOST" -U postgres "$DB_NAME" || error "No se pudo crear BD"
  log "✓ BD creada"
}

# Usar contraseña de app_user
export PGPASSWORD="$DB_PASS"

# Crear extensiones
log "=== Extensiones ==="
psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" << EOF
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";  -- Para coordenadas (opcional)
\dt  -- Listar tablas (vacío ahora)
EOF
log "✓ Extensiones creadas"

# Ejecutar esquema base (Práctica 3)
log "=== Esquema base (Práctica 3) ==="
if [ -f "$SCHEMA_DIR/esquema.sql" ]; then
  log "Ejecutando $SCHEMA_DIR/esquema.sql..."
  psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" < "$SCHEMA_DIR/esquema.sql" || error "Fallo esquema.sql"
  log "✓ Esquema base completado"
else
  error "$SCHEMA_DIR/esquema.sql no encontrado"
fi

# Migraciones (Práctica 4 y 5)
log "=== Migraciones (dominios, FK) ==="
for migration in "$SCHEMA_DIR"/00*-*.sql; do
  if [ -f "$migration" ]; then
    log "Ejecutando $(basename "$migration")..."
    psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" < "$migration" || error "Fallo $(basename "$migration")"
  fi
done
log "✓ Migraciones completadas"

# Carga de datos
log "=== Carga de datos ==="
log "Iniciando carga..."

STMT_COUNT=0
ERROR_COUNT=0

# Helper para cargar CSV con COPY
load_csv() {
  local table=$1
  local file=$2

  if [ -f "$file" ]; then
    log "Cargando $table desde $file..."
    psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" << EOF
\SET ON_ERROR_ROLLBACK on
COPY $table FROM STDIN WITH (FORMAT csv, HEADER, DELIMITER ',');
EOF < "$file" || {
      ERROR_COUNT=$((ERROR_COUNT + 1))
      warning "Error al cargar $table"
    }
  fi
}

# Orden de carga (dimensiones primero)
psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" << 'SQL'
BEGIN;

-- Cargar dimensiones (sin FK a nada)
INSERT INTO carrera (nombre, plan_version, carga_minima, carga_media) VALUES
  ('Ingeniería en Sistemas Computacionales', '2020', 4, 7),
  ('Ingeniería en Inteligencia Artificial', '2020', 4, 6),
  ('Licenciatura en Ciencia de Datos', '2020', 4, 6);

INSERT INTO periodo (anio, semestre) VALUES
  (2025, 2), (2026, 1), (2026, 2), (2027, 1);

-- Cargar profesores (datos reales observables de SAESPEED)
INSERT INTO profesor (nombre, email, activo) VALUES
  ('HERNANDEZ LOPEZ CARLOS', 'carlos@escom.ipn.mx', TRUE),
  ('GARCIA BLANQUEL CLAUDIA', 'claudia@escom.ipn.mx', TRUE),
  ('BARRALES LOPEZ ANA LUZ', 'ana@escom.ipn.mx', TRUE),
  ('LUNA BENOSO BENJAMIN', 'benjamin@escom.ipn.mx', FALSE),
  ('MARQUEZ ARREGUIN GUILLERMO', 'guillermo@escom.ipn.mx', TRUE)
ON CONFLICT DO NOTHING;

-- Cargar materias (ISC obligatorias, muestra)
INSERT INTO materia (clave, nombre, creditos, semestre_sugerido, carrera_id, horas_teoria, horas_practica) VALUES
  ('C101', 'CALCULO MULTIVARIABLE', 9, 1, 1, 3, 2),
  ('C102', 'ALGEBRA LINEAL', 9, 1, 1, 3, 2),
  ('C103', 'ANALISIS VECTORIAL', 9, 2, 1, 3, 2),
  ('C301', 'BASES DE DATOS', 9, 3, 1, 3, 2),
  ('C401', 'SISTEMAS OPERATIVOS', 9, 4, 1, 3, 2)
ON CONFLICT (clave, carrera_id) DO NOTHING;

-- Cargar ramas de optativas (ISC)
INSERT INTO rama (nombre, carrera_id) VALUES
  ('CRIPTOGRAFIA', 1),
  ('BIG DATA', 1),
  ('SISTEMAS DISTRIBUIDOS', 1),
  ('DESARROLLO WEB', 1)
ON CONFLICT DO NOTHING;

-- Cargar grupos (ISC 2026/1, muestra)
INSERT INTO grupo (codigo, materia_id, profesor_id, turno, periodo_id, cupo, inscritos) VALUES
  ('1CM1', 1, 1, 'M', 2, 30, 28),
  ('1CM2', 2, 2, 'M', 2, 30, 29),
  ('1CV1', 1, 3, 'V', 2, 25, 24),
  ('3CM3', 4, 1, 'M', 2, 35, 33),
  ('4CM1', 5, 4, 'M', 2, 30, 25)
ON CONFLICT (codigo, periodo_id) DO NOTHING;

-- Cargar sesiones de horario
INSERT INTO sesion_horario (grupo_id, dia, hora_inicio, hora_fin, aula, edificio) VALUES
  (1, 'lunes', '07:00'::TIME, '08:30'::TIME, '1-101', 'Edificio 1'),
  (1, 'miercoles', '07:00'::TIME, '08:30'::TIME, '1-101', 'Edificio 1'),
  (1, 'viernes', '07:00'::TIME, '08:30'::TIME, '1-101', 'Edificio 1'),
  (2, 'martes', '08:30'::TIME, '10:00'::TIME, '2-204', 'Edificio 2'),
  (2, 'jueves', '08:30'::TIME, '10:00'::TIME, '2-204', 'Edificio 2')
ON CONFLICT DO NOTHING;

-- Cargar estudiantes (sintéticos, realistas)
INSERT INTO estudiante (matricula, nombre, email, carrera_id, semestre_actual, promedio, fecha_ingreso) VALUES
  ('2024001234', 'GARCIA LOPEZ JUAN', 'juan@escom.ipn.mx', 1, 3, 7.5, '2024-09-01'),
  ('2024001235', 'MORALES GARCIA LUPITA', 'lupita@escom.ipn.mx', 1, 3, 8.2, '2024-09-01'),
  ('2024001236', 'HERNANDEZ RODRIGUEZ CARLOS', 'carlos.h@escom.ipn.mx', 1, 3, 6.9, '2024-09-01'),
  ('2024001237', 'MARTINEZ SANCHEZ MARIA', 'maria@escom.ipn.mx', 1, 3, 8.8, '2024-09-01'),
  ('2024001238', 'LOPEZ TORRES FRANCISCO', 'francisco@escom.ipn.mx', 1, 3, 7.1, '2024-09-01')
ON CONFLICT (matricula) DO NOTHING;

-- Cargar inscripciones (cursa)
INSERT INTO cursa (estudiante_id, grupo_id, tipo, fecha_inscripcion, calificacion) VALUES
  (1, 1, 'regular', '2026-09-01'::DATE, 7.5),
  (1, 2, 'regular', '2026-09-01'::DATE, 8.0),
  (2, 1, 'regular', '2026-09-01'::DATE, 8.5),
  (3, 3, 'regular', '2026-09-01'::DATE, 6.5),
  (4, 2, 'regular', '2026-09-01'::DATE, 9.0)
ON CONFLICT (estudiante_id, grupo_id) DO NOTHING;

-- Cargar reseñas
INSERT INTO resena (estudiante_id, profesor_id, grupo_id, calidad, dificultad, recomiendan, fecha_resena) VALUES
  (1, 1, 1, 8, 4, 1, '2026-06-15'::DATE),
  (2, 2, 2, 9, 3, 1, '2026-06-15'::DATE),
  (3, 3, 3, 7, 5, 0, '2026-06-15'::DATE),
  (4, 1, 4, 8, 4, 1, '2026-06-15'::DATE)
ON CONFLICT DO NOTHING;

COMMIT;
SQL

log "✓ Datos insertados"

# Verificación
log "=== Verificación ==="
psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" << 'SQL'
SELECT '--- Conteos finales ---' AS info;
SELECT 'Carreras: ' || COUNT(*) FROM carrera;
SELECT 'Periodos: ' || COUNT(*) FROM periodo;
SELECT 'Profesores: ' || COUNT(*) FROM profesor;
SELECT 'Materias: ' || COUNT(*) FROM materia;
SELECT 'Grupos: ' || COUNT(*) FROM grupo;
SELECT 'Sesiones: ' || COUNT(*) FROM sesion_horario;
SELECT 'Estudiantes: ' || COUNT(*) FROM estudiante;
SELECT 'Inscripciones (cursa): ' || COUNT(*) FROM cursa;
SELECT 'Reseñas: ' || COUNT(*) FROM resena;

SELECT '--- Comprobación de integridad ---' AS info;
SELECT 'Huérfanos cursa.estudiante_id: ' || COUNT(*) FROM cursa WHERE estudiante_id NOT IN (SELECT id FROM estudiante);
SELECT 'Huérfanos cursa.grupo_id: ' || COUNT(*) FROM cursa WHERE grupo_id NOT IN (SELECT id FROM grupo);
SELECT 'Duplicados matricula: ' || COUNT(*) FROM (SELECT matricula FROM estudiante GROUP BY matricula HAVING COUNT(*) > 1) AS t;
SQL

log "✓ Integridad verificada"

# Resumen
log ""
log "=== Carga completada ==="
log "BD: $DB_NAME (host: $DB_HOST:$DB_PORT)"
log "Usuario: $DB_USER"
log "Errores: $ERROR_COUNT"
log "Log: $LOG_FILE"
log ""
log "Para ejecutar de nuevo: bash poblar.sh"
log "Para conectar: psql -h $DB_HOST -U $DB_USER -d $DB_NAME"
