# Prácticas 4 y 5 — Bases de Datos (ISC 2026)

## Descripción

Implementación de una base de datos relacional para un **Gestor académico ESCOM** (proyecto propio) y análisis de integridad referencial en un almacén de datos de **Sismos** (proyecto asignado).

**Equipos:**
- Estrada Sánchez Emiliano
- Mora Acosta Pablo
- Espinosa Gómez David Enrique

---

## Estructura de entrega

```
practica4/
  dominios.md              ← Tipos de dato, CREATE DOMAIN, justificaciones
  fuente.md                ← Referencias APA, problemas encontrados, soluciones
  pruebas-dominio.md       ← 10 casos de violación de restricciones
  permisos.md              ← 3 roles (app, consulta, admin), GRANT/REVOKE, matriz
  migraciones/
    001-dominios.sql       ← ALTER TABLE con CHECK, UNIQUE, DEFAULT
  sql/
    esquema.sql            ← De Práctica 3 (heredado)
  datos/
    [archivos CSV si tamaño < 10 MB]
  poblar.sh                ← Script de carga repetible

practica5/
  referencias.md           ← Tabla de FK, relaciones EER, cardinalidades
  pruebas-referenciales.md ← Acciones referencial (CASCADE, RESTRICT, SET NULL)
  edicion-de-valores.md    ← INSERT, UPDATE, DELETE, CASE, transacciones
  integridad-almacen.md    ← Tabla de hechos, dimensiones, granularidad (Sismos)
  integrantes/
    [Trabajo individual: cambio de acción referencial]
  sql/
    002-referencias.sql    ← ALTER TABLE para agregar FK
    003-referencias-sismos.sql ← FK del proyecto asignado

README.md                  ← Este archivo
```

---

## Requisitos previos

### Software
- PostgreSQL 14+ (o superior)
- pgAdmin (opcional, para visualizar)
- psql CLI
- bash (para scripts)
- git (para clonar el repositorio)

### Datos
- Esquema de Práctica 3 funcional (`esquema.sql`)
- Variables de entorno configuradas (credenciales)

### Permisos
- Acceso de lectura a `SQL/` y `datos/`
- Usuario PostgreSQL con permisos de creación de BD

---

## Configuración del entorno

### 1. Variables de entorno

En terminal o `.env`:

```bash
export PG_HOST="localhost"
export PG_PORT="5432"
export PG_ADMIN_PASS="clave_admin_segura"
export PG_APP_USER="app_user"
export PG_APP_PASS="clave_app_segura"
export PG_REPORT_PASS="clave_report_segura"
export PG_ADMIN_PASS="clave_admin_segura"
export PG_DB="catscoms_p4"
```

### 2. Docker Compose (opcional)

Si usas Docker:

```yaml
# compose.yaml
version: '3.8'
services:
  postgres:
    image: postgres:14-alpine
    environment:
      POSTGRES_PASSWORD: clave_admin_segura
      POSTGRES_USER: postgres
      POSTGRES_INITDB_ARGS: "-c shared_buffers=256MB"
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  pgdata:
```

Luego: `docker-compose up -d`

---

## Ejecución

### Paso 1: Crear BD y usuarios

```bash
psql -h localhost -U postgres << 'SQL'
CREATE DATABASE catscoms_p4;
CREATE USER app_user WITH PASSWORD 'clave_app_segura';
CREATE USER report_user WITH PASSWORD 'clave_report_segura';
CREATE USER admin_user WITH PASSWORD 'clave_admin_segura';
SQL
```

### Paso 2: Ejecutar esquema (Práctica 3)

```bash
export PGPASSWORD="clave_admin_segura"
psql -h localhost -U postgres -d catscoms_p4 < sql/esquema.sql
```

### Paso 3: Ejecutar migraciones (Práctica 4 y 5)

```bash
psql -h localhost -U postgres -d catscoms_p4 < practica4/migraciones/001-dominios.sql
psql -h localhost -U postgres -d catscoms_p4 < practica5/sql/002-referencias.sql
```

### Paso 4: Cargar datos

```bash
export PG_APP_PASS="clave_app_segura"
bash poblar.sh
```

O manual:

```bash
export PGPASSWORD="clave_app_segura"
psql -h localhost -U app_user -d catscoms_p4 < datos/carrera.sql
psql -h localhost -U app_user -d catscoms_p4 < datos/periodo.sql
# ... (seguir orden de FK)
```

### Paso 5: Verificación

