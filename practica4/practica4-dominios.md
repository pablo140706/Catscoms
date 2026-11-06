# Práctica 4 — Dominios

## Ejercicio 1.1: Tipos de dato y dominios

### Tabla de columnas y tipos

| Tabla | Columna | Tipo | Longitud / Precisión | Justificación |
|---|---|---|---|---|
| carrera | id | SMALLINT | — | 3 carreras (ISC, IA, LCD) caben en 1 byte |
| carrera | nombre | VARCHAR | 80 | "Ingeniería en Sistemas Computacionales" = 47 caracteres |
| carrera | plan_version | CHAR | 4 | Formato año-semestre: "2020" |
| carrera | carga_minima | SMALLINT | — | Rango 1–100 UA; SMALLINT bastante |
| carrera | carga_media | SMALLINT | — | Ídem |
| periodo | id | SMALLINT | — | Período es número: 26/2, 27/1, etc. → SMALLINT |
| periodo | anio | SMALLINT | — | Año: 2020–2030 |
| periodo | semestre | SMALLINT | — | 1 ó 2 |
| profesor | id | INTEGER | — | 200+ profesores esperados |
| profesor | nombre | VARCHAR | 150 | Nombres completos ESCOM pueden ser largos |
| profesor | email | VARCHAR | 100 | Email estándar |
| profesor | telefono | VARCHAR | 20 | Teléfono con posibles extensiones |
| profesor | activo | BOOLEAN | — | 1 ó 0 (activo en el periodo vigente) |
| estudiante | id | INTEGER | — | 6000+ estudiantes en ESCOM |
| estudiante | nombre | VARCHAR | 150 | Nombre completo |
| estudiante | matricula | VARCHAR | 20 | Matrícula única de IPN |
| estudiante | email | VARCHAR | 100 | Email de estudiante |
| estudiante | carrera_id | SMALLINT | — | FK a carrera |
| estudiante | semestre_actual | SMALLINT | — | 1–8 |
| estudiante | promedio | NUMERIC | (5,2) | GPA: 0.00–10.00 |
| estudiante | fecha_ingreso | DATE | — | YYYY-MM-DD |
| materia | id | INTEGER | — | ~50 obligatorias + optativas = 150+ |
| materia | clave | VARCHAR | 10 | "C101", "B640", "A720", etc. |
| materia | nombre | VARCHAR | 120 | "Cálculo Multivariable", etc. |
| materia | creditos | SMALLINT | — | 7–9 típicamente |
| materia | semestre_sugerido | SMALLINT | — | 1–8 |
| materia | carrera_id | SMALLINT | — | FK a carrera |
| materia | horas_teoria | SMALLINT | — | 2–4 horas/semana |
| materia | horas_practica | SMALLINT | — | 0–3 horas/semana |
| grupo | id | INTEGER | — | Crecimiento anual |
| grupo | codigo | VARCHAR | 10 | "1CM1", "3BV2", etc. (semestre+carrera+turno+num) |
| grupo | materia_id | INTEGER | — | FK a materia |
| grupo | profesor_id | INTEGER | — | FK a profesor |
| grupo | turno | CHAR | 1 | 'M' ó 'V' |
| grupo | periodo_id | SMALLINT | — | FK a periodo |
| grupo | cupo | SMALLINT | — | 20–50 estudiantes típicamente |
| grupo | inscritos | SMALLINT | — | 0–cupo |
| sesion_horario | id | INTEGER | — | Múltiples sesiones por grupo |
| sesion_horario | grupo_id | INTEGER | — | FK a grupo |
| sesion_horario | dia | VARCHAR | 10 | "lunes", "martes", etc. |
| sesion_horario | hora_inicio | TIME | — | HH:MM:SS (07:00, 18:30, etc.) |
| sesion_horario | hora_fin | TIME | — | HH:MM:SS |
| sesion_horario | aula | VARCHAR | 20 | "2-504", "Auditorio", etc. |
| sesion_horario | edificio | VARCHAR | 50 | "Edificio 2", "Biblioteca", etc. |
| cursa | id | INTEGER | — | Millones de registros esperados |
| cursa | estudiante_id | INTEGER | — | FK a estudiante |
| cursa | grupo_id | INTEGER | — | FK a grupo |
| cursa | calificacion | NUMERIC | (4,2) | 0.00–10.00; NULL si aún no hay califa |
| cursa | fecha_inscripcion | DATE | — | Cuándo se inscribió |
| cursa | fecha_termino | DATE | — | Cuándo concluyó (NULL si en curso) |
| cursa | tipo | VARCHAR | 20 | 'regular', 'recurse', 'especial' |
| rama | id | SMALLINT | — | 14 ramas de optativas en ISC |
| rama | nombre | VARCHAR | 100 | "Criptografía", "Big Data", etc. |
| rama | carrera_id | SMALLINT | — | FK a carrera |
| materia_optativa | id | INTEGER | — | Múltiples optativas por carrera |
| materia_optativa | materia_id | INTEGER | — | FK a materia |
| materia_optativa | slot | CHAR | 2 | 'A1', 'B1', 'A2', 'B2' (solo ISC) o NULL (IA/LCD) |
| materia_optativa | rama_id | SMALLINT | — | FK a rama (solo si slot tiene valor) |
| prerrequisito | id | INTEGER | — | ~20 pares de prerequisitos |
| prerrequisito | materia_id | INTEGER | — | FK a materia (la que requiere) |
| prerrequisito | prerequisito_id | INTEGER | — | FK a materia (la requerida) |

### CREATE DOMAIN y enumerados

Si el SGBD lo permite (PostgreSQL sí):

```sql
CREATE DOMAIN dominio_turno AS CHAR(1) CHECK (VALUE IN ('M', 'V'));
CREATE DOMAIN dominio_tipo_cursa AS VARCHAR(20) CHECK (VALUE IN ('regular', 'recurse', 'especial'));
CREATE DOMAIN dominio_calificacion AS NUMERIC(4, 2) CHECK (VALUE >= 0 AND VALUE <= 10 OR VALUE IS NULL);
CREATE DOMAIN dominio_promedio AS NUMERIC(5, 2) CHECK (VALUE >= 0 AND VALUE <= 10);
CREATE DOMAIN dominio_creditos AS SMALLINT CHECK (VALUE > 0 AND VALUE <= 15);
CREATE DOMAIN dominio_semestre AS SMALLINT CHECK (VALUE >= 1 AND VALUE <= 8);
CREATE DOMAIN dominio_horas AS SMALLINT CHECK (VALUE >= 0 AND VALUE <= 10);
```

**Beneficio:** Una vez creados, todos los tipos se validan en el punto de inserción/actualización. Si cambias el rango (ej. permitir 10.5 en calificaciones), cambia en un solo lugar. Además, la semántica queda clara en el esquema.
