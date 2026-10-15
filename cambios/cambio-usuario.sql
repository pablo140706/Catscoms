-- =====================================================================
-- Practica 3 - Ejercicio 8 - Cambio de esquema por integrante
-- Mora Acosta Pablo - pablo140706
--
-- Propuesta: "Bitacora de carga y auditoria de registros descartados"
-- Issue: https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/2
--
-- Proyecto asignado: Sistema de visualizacion de datos sismicos
-- Se ejecuta sobre una COPIA de la base, no sobre datawarehouse:
--   docker exec -i seismic-data-visualization-system-db-1 \
--       psql -U postgres -d dw_pablo140706 -v ON_ERROR_STOP=1 \
--       < cambio-pablo140706.sql
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- El problema
--
-- El almacen se construye a partir de datos abiertos heterogeneos. Al
-- cargarlos se descartan filas: coordenadas fuera de rango, entidades
-- que no casan con el catalogo, magnitudes ausentes. Hoy ese descarte
-- no deja rastro: la fila simplemente no llega a la tabla de hechos y
-- nadie puede saber cuantas se perdieron, por que, ni de que archivo
-- venian. Tampoco hay forma de distinguir "no hubo sismos" de "la
-- carga fallo a la mitad".
-- ---------------------------------------------------------------------

-- REGLA 1. Entidad fuerte nueva: cada ejecucion del proceso de carga.
CREATE TABLE carga_lote (
    id_lote           INTEGER      GENERATED ALWAYS AS IDENTITY,
    archivo_origen    TEXT         NOT NULL,
    tabla_destino     VARCHAR(63)  NOT NULL,
    inicio            TIMESTAMPTZ  NOT NULL DEFAULT now(),
    fin               TIMESTAMPTZ,
    filas_leidas      INTEGER      NOT NULL DEFAULT 0,
    filas_insertadas  INTEGER      NOT NULL DEFAULT 0,
    filas_descartadas INTEGER      NOT NULL DEFAULT 0,
    estado            VARCHAR(12)  NOT NULL DEFAULT 'en_proceso',
    CONSTRAINT pk_carga_lote PRIMARY KEY (id_lote),
    CONSTRAINT ck_lote_estado CHECK (estado IN ('en_proceso', 'completado', 'fallido')),
    CONSTRAINT ck_lote_fechas CHECK (fin IS NULL OR fin >= inicio),
    CONSTRAINT ck_lote_conteos CHECK (
        filas_leidas >= 0
        AND filas_insertadas >= 0
        AND filas_descartadas >= 0
        AND filas_insertadas + filas_descartadas <= filas_leidas)
);

COMMENT ON TABLE carga_lote IS
    'Una fila por ejecucion del proceso de carga. Permite distinguir una '
    'carga vacia de una carga fallida.';

-- REGLA 4. Relacion uno a muchos: un lote descarta cero o muchos
-- registros; cada registro descartado pertenece a exactamente un lote,
-- asi que la clave foranea es NOT NULL y va con ON DELETE CASCADE:
-- el descarte no tiene sentido sin la carga que lo produjo.
CREATE TABLE registro_descartado (
    id_descarte   INTEGER      GENERATED ALWAYS AS IDENTITY,
    id_lote       INTEGER      NOT NULL,
    numero_linea  INTEGER      NOT NULL,
    motivo        VARCHAR(40)  NOT NULL,
    detalle       TEXT,
    contenido     JSONB        NOT NULL,
    registrado_en TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT pk_registro_descartado PRIMARY KEY (id_descarte),
    CONSTRAINT uq_descarte_linea UNIQUE (id_lote, numero_linea),
    CONSTRAINT ck_descarte_linea CHECK (numero_linea > 0),
    CONSTRAINT ck_descarte_motivo CHECK (motivo IN (
        'coordenada_invalida',
        'magnitud_ausente',
        'entidad_no_catalogada',
        'fecha_invalida',
        'duplicado',
        'otro')),
    CONSTRAINT fk_descarte_lote FOREIGN KEY (id_lote)
        REFERENCES carga_lote (id_lote) ON DELETE CASCADE ON UPDATE CASCADE
);

COMMENT ON COLUMN registro_descartado.contenido IS
    'La fila original tal como venia en la fuente. JSONB y no TEXT porque '
    'las fuentes tienen columnas distintas entre si y se quiere poder '
    'consultar campo por campo sin volver a parsear.';

