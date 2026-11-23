-- =====================================================================
-- Practica 3 - Bases de Datos - ESCOM-IPN - Equipo Catscoms
-- Proyecto propio: Gestor academico ESCOM
--
-- Pruebas de restricciones. Primero carga unos datos minimos y despues
-- intenta cinco inserciones que el gestor DEBE rechazar. El rechazo es
-- la prueba de que el esquema protege los datos.
--
-- Ejecutar SIN ON_ERROR_STOP, para que el script continue tras cada
-- error y se vean los cinco mensajes:
--   docker exec -i pg-practica1 psql -U postgres -d catscoms_p3 \
--       < pruebas-de-restricciones.sql
-- =====================================================================

\set ON_ERROR_STOP off

-- ---------------------------------------------------------------------
-- Datos minimos
-- ---------------------------------------------------------------------
INSERT INTO carrera (nombre, plan_version, carga_minima, carga_media)
VALUES ('Ingenieria en Sistemas Computacionales', '2020', 4, 7);

INSERT INTO rama (carrera_id, nombre) VALUES (1, 'Ciberseguridad');

INSERT INTO periodo (nombre, fecha_inicio, fecha_fin)
VALUES ('2027/1', '2026-08-24', '2027-01-30');

INSERT INTO profesor (nombre) VALUES ('Hurtado Aviles Gabriel');

INSERT INTO estudiante (boleta, carrera_id, nombres, ap_paterno, ap_materno, correo)
VALUES ('2023630001', 1, 'Pablo', 'Mora', 'Acosta', 'pmora@alumno.ipn.mx');

INSERT INTO telefono_estudiante (estudiante_boleta, telefono, tipo)
VALUES ('2023630001', '5555550101', 'casa'),
       ('2023630001', '5512345678', 'celular');

INSERT INTO materia (carrera_id, nombre, creditos, unidades_aprendizaje, tipo)
VALUES (1, 'Bases de Datos', 7.5, 1, 'OBL');
INSERT INTO materia_obligatoria (materia_id, semestre_fijo, tiene_recurse)
VALUES (1, 4, TRUE);

INSERT INTO grupo (periodo_id, codigo, materia_id, profesor_id, turno, cupo)
VALUES (1, '4CV1', 1, 1, 'V', 2);

INSERT INTO sesion_horario (grupo_id, dia, bloque) VALUES (1, 1, 5);

INSERT INTO inscripcion_periodo
    (estudiante_boleta, periodo_id, situacion_escolar, ocupabilidad)
VALUES ('2023630001', 1, 'cero adeudos', 30);

INSERT INTO cursa (estudiante_boleta, periodo_id, grupo_id)
VALUES ('2023630001', 1, 1);


-- =====================================================================
-- PRUEBA 1 - Grupo sin profesor titular
-- Regla del modelo: [Profesor] - [Imparte] - [Grupo] es (0,N):(1,1),
-- asi que la clave foranea es NOT NULL. Ningun grupo puede publicarse
-- sin titular.
-- Se espera: null value in column "profesor_id" violates not-null constraint
-- =====================================================================
\echo '--- PRUEBA 1: grupo sin profesor (NOT NULL en la clave foranea) ---'
INSERT INTO grupo (periodo_id, codigo, materia_id, profesor_id, turno, cupo)
VALUES (1, '4CV2', 1, NULL, 'V', 30);


-- =====================================================================
-- PRUEBA 2 - Dos sesiones en el mismo grupo, dia y bloque
-- SesionHorario es entidad debil por identificacion: su clave parcial
-- dia + bloque solo distingue DENTRO de un grupo, de ahi la clave
-- primaria compuesta.
-- Se espera: duplicate key value violates unique constraint "pk_sesion"
-- =====================================================================
\echo '--- PRUEBA 2: sesion duplicada (clave primaria compuesta) ---'
INSERT INTO sesion_horario (grupo_id, dia, bloque) VALUES (1, 1, 5);


-- =====================================================================
-- PRUEBA 3 - Resena sobre una inscripcion que no existe
-- La agregacion exige que la resena se ancle a un registro real de
-- cursa: solo resena quien efectivamente curso.
-- Se espera: insert or update on table "resena" violates foreign key
--            constraint "fk_resena_cursa"
-- =====================================================================
\echo '--- PRUEBA 3: resena sin inscripcion que la respalde (clave foranea) ---'
INSERT INTO resena (estudiante_boleta, periodo_id, grupo_id,
                    calif_calidad, calif_dificultad, recomienda, texto)
