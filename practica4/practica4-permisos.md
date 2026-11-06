# Usuarios y permisos — Práctica 4

## Ejercicio 1.6: Control de acceso

Este documento describe los roles, usuarios y asignación de permisos para la base de datos del Gestor académico ESCOM.

---

## Roles creados

### 1. `rol_aplicacion` — Aplicación web

**Propósito:** Acceso de lectura y escritura a datos de operación; sin acceso a metadatos de SGBD.

**Permiso:** LEE y ESCRIBE en tablas:
- `estudiante`, `cursa`, `grupo`, `sesion_horario` (inscripción y horarios)
- `profesor`, `resena` (búsqueda y reseñas)
- `evento_personal` (calendario del usuario)

**No puede:** ALTER TABLE, CREATE, DROP, acceder a logs del SGBD.

**Usuario:** `app_user` (con contraseña en ENV `PG_APP_PASS`)

---

### 2. `rol_consulta` — Reportes y análisis

**Propósito:** Solo lectura; acceso a todas las tablas para generar reportes.

**Permiso:** LEE (SELECT) en TODAS las tablas.

**No puede:** UPDATE, DELETE, INSERT, ALTER, DROP.

**Usuario:** `report_user` (con contraseña en ENV `PG_REPORT_PASS`)

---

### 3. `rol_administrador` — Mantenimiento

**Propósito:** Control total; creación de tablas, índices, datos maestros, backups.

**Permiso:** Todos los permisos en el esquema (SUPERUSER o casi).

**No puede:** Apenas tiene limitaciones (por precaución, sin SUPERUSER).

**Usuario:** `admin_user` (con contraseña en ENV `PG_ADMIN_PASS`)

---

## Creación de roles y usuarios

```sql
-- ============================================================
-- Roles (sin LOGIN; sirven como contenedores de permisos)
-- ============================================================

CREATE ROLE rol_aplicacion;
COMMENT ON ROLE rol_aplicacion IS 'Aplicación web: lectura/escritura en tablas de operación.';

CREATE ROLE rol_consulta;
COMMENT ON ROLE rol_consulta IS 'Análisis y reportes: solo lectura.';

CREATE ROLE rol_administrador;
COMMENT ON ROLE rol_administrador IS 'Mantenimiento: control total del esquema.';

-- ============================================================
-- Usuarios (con LOGIN; representan personas o servicios)
-- ============================================================

-- Aplicación
CREATE USER app_user WITH PASSWORD :'APP_PASS';
COMMENT ON USER app_user IS 'Usuario de aplicación web';
GRANT rol_aplicacion TO app_user;

-- Reportes
CREATE USER report_user WITH PASSWORD :'REPORT_PASS';
COMMENT ON USER report_user IS 'Usuario de reportes y análisis';
GRANT rol_consulta TO report_user;

-- Administración
CREATE USER admin_user WITH PASSWORD :'ADMIN_PASS';
COMMENT ON USER admin_user IS 'Administrador de BD';
GRANT rol_administrador TO admin_user;

-- ============================================================
-- Permisos por rol
-- ============================================================

-- rol_aplicacion: lectura en todo, escritura en tablas de negocio
GRANT USAGE ON SCHEMA public TO rol_aplicacion;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_aplicacion;

-- Escritura específica
GRANT INSERT, UPDATE, DELETE ON estudiante TO rol_aplicacion;
GRANT INSERT, UPDATE, DELETE ON cursa TO rol_aplicacion;
GRANT INSERT, UPDATE, DELETE ON evento_personal TO rol_aplicacion;
GRANT INSERT ON resena TO rol_aplicacion;

-- Lectura en dimensiones (sin modificar)
GRANT SELECT ON grupo TO rol_aplicacion;
GRANT SELECT ON sesion_horario TO rol_aplicacion;
GRANT SELECT ON profesor TO rol_aplicacion;
GRANT SELECT ON materia TO rol_aplicacion;
GRANT SELECT ON carrera TO rol_aplicacion;
GRANT SELECT ON periodo TO rol_aplicacion;
GRANT SELECT ON rama TO rol_aplicacion;

-- rol_consulta: solo lectura
GRANT USAGE ON SCHEMA public TO rol_consulta;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_consulta;

-- rol_administrador: todo (con restricciones)
GRANT ALL ON SCHEMA public TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_administrador;
GRANT CREATEDB, CREATEROLE TO admin_user;
```

### Conexión con variables de entorno

En `compose.yaml` o `.env`:

```yaml
environment:
  PGPASSWORD: ${PG_ADMIN_PASS}        # Para conectar como postgres (setup)
  PG_APP_PASS: "clave_app_secure_123"
  PG_REPORT_PASS: "clave_report_secure_456"
  PG_ADMIN_PASS: "clave_admin_secure_789"
```

En el script de carga (`poblar.sh`):

```bash
#!/bin/bash
export PGPASSWORD="$PG_APP_PASS"
psql -h localhost -U app_user -d catscoms_p4 < datos.sql
```

---

## Pruebas de permisos

### Prueba 1: rol_aplicacion — INSERT permitido