-- Indices para las consultas de auditoria que habilita el cambio.
CREATE INDEX ix_descarte_motivo ON registro_descartado (motivo);
CREATE INDEX ix_descarte_lote   ON registro_descartado (id_lote);

-- La tabla de hechos gana la trazabilidad al lote que la cargo.
-- Admite nulos a proposito: las filas que ya existian se cargaron
-- antes de que existiera la bitacora y no se les puede inventar un
-- lote de origen.
ALTER TABLE fact_impacto_sismos_imputed
    ADD COLUMN id_lote INTEGER;

ALTER TABLE fact_impacto_sismos_imputed
    ADD CONSTRAINT fk_fact_lote FOREIGN KEY (id_lote)
        REFERENCES carga_lote (id_lote) ON DELETE SET NULL ON UPDATE CASCADE;

COMMIT;


-- =====================================================================
-- Datos de ejemplo, para poder demostrar la consulta en clase
-- =====================================================================
BEGIN;

INSERT INTO carga_lote (archivo_origen, tabla_destino, fin,
                        filas_leidas, filas_insertadas, filas_descartadas, estado)
VALUES ('sismos_ssn_2024.csv',   'dim_sismos', now(), 1200, 1174, 26, 'completado'),
       ('censo_inegi_2020.csv',  'dim_zonas',  now(),   32,   32,  0, 'completado'),
       ('economia_inegi.csv',    'dim_economia', now(), 40,   32,  8, 'completado');

INSERT INTO registro_descartado (id_lote, numero_linea, motivo, detalle, contenido)
VALUES
 (1,  18, 'magnitud_ausente',      'La columna magnitud venia vacia',
     '{"fecha":"2024-03-02","latitud":16.21,"longitud":-98.04,"magnitud":null}'),
 (1,  54, 'coordenada_invalida',   'Longitud fuera del rango de Mexico',
     '{"fecha":"2024-03-11","latitud":17.9,"longitud":-204.5,"magnitud":4.1}'),
 (1, 310, 'coordenada_invalida',   'Latitud fuera del rango de Mexico',
     '{"fecha":"2024-05-21","latitud":99.9,"longitud":-95.2,"magnitud":3.8}'),
 (1, 702, 'fecha_invalida',        'Fecha posterior a la de la carga',
     '{"fecha":"2031-01-01","latitud":16.5,"longitud":-97.1,"magnitud":5.2}'),
 (1, 905, 'duplicado',             'Mismo sismo ya cargado en la linea 904',
     '{"fecha":"2024-09-08","latitud":15.8,"longitud":-96.2,"magnitud":6.1}'),
 (3,   7, 'entidad_no_catalogada', 'La entidad no existe en el catalogo del censo',
     '{"nombre_entidad":"Estado de Mexico Oriente","entidad":"99"}'),
 (3,  22, 'entidad_no_catalogada', 'Clave de entidad con letras',
     '{"nombre_entidad":"Jalisco","entidad":"JA"}');

UPDATE carga_lote SET filas_descartadas = (
    SELECT COUNT(*) FROM registro_descartado d WHERE d.id_lote = carga_lote.id_lote);

COMMIT;


-- =====================================================================
-- La consulta que SOLO es posible despues del cambio
--
-- Antes, una fila descartada no se guardaba en ningun lado: no existia
-- la pregunta. Ahora se puede auditar cada carga, saber que proporcion
-- se perdio y por que motivo, y recuperar la fila original para
-- corregirla.
-- =====================================================================
\echo '=== Auditoria de cargas: que se perdio y por que ==='

SELECT l.id_lote,
       l.archivo_origen,
       l.tabla_destino,
       d.motivo,
       COUNT(*) AS descartados,
       ROUND(100.0 * COUNT(*) / l.filas_leidas, 2) AS pct_del_archivo
  FROM carga_lote l
  JOIN registro_descartado d ON d.id_lote = l.id_lote
 GROUP BY l.id_lote, l.archivo_origen, l.tabla_destino, l.filas_leidas, d.motivo
 ORDER BY l.id_lote, descartados DESC;

\echo ''
\echo '=== Las filas con coordenada invalida, listas para corregir ==='

SELECT d.id_lote,
       d.numero_linea,
       d.contenido ->> 'fecha'    AS fecha,
       d.contenido ->> 'latitud'  AS latitud,
       d.contenido ->> 'longitud' AS longitud,
       d.detalle
  FROM registro_descartado d
 WHERE d.motivo = 'coordenada_invalida'
 ORDER BY d.id_lote, d.numero_linea;
