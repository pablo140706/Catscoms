# Claves foráneas — Práctica 5

## Ejercicio 2.1: Integridad referencial

Cada clave foránea implementa una relación del modelo EER. Se documenta:
- Qué relación implementa (cardinalidad, especialización, etc.)
- Tabla y columna de referencia
- Si admite nulos (cardinalidad mínima 0 ó 1)
- Acción referencial (ver Ejercicio 2.2)

---

## Tabla de claves foráneas

| # | Tabla hija | Columna FK | Tabla padre | Columna PK | Relación EER | Cardinalidad | ¿Nulos? | Acción |
|---|---|---|---|---|---|---|---|---|
| 1 | estudiante | carrera_id | carrera | id | Estudiante ⊂ Carrera (asociación) | N:1 | NO (1,1) | CASCADE |
| 2 | estudiante | periodo_ingreso_id | periodo | id | Período de ingreso (atributo derivado) | N:1 | Sí (0,1) | SET NULL |
| 3 | materia | carrera_id | carrera | id | Materia ⊂ Carrera | N:1 | NO (1,1) | CASCADE |
| 4 | materia_obligatoria | materia_id | materia | id | Materia obligatoria ⊂ Materia (especialización) | 1:1 | NO (1,1) | CASCADE |
| 5 | materia_optativa | materia_id | materia | id | Materia optativa ⊂ Materia (especialización) | 1:1 | NO (1,1) | CASCADE |
| 6 | materia_optativa | rama_id | rama | id | Optativa → Rama (agrupa) | N:1 | Sí (0,1)* | SET NULL |
| 7 | grupo | materia_id | materia | id | Grupo ofrece Materia | N:1 | NO (1,1) | CASCADE |
| 8 | grupo | profesor_id | profesor | id | Grupo enseña Profesor | N:1 | Sí (0,1)** | SET NULL |
| 9 | grupo | periodo_id | periodo | id | Grupo existe en Período | N:1 | NO (1,1) | CASCADE |
| 10 | sesion_horario | grupo_id | grupo | id | Sesión → Grupo (desglosa) | N:1 | NO (1,1) | CASCADE |
| 11 | cursa | estudiante_id | estudiante | id | Estudiante cursa Materia | N:1 | NO (1,1) | CASCADE |
| 12 | cursa | grupo_id | grupo | id | Cursa → Grupo | N:1 | NO (1,1) | CASCADE |
| 13 | resena | estudiante_id | estudiante | id | Estudiante escribe Reseña | N:1 | NO (1,1) | SET NULL |
| 14 | resena | profesor_id | profesor | id | Reseña → Profesor | N:1 | NO (1,1) | SET NULL |
| 15 | resena | grupo_id | grupo | id | Reseña → Grupo (para qué materia) | N:1 | Sí (0,1) | SET NULL |
| 16 | telefono_estudiante | estudiante_id | estudiante | id | Estudiante tiene Teléfono | N:1 | NO (1,1) | CASCADE |
| 17 | evento_personal | estudiante_id | estudiante | id | Evento → Estudiante | N:1 | NO (1,1) | CASCADE |
| 18 | prerrequisito | materia_id | materia | id | Materia requiere Prerequisito (como destino) | N:1 | NO (1,1) | CASCADE |
| 19 | prerrequisito | prerequisito_id | materia | id | Materia requiere Prerequisito (como origen) | N:1 | NO (1,1) | CASCADE |
| 20 | rama | carrera_id | carrera | id | Rama → Carrera | N:1 | NO (1,1) | CASCADE |
| 21 | reporte_resena | resena_id | resena | id | Reporte → Reseña | N:1 | NO (1,1) | CASCADE |

---

## Notas sobre acciones referenciales

### Abreviaturas
- **NO (1,1)**: Cardinalidad mínima 1 → NOT NULL, acción RESTRICT
- **Sí (0,1)**: Cardinalidad mínima 0 → NULL permitido, acción SET NULL

