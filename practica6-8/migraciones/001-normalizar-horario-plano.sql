-- =====================================================================
--  Migración 001 · Normalizar horario_plano hasta FNBC
-- =====================================================================
--  Ejercicio 1.3.4: el esquema resultante de normalizacion.md, aplicado
--  sobre la base YA POBLADA. No se carga nada a mano: cada tabla nueva se
--  llena con INSERT … SELECT DISTINCT desde horario_plano.
--
--  Si una dependencia funcional NO se cumpliera en los datos (por ejemplo,
--  dos calidades distintas para el mismo profesor), el SELECT DISTINCT
--  daría dos filas con la misma llave y la llave primaria haría fallar la
--  migración. O sea: la migración también comprueba F sobre los datos.
--
--  Al final se comprueba que la reunión de las tablas nuevas devuelve
--  exactamente las filas de horario_plano (sin pérdida y sin tuplas de
--  más). Si no, se aborta y no queda nada a medias (todo va en una
--  transacción). horario_plano no se borra: se mueve al esquema "antes".
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
--  1FN: "requisitos" era una lista. Cada requisito pasa a ser su fila
--  (tabla seriacion, más abajo).
--  2FN y 3FN: una tabla por cada determinante del recubrimiento mínimo.
-- ---------------------------------------------------------------------

-- carrera → carrera_nombre, letra, cargas   y   letra → carrera
CREATE TABLE carrera (
    codigo          VARCHAR(3)  PRIMARY KEY,
    letra           CHAR(1)     NOT NULL UNIQUE,   -- también es clave candidata
    nombre          TEXT        NOT NULL,
    carga_min_ua    SMALLINT    NOT NULL,
    carga_media_ua  SMALLINT    NOT NULL,
    carga_max_ua    SMALLINT    NOT NULL,
    CHECK (0 < carga_min_ua AND carga_min_ua <= carga_media_ua AND carga_media_ua <= carga_max_ua)
);
INSERT INTO carrera
SELECT DISTINCT carrera, letra, carrera_nombre, carga_min_ua, carga_media_ua, carga_max_ua
FROM horario_plano;

-- periodo → periodo_inicio, periodo_fin
CREATE TABLE periodo (
    codigo  VARCHAR(4)  PRIMARY KEY CHECK (codigo ~ '^[0-9]{2}/[12]$'),
    inicio  DATE,
    fin     DATE,
    CHECK (fin IS NULL OR inicio IS NULL OR fin >= inicio)
);
INSERT INTO periodo
SELECT DISTINCT periodo, periodo_inicio, periodo_fin FROM horario_plano;

-- clave → materia, tipo, semestre, creditos, ua, carrera
CREATE TABLE materia (
    clave     VARCHAR(5)    PRIMARY KEY,
    carrera   VARCHAR(3)    NOT NULL REFERENCES carrera,
    nombre    TEXT          NOT NULL,
    tipo      CHAR(3)       NOT NULL CHECK (tipo IN ('OBL', 'OPT')),
    semestre  SMALLINT      NOT NULL CHECK (semestre BETWEEN 1 AND 8),
    creditos  NUMERIC(4,1)  NOT NULL CHECK (creditos > 0),
    ua        SMALLINT      NOT NULL CHECK (ua IN (1, 2))
);
INSERT INTO materia
SELECT DISTINCT clave, carrera, materia, tipo, semestre, creditos, ua FROM horario_plano;

-- 1FN: la lista "requisitos" se parte en filas
CREATE TABLE seriacion (
    materia    VARCHAR(5)  REFERENCES materia,
    requisito  VARCHAR(5)  REFERENCES materia,
    PRIMARY KEY (materia, requisito),
    CHECK (materia <> requisito)
);
INSERT INTO seriacion
SELECT DISTINCT clave, trim(r)
FROM horario_plano, unnest(string_to_array(requisitos, ',')) AS r
WHERE requisitos IS NOT NULL;

-- profesor → mp_calidad, mp_recomiendan, mp_dificultad
-- (id sustituto: así oferta apunta a un número y no a un nombre largo)
CREATE TABLE profesor (
    id              SERIAL        PRIMARY KEY,
    nombre          TEXT          NOT NULL UNIQUE,
    mp_calidad      NUMERIC(3,1)  CHECK (mp_calidad     BETWEEN 0 AND 10),
    mp_recomiendan  NUMERIC(4,1)  CHECK (mp_recomiendan BETWEEN 0 AND 100),
    mp_dificultad   NUMERIC(3,1)  CHECK (mp_dificultad  BETWEEN 0 AND 10)
);
INSERT INTO profesor (nombre, mp_calidad, mp_recomiendan, mp_dificultad)
SELECT DISTINCT profesor, mp_calidad, mp_recomiendan, mp_dificultad
FROM horario_plano
ORDER BY profesor;

-- bloque → hora_ini, hora_fin
CREATE TABLE bloque (
    numero  SMALLINT  PRIMARY KEY CHECK (numero BETWEEN 1 AND 9),
    inicio  TIME      NOT NULL UNIQUE,
    fin     TIME      NOT NULL UNIQUE,
    CHECK (fin > inicio)
);
INSERT INTO bloque
SELECT DISTINCT bloque, hora_ini, hora_fin FROM horario_plano;

