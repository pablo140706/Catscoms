-- =====================================================================
--  Gestorix · subconjunto para RelaX (práctica integrada 6, 7 y 8)
-- =====================================================================
--  Copia una parte chica y real de la base al esquema "relax", con las
--  mismas columnas que el grupo de RelaX (gestorix.txt). Así el SQL de
--  docs/algebra.md da exactamente lo mismo aquí que en RelaX:
--
--      SET search_path = relax;     -- y luego la consulta
--
--  Qué entra: los grupos 1CM1, 1CM2, 1CM8 y 2CM1 de ISC en 26/2 y 27/1,
--  y Trabajo Terminal II (B801) de IA en 8BM1 y 8BM2 de 27/1 (varios
--  asesores comparten un cupo). Con sus materias, profesores, cupos y
--  seriación.
--
--  Correr con el administrador (no toca las tablas de la app):
--      docker compose exec -T db psql -U gestorix_admin -d gestorix < docs/relax/subconjunto.sql
--  Se puede repetir: borra y vuelve a crear SOLO el esquema relax.
-- =====================================================================

DROP SCHEMA IF EXISTS relax CASCADE;
CREATE SCHEMA relax;

CREATE TABLE relax.oferta AS
SELECT o.id, o.periodo, o.grupo, o.materia, o.profesor, o.turno, o.edificio, o.salon
FROM public.oferta o
WHERE (o.grupo IN ('1CM1', '1CM2', '1CM8', '2CM1'))
   OR (o.periodo = '27/1' AND o.grupo IN ('8BM1', '8BM2') AND o.materia = 'B801');

CREATE TABLE relax.materia AS
SELECT m.clave, m.carrera, m.nombre, m.tipo, m.semestre, m.creditos, m.ua
FROM public.materia m
WHERE m.clave IN (SELECT materia FROM relax.oferta);

CREATE TABLE relax.carrera AS
SELECT codigo, letra, nombre, carga_min_ua, carga_media_ua, carga_max_ua
FROM public.carrera;

CREATE TABLE relax.profesor AS
SELECT p.id, p.nombre, p.mp_calidad, p.mp_recomiendan, p.mp_dificultad
FROM public.profesor p
WHERE p.id IN (SELECT profesor FROM relax.oferta);

CREATE TABLE relax.cupo AS
SELECT c.periodo, c.grupo, c.materia, c.cupo, c.inscritos
FROM public.cupo c
WHERE (c.periodo, c.grupo, c.materia) IN (SELECT periodo, grupo, materia FROM relax.oferta);

CREATE TABLE relax.seriacion AS
SELECT s.materia, s.requisito
FROM public.seriacion s
WHERE s.materia IN (SELECT clave FROM relax.materia)
  AND s.requisito IN (SELECT clave FROM relax.materia);

-- Las mismas llaves que en la base, para que el subconjunto sea consistente.
ALTER TABLE relax.carrera   ADD PRIMARY KEY (codigo);
ALTER TABLE relax.materia   ADD PRIMARY KEY (clave);
ALTER TABLE relax.profesor  ADD PRIMARY KEY (id);
ALTER TABLE relax.oferta    ADD PRIMARY KEY (id);
ALTER TABLE relax.cupo      ADD PRIMARY KEY (periodo, grupo, materia);
ALTER TABLE relax.seriacion ADD PRIMARY KEY (materia, requisito);
ALTER TABLE relax.materia   ADD FOREIGN KEY (carrera)   REFERENCES relax.carrera;
ALTER TABLE relax.oferta    ADD FOREIGN KEY (materia)   REFERENCES relax.materia;
ALTER TABLE relax.oferta    ADD FOREIGN KEY (profesor)  REFERENCES relax.profesor;
ALTER TABLE relax.seriacion ADD FOREIGN KEY (materia)   REFERENCES relax.materia;
ALTER TABLE relax.seriacion ADD FOREIGN KEY (requisito) REFERENCES relax.materia;

SELECT 'oferta' AS tabla, count(*) FROM relax.oferta
UNION ALL SELECT 'materia',   count(*) FROM relax.materia
UNION ALL SELECT 'carrera',   count(*) FROM relax.carrera
UNION ALL SELECT 'profesor',  count(*) FROM relax.profesor
UNION ALL SELECT 'cupo',      count(*) FROM relax.cupo
UNION ALL SELECT 'seriacion', count(*) FROM relax.seriacion;
