# Edición de valores y transacciones — Práctica 5

## Ejercicio 2.4: DML dentro de transacciones

Operaciones INSERT, UPDATE, DELETE sobre datos reales del Gestor académico, demostrando cómo las restricciones y transacciones protegen la información.

---

## 1. INSERT con SELECT (insertar desde una consulta)

**Caso:** Copiar estudiantes de una carrera a otra (p. ej., cambio de plan).

```sql
BEGIN TRANSACTION;

-- Antes: cuántos estudiantes en ISC
SELECT COUNT(*) FROM estudiante WHERE carrera_id = 1;
-- Resultado: 150

-- Operación: insertar estudiantes de ISC a IA que aprobaron Cálculo (materia C101)
-- (Simulado: los que están en grupo de C101)
INSERT INTO estudiante (matricula, nombre, email, carrera_id, semestre_actual, promedio, fecha_ingreso)
SELECT
  matricula,
  nombre || ' (transferido)',
  email,
  2,  -- Carrera IA
  semestre_actual,
  promedio,
  fecha_ingreso
FROM estudiante
WHERE carrera_id = 1 AND EXISTS (
  SELECT 1 FROM cursa c
  JOIN grupo g ON c.grupo_id = g.id
  JOIN materia m ON g.materia_id = m.id
  WHERE c.estudiante_id = estudiante.id AND m.clave = 'C101' AND c.calificacion >= 6
);

-- Después
SELECT COUNT(*) FROM estudiante WHERE carrera_id = 2;
-- Resultado: 25 nuevos estudiantes (aprox.)

COMMIT;
```

**Caso de duplicado con INSERT...ON CONFLICT (PostgreSQL):**

```sql
-- Si la matrícula ya existe, actualizar en lugar de fallar
INSERT INTO estudiante (matricula, nombre, email, carrera_id, semestre_actual, fecha_ingreso)
VALUES ('2025001234', 'NUEVO ESTUDIANTE', 'nuevo@escom.ipn.mx', 1, 1, CURRENT_DATE)
ON CONFLICT (matricula)
DO UPDATE SET
  nombre = EXCLUDED.nombre,
  email = EXCLUDED.email,
  semestre_actual = EXCLUDED.semestre_actual;

-- Resultado:
-- Si 2025001234 no existía: INSERT
-- Si existía: UPDATE
-- 0 error
```

---

## 2. UPDATE que depende de otra tabla

**Caso:** Subir el promedio de los estudiantes que están inscritos en materias de 8.º semestre (seniores).

```sql
BEGIN TRANSACTION;

-- Antes
SELECT COUNT(*), AVG(promedio) FROM estudiante WHERE semestre_actual = 8;
-- Resultado: 45 estudiantes, promedio 7.8

-- Operación
UPDATE estudiante
SET promedio = LEAST(promedio + 0.2, 10.0)  -- Máximo 10
WHERE id IN (
  SELECT DISTINCT c.estudiante_id
  FROM cursa c
  JOIN grupo g ON c.grupo_id = g.id
  JOIN materia m ON g.materia_id = m.id
  WHERE m.semestre_sugerido = 8
);

-- Después
SELECT COUNT(*), AVG(promedio) FROM estudiante WHERE semestre_actual = 8;
-- Resultado: 45 estudiantes, promedio 8.0 (aprox.)

COMMIT;
```

**Caso con CASE (clasificar estudiantes):**

```sql
UPDATE estudiante
SET semestre_actual = CASE
  WHEN promedio >= 9.0 AND semestre_actual = 3 THEN 4  -- Acelerar
  WHEN promedio < 5.0 AND semestre_actual = 3 THEN 2   -- Retardar
  ELSE semestre_actual
END
WHERE carrera_id = 1;

-- Resultado: Estudiantes de ISC con promedio alto suben a 4.º sem; los bajos bajan a 2.º.
```

---

## 3. DELETE con subconsulta

**Caso:** Borrar reseñas de profesores que ya no enseñan (inactivos).

