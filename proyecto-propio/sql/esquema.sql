-- =====================================================================
-- Practica 3 - Bases de Datos - ESCOM-IPN - Equipo Catscoms
-- Proyecto propio: Gestor academico ESCOM
--
-- Esquema relacional obtenido al transformar el modelo EER del
-- ejercicio 4 de la Practica 2, aplicando las reglas 1 a 9.
--
-- Gestor: PostgreSQL 16
-- Ejecutar:
--   docker exec -i pg-practica1 psql -U postgres -d catscoms_p3 \
--       -v ON_ERROR_STOP=1 < esquema.sql
-- =====================================================================

BEGIN;

-- Se eliminan en orden inverso de dependencia para poder re-ejecutar
-- el script durante las pruebas.
DROP TABLE IF EXISTS reporte_resena      CASCADE;
DROP TABLE IF EXISTS resena              CASCADE;
DROP TABLE IF EXISTS cursa               CASCADE;
DROP TABLE IF EXISTS sesion_horario      CASCADE;
DROP TABLE IF EXISTS grupo               CASCADE;
DROP TABLE IF EXISTS inscripcion_periodo CASCADE;
DROP TABLE IF EXISTS evento_personal     CASCADE;
DROP TABLE IF EXISTS evento_calendario   CASCADE;
DROP TABLE IF EXISTS prerrequisito       CASCADE;
DROP TABLE IF EXISTS materia_optativa    CASCADE;
DROP TABLE IF EXISTS materia_obligatoria CASCADE;
DROP TABLE IF EXISTS materia             CASCADE;
DROP TABLE IF EXISTS telefono_estudiante CASCADE;
DROP TABLE IF EXISTS estudiante          CASCADE;
DROP TABLE IF EXISTS rama                CASCADE;
DROP TABLE IF EXISTS profesor            CASCADE;
DROP TABLE IF EXISTS periodo             CASCADE;
DROP TABLE IF EXISTS carrera             CASCADE;


-- =====================================================================
-- REGLA 1. Entidades fuertes
-- =====================================================================

-- Carrera -------------------------------------------------------------
-- carga_minima y carga_media salen del procedimiento de reinscripcion:
-- 4 y 7 UA en ISC, 4 y 6 en IIA y LCD.
CREATE TABLE carrera (
    id              SMALLINT     GENERATED ALWAYS AS IDENTITY,
    nombre          VARCHAR(80)  NOT NULL,
    plan_version    CHAR(4)      NOT NULL,
    carga_minima    SMALLINT     NOT NULL DEFAULT 4,
    carga_media     SMALLINT     NOT NULL,
    CONSTRAINT pk_carrera            PRIMARY KEY (id),
    CONSTRAINT uq_carrera_nombre     UNIQUE (nombre, plan_version),
    CONSTRAINT ck_carrera_cargas     CHECK (carga_minima > 0
                                            AND carga_media >= carga_minima)
);

-- Periodo -------------------------------------------------------------
CREATE TABLE periodo (
    id            SMALLINT    GENERATED ALWAYS AS IDENTITY,
    nombre        VARCHAR(10) NOT NULL,          -- p. ej. 2027/1
    fecha_inicio  DATE        NOT NULL,
    fecha_fin     DATE        NOT NULL,
    CONSTRAINT pk_periodo         PRIMARY KEY (id),
    CONSTRAINT uq_periodo_nombre  UNIQUE (nombre),
    CONSTRAINT ck_periodo_fechas  CHECK (fecha_fin > fecha_inicio)
);

-- Profesor ------------------------------------------------------------
CREATE TABLE profesor (
    id           INTEGER      GENERATED ALWAYS AS IDENTITY,
    nombre       VARCHAR(120) NOT NULL,
    link_fuente  TEXT,
    CONSTRAINT pk_profesor PRIMARY KEY (id)
);

