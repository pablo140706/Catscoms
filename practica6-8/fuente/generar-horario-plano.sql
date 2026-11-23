-- =====================================================================
--  Genera init/01-horario-plano-datos.sql desde la base de Gestorix
-- =====================================================================
--  NO lo corre el contenedor de la práctica: se corrió UNA vez contra la
--  base real de Gestorix (pablo140706/Gestorix) para sacar la muestra.
--  Queda aquí para que se vea de dónde salen los datos.
--
--  La muestra: grupos 1CM1, 1CM8 y 2CM1 de ISC en 26/2 y 27/1, y Trabajo
--  Terminal II (B801) de IA en 8BM1 y 8BM2 de 27/1 (varios asesores
--  comparten un cupo). Una fila por SESIÓN de clase, con todo repetido,
--  como el registro plano de iscweb (la versión de Gestorix sin base).
--
--  Desde la carpeta de Gestorix:
--    docker compose exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -At -q' \
--      < ruta/a/fuente/generar-horario-plano.sql > ruta/a/init/01-horario-plano-datos.sql
-- =====================================================================

WITH muestra AS (
    SELECT o.*
    FROM oferta o
    WHERE o.grupo IN ('1CM1', '1CM8', '2CM1')
       OR (o.periodo = '27/1' AND o.grupo IN ('8BM1', '8BM2') AND o.materia = 'B801')
),
reqs AS (   -- requisitos de cada materia, solo entre materias de la muestra, en una lista
    SELECT s.materia, string_agg(s.requisito, ',' ORDER BY s.requisito) AS requisitos
    FROM seriacion s
    WHERE s.materia IN (SELECT materia FROM muestra) AND s.requisito IN (SELECT materia FROM muestra)
    GROUP BY s.materia
),
filas AS (
    SELECT format('(%L, %L, %L, %L, %L, %L, %L, %L, %s, %s, %s, %L, %L, %L, %L, %s, %s, %s, %L, %s, %s, %s, %L, %L, %s, %s, %L, %L, %s, %s, %s)',
               o.periodo, pe.inicio, pe.fin, o.grupo, o.turno,
               m.clave, m.nombre, m.tipo, m.semestre, m.creditos, m.ua, r.requisitos,
               c.codigo, c.nombre, c.letra, c.carga_min_ua, c.carga_media_ua, c.carga_max_ua,
               p.nombre, coalesce(p.mp_calidad::text, 'NULL'), coalesce(p.mp_recomiendan::text, 'NULL'),
               coalesce(p.mp_dificultad::text, 'NULL'),
               nullif(o.edificio, ''), nullif(o.salon, ''),
               s.dia, s.bloque, to_char(b.inicio, 'HH24:MI'), to_char(b.fin, 'HH24:MI'),
               cu.cupo, cu.inscritos, cu.cupo - cu.inscritos) AS fila,
           o.periodo, o.grupo, m.clave, p.nombre AS profesor, s.dia, s.bloque
    FROM muestra o
    JOIN periodo pe   ON pe.codigo = o.periodo
    JOIN materia m    ON m.clave = o.materia
    JOIN carrera c    ON c.codigo = m.carrera
    JOIN profesor p   ON p.id = o.profesor
    JOIN sesion s     ON s.oferta = o.id
    JOIN bloque b     ON b.numero = s.bloque
    JOIN cupo cu      ON (cu.periodo, cu.grupo, cu.materia) = (o.periodo, o.grupo, o.materia)
    LEFT JOIN reqs r  ON r.materia = m.clave
)
SELECT '-- Generado con fuente/generar-horario-plano.sql desde la base de Gestorix (datos reales de SAES).' || E'\n'
    || '-- Una fila por sesión de clase: ' || count(*) || ' filas.' || E'\n'
    || 'INSERT INTO horario_plano VALUES' || E'\n'
    || string_agg(fila, E',\n' ORDER BY periodo, grupo, clave, profesor, dia, bloque) || ';'
FROM filas;