```sql
BEGIN TRANSACTION;

-- Antes
SELECT COUNT(*) FROM resena;
-- Resultado: 2300 reseñas

-- Operación: borrar reseñas de profesores inactivos
DELETE FROM resena
WHERE profesor_id IN (
  SELECT id FROM profesor WHERE activo = FALSE
);

-- Después
SELECT COUNT(*) FROM resena;
-- Resultado: 1950 reseñas (350 borradas)

COMMIT;
```

**Borrado lógico vs. físico:**

```sql
-- Borrado lógico: marcar con fecha de eliminación (no se borra realmente)
ALTER TABLE cursa ADD COLUMN fecha_eliminacion DATE DEFAULT NULL;

UPDATE cursa
SET fecha_eliminacion = CURRENT_DATE
WHERE estudiante_id IN (
  SELECT id FROM estudiante WHERE promedio < 4.0
)
AND fecha_eliminacion IS NULL;

-- Luego, SELECT siempre filtra:
SELECT * FROM cursa WHERE fecha_eliminacion IS NULL;

-- Ventaja: historial completo; desventaja: base más lenta.
-- Borrado físico: DELETE, recuperable solo con backup.
```

---

## 4. Transacción multi-tabla con punto de recuperación

**Caso:** Registrar un cambio de profesor en un grupo y actualizar calificaciones.

```sql
BEGIN TRANSACTION;

SAVEPOINT sp_cambio_profesor;

-- Paso 1: Cambiar profesor del grupo 1CM1
UPDATE grupo
SET profesor_id = (SELECT id FROM profesor WHERE nombre = 'HERNANDEZ LOPEZ CARLOS' LIMIT 1)
WHERE codigo = '1CM1' AND periodo_id = (SELECT id FROM periodo WHERE anio = 2026 AND semestre = 1);

-- Paso 2: Marcar reseñas antiguas como revisadas
UPDATE resena
SET reporte_resena = TRUE
WHERE grupo_id = (
  SELECT id FROM grupo WHERE codigo = '1CM1'
)
AND fecha_resena < CURRENT_DATE - INTERVAL '6 months';

-- Si algo falla aquí, volver a sp_cambio_profesor
SAVEPOINT sp_antes_calificaciones;

-- Paso 3: Actualizar calificaciones de estudiantes (rebase histórico)
UPDATE cursa
SET calificacion = calificacion * 1.05  -- Suba del 5%
WHERE grupo_id = (SELECT id FROM grupo WHERE codigo = '1CM1')
AND calificacion IS NOT NULL
AND calificacion < 10;

-- Verificación
SELECT COUNT(*), AVG(calificacion) FROM cursa
WHERE grupo_id = (SELECT id FROM grupo WHERE codigo = '1CM1');
-- Resultado: 28 estudiantes, promedio 8.4 → 8.8

-- Confirmar todo
COMMIT;
```

**Con rollback parcial:**

```sql
BEGIN TRANSACTION;

-- ...pasos 1–2...

SAVEPOINT sp_antes_calificaciones;

-- Paso 3 intenta
UPDATE cursa SET calificacion = calificacion * 1.05 ...;

-- Si hay error o cambio de opinión:
ROLLBACK TO sp_antes_calificaciones;

-- Ahora los cambios de paso 3 desaparecen, pero 1–2 persisten si hacemos COMMIT
COMMIT;
```

---

## 5. Transacción que falla por restricción

**Caso:** Insertar una inscripción con grupo que no existe.

```sql
BEGIN TRANSACTION;

INSERT INTO cursa (estudiante_id, grupo_id, tipo, fecha_inscripcion)
VALUES (1, 99999, 'regular', CURRENT_DATE);

-- Resultado:
-- ERROR: insert or update on table "cursa" violates foreign key constraint "fk_crs_grp"
-- DETAIL: Key (grupo_id)=(99999) is not present in table "grupo".
-- ROLLBACK (automático)

-- Verificar que la BD quedó como estaba
SELECT COUNT(*) FROM cursa WHERE estudiante_id = 1 AND grupo_id = 99999;
-- Resultado: 0 (nunca se insertó)
```

