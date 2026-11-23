-- =====================================================================
--  00 · La base "antes": el registro plano de horarios
-- =====================================================================
--  Así guardaba iscweb (la versión de Gestorix sin base de datos) los
--  horarios: una fila por SESIÓN de clase, con la materia, su carrera, el
--  profesor, el salón y el cupo repetidos en cada fila. Es la relación R
--  de normalizacion.md, desnormalizada a propósito con datos reales.
--
--  Ni siquiera está en 1FN: "requisitos" es una lista ("C101,C104").
--  La única llave es la de cada sesión: periodo + grupo + materia +
--  profesor + día + bloque (en TT varios asesores comparten grupo y
--  materia, por eso el profesor es parte de la llave).
--
--  La migración migraciones/001 la normaliza moviendo estos renglones.
-- =====================================================================

CREATE TABLE horario_plano (
    periodo          VARCHAR(4)    NOT NULL,   -- 27/1
    periodo_inicio   DATE,                     -- NULL si no se sabe (26/2)
    periodo_fin      DATE,
    grupo            VARCHAR(5)    NOT NULL,   -- 2CM1
    turno            CHAR(1)       NOT NULL,   -- M, V o X: 3.ª letra del grupo
    clave            VARCHAR(5)    NOT NULL,   -- C203
    materia          TEXT          NOT NULL,   -- Cálculo aplicado
    tipo             CHAR(3)       NOT NULL,   -- OBL u OPT
    semestre         SMALLINT      NOT NULL,
    creditos         NUMERIC(4,1)  NOT NULL,
    ua               SMALLINT      NOT NULL,
    requisitos       TEXT,                     -- lista separada por comas: NO es atómico
    carrera          VARCHAR(3)    NOT NULL,   -- ISC
    carrera_nombre   TEXT          NOT NULL,
    letra            CHAR(1)       NOT NULL,   -- C
    carga_min_ua     SMALLINT      NOT NULL,
    carga_media_ua   SMALLINT      NOT NULL,
    carga_max_ua     SMALLINT      NOT NULL,
    profesor         TEXT          NOT NULL,   -- nombre completo
    mp_calidad       NUMERIC(3,1),             -- métricas de MisProfesores (NULL = sin dato)
    mp_recomiendan   NUMERIC(4,1),
    mp_dificultad    NUMERIC(3,1),
    edificio         TEXT,
    salon            TEXT,
    dia              SMALLINT      NOT NULL,   -- 1 = lunes … 6 = sábado
    bloque           SMALLINT      NOT NULL,   -- 1 a 9
    hora_ini         TIME          NOT NULL,
    hora_fin         TIME          NOT NULL,
    cupo             SMALLINT      NOT NULL,   -- de SAES, por grupo + materia
    inscritos        SMALLINT      NOT NULL,
    disponibles      SMALLINT      NOT NULL,   -- cupo − inscritos
    PRIMARY KEY (periodo, grupo, clave, profesor, dia, bloque)
);