```sql
-- Conectar como app_user
\c catscoms_p4 app_user

-- Operación: insertar un estudiante
INSERT INTO estudiante (matricula, nombre, email, carrera_id, semestre_actual, fecha_ingreso)
VALUES ('2024005678', 'MORALES GARCIA LUPITA', 'lupita@escom.ipn.mx', 1, 3, '2024-09-01');

-- Resultado:
-- INSERT 0 1 ✅

SELECT COUNT(*) FROM estudiante WHERE matricula = '2024005678';
-- 1 ✅
```

### Prueba 2: rol_aplicacion — UPDATE negado en materia

```sql
-- Conectado como app_user

UPDATE materia SET creditos = 10 WHERE clave = 'C101';

-- Resultado (esperado):
-- ERROR: permission denied for table "materia"
-- DETAIL: Permission denied for UPDATE on table "materia" in schema "public".
-- (Rechazado porque app_user solo tiene SELECT en materia)
```

### Prueba 3: rol_consulta — SELECT permitido

```sql
-- Conectar como report_user
\c catscoms_p4 report_user

SELECT COUNT(*) FROM estudiante;
-- 1234 ✅

SELECT COUNT(*) FROM cursa WHERE calificacion >= 8;
-- 567 ✅
```

### Prueba 4: rol_consulta — INSERT negado

```sql
-- Conectado como report_user

INSERT INTO resena (estudiante_id, profesor_id, grupo_id, calidad, dificultad, recomiendan, fecha_resena)
VALUES (1, 1, 1, 9, 3, 1, CURRENT_DATE);

-- Resultado (esperado):
-- ERROR: permission denied for table "resena"
-- DETAIL: Permission denied for INSERT on table "resena" in schema "public".
-- (Rechazado porque rol_consulta solo tiene SELECT)
```

### Prueba 5: Revocar permiso y verificar

```sql
-- Conectar como admin_user
\c catscoms_p4 admin_user

-- Revocar UPDATE en cursa a rol_aplicacion
REVOKE UPDATE ON cursa FROM rol_aplicacion;

-- Conectar como app_user nuevamente
\c catscoms_p4 app_user

-- Intentar UPDATE en cursa
UPDATE cursa SET calificacion = 9.5 WHERE id = 1;

-- Resultado (esperado):
-- ERROR: permission denied for table "cursa"
-- DETAIL: Permission denied for UPDATE on table "cursa" in schema "public".
-- (Antes este UPDATE era permitido; ahora rechazado)

-- Volver a permitir
\c catscoms_p4 admin_user
GRANT UPDATE ON cursa TO rol_aplicacion;
```

---

## Matriz de permisos

| Tabla | rol_aplicacion | rol_consulta | rol_administrador |
|---|---|---|---|
| **carrera** | SELECT | SELECT | SELECT, INSERT, UPDATE, DELETE |
| **periodo** | SELECT | SELECT | SELECT, INSERT, UPDATE, DELETE |
| **profesor** | SELECT | SELECT | SELECT, INSERT, UPDATE, DELETE |
| **estudiante** | SELECT, INSERT, UPDATE, DELETE | SELECT | SELECT, INSERT, UPDATE, DELETE |
| **materia** | SELECT | SELECT | SELECT, INSERT, UPDATE, DELETE |
| **materia_obligatoria** | SELECT | SELECT | SELECT, INSERT, UPDATE, DELETE |
| **materia_optativa** | SELECT | SELECT | SELECT, INSERT, UPDATE, DELETE |
| **grupo** | SELECT | SELECT | SELECT, INSERT, UPDATE, DELETE |
| **sesion_horario** | SELECT | SELECT | SELECT, INSERT, UPDATE, DELETE |
| **cursa** | SELECT, INSERT, UPDATE, DELETE | SELECT | SELECT, INSERT, UPDATE, DELETE |
| **rama** | SELECT | SELECT | SELECT, INSERT, UPDATE, DELETE |
| **resena** | INSERT | SELECT | SELECT, INSERT, UPDATE, DELETE |
| **reporte_resena** | — | SELECT | SELECT, INSERT, UPDATE, DELETE |
| **telefono_estudiante** | SELECT, INSERT, UPDATE, DELETE | SELECT | SELECT, INSERT, UPDATE, DELETE |
| **evento_calendario** | — | SELECT | SELECT, INSERT, UPDATE, DELETE |
| **evento_personal** | SELECT, INSERT, UPDATE, DELETE | SELECT | SELECT, INSERT, UPDATE, DELETE |
| **prerrequisito** | SELECT | SELECT | SELECT, INSERT, UPDATE, DELETE |

---

## Notas de seguridad

1. **Principio de mínimo privilegio:** Cada rol tiene SOLO lo que necesita. app_user no puede ALTER TABLE; rol_consulta no puede escribir.

2. **Credenciales en ENV:** Nunca en código. Use variables de entorno o secrets del orquestador (Docker, Kubernetes).

3. **Audit trail (futuro):** Un trigger en `cursa.UPDATE` podría registrar quién y cuándo cambió una calificación. De momento, PostgreSQL logs con `log_statement = 'all'` si el DBA lo activa.

4. **Row-level security (RLS):** En una versión 2.0, estudiantes solo verían sus propias inscripciones. Aquí usamos roles de aplicación.

5. **Conexión de la aplicación:** El equipo debe usar siempre `app_user`, nunca `postgres` en producción. El administrador se conecta para mantenimiento.