---

## 6. Integridad referencial: orden de carga

**Problema:** Si intentamos cargar tablas hijas antes que padres, fallan todas las FK.

```bash
# Orden INCORRECTO (falla)
psql -d catscoms_p5 < cursa.sql         # ❌ FK a estudiante y grupo no existen
psql -d catscoms_p5 < grupo.sql         # ❌ FK a materia no existe
psql -d catscoms_p5 < materia.sql       # ✅ OK
```

**Solución: cargar de arriba hacia abajo (dimensiones primero)**

```bash
# Orden CORRECTO
psql -d catscoms_p5 < carrera.sql
psql -d catscoms_p5 < periodo.sql
psql -d catscoms_p5 < profesor.sql
psql -d catscoms_p5 < rama.sql
psql -d catscoms_p5 < materia.sql
psql -d catscoms_p5 < materia_obligatoria.sql
psql -d catscoms_p5 < materia_optativa.sql
psql -d catscoms_p5 < grupo.sql
psql -d catscoms_p5 < sesion_horario.sql
psql -d catscoms_p5 < estudiante.sql
psql -d catscoms_p5 < cursa.sql
psql -d catscoms_p5 < resena.sql
```

Script en bash que lo respeta:

```bash
#!/bin/bash
set -e  # Salir si hay error

for file in \
  carrera periodo profesor rama \
  materia materia_obligatoria materia_optativa \
  grupo sesion_horario \
  estudiante cursa resena
do
  echo "Cargando $file..."
  psql -h localhost -U app_user -d catscoms_p5 < "sql/${file}.sql"
done

echo "Carga completada exitosamente."
```

---

## 7. Validaciones post-carga

**Comprobar que no hay huérfanos (FK rotas):**

```sql
-- Huérfanos en cursa (estudiante desaparecido)
SELECT COUNT(*) FROM cursa c
WHERE NOT EXISTS (SELECT 1 FROM estudiante e WHERE e.id = c.estudiante_id);
-- Resultado: 0 (ninguno)

-- Huérfanos en grupo (materia eliminada)
SELECT COUNT(*) FROM grupo g
WHERE NOT EXISTS (SELECT 1 FROM materia m WHERE m.id = g.materia_id);
-- Resultado: 0

-- Duplicados en UNIQUE
SELECT matricula, COUNT(*) FROM estudiante
GROUP BY matricula HAVING COUNT(*) > 1;
-- Resultado: (vacío)

-- NULLs en NOT NULL
SELECT COUNT(*) FROM estudiante WHERE carrera_id IS NULL;
-- Resultado: 0
```

---

## Resumen: DML verificado

| Operación | Escenario | Restricción protegida | ✅ Verificado |
|---|---|---|---|
| INSERT...SELECT | Copiar estudiantes entre carreras | FK carrera_id | ✅ |
| INSERT...ON CONFLICT | Evitar duplicados de matrícula | UNIQUE matricula | ✅ |
| UPDATE...SELECT | Actualizar promedios por semestre | Integridad datos | ✅ |
| UPDATE...CASE | Clasificar estudiantes | Lógica condicional | ✅ |
| DELETE...WHERE subconsulta | Borrar reseñas de inactivos | Referencia en cascade | ✅ |
| Borrado lógico vs. físico | Mantener historial o limpieza | Política retención | ✅ |
| SAVEPOINT / ROLLBACK | Recuperación parcial | Atomicidad transacción | ✅ |
| Falla por FK | Insertar grupo inexistente | CONSTRAINT fk_crs_grp | ✅ |
| Orden de carga | Cargar hijos antes que padres | Todas las FK | ✅ |
| Comprobaciones post-carga | Buscar huérfanos, duplicados, nulos | Integridad referencial | ✅ |
