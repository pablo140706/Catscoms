-- ============================================================
-- MIGRACIÓN 001: Dominios y restricciones de columna
-- Bases de Datos — Práctica 4 — Gestor académico ESCOM
-- ============================================================
-- Este archivo se ejecuta sobre el esquema vacío de Práctica 3.
-- Agrega dominios con CREATE DOMAIN, luego ALTER TABLE con
-- NOT NULL, DEFAULT, UNIQUE y CHECK.

-- ============================================================
-- Dominios reutilizables (PostgreSQL)
-- ============================================================

CREATE DOMAIN dominio_turno AS CHAR(1)
  CHECK (VALUE IN ('M', 'V'));
COMMENT ON DOMAIN dominio_turno IS 'Turno: M=Matutino, V=Vespertino';

CREATE DOMAIN dominio_tipo_cursa AS VARCHAR(20)
  CHECK (VALUE IN ('regular', 'recurse', 'especial'));
COMMENT ON DOMAIN dominio_tipo_cursa IS 'Tipo de inscripción: regular (1.ª vez), recurse (2.ª+), especial';

CREATE DOMAIN dominio_calificacion AS NUMERIC(4, 2)
  CHECK (VALUE >= 0 AND VALUE <= 10 OR VALUE IS NULL);
COMMENT ON DOMAIN dominio_calificacion IS 'Calificación: 0.00–10.00 o NULL (sin califa aún)';

CREATE DOMAIN dominio_promedio AS NUMERIC(5, 2)
  CHECK (VALUE >= 0 AND VALUE <= 10);
COMMENT ON DOMAIN dominio_promedio IS 'Promedio acumulado: 0.00–10.00';

CREATE DOMAIN dominio_creditos AS SMALLINT
  CHECK (VALUE > 0 AND VALUE <= 15);
COMMENT ON DOMAIN dominio_creditos IS 'Créditos por materia: 1–15 (típico 7–9)';

CREATE DOMAIN dominio_semestre AS SMALLINT
  CHECK (VALUE >= 1 AND VALUE <= 8);
COMMENT ON DOMAIN dominio_semestre IS 'Semestre: 1–8';

CREATE DOMAIN dominio_horas AS SMALLINT
  CHECK (VALUE >= 0 AND VALUE <= 10);
COMMENT ON DOMAIN dominio_horas IS 'Horas de clase por semana: 0–10';

-- ============================================================
-- Restricciones: carrera
-- ============================================================

ALTER TABLE carrera
  ADD CONSTRAINT ck_car_carga_minima
    CHECK (carga_minima > 0 AND carga_minima <= 10)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Carga mínima debe ser positiva y alcanzable en un período.

ALTER TABLE carrera
  ADD CONSTRAINT ck_car_carga_media
    CHECK (carga_media > carga_minima AND carga_media <= 60)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Carga media > mínima, pero realista (máx 60 créditos en un semestre).

ALTER TABLE carrera
  ADD CONSTRAINT ck_car_plan_version
    CHECK (plan_version ~ '^\d{4}$')
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: plan_version es un año en formato YYYY.

-- ============================================================
-- Restricciones: periodo
-- ============================================================

ALTER TABLE periodo
  ADD CONSTRAINT ck_per_semestre
    CHECK (semestre IN (1, 2))
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Semestre es 1 (enero–junio) o 2 (agosto–diciembre).

ALTER TABLE periodo
  ADD CONSTRAINT ck_per_anio
    CHECK (anio >= 2000 AND anio <= 2100)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Año plausible.

-- ============================================================
-- Restricciones: profesor
-- ============================================================

ALTER TABLE profesor
  ADD CONSTRAINT uk_prof_email
    UNIQUE (email)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Email es único por profesor (permite NULL si no tiene).