-- Rama ----------------------------------------------------------------
-- REGLA 4: Carrera (1) -- Rama (N). carrera_id NOT NULL porque la
-- cardinalidad minima del lado Rama es 1.
CREATE TABLE rama (
    id          SMALLINT    GENERATED ALWAYS AS IDENTITY,
    carrera_id  SMALLINT    NOT NULL,
    nombre      VARCHAR(80) NOT NULL,
    CONSTRAINT pk_rama         PRIMARY KEY (id),
    CONSTRAINT uq_rama_nombre  UNIQUE (carrera_id, nombre),
    CONSTRAINT fk_rama_carrera FOREIGN KEY (carrera_id)
        REFERENCES carrera (id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Estudiante ----------------------------------------------------------
-- REGLA 2: el atributo compuesto `nombre` se descompone en sus tres
-- componentes simples y el atributo padre desaparece.
-- `promedio` es derivado de cursa; se deja como columna calculada en
-- consulta, no se almacena (ver seccion 6.5 del documento).
CREATE TABLE estudiante (
    boleta      CHAR(10)     NOT NULL,
    carrera_id  SMALLINT     NOT NULL,
    nombres     VARCHAR(80)  NOT NULL,
    ap_paterno  VARCHAR(60)  NOT NULL,
    ap_materno  VARCHAR(60),
    correo      VARCHAR(120) NOT NULL,
    CONSTRAINT pk_estudiante         PRIMARY KEY (boleta),
    CONSTRAINT uq_estudiante_correo  UNIQUE (correo),
    CONSTRAINT ck_estudiante_boleta  CHECK (boleta ~ '^[0-9]{10}$'),
    CONSTRAINT ck_estudiante_correo  CHECK (correo LIKE '%@%'),
    CONSTRAINT fk_estudiante_carrera FOREIGN KEY (carrera_id)
        REFERENCES carrera (id) ON DELETE RESTRICT ON UPDATE CASCADE
);


-- =====================================================================
-- REGLA 3. Atributo multivaluado
-- =====================================================================
-- Estudiante.telefono es multivaluado: el procedimiento de
-- reinscripcion exige telefono de casa y celular. Tabla propia con la
-- clave de la entidad original mas el valor; la clave primaria es la
-- combinacion de ambos.
CREATE TABLE telefono_estudiante (
    estudiante_boleta CHAR(10)    NOT NULL,
    telefono          VARCHAR(15) NOT NULL,
    tipo              VARCHAR(10) NOT NULL,
    CONSTRAINT pk_telefono       PRIMARY KEY (estudiante_boleta, telefono),
    CONSTRAINT ck_telefono_tipo  CHECK (tipo IN ('casa', 'celular')),
    CONSTRAINT ck_telefono_digitos CHECK (telefono ~ '^[0-9]{8,15}$'),
    CONSTRAINT fk_telefono_estudiante FOREIGN KEY (estudiante_boleta)
        REFERENCES estudiante (boleta) ON DELETE CASCADE ON UPDATE CASCADE
);


-- =====================================================================
-- REGLA 9. Jerarquia Materia -> MateriaObligatoria / MateriaOptativa
-- Estrategia A: una tabla para el supertipo y una por cada subtipo.
-- Justificacion en la seccion 5 del documento de transformacion.
-- =====================================================================

CREATE TABLE materia (
    id                   INTEGER      GENERATED ALWAYS AS IDENTITY,
    carrera_id           SMALLINT     NOT NULL,
    nombre               VARCHAR(120) NOT NULL,
    creditos             NUMERIC(4,2) NOT NULL,
    unidades_aprendizaje SMALLINT     NOT NULL DEFAULT 1,
    tipo                 CHAR(3)      NOT NULL,   -- discriminador: OBL | OPT
    link_plan_estudios   TEXT,
    CONSTRAINT pk_materia        PRIMARY KEY (id),
    CONSTRAINT uq_materia_nombre UNIQUE (carrera_id, nombre),
    CONSTRAINT ck_materia_tipo   CHECK (tipo IN ('OBL', 'OPT')),
    CONSTRAINT ck_materia_creditos CHECK (creditos > 0),
    CONSTRAINT ck_materia_ua     CHECK (unidades_aprendizaje BETWEEN 1 AND 2),
    CONSTRAINT fk_materia_carrera FOREIGN KEY (carrera_id)
        REFERENCES carrera (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    -- permite que los subtipos referencien (id, tipo) y asi el gestor
    -- garantice la disyuncion: una materia no puede estar en las dos
    CONSTRAINT uq_materia_id_tipo UNIQUE (id, tipo)
);

CREATE TABLE materia_obligatoria (
    materia_id    INTEGER  NOT NULL,
    tipo          CHAR(3)  NOT NULL DEFAULT 'OBL',
    semestre_fijo SMALLINT NOT NULL,
    tiene_recurse BOOLEAN  NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_materia_obligatoria PRIMARY KEY (materia_id),
    CONSTRAINT ck_mo_tipo      CHECK (tipo = 'OBL'),
    CONSTRAINT ck_mo_semestre  CHECK (semestre_fijo BETWEEN 1 AND 8),
    CONSTRAINT fk_mo_materia FOREIGN KEY (materia_id, tipo)
        REFERENCES materia (id, tipo) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE materia_optativa (
    materia_id        INTEGER  NOT NULL,
    tipo              CHAR(3)  NOT NULL DEFAULT 'OPT',
    slot              CHAR(2)  NOT NULL,
    semestre_sugerido SMALLINT NOT NULL,
    rama_id           SMALLINT NOT NULL,          -- REGLA 4, (1,1) del lado optativa
    CONSTRAINT pk_materia_optativa PRIMARY KEY (materia_id),
    CONSTRAINT ck_mop_tipo     CHECK (tipo = 'OPT'),
    CONSTRAINT ck_mop_slot     CHECK (slot IN ('A1', 'B1', 'A2', 'B2')),
    CONSTRAINT ck_mop_semestre CHECK (semestre_sugerido BETWEEN 1 AND 8),
    CONSTRAINT fk_mop_materia FOREIGN KEY (materia_id, tipo)
        REFERENCES materia (id, tipo) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_mop_rama FOREIGN KEY (rama_id)
        REFERENCES rama (id) ON DELETE RESTRICT ON UPDATE CASCADE
);


-- =====================================================================
-- REGLA 5. Relacion recursiva muchos a muchos: prerrequisitos
-- =====================================================================
CREATE TABLE prerrequisito (
    materia_id          INTEGER NOT NULL,
    requiere_materia_id INTEGER NOT NULL,
    CONSTRAINT pk_prerrequisito PRIMARY KEY (materia_id, requiere_materia_id),
    CONSTRAINT ck_prerrequisito_no_refleja CHECK (materia_id <> requiere_materia_id),
    CONSTRAINT fk_prq_materia FOREIGN KEY (materia_id)
        REFERENCES materia (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_prq_requiere FOREIGN KEY (requiere_materia_id)
        REFERENCES materia (id) ON DELETE RESTRICT ON UPDATE CASCADE
);


-- =====================================================================
-- REGLA 8. Entidades debiles
-- =====================================================================

-- InscripcionPeriodo: dependencia de IDENTIFICACION de Estudiante y
-- Periodo. Clave primaria compuesta por las dos foraneas, sin
-- discriminador propio. ON DELETE CASCADE.
CREATE TABLE inscripcion_periodo (
    estudiante_boleta CHAR(10)    NOT NULL,
    periodo_id        SMALLINT    NOT NULL,
    situacion_escolar VARCHAR(40) NOT NULL,
    ocupabilidad      SMALLINT    NOT NULL,
    CONSTRAINT pk_inscripcion PRIMARY KEY (estudiante_boleta, periodo_id),
    CONSTRAINT ck_inscripcion_ocupabilidad CHECK (ocupabilidad IN (30, 34, 36)),
    CONSTRAINT ck_inscripcion_situacion CHECK (situacion_escolar IN (
        'cero adeudos', 'con adeudos', 'ua desfasada',
        'dictamen vigente', 'regreso de baja', 'recuperado ets')),
    CONSTRAINT fk_inscripcion_estudiante FOREIGN KEY (estudiante_boleta)
        REFERENCES estudiante (boleta) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_inscripcion_periodo FOREIGN KEY (periodo_id)
        REFERENCES periodo (id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Grupo: dependencia de IDENTIFICACION de Periodo. El discriminador es
-- `codigo`: ESCOM reutiliza 6CV3 cada semestre, asi que la clave real
-- es (periodo_id, codigo). Se conserva un id subrogado para que las
-- tablas hijas no arrastren dos columnas, y la clave natural queda
-- declarada como UNIQUE.
CREATE TABLE grupo (
    id          INTEGER  GENERATED ALWAYS AS IDENTITY,
    periodo_id  SMALLINT NOT NULL,
    codigo      CHAR(4)  NOT NULL,
    materia_id  INTEGER  NOT NULL,
    profesor_id INTEGER  NOT NULL,          -- (1,1): ningun grupo sin titular
    turno       CHAR(1)  NOT NULL,
    cupo        SMALLINT NOT NULL,
    CONSTRAINT pk_grupo            PRIMARY KEY (id),
    CONSTRAINT uq_grupo_natural    UNIQUE (periodo_id, codigo),
    CONSTRAINT ck_grupo_codigo     CHECK (codigo ~ '^[1-8][A-Z][MV][1-9]$'),
    CONSTRAINT ck_grupo_turno      CHECK (turno IN ('M', 'V')),
    CONSTRAINT ck_grupo_cupo       CHECK (cupo BETWEEN 1 AND 40),
    CONSTRAINT fk_grupo_periodo FOREIGN KEY (periodo_id)
        REFERENCES periodo (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_grupo_materia FOREIGN KEY (materia_id)
        REFERENCES materia (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_grupo_profesor FOREIGN KEY (profesor_id)
        REFERENCES profesor (id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- SesionHorario: dependencia de IDENTIFICACION de Grupo. Clave parcial
-- dia + bloque, que solo distingue dentro de un grupo.
CREATE TABLE sesion_horario (
    grupo_id INTEGER  NOT NULL,
    dia      SMALLINT NOT NULL,
    bloque   SMALLINT NOT NULL,
    CONSTRAINT pk_sesion       PRIMARY KEY (grupo_id, dia, bloque),
    CONSTRAINT ck_sesion_dia    CHECK (dia BETWEEN 1 AND 6),
    CONSTRAINT ck_sesion_bloque CHECK (bloque BETWEEN 1 AND 9),
    CONSTRAINT fk_sesion_grupo FOREIGN KEY (grupo_id)
        REFERENCES grupo (id) ON DELETE CASCADE ON UPDATE CASCADE
);


-- =====================================================================
-- REGLA 5. Relacion muchos a muchos con atributos propios
-- InscripcionPeriodo -- Cursa -- Grupo  (0,N):(0,N)
--
-- El tope de carga (Carrera.carga_media) y el cupo del grupo NO son
-- cardinalidades: se verifican con los disparadores del final.
-- =====================================================================
CREATE TABLE cursa (
    estudiante_boleta CHAR(10)     NOT NULL,
    periodo_id        SMALLINT     NOT NULL,
    grupo_id          INTEGER      NOT NULL,
    calificacion      NUMERIC(4,2),
    veces_cursada     SMALLINT     NOT NULL DEFAULT 1,
    es_adeudo         BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_cursa PRIMARY KEY (estudiante_boleta, periodo_id, grupo_id),
    CONSTRAINT ck_cursa_calificacion CHECK (calificacion IS NULL
                                            OR calificacion BETWEEN 0 AND 10),
    CONSTRAINT ck_cursa_veces CHECK (veces_cursada BETWEEN 1 AND 3),
    CONSTRAINT fk_cursa_inscripcion FOREIGN KEY (estudiante_boleta, periodo_id)
        REFERENCES inscripcion_periodo (estudiante_boleta, periodo_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_cursa_grupo FOREIGN KEY (grupo_id)
        REFERENCES grupo (id) ON DELETE RESTRICT ON UPDATE CASCADE
);


-- =====================================================================
-- Agregacion: la resena se ancla a un registro de cursa, no al par
-- (estudiante, profesor). El UNIQUE sobre la clave de cursa impone
-- "a lo sumo una resena por curso".
-- El profesor resenado NO se guarda: se deriva por grupo.profesor_id.
-- =====================================================================
CREATE TABLE resena (
    id                INTEGER      GENERATED ALWAYS AS IDENTITY,
    estudiante_boleta CHAR(10)     NOT NULL,
    periodo_id        SMALLINT     NOT NULL,
    grupo_id          INTEGER      NOT NULL,
    calif_calidad     SMALLINT     NOT NULL,
    calif_dificultad  SMALLINT     NOT NULL,
    recomienda        BOOLEAN      NOT NULL,
    texto             VARCHAR(400),
    es_anonima        BOOLEAN      NOT NULL DEFAULT FALSE,
    fecha             TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT pk_resena PRIMARY KEY (id),
    CONSTRAINT uq_resena_por_curso UNIQUE (estudiante_boleta, periodo_id, grupo_id),
    CONSTRAINT ck_resena_calidad    CHECK (calif_calidad BETWEEN 1 AND 10),
    CONSTRAINT ck_resena_dificultad CHECK (calif_dificultad BETWEEN 1 AND 10),
    CONSTRAINT fk_resena_cursa FOREIGN KEY (estudiante_boleta, periodo_id, grupo_id)
        REFERENCES cursa (estudiante_boleta, periodo_id, grupo_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ReporteResena: dependencia de EXISTENCIA. Tiene clave propia y
-- agrega la foranea como NOT NULL.
CREATE TABLE reporte_resena (
    id                INTEGER     GENERATED ALWAYS AS IDENTITY,
    resena_id         INTEGER     NOT NULL,
    reportante_boleta CHAR(10)    NOT NULL,
    motivo            VARCHAR(40) NOT NULL,
    estado            VARCHAR(20) NOT NULL DEFAULT 'pendiente',
    CONSTRAINT pk_reporte PRIMARY KEY (id),
    CONSTRAINT uq_reporte_por_usuario UNIQUE (resena_id, reportante_boleta),
    CONSTRAINT ck_reporte_estado CHECK (estado IN ('pendiente', 'aceptado', 'rechazado')),
    CONSTRAINT fk_reporte_resena FOREIGN KEY (resena_id)
        REFERENCES resena (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reporte_estudiante FOREIGN KEY (reportante_boleta)
        REFERENCES estudiante (boleta) ON DELETE CASCADE ON UPDATE CASCADE
);


-- =====================================================================
-- Calendario oficial y agenda personal
-- =====================================================================
CREATE TABLE evento_calendario (
    id           INTEGER      GENERATED ALWAYS AS IDENTITY,
    periodo_id   SMALLINT     NOT NULL,
    nombre       VARCHAR(120) NOT NULL,
    tipo_evento  VARCHAR(40)  NOT NULL,
    fecha_inicio DATE         NOT NULL,
    fecha_fin    DATE         NOT NULL,
    CONSTRAINT pk_evento_calendario PRIMARY KEY (id),
    CONSTRAINT ck_ec_fechas CHECK (fecha_fin >= fecha_inicio),
    CONSTRAINT fk_ec_periodo FOREIGN KEY (periodo_id)
        REFERENCES periodo (id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- EventoPersonal: dependencia de EXISTENCIA sobre Estudiante.
-- materia_id admite nulos porque la cardinalidad minima es 0.
CREATE TABLE evento_personal (
    id                INTEGER      GENERATED ALWAYS AS IDENTITY,
    estudiante_boleta CHAR(10)     NOT NULL,
    materia_id        INTEGER,
    titulo            VARCHAR(120) NOT NULL,
    fecha             TIMESTAMPTZ  NOT NULL,
    tipo              VARCHAR(30)  NOT NULL,
    CONSTRAINT pk_evento_personal PRIMARY KEY (id),
    CONSTRAINT fk_ep_estudiante FOREIGN KEY (estudiante_boleta)
        REFERENCES estudiante (boleta) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ep_materia FOREIGN KEY (materia_id)
        REFERENCES materia (id) ON DELETE SET NULL ON UPDATE CASCADE
);


-- =====================================================================
-- Reglas de negocio que NO caben en una cardinalidad
-- =====================================================================

-- 1. La carga inscrita no puede rebasar la carga media de la carrera.
--    El tope depende de Carrera.carga_media (7 en ISC, 6 en IIA y LCD)
--    y se cuenta en unidades de aprendizaje, no en grupos.
CREATE OR REPLACE FUNCTION fn_valida_carga() RETURNS TRIGGER AS $$
DECLARE
    tope   SMALLINT;
    actual SMALLINT;
BEGIN
    SELECT c.carga_media INTO tope
      FROM estudiante e
      JOIN carrera c ON c.id = e.carrera_id
     WHERE e.boleta = NEW.estudiante_boleta;

    SELECT COALESCE(SUM(m.unidades_aprendizaje), 0) INTO actual
      FROM cursa cu
      JOIN grupo g   ON g.id = cu.grupo_id
      JOIN materia m ON m.id = g.materia_id
     WHERE cu.estudiante_boleta = NEW.estudiante_boleta
       AND cu.periodo_id        = NEW.periodo_id;

    IF actual + (SELECT m.unidades_aprendizaje
                   FROM grupo g JOIN materia m ON m.id = g.materia_id
                  WHERE g.id = NEW.grupo_id) > tope THEN
        RAISE EXCEPTION
            'La inscripcion rebasa la carga media de la carrera (tope: % UA)', tope
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_valida_carga
    BEFORE INSERT ON cursa
    FOR EACH ROW EXECUTE FUNCTION fn_valida_carga();

-- 2. Un grupo no admite mas inscritos que su cupo.
CREATE OR REPLACE FUNCTION fn_valida_cupo() RETURNS TRIGGER AS $$
DECLARE
    limite   SMALLINT;
    ocupados SMALLINT;
BEGIN
    SELECT cupo INTO limite FROM grupo WHERE id = NEW.grupo_id;
    SELECT COUNT(*) INTO ocupados FROM cursa WHERE grupo_id = NEW.grupo_id;

    IF ocupados >= limite THEN
        RAISE EXCEPTION 'El grupo ya alcanzo su cupo de % lugares', limite
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_valida_cupo
    BEFORE INSERT ON cursa
    FOR EACH ROW EXECUTE FUNCTION fn_valida_cupo();

-- 3. Solo una materia optativa puede pertenecer a una rama de su
--    propia carrera.
CREATE OR REPLACE FUNCTION fn_valida_rama() RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT r.carrera_id FROM rama r WHERE r.id = NEW.rama_id)
       <> (SELECT m.carrera_id FROM materia m WHERE m.id = NEW.materia_id) THEN
        RAISE EXCEPTION 'La rama pertenece a una carrera distinta de la materia'
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_valida_rama
    BEFORE INSERT OR UPDATE ON materia_optativa
    FOR EACH ROW EXECUTE FUNCTION fn_valida_rama();


-- =====================================================================
-- Atributos derivados: no se almacenan, se calculan
-- =====================================================================
CREATE VIEW v_estudiante_promedio AS
SELECT e.boleta,
       e.nombres || ' ' || e.ap_paterno AS nombre_completo,
       ROUND(AVG(cu.calificacion), 2) AS promedio
  FROM estudiante e
  LEFT JOIN cursa cu ON cu.estudiante_boleta = e.boleta
                    AND cu.calificacion IS NOT NULL
 GROUP BY e.boleta, e.nombres, e.ap_paterno;

CREATE VIEW v_carga_por_periodo AS
SELECT ip.estudiante_boleta,
       ip.periodo_id,
       ip.situacion_escolar,
       ip.ocupabilidad,
       COALESCE(SUM(m.unidades_aprendizaje), 0) AS carga_inscrita,
       COUNT(*) FILTER (WHERE cu.es_adeudo)     AS adeudos_contabilizados
  FROM inscripcion_periodo ip
  LEFT JOIN cursa cu   ON cu.estudiante_boleta = ip.estudiante_boleta
                      AND cu.periodo_id        = ip.periodo_id
  LEFT JOIN grupo g    ON g.id = cu.grupo_id
  LEFT JOIN materia m  ON m.id = g.materia_id
 GROUP BY ip.estudiante_boleta, ip.periodo_id, ip.situacion_escolar, ip.ocupabilidad;

COMMIT;