VALUES ('2023630001', 1, 999, 9, 6, TRUE, 'Nunca curse este grupo');


-- =====================================================================
-- PRUEBA 4 - Codigo de grupo con formato invalido
-- El CHECK traduce la convencion de ESCOM: semestre, carrera, turno y
-- numero de grupo.
-- Se espera: new row violates check constraint "ck_grupo_codigo"
-- =====================================================================
\echo '--- PRUEBA 4: codigo de grupo fuera de formato (CHECK) ---'
INSERT INTO grupo (periodo_id, codigo, materia_id, profesor_id, turno, cupo)
VALUES (1, 'XXXX', 1, 1, 'V', 30);


-- =====================================================================
-- PRUEBA 5 - Segunda resena sobre el mismo curso
-- El UNIQUE sobre la clave de cursa impone "a lo sumo una resena por
-- inscripcion", que es la otra garantia de la agregacion.
-- Se espera: duplicate key value violates unique constraint
--            "uq_resena_por_curso"
-- =====================================================================
\echo '--- PRUEBA 5: dos resenas del mismo curso (UNIQUE) ---'
INSERT INTO resena (estudiante_boleta, periodo_id, grupo_id,
                    calif_calidad, calif_dificultad, recomienda)
VALUES ('2023630001', 1, 1, 8, 5, TRUE);
INSERT INTO resena (estudiante_boleta, periodo_id, grupo_id,
                    calif_calidad, calif_dificultad, recomienda)
VALUES ('2023630001', 1, 1, 3, 9, FALSE);


-- =====================================================================
-- PRUEBA 6 - Regla de negocio que no cabe en una cardinalidad:
-- rebasar la carga media de la carrera (7 UA en ISC).
-- La impone el disparador tg_valida_carga, no una restriccion
-- declarativa, porque el tope depende de un atributo de otra entidad.
-- Se espera: La inscripcion rebasa la carga media de la carrera
-- =====================================================================
\echo '--- PRUEBA 6: rebasar la carga media (disparador) ---'
-- Se evitan los id fijos: los INSERT rechazados arriba ya consumieron
-- la secuencia, asi que los grupos se localizan por su codigo.

-- seis materias mas de 1 UA, con su grupo
INSERT INTO materia (carrera_id, nombre, creditos, unidades_aprendizaje, tipo)
SELECT 1, 'Unidad de aprendizaje ' || g, 6.0, 1, 'OBL'
  FROM generate_series(1, 6) g;

INSERT INTO materia_obligatoria (materia_id, semestre_fijo)
SELECT id, 1 FROM materia WHERE nombre LIKE 'Unidad de aprendizaje %';

INSERT INTO grupo (periodo_id, codigo, materia_id, profesor_id, turno, cupo)
SELECT 1, '1CV' || ROW_NUMBER() OVER (ORDER BY id), id, 1, 'V', 30
  FROM materia WHERE nombre LIKE 'Unidad de aprendizaje %';

-- El estudiante ya lleva 1 UA (Bases de Datos). Estas seis lo dejan en
-- 7, que es exactamente la carga media de ISC: deben pasar.
INSERT INTO cursa (estudiante_boleta, periodo_id, grupo_id)
SELECT '2023630001', 1, id FROM grupo WHERE codigo LIKE '1CV%';

-- La septima rebasa el tope y el disparador la rechaza.
INSERT INTO materia (carrera_id, nombre, creditos, unidades_aprendizaje, tipo)
VALUES (1, 'Trabajo Terminal I', 10.0, 2, 'OBL');
INSERT INTO materia_obligatoria (materia_id, semestre_fijo)
SELECT id, 7 FROM materia WHERE nombre = 'Trabajo Terminal I';
INSERT INTO grupo (periodo_id, codigo, materia_id, profesor_id, turno, cupo)
SELECT 1, '7CV1', id, 1, 'V', 30 FROM materia WHERE nombre = 'Trabajo Terminal I';

INSERT INTO cursa (estudiante_boleta, periodo_id, grupo_id)
SELECT '2023630001', 1, id FROM grupo WHERE codigo = '7CV1';


-- ---------------------------------------------------------------------
-- Comprobacion final: el estado quedo consistente
-- ---------------------------------------------------------------------
\echo '--- Estado final: ninguna fila invalida entro ---'
SELECT 'grupo'          AS tabla, COUNT(*) FROM grupo
UNION ALL SELECT 'sesion_horario', COUNT(*) FROM sesion_horario
UNION ALL SELECT 'resena',         COUNT(*) FROM resena
UNION ALL SELECT 'cursa',          COUNT(*) FROM cursa;