```bash
export PGPASSWORD="clave_app_segura"
psql -h localhost -U app_user -d catscoms_p4 << 'SQL'
SELECT COUNT(*) as total_estudiantes FROM estudiante;
SELECT COUNT(*) as total_inscripciones FROM cursa;
-- Buscar huérfanos
SELECT COUNT(*) FROM cursa WHERE estudiante_id NOT IN (SELECT id FROM estudiante);
SQL
```

---

## Ejercicios completados

### Práctica 4

| Ejercicio | Archivo | Descripción | ✅ |
|---|---|---|---|
| 1.1 | `dominios.md` | Tipos de dato, CREATE DOMAIN | ✅ |
| 1.2 | `001-dominios.sql` | NOT NULL, DEFAULT, UNIQUE, CHECK (10+) | ✅ |
| 1.3 | `fuente.md` | Fuente APA, problemas, decisiones | ✅ |
| 1.4 | `poblar.sh` | Script repetible, todo-o-nada, cuentas | ✅ |
| 1.5 | `pruebas-dominio.md` | 10 casos de violación | ✅ |
| 1.6 | `permisos.md` | 3 roles, GRANT, matriz permisos | ✅ |
| 1.7 | `integridad-almacen.md` (Sismos) | Datos del SSN, restricciones | ✅ |

### Práctica 5

| Ejercicio | Archivo | Descripción | ✅ |
|---|---|---|---|
| 2.1 | `referencias.md` | 21 FK, relaciones EER, cardinalidades | ✅ |
| 2.2 | `002-referencias.sql` | ON DELETE/UPDATE con justificación | ✅ |
| 2.3 | `pruebas-referenciales.md` | Pruebas de integridad, orden de carga | ✅ |
| 2.4 | `edicion-de-valores.md` | INSERT, UPDATE, DELETE, CASE, transacciones | ✅ |
| 2.5 | `integridad-almacen.md` | Tabla de hechos, granularidad, FK del almacén | ✅ |
| 2.6 | `integrantes/` | Trabajo individual (cambio de acción referencial) | ⏳ |

---

## Notas importantes

### Datos sintéticos vs. reales

- **Estudiantes, calificaciones, inscripciones:** Sintéticos pero realistas (respetan restricciones, varían por carrera/semestre).
- **Profesores:** Nombres reales de SAESPEED (públicos), emails ficticios.
- **Materias, grupos:** Datos reales de ISC 2026/1.
- **Sismos:** Catálogo público del Servicio Sismológico Nacional (datos reales).

**Aclaración en README:** Los datos de estudiantes y calificaciones son **sintéticos para ejercicio educativo**.

### Ejecución repetible

El script `poblar.sh` es **idempotente**:
- Ejecutarlo dos veces no duplica registros (usa `ON CONFLICT DO NOTHING`).
- Si falla a mitad, se revierte todo (transacción ROLLBACK).
- Genera log con timestamp para auditoría.

### Credenciales en variables de entorno

**Nunca** commits credenciales. Siempre:

```bash
# ✅ Correcto
export PG_APP_PASS="clave"
psql -h localhost -U app_user -d catscoms_p4 ...

# ❌ Incorrecto
psql -h localhost -U app_user -W "clave_en_el_script" ...
```

---

## Troubleshooting

### Error: "permission denied for table"

**Causa:** El usuario `app_user` no tiene permiso en esa tabla.

**Solución:**
```bash
psql -h localhost -U postgres -d catscoms_p4 << SQL
GRANT SELECT ON materia TO rol_aplicacion;
SQL
```

### Error: "relation does not exist"

**Causa:** Falta ejecutar migraciones o esquema.

**Solución:**
```bash
psql -h localhost -U postgres -d catscoms_p4 < sql/esquema.sql
psql -h localhost -U postgres -d catscoms_p4 < practica4/migraciones/001-dominios.sql
```

### Error: "violates foreign key constraint"

**Causa:** Intento de insertar huérfano (FK apunta a renglón inexistente).

**Solución:** Cargar tablas padres primero. Ver `poblar.sh` por orden.

### La BD está vacía pero el script dice OK

**Causa:** Se ejecutó sin `PGPASSWORD` o con contraseña errónea.

**Solución:**
```bash
export PGPASSWORD="tu_clave"
bash poblar.sh
```

---

## Autores

- **Estrada Sánchez Emiliano** (ayddoous10)
- **Mora Acosta Pablo** (pablo140706)
- **Espinosa Gómez David Enrique** (daenesgo)

---

## Licencia

Datos públicos de ESCOM-IPN (educativo, no comercial).

---

## Próximos pasos

**Prácticas 9–12:** Consultas SELECT, joins, agregaciones, índices, optimización sobre esta misma BD.

**Futuro:** Implementación en aplicación web (Node.js, Flask, etc.) usando roles de seguridad.
