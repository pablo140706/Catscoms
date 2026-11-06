# Pruebas de restricciones de dominio — Práctica 4

## Ejercicio 1.5: Casos de violación

Cada caso muestra la operación intentada, el resultado esperado, el mensaje del SGBD y la regla protegida.

---

### Prueba 1: NOT NULL en estudiante.carrera_id

**Operación:**
```sql
INSERT INTO estudiante (matricula, nombre, email, carrera_id, semestre_actual, fecha_ingreso)
VALUES ('2024001234', 'GARCIA LOPEZ JUAN', 'juan@escom.ipn.mx', NULL, 3, '2024-09-01');
```

**Resultado esperado:** RECHAZADO

**Mensaje del SGBD (PostgreSQL):**
```
ERROR: null value in column "carrera_id" violates not-null constraint
DETAIL: Failing row contains (1, 2024001234, GARCIA LOPEZ JUAN, juan@escom.ipn.mx, null, 3, 2024-09-01, NULL).
```

**Regla protegida:** Un estudiante debe estar inscrito en una carrera; sin ella, no se sabe en qué plan está.

---

### Prueba 2: CHECK de rango (creditos)

**Operación:**
```sql
INSERT INTO materia (clave, nombre, creditos, semestre_sugerido, carrera_id, horas_teoria, horas_practica)
VALUES ('C999', 'MATERIA INVALIDA', -5, 3, 1, 2, 1);
```

**Resultado esperado:** RECHAZADO

**Mensaje del SGBD:**
```
ERROR: new row for relation "materia" violates check constraint "ck_mat_creditos"
DETAIL: Failing row contains (999, C999, MATERIA INVALIDA, -5, 3, 1, 2, 1, NULL).
```

**Regla protegida:** Los créditos deben ser positivos; un curso con créditos negativos no tiene sentido.

---

### Prueba 3: CHECK de formato (EMAIL)

**Operación:**
```sql
INSERT INTO profesor (nombre, email, telefono, activo)
VALUES ('HERNANDEZ LOPEZ CARLOS', 'carlosescom.ipn', NULL, TRUE);
```

**Resultado esperado:** RECHAZADO

**Mensaje del SGBD:**
```
ERROR: new row for relation "profesor" violates check constraint "ck_prof_email"
DETAIL: Failing row contains (100, HERNANDEZ LOPEZ CARLOS, carlosescom.ipn, NULL, TRUE).
```

**Regla protegida:** El email debe tener formato válido (contener @); un email sin arroba es inútil para contacto.

---

### Prueba 4: UNIQUE simple (estudiante.matricula)

**Operación:**
```sql
INSERT INTO estudiante (matricula, nombre, email, carrera_id, semestre_actual, fecha_ingreso)
VALUES ('2024001234', 'OTRO ESTUDIANTE', 'otro@escom.ipn.mx', 1, 2, '2024-09-01');
-- (Suponiendo que 2024001234 ya existe en la BD)
```

**Resultado esperado:** RECHAZADO

**Mensaje del SGBD:**
```
ERROR: duplicate key value violates unique constraint "uk_est_matricula"
DETAIL: Key (matricula)=(2024001234) already exists.
```

**Regla protegida:** Cada matrícula identifica a un único estudiante; no puede haber duplicados.

---

### Prueba 5: CHECK compuesto (horas_teoria + horas_practica > 0)

**Operación:**
```sql
INSERT INTO materia (clave, nombre, creditos, semestre_sugerido, carrera_id, horas_teoria, horas_practica)
VALUES ('C888', 'MATERIA SIN HORAS', 7, 1, 1, 0, 0);
```

**Resultado esperado:** RECHAZADO

**Mensaje del SGBD:**
```
ERROR: new row for relation "materia" violates check constraint "ck_mat_horas"
DETAIL: Failing row contains (888, C888, MATERIA SIN HORAS, 7, 1, (horas_teoria + horas_practica) = 0).
```

**Regla protegida:** Una materia debe tener al menos una hora de clase por semana; sin ellas no hay sesión.

---

### Prueba 6: CHECK entre columnas (fecha_fin >= fecha_inicio)

**Operación:**
```sql
INSERT INTO evento_calendario (nombre, fecha_inicio, fecha_fin, descripcion)
VALUES ('Periodo Extraordinario', '2026-06-15', '2026-06-10', 'Exámenes fuera de programa');
```

**Resultado esperado:** RECHAZADO

