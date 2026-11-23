-- =====================================================================
--  Exporta la base normalizada al formato de grupo de RelaX
-- =====================================================================
--  Ejercicio 2.1. Lo corre consultas/correr.sh dentro del contenedor:
--      psql -At -q -f relax/exportar-grupo.sql > relax/grupo.txt
--  Si la base cambia, el grupo se regenera con el mismo comando: nada se
--  copia a mano.
--
--  Cada tabla sale como:   tabla = { col:tipo, …   filas }
--  La función es temporal (pg_temp): no deja nada en la base.
--
--  Qué tablas van: las seis que usan las consultas. Quedan fuera
--  "sesion" (90 filas: pasa de 30) y "bloque" y "periodo", que ninguna
--  consulta usa. "carrera" (2) y "seriacion" (3) tienen menos de 10
--  porque la muestra solo trae esas: no se inventan filas.
-- =====================================================================

CREATE FUNCTION pg_temp.a_relax(t text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE
    encabezado text;
    valores    text;
    orden      text;
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
     WHERE table_schema = 'public' AND table_name = t;

    EXECUTE format('SELECT string_agg(%s, E''\n'' ORDER BY %s) FROM public.%I', valores, orden, t) INTO filas;
    RETURN t || ' = {' || E'\n' || encabezado || E'\n' || coalesce(filas, '') || E'\n}' || E'\n';
END $$;

SELECT 'group: Gestorix (práctica 6, 7 y 8)' || E'\n'
    || 'description[[Muestra real de Gestorix ya normalizada: grupos 1CM1, 1CM8 y 2CM1 de ISC en 26/2 y 27/1, '
    || 'y Trabajo Terminal II (B801) de IA en 8BM1 y 8BM2, donde varios asesores comparten un cupo. '
    || 'Generado desde la base con relax/exportar-grupo.sql.]]' || E'\n';
SELECT pg_temp.a_relax('carrera');
SELECT pg_temp.a_relax('materia');
SELECT pg_temp.a_relax('seriacion');
SELECT pg_temp.a_relax('profesor');
SELECT pg_temp.a_relax('oferta');
SELECT pg_temp.a_relax('cupo');