-- periodo, grupo, clave, profesor → edificio, salon
-- grupo → turno se conserva como columna GENERADA (normalizacion.md, §1.3):
-- el gestor la calcula y nadie la puede escribir, así que no se contradice.
CREATE TABLE oferta (
    id        SERIAL      PRIMARY KEY,
    periodo   VARCHAR(4)  NOT NULL REFERENCES periodo,
    grupo     VARCHAR(5)  NOT NULL CHECK (grupo ~ '^[1-8][ABC][MVX][1-9][0-9]?$'),
    materia   VARCHAR(5)  NOT NULL REFERENCES materia,
    profesor  INT         NOT NULL REFERENCES profesor,
    turno     CHAR(1)     GENERATED ALWAYS AS (substr(grupo, 3, 1)) STORED,
    edificio  TEXT,
    salon     TEXT,
    UNIQUE (periodo, grupo, materia, profesor)
);
INSERT INTO oferta (periodo, grupo, materia, profesor, edificio, salon)
SELECT DISTINCT h.periodo, h.grupo, h.clave, p.id, h.edificio, h.salon
FROM horario_plano h JOIN profesor p ON p.nombre = h.profesor
ORDER BY h.periodo, h.grupo, h.clave, p.id;

-- La llave completa de R: cada sesión de cada oferta
CREATE TABLE sesion (
    oferta  INT       REFERENCES oferta ON DELETE CASCADE,
    dia     SMALLINT  CHECK (dia BETWEEN 1 AND 6),
    bloque  SMALLINT  REFERENCES bloque,
    PRIMARY KEY (oferta, dia, bloque)
);
INSERT INTO sesion
SELECT DISTINCT o.id, h.dia, h.bloque
FROM horario_plano h
JOIN profesor p ON p.nombre = h.profesor
JOIN oferta o   ON (o.periodo, o.grupo, o.materia, o.profesor) = (h.periodo, h.grupo, h.clave, p.id);

-- periodo, grupo, clave → cupo, inscritos   (SAES da el cupo por grupo + materia)
-- disponibles NO se guarda: cupo, inscritos → disponibles es transitiva (3FN);
-- se calcula al consultar (cupo − inscritos).
CREATE TABLE cupo (
    periodo    VARCHAR(4)  REFERENCES periodo,
    grupo      VARCHAR(5)  CHECK (grupo ~ '^[1-8][ABC][MVX][1-9][0-9]?$'),
    materia    VARCHAR(5)  REFERENCES materia,
    cupo       SMALLINT    NOT NULL CHECK (cupo >= 0),
    inscritos  SMALLINT    NOT NULL CHECK (inscritos >= 0),
    PRIMARY KEY (periodo, grupo, materia)
);
INSERT INTO cupo
SELECT DISTINCT periodo, grupo, clave, cupo, inscritos FROM horario_plano;

-- ---------------------------------------------------------------------
--  Comprobación: la reunión de las tablas nuevas = horario_plano.
--  "Sin pérdida" = no falta ninguna fila; "sin tuplas espurias" = no
--  sobra ninguna. Se compara en los dos sentidos con EXCEPT.
-- ---------------------------------------------------------------------
CREATE TEMP VIEW reconstruida AS
SELECT o.periodo, pe.inicio AS periodo_inicio, pe.fin AS periodo_fin, o.grupo, o.turno,
       m.clave, m.nombre AS materia, m.tipo, m.semestre, m.creditos, m.ua,
       (SELECT string_agg(s.requisito, ',' ORDER BY s.requisito) FROM seriacion s WHERE s.materia = m.clave) AS requisitos,
       c.codigo AS carrera, c.nombre AS carrera_nombre, c.letra, c.carga_min_ua, c.carga_media_ua, c.carga_max_ua,
       p.nombre AS profesor, p.mp_calidad, p.mp_recomiendan, p.mp_dificultad,
       o.edificio, o.salon, se.dia, se.bloque, b.inicio AS hora_ini, b.fin AS hora_fin,
       cu.cupo, cu.inscritos, (cu.cupo - cu.inscritos)::smallint AS disponibles
FROM oferta o
JOIN periodo pe  ON pe.codigo = o.periodo
JOIN materia m   ON m.clave = o.materia
JOIN carrera c   ON c.codigo = m.carrera
JOIN profesor p  ON p.id = o.profesor
JOIN sesion se   ON se.oferta = o.id
JOIN bloque b    ON b.numero = se.bloque
JOIN cupo cu     ON (cu.periodo, cu.grupo, cu.materia) = (o.periodo, o.grupo, o.materia);

DO $$
DECLARE
    faltan  int;
    sobran  int;
    antes   int;
BEGIN
    SELECT count(*) INTO antes FROM horario_plano;
    SELECT count(*) INTO faltan FROM (SELECT * FROM horario_plano EXCEPT SELECT * FROM reconstruida) x;
    SELECT count(*) INTO sobran FROM (SELECT * FROM reconstruida EXCEPT SELECT * FROM horario_plano) x;
    IF faltan > 0 OR sobran > 0 THEN
        RAISE EXCEPTION 'La descomposición no reconstruye horario_plano: faltan %, sobran %', faltan, sobran;
    END IF;
    RAISE NOTICE 'Sin pérdida: las % filas de horario_plano salen igual al reunir las tablas nuevas (faltan 0, sobran 0).', antes;
END $$;

-- La tabla plana no se borra: queda en el esquema "antes" para compararla.
CREATE SCHEMA antes;
ALTER TABLE horario_plano SET SCHEMA antes;

COMMIT;