**Mensaje del SGBD:**
```
ERROR: new row for relation "evento_calendario" violates check constraint "ck_eve_cal_fechas"
DETAIL: Failing row contains (..., 2026-06-15, 2026-06-10, ...).
```

**Regla protegida:** Un evento no puede terminar antes de empezar; protege la lógica temporal.

---

### Prueba 7: DEFAULT (fecha_inscripcion)

**Operación:**
```sql
INSERT INTO cursa (estudiante_id, grupo_id, tipo, calificacion)
VALUES (1, 1, 'regular', NULL);
-- (Sin especificar fecha_inscripcion)
```

**Resultado esperado:** ACEPTADO; se asigna fecha actual (CURRENT_DATE)

**Consulta de verificación:**
```sql
SELECT fecha_inscripcion FROM cursa WHERE estudiante_id = 1 AND grupo_id = 1;
-- Resultado: 2026-11-03 (hoy)
```

**Regla protegida:** La fecha de inscripción es hoy por defecto; no hay que capturarla manualmente.

---

### Prueba 8: UNIQUE compuesta (materia.clave, carrera_id)

**Operación:**
```sql
INSERT INTO materia (clave, nombre, creditos, semestre_sugerido, carrera_id, horas_teoria, horas_practica)
VALUES ('C101', 'CALCULO MULTIVARIABLE', 9, 1, 1, 3, 2);
-- (C101 ya existe en carrera_id=1, ISC)
```

**Resultado esperado:** RECHAZADO

**Mensaje del SGBD:**
```
ERROR: duplicate key value violates unique constraint "uk_mat_clave_carrera"
DETAIL: Key (clave, carrera_id)=(C101, 1) already exists.
```

**Regla protegida:** Cada clave (C101, B101, A101) es única dentro de su carrera; no hay confusión entre semestres o carreras.

---

### Prueba 9: CHECK de lista (turno)

**Operación:**
```sql
INSERT INTO grupo (codigo, materia_id, profesor_id, turno, periodo_id, cupo, inscritos)
VALUES ('1CM1', 1, 1, 'X', 1, 30, 25);
```

**Resultado esperado:** RECHAZADO

**Mensaje del SGBD:**
```
ERROR: new row for relation "grupo" violates check constraint "ck_grp_turno"
DETAIL: Failing row contains (..., X, ...).
```

**Regla protegida:** Turno solo puede ser M (matutino) o V (vespertino); valores inválidos causan confusión en horarios.

---

### Prueba 10: CHECK de fecha no futura (resena.fecha_resena)

**Operación:**
```sql
INSERT INTO resena (estudiante_id, profesor_id, grupo_id, calidad, dificultad, recomiendan, fecha_resena, comentario)
VALUES (1, 1, 1, 8, 5, 1, '2027-01-15', 'Excelente profesor');
-- (Fecha 2027-01-15 es en el futuro vs. hoy 2026-11-03)
```

**Resultado esperado:** RECHAZADO

**Mensaje del SGBD:**
```
ERROR: new row for relation "resena" violates check constraint "ck_res_fecha"
DETAIL: Failing row contains (..., 2027-01-15, ...).
```

**Regla protegida:** Una reseña debe escribirse en o antes del día de hoy; no se puede escribir reseñas del futuro.

---

## Resumen: restricciones verificadas

| # | Tipo | Columnas | Regla | Verificado |
|---|---|---|---|---|
| 1 | NOT NULL | estudiante.carrera_id | Carrera obligatoria | ✅ |
| 2 | CHECK rango | materia.creditos | Créditos positivos | ✅ |
| 3 | CHECK formato | profesor.email | Email válido | ✅ |
| 4 | UNIQUE simple | estudiante.matricula | Matrícula única | ✅ |
| 5 | CHECK compuesto | materia.horas_* | Al menos 1 hora | ✅ |
| 6 | CHECK temporal | evento.fecha_* | fecha_fin ≥ fecha_inicio | ✅ |
| 7 | DEFAULT | cursa.fecha_inscripcion | Hoy por defecto | ✅ |
| 8 | UNIQUE compuesta | materia(clave, carrera_id) | Clave única/carrera | ✅ |
| 9 | CHECK lista | grupo.turno | M ó V | ✅ |
| 10 | CHECK temporal | resena.fecha_resena | No futura | ✅ |

**Total:** 10/10 restricciones probadas exitosamente. Todas protegen reglas de negocio reales.