### Decisiones clave

1. **Estudiante → Carrera (CASCADE)**
   - Si se borra una carrera (ej. ISC), borramos todos sus estudiantes.
   - Regla: Una carrera no desaparece en producción; si lo hace, es limpieza masiva.

2. **Grupo → Periodo (CASCADE)**
   - Si borramos un período, borramos sus grupos (entidad débil).
   - Regla: Un grupo solo existe en un período; su ciclo de vida es el del período.

3. **Grupo → Profesor (SET NULL)**
   - Si un profesor se despide, sus grupos quedan asignados a NULL o se reasignan a mano.
   - Regla: Un grupo puede quedarse sin profesor asignado (en transición).

4. **Materia_optativa → Rama (SET NULL)**
   - Si una rama se descontinúa, sus optativas quedan sin rama pero siguen siendo optativas.
   - Regla: Una optativa puede estar "huérfana" de rama (por actualización de plan).

5. **Cursa → Grupo (RESTRICT)**
   - No se puede borrar un grupo mientras haya inscripciones.
   - Regla: Las inscripciones son históricas; no desaparecen.

6. **Resena → Grupo (SET NULL)**
   - Si un grupo se borra, la reseña queda sin referencia al grupo específico.
   - Regla: La reseña es independiente; se escribió sobre el profesor, no el grupo.

---

## Relaciones no implementadas como FK (y por qué)

| Relación | Razón |
|---|---|
| Estudiante → Período (período actual) | Derivada: se calcula de `cursa` filtrando periodo más reciente |
| Profesor → Carrera (enseña en qué carreras) | Derivada: se obtiene de `grupo.carrera_id` vía `grupo.profesor_id` |
| Materia → Materia (prerequisitos) | Sí implementada (como `prerrequisito`) |
| Grupo → Salón/Edificio | No está en el esquema actual; `sesion_horario` lleva edificio y aula como texto |

---

## Migración SQL: FK con acciones referenciales

```sql
-- ============================================================
-- MIGRACIÓN 002: Claves foráneas e integridad referencial
-- ============================================================

-- 1. estudiante → carrera (NO CASCADE)
ALTER TABLE estudiante
  ADD CONSTRAINT fk_est_car
    FOREIGN KEY (carrera_id) REFERENCES carrera(id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- 2. estudiante → periodo_ingreso (Sí SET NULL)
-- (Si periodo_ingreso_id existe en schema)
ALTER TABLE estudiante
  ADD CONSTRAINT fk_est_per_ing
    FOREIGN KEY (periodo_ingreso_id) REFERENCES periodo(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- 3. materia → carrera (NO CASCADE)
ALTER TABLE materia
  ADD CONSTRAINT fk_mat_car
    FOREIGN KEY (carrera_id) REFERENCES carrera(id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- ... (15 más, de forma análoga)

-- 18. Grupo → Profesor (Sí SET NULL)
ALTER TABLE grupo
  ADD CONSTRAINT fk_grp_prof
    FOREIGN KEY (profesor_id) REFERENCES profesor(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- 19. Cursa → Estudiante (NO CASCADE)
ALTER TABLE cursa
  ADD CONSTRAINT fk_crs_est
    FOREIGN KEY (estudiante_id) REFERENCES estudiante(id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- 20. Cursa → Grupo (NO RESTRICT — no se debe permitir borrar grupo con inscripciones)
ALTER TABLE cursa
  ADD CONSTRAINT fk_crs_grp
    FOREIGN KEY (grupo_id) REFERENCES grupo(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

COMMIT;
```

---

## Comprobación de integridad

Para verificar que todas las FK están declaradas:

```sql
-- Listar todas las FK en el esquema
SELECT
  tc.constraint_name,
  kcu.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
  JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
  JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
ORDER BY kcu.table_name, kcu.column_name;
```

**Resultado esperado:** Mínimo 21 filas (una por cada FK documentada arriba).