ALTER TABLE profesor
  ADD CONSTRAINT ck_prof_email
    CHECK (email IS NULL OR email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Si email existe, debe ser formato válido (RFC 5322 simplificado).

ALTER TABLE profesor
  ADD CONSTRAINT ck_prof_nombre_length
    CHECK (LENGTH(TRIM(nombre)) >= 3)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Nombre no puede ser vacío o muy corto.

-- ============================================================
-- Restricciones: estudiante
-- ============================================================

ALTER TABLE estudiante
  ADD CONSTRAINT uk_est_matricula
    UNIQUE (matricula)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Matrícula es única y no nula (PK de facto).

ALTER TABLE estudiante
  ADD CONSTRAINT ck_est_matricula
    CHECK (LENGTH(matricula) > 5 AND LENGTH(matricula) <= 20)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Matrícula tiene formato IPN (típicamente 10–15 caracteres).

ALTER TABLE estudiante
  ADD CONSTRAINT ck_est_email
    CHECK (email IS NULL OR email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Email válido si existe.

ALTER TABLE estudiante
  ADD CONSTRAINT ck_est_semestre
    CHECK (semestre_actual >= 1 AND semestre_actual <= 8)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Semestre actual es 1–8.

ALTER TABLE estudiante
  ADD CONSTRAINT ck_est_promedio
    CHECK (promedio IS NULL OR (promedio >= 0 AND promedio <= 10))
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Promedio es NULL (sin calificaciones aún) o 0–10.

ALTER TABLE estudiante
  ADD CONSTRAINT ck_est_fecha_ingreso
    CHECK (fecha_ingreso <= CURRENT_DATE)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Fecha de ingreso no puede ser en el futuro.

-- ============================================================
-- Restricciones: materia
-- ============================================================

ALTER TABLE materia
  ADD CONSTRAINT uk_mat_clave_carrera
    UNIQUE (clave, carrera_id)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Clave es única por carrera (no puede haber C101 dos veces en ISC).

ALTER TABLE materia
  ADD CONSTRAINT ck_mat_creditos
    CHECK (creditos > 0 AND creditos <= 15)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Créditos positivos y razonables.

ALTER TABLE materia
  ADD CONSTRAINT ck_mat_semestre
    CHECK (semestre_sugerido >= 1 AND semestre_sugerido <= 8)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Semestre sugerido es 1–8.

ALTER TABLE materia
  ADD CONSTRAINT ck_mat_horas
    CHECK (horas_teoria >= 0 AND horas_practica >= 0 AND (horas_teoria + horas_practica) > 0)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Al menos una hora de clase por semana; ambas ≥ 0.

ALTER TABLE materia
  ADD CONSTRAINT ck_mat_nombre_length
    CHECK (LENGTH(TRIM(nombre)) >= 3)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Nombre no puede estar vacío.

-- ============================================================
-- Restricciones: grupo
-- ============================================================

ALTER TABLE grupo
  ADD CONSTRAINT uk_grp_codigo_periodo
    UNIQUE (codigo, periodo_id)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Código de grupo es único por período (1CM1 solo aparece una vez en 2026/1).

ALTER TABLE grupo
  ADD CONSTRAINT ck_grp_codigo_format
    CHECK (codigo ~ '^[1-8][A-Z][MV][1-9]$')
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Formato VÁLIDO: [semestre 1-8][carrera A-Z][turno M-V][número 1-9].

ALTER TABLE grupo
  ADD CONSTRAINT ck_grp_cupo
    CHECK (cupo IS NULL OR cupo > 0)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Si cupo existe, es positivo. NULL = sin límite (tutoría, TT).

ALTER TABLE grupo
  ADD CONSTRAINT ck_grp_inscritos
    CHECK (inscritos >= 0 AND (cupo IS NULL OR inscritos <= cupo + 5))
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Inscritos ≥ 0. Permite sobrecupo de hasta 5 (espera de lista).

ALTER TABLE grupo
  ADD CONSTRAINT ck_grp_turno
    CHECK (turno IN ('M', 'V'))
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Turno es M (matutino, ~07:00-15:00) o V (vespertino, ~12:00-21:30).

-- ============================================================
-- Restricciones: sesion_horario
-- ============================================================

ALTER TABLE sesion_horario
  ADD CONSTRAINT ck_ses_horas
    CHECK (hora_inicio < hora_fin)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Hora de inicio anterior a hora de fin.

ALTER TABLE sesion_horario
  ADD CONSTRAINT ck_ses_dia
    CHECK (dia ~ '^(lunes|martes|miércoles|jueves|viernes|sábado)$')
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Día válido (lunes–sábado; domingo no hay clases en ESCOM).

-- ============================================================
-- Restricciones: cursa (inscripción)
-- ============================================================

ALTER TABLE cursa
  ADD CONSTRAINT uk_crs_est_grp
    UNIQUE (estudiante_id, grupo_id)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Estudiante no puede inscribirse dos veces en el mismo grupo.

ALTER TABLE cursa
  ADD CONSTRAINT ck_crs_calificacion
    CHECK (calificacion IS NULL OR (calificacion >= 0 AND calificacion <= 10))
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Calificación NULL (sin evaluar aún) o 0–10.

ALTER TABLE cursa
  ADD CONSTRAINT ck_crs_fechas
    CHECK (fecha_termino IS NULL OR fecha_termino >= fecha_inscripcion)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Fecha de término no anterior a inscripción (o NULL si en curso).

ALTER TABLE cursa
  ADD CONSTRAINT ck_crs_tipo
    CHECK (tipo IN ('regular', 'recurse', 'especial'))
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Tipo de inscripción válido.

-- ============================================================
-- Restricciones: materia_optativa
-- ============================================================

ALTER TABLE materia_optativa
  ADD CONSTRAINT ck_mop_slot_rama
    CHECK (
      (slot IN ('A1', 'B1', 'A2', 'B2') AND rama_id IS NOT NULL)
      OR
      (slot IS NULL AND rama_id IS NULL)
    )
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Si slot existe (ISC), rama_id debe existir. Si no (IA/LCD), ambos NULL.
-- Nota: Esto es una simplificación. Idealmente, sería "si carrera_id de materia es ISC, entonces...".

-- ============================================================
-- Restricciones: rama (optativas)
-- ============================================================

ALTER TABLE rama
  ADD CONSTRAINT uk_ram_nombre_carrera
    UNIQUE (nombre, carrera_id)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Nombre de rama único por carrera (no puede haber dos "Criptografía" en ISC).

-- ============================================================
-- Restricciones: prerrequisito
-- ============================================================

ALTER TABLE prerrequisito
  ADD CONSTRAINT uk_pre_materia_prereq
    UNIQUE (materia_id, prerequisito_id)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: No puede haber prerrequisito duplicado (Cálculo II requiere Cálculo I una sola vez).

ALTER TABLE prerrequisito
  ADD CONSTRAINT ck_pre_no_circular
    CHECK (materia_id <> prerequisito_id)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Una materia no puede ser prerrequisito de sí misma.

-- ============================================================
-- Restricciones: telefono_estudiante
-- ============================================================

ALTER TABLE telefono_estudiante
  ADD CONSTRAINT ck_tel_numero
    CHECK (numero ~ '^\+?[0-9]{10,}$')
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Teléfono tiene al menos 10 dígitos (con o sin +).

-- ============================================================
-- Restricciones: resena
-- ============================================================

ALTER TABLE resena
  ADD CONSTRAINT ck_res_calidad
    CHECK (calidad >= 0 AND calidad <= 10)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Calidad de profesor: 0–10.

ALTER TABLE resena
  ADD CONSTRAINT ck_res_dificultad
    CHECK (dificultad >= 0 AND dificultad <= 10)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Dificultad: 0–10.

ALTER TABLE resena
  ADD CONSTRAINT ck_res_recomiendan
    CHECK (recomiendan IN (0, 1))
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Recomiendan es booleano (0=no, 1=sí).

ALTER TABLE resena
  ADD CONSTRAINT ck_res_fecha
    CHECK (fecha_resena <= CURRENT_DATE)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: La reseña no puede ser de una fecha futura.

-- ============================================================
-- Restricciones: evento_calendario y evento_personal
-- ============================================================

ALTER TABLE evento_calendario
  ADD CONSTRAINT ck_eve_cal_fechas
    CHECK (fecha_fin >= fecha_inicio)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Evento no puede terminar antes de empezar.

ALTER TABLE evento_personal
  ADD CONSTRAINT ck_eve_per_fechas
    CHECK (fecha_fin >= fecha_inicio)
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Ídem.

ALTER TABLE evento_personal
  ADD CONSTRAINT ck_eve_per_prioridad
    CHECK (prioridad IN ('baja', 'media', 'alta'))
    DEFERRABLE INITIALLY DEFERRED;
-- Regla: Prioridad es una de las tres categorías válidas.

COMMIT;
