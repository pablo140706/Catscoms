# Modelo relacional de Gestorix

Sale de [`sql/00-tablas.sql`](https://github.com/pablo140706/Gestorix/blob/main/sql/00-tablas.sql), que es el que manda. GitHub dibuja los
diagramas solo (Mermaid). Están en dos partes para que se lean: el **catálogo** (lo que viene de
SAES y del IPN) y lo de los **usuarios** (cuentas, avance, comentarios y moderación). La tabla
`usuario` sale en las dos partes porque las une.

Notación: `||` = exactamente uno, `|o` = cero o uno (llave foránea que acepta `NULL`),
`o{` = cero o muchos. PK = llave primaria, FK = llave foránea, UK = única.

## 1. Catálogo: plan de estudios, profesores y horarios

```mermaid
erDiagram
    carrera ||--o{ materia : "tiene"
    carrera ||--o{ ruta_optativa : "tiene"
    materia ||--o{ seriacion : "es la materia"
    materia ||--o{ seriacion : "es el requisito"
    ruta_optativa ||--o{ ruta_materia : "agrupa"
    materia ||--o{ ruta_materia : "pertenece a"
    periodo |o--o{ evento_calendario : "contiene"
    periodo ||--o{ oferta : "en"
    materia ||--o{ oferta : "se imparte en"
    profesor |o--o{ oferta : "imparte"
    profesor ||--o{ cedula : "tiene"
    materia ||--o{ equivalencia : "equivale a"
    materia ||--o{ equivalencia : "es la equivalente"
    oferta ||--o{ sesion : "se da en"
    bloque ||--o{ sesion : "ocupa"
    periodo ||--o{ cupo : "en"
    materia ||--o{ cupo : "de"
    cupo }o..o{ oferta : "se cruzan por periodo, grupo y materia (sin FK)"

    carrera {
        varchar codigo PK "ISC, IA, LCD"
        char letra UK "C, B, A"
        text nombre
        smallint plan
        smallint carga_min_ua
        smallint carga_media_ua
        smallint carga_max_ua
    }
    materia {
        varchar clave PK "C101, B643"
        varchar carrera FK "UK con semestre y nombre_saes"
        text nombre
        text nombre_saes
        text nombre_en
        char tipo "OBL u OPT"
        smallint semestre "1 a 8"
        numeric creditos
        smallint ua "1, o 2 en TT"
        smallint orden
        boolean se_ofrece
        text descripcion "propósito y temas del PDF"
        text descripcion_fuente "NULL = programa oficial"
        text pdf
    }
    seriacion {
        varchar materia PK, FK
        varchar requisito PK, FK
        boolean oficial
    }
    ruta_optativa {
        serial id PK
        varchar carrera FK
        text nombre
        varchar icono
    }
    ruta_materia {
        int ruta PK, FK
        varchar materia PK, FK
    }
    periodo {
        varchar codigo PK "27/1"
        date inicio
        date fin
    }
    evento_calendario {
        serial id PK
        varchar periodo FK "NULL = fuera de periodo"
        date inicio
        date fin
        text tipo
    }
    profesor {
        serial id PK
        text nombre
        text nombre_norm UK
        text mp_link
        numeric mp_calidad "0 a 10"
        numeric mp_recomiendan "0 a 100"
        numeric mp_dificultad "0 a 10"
    }
    oferta {
        serial id PK
        varchar periodo FK "UK con grupo, materia y profesor"
        varchar grupo "2CM1"
        varchar materia FK
        int profesor FK "NULL = sin asignar"
        char turno "generado del grupo"
        text edificio
        text salon
    }
    equivalencia {
        varchar materia PK, FK "de SAES, entre carreras"
        varchar equivalente PK, FK "distinta de materia"
    }
    cedula {
        int profesor PK, FK
        varchar numero PK "Registro Nacional de Profesionistas"
        varchar nivel "licenciatura, ingenieria, especialidad, maestria, doctorado"
    }
    bloque {
        smallint numero PK "1 a 9"
        time inicio UK
        time fin UK
    }
    sesion {
        int oferta PK, FK
        smallint dia PK "1 a 6"
        smallint bloque PK, FK
    }
    cupo {
        varchar periodo PK, FK
        varchar grupo PK
        varchar materia PK, FK
        smallint cupo
        smallint inscritos
    }
```

## 2. Usuarios: cuentas, avance, horario, agenda y comentarios

```mermaid
erDiagram
    carrera ||--o{ usuario : "elige al registrarse"
    usuario ||--o{ token : "recibe"
    usuario ||--o{ avance : "captura"
    materia ||--o{ avance : "de"
    usuario ||--o{ horario : "arma"
    oferta ||--o{ horario : "inscrita en"
    usuario ||--o{ recordatorio : "apunta"
    materia |o--o{ recordatorio : "sobre"
    usuario |o--o{ comentario : "escribe"
    profesor ||--o{ comentario : "recibe"
    materia ||--o{ comentario : "etiqueta"
    comentario ||--o{ rubrica : "desglosa"
    comentario ||--o{ reporte : "recibe"
    usuario |o--o{ reporte : "reporta o resuelve"
    usuario |o--o{ bitacora : "actúa o es objetivo"
    comentario |o--o{ bitacora : "es objetivo"
    usuario ||--o{ alias_cambio : "cambia su alias"
    usuario ||--o{ moderador_carrera : "modera"
    carrera ||--o{ moderador_carrera : "moderada por"

    usuario {
        serial id PK
        text correo UK "en minúsculas"
        text hash "password_hash"
        boolean verificado
        varchar alias UK "sin importar mayúsculas"
        varchar rol "alumno, moderador, admin"
        varchar carrera FK
        timestamptz creado
        timestamptz suspendido_hasta
        boolean baneado
        varchar ingreso "periodo, 25/1"
    }
    alias_cambio {
        serial id PK
        int usuario FK
        varchar alias_anterior
        varchar alias_nuevo
        int por FK "el mismo usuario o un admin"
        timestamptz cuando "3 al año por usuario"
    }
    moderador_carrera {
        int usuario PK, FK
        varchar carrera PK, FK
    }
    correo_borrado {
        char hash PK "sha256 del correo, sin FK"
        timestamptz hasta "7 días sin poder registrarse"
    }
    token {
        char hash PK "sha256"
        int usuario FK
        varchar tipo "verificar o recuperar"
        timestamptz expira
    }
    avance {
        int usuario PK, FK
        varchar materia PK, FK
        smallint veces "1 o 2"
        smallint calif "0 a 10"
        smallint calif_ets "solo si reprobó"
        varchar resultado "aprobada o reprobada, sin número"
        varchar resultado_ets "aprobado o reprobado, sin número"
        varchar periodo_reprobada "para el desfase"
    }
    horario {
        int usuario PK, FK
        int oferta PK, FK
    }
    recordatorio {
        serial id PK
        int usuario FK
        date fecha
        time hora "NULL = todo el día"
        varchar titulo
        varchar materia FK "opcional"
        varchar nota
    }
    comentario {
        serial id PK
        int usuario FK "se borra con la cuenta"
        int profesor FK
        varchar materia FK
        smallint calidad "0 a 10"
        boolean recomienda
        smallint dificultad "0 a 10"
        varchar texto "máximo 500"
        timestamptz creado
        timestamptz editado
        varchar estado "visible u oculto"
        varchar anonimo "nombre al azar o NULL"
    }
    rubrica {
        int comentario PK, FK
        varchar concepto PK
        smallint porcentaje "1 a 100"
    }
    reporte {
        serial id PK
        int comentario FK
        int reportante FK
        varchar motivo
        timestamptz creado
        varchar estado
        int resuelto_por FK
    }
    bitacora {
        serial id PK
        int actor FK
        varchar accion
        int objetivo_usuario FK
        int objetivo_comentario FK
        varchar motivo
        timestamptz cuando
    }
    carrera {
        varchar codigo PK
    }
    materia {
        varchar clave PK
    }
    oferta {
        serial id PK
    }
    profesor {
        serial id PK
    }
```

## 3. Qué pasa al borrar (acciones referenciales)

| Llave foránea | Al borrar el padre | Por qué |
|---|---|---|
| `sesion.oferta` | `CASCADE` | Una sesión no existe sin su clase |
| `cedula.profesor` | `CASCADE` | Las cédulas son parte del profesor |
| `token`, `avance`, `horario`, `recordatorio`, `alias_cambio`, `moderador_carrera` → `usuario` | `CASCADE` | Son datos personales o permisos: se van con la cuenta |
| `rubrica.comentario`, `reporte.comentario` | `CASCADE` | Son parte del comentario |
| `comentario.usuario` | `CASCADE` | Se borran con la cuenta (cambio del 2026-11-21 por un reporte de abuso: antes quedaban como "usuario eliminado") |
| `alias_cambio.por` | `SET NULL` | El historial de alias se queda aunque se borre el admin que lo cambió |
| `reporte.reportante`, `reporte.resuelto_por`, `bitacora.*` | `SET NULL` | La bitácora de moderación no se pierde si alguien borra su cuenta |
| Todo lo del catálogo (`materia`, `profesor`, `oferta`, `periodo`…) | `NO ACTION` (rechaza) | pgAdmin no deja borrar una materia o un profesor que se está usando |

## 4. Restricciones de dominio que vale la pena enseñar

| Tabla | Restricción | Qué atrapa |
|---|---|---|
| `oferta`, `cupo` | `grupo ~ '^[1-8][ABC][MVX][1-9][0-9]?$'` | Un grupo mal escrito (`2XM1`); acepta `1CM10` |
| `profesor` | `mp_calidad` y `mp_dificultad BETWEEN 0 AND 10` | Errores reales de captura en las métricas de iscweb: OLALDE 83 en calidad, LUNA BENOSO 44 y MÁRQUEZ ARREGUÍN 33 en dificultad (eran 8.3, 4.4 y 3.3) |
| `avance` | `veces IN (1, 2)` y `calif_ets IS NULL OR calif < 6` | Una 3.ª vez cursada, o un ETS de una materia aprobada |
| `usuario` | `correo = lower(correo)` e índice único sobre `lower(alias)` | Dos cuentas con el mismo correo en mayúsculas, o "Pablo" y "pablo" |
| `oferta` | `UNIQUE NULLS NOT DISTINCT (periodo, grupo, materia, profesor)` | Dos ofertas "sin profesor" iguales |
| `carrera` | `carga_min_ua <= carga_media_ua <= carga_max_ua` | Una carga académica imposible |
| `seriacion` | `materia <> requisito` | Una materia que se pide a sí misma |
| `cedula` | `numero ~ '^[0-9]{5,9}$'` y `nivel IN (…)` | Una cédula capturada con letras (`L2890498`) o un texto como `no-existe` |
| `equivalencia` | `materia <> equivalente` | Una materia equivalente a sí misma |
| `avance` | `resultado IS NULL OR calif IS NULL` | "Aprobada sin número" y además un número en la misma materia |
| `comentario` | `anonimo ~ '^[A-Za-z0-9]{6,15}$'` | Un nombre anónimo con espacios, símbolos o de otro largo |
| `bitacora` | `accion IN (…)` | Una acción de moderación que no existe |

La vista `avance_status` deriva el status (pendiente, en recurse, aprobada, reprobada, solo por
ETS, aprobada por ETS) y la calificación final de `veces`, `calif` y `calif_ets`, así que esos
datos no se guardan dos veces.
