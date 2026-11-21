-- =====================================================================
--  Gestorix · escribe el grupo de RelaX a partir del esquema "relax"
-- =====================================================================
--  Primero corre subconjunto.sql. Luego, desde la raíz del repo:
--
--    docker compose exec -T db psql -U gestorix_admin -d gestorix -At -q \
--        < docs/relax/exportar.sql > docs/relax/gestorix.txt
--
--  Cada tabla sale con el formato de RelaX:  tabla = { col:tipo, …  filas }
-- =====================================================================

CREATE OR REPLACE FUNCTION relax.a_relax(t text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE
    encabezado text;
    valores    text;
    orden      text;   -- todas las columnas: filas siempre en el mismo orden
    filas      text;
BEGIN
    SELECT string_agg(column_name || ':' ||
               CASE WHEN data_type IN ('smallint', 'integer', 'bigint', 'numeric') THEN 'number' ELSE 'string' END,
               ', ' ORDER BY ordinal_position),
           string_agg(
               CASE WHEN data_type IN ('smallint', 'integer', 'bigint', 'numeric')
                    THEN format('coalesce(%I::text, ''null'')', column_name)
                    ELSE format('coalesce(quote_literal(%I), ''null'')', column_name) END,
               ' || '', '' || ' ORDER BY ordinal_position),
           string_agg(quote_ident(column_name), ', ' ORDER BY ordinal_position)
      INTO encabezado, valores, orden
      FROM information_schema.columns
     WHERE table_schema = 'relax' AND table_name = t;

    EXECUTE format('SELECT string_agg(%s, E''\n'' ORDER BY %s) FROM relax.%I', valores, orden, t) INTO filas;
    RETURN t || ' = {' || E'\n' || encabezado || E'\n' || filas || E'\n}' || E'\n';
END $$;

SELECT 'group: Gestorix (subconjunto real, 27/1 y 26/2)' || E'\n'
    || 'description[[Parte de la base de Gestorix: grupos 1CM1, 1CM2, 1CM8 y 2CM1 de ISC en 26/2 y 27/1, '
    || 'y Trabajo Terminal II (B801) de IA en 8BM1 y 8BM2, que comparten un cupo entre varios asesores. '
    || 'Generado con docs/relax/subconjunto.sql y exportar.sql.]]' || E'\n';
SELECT relax.a_relax('carrera');
SELECT relax.a_relax('materia');
SELECT relax.a_relax('seriacion');
SELECT relax.a_relax('profesor');
SELECT relax.a_relax('oferta');
SELECT relax.a_relax('cupo');
