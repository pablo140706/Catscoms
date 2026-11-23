# Parte 1 · Dependencias funcionales y normalización

Prácticas 6, 7 y 8 · Bases de Datos · ESCOM · proyecto propio: **Gestorix**

Gestorix es el gestor académico para alumnos de ESCOM (avance, horario, profesores, comentarios). Su
esquema completo está en [`sql/00-tablas.sql`](https://github.com/pablo140706/Gestorix/blob/main/sql/00-tablas.sql)
(26 tablas). Aquí:

- **1.1** revisa cada tabla con las cuatro pautas informales;
- **1.2** saca las dependencias funcionales de las reglas del negocio, las claves con el cierre y el
  recubrimiento mínimo;
- **1.3** dice en qué forma normal está cada tabla. Como el esquema de Gestorix **ya está en 3FN**
  (salvo una excepción que se justifica), se normaliza además una tabla **desnormalizada a propósito**
  con datos reales: `horario_plano`, el registro plano con el que trabajaba iscweb, la versión de
  Gestorix sin base de datos. La migración [`migraciones/001`](migraciones/001-normalizar-horario-plano.sql)
  la normaliza moviendo sus renglones, y el contenedor la aplica solo.

Las cifras de la base completa son de la base publicada de Gestorix (27/1). Las de `horario_plano` son
de la muestra que carga el contenedor: 90 sesiones de clase, 30 ofertas.

---

## Ejercicio 1.1 · Pautas de diseño

Las cuatro pautas informales:
- **(P1) Semántica clara:** cada fila es una sola cosa.
- **(P2) Sin anomalías:** de inserción, borrado ni actualización.
- **(P3) Pocos nulos.**
- **(P4) Sin tuplas espurias:** al reunir por los atributos comunes no salen filas falsas.

Marcas: ✅ cumple · ⚠️ cumple con una salvedad · ❌ falla.

| Tabla | Cada fila es… | P1 | P2 | P3 | P4 |
|---|---|---|---|---|---|
| `carrera` | una carrera de ESCOM con su carga en UA | ✅ | ✅ | ✅ | ✅ |
| `materia` | una unidad de aprendizaje de un plan, por su clave oficial | ✅ | ✅ | ⚠️ | ✅ |
| `seriacion` | "la materia X pide antes la materia Y" | ✅ | ✅ | ✅ | ✅ |
| `equivalencia` | "la materia X de una carrera equivale a la Y de otra" (SAES) | ✅ | ✅ | ✅ | ✅ |
| `ruta_optativa` | una ruta (trayectoria) de optativas de una carrera | ✅ | ✅ | ✅ | ✅ |
| `ruta_materia` | "la optativa X pertenece a la ruta R" | ✅ | ✅ | ✅ | ✅ |
| `periodo` | un periodo escolar (27/1) con sus fechas de clase | ✅ | ✅ | ⚠️ | ✅ |
| `evento_calendario` | un día o rango del calendario del IPN | ⚠️ | ✅ | ⚠️ | ✅ |
| `profesor` | un profesor, con sus métricas de MisProfesores | ✅ | ✅ | ✅ | ✅ |
| `cedula` | una cédula profesional de un profesor | ✅ | ✅ | ✅ | ✅ |
| `oferta` | una clase: un grupo da una materia con un profesor en un periodo | ✅ | ⚠️ | ✅ | ✅ |
| `bloque` | uno de los 9 bloques de hora y media de la rejilla | ✅ | ✅ | ✅ | ✅ |
| `sesion` | "la oferta X se da el día D en el bloque B" | ✅ | ✅ | ✅ | ✅ |
| `cupo` | el cupo de SAES de un grupo + materia en un periodo | ✅ | ✅ | ✅ | ⚠️ |
| `usuario` | una cuenta de Gestorix | ⚠️ | ✅ | ⚠️ | ✅ |
| `alias_cambio` | un cambio de alias de una cuenta | ✅ | ✅ | ✅ | ✅ |
| `moderador_carrera` | "la cuenta X modera la carrera C" | ✅ | ✅ | ✅ | ✅ |
| `token` | un enlace de un solo uso (activar o recuperar), guardado como sha256 | ✅ | ✅ | ✅ | ✅ |
| `correo_borrado` | el sha256 de un correo que no se puede volver a registrar en 7 días | ✅ | ✅ | ✅ | ✅ |
| `avance` | lo que un alumno lleva de una materia | ✅ | ✅ | ⚠️ | ✅ |
| `horario` | "el alumno X inscribió la oferta Y" | ✅ | ✅ | ✅ | ✅ |
| `recordatorio` | un recordatorio de la agenda de un alumno | ✅ | ✅ | ✅ | ✅ |
| `comentario` | una reseña de un alumno sobre un profesor, con etiqueta de materia | ✅ | ✅ | ⚠️ | ✅ |
| `rubrica` | un concepto de evaluación de una reseña ("examen 60 %") | ✅ | ✅ | ✅ | ✅ |
| `reporte` | un reporte de una reseña | ✅ | ✅ | ✅ | ✅ |
| `bitacora` | una acción de moderación o de administración | ✅ | ✅ | ⚠️ | ✅ |
| **`horario_plano`** (la tabla a propósito) | una **sesión de clase**, con la materia, su carrera, el profesor, el salón y el cupo repetidos | ❌ | ❌ | ❌ | ❌ |

**Qué tabla falla cuál, y por qué:**

- **`horario_plano` falla las cuatro.** Por eso es la que se normaliza en el 1.3.
  - **P1:** cada fila mezcla siete cosas (sesión, clase, materia, carrera, profesor, periodo y cupo).
  - **P2:** las tres anomalías, con datos reales:
    - "Matemáticas discretas" y sus créditos se repiten en cada sesión de cada grupo;
    - cambiar el cupo de `8BM1` B801 obliga a cambiar las filas de sus 3 asesores;
    - un grupo X de Trabajo Terminal, que tiene cupo pero no horario, no se puede guardar;
    - borrar la última sesión de una materia borra la materia.
  - **P3:** `edificio`/`salon` vacíos en TT y `mp_*` vacíos en los profes sin métricas, repetidos en
    cada sesión.
  - **P4:** si se parte mal, por ejemplo cupo por `grupo` y no por `grupo + materia`, al reunir salen
    cupos de una materia pegados a otra.
- **`oferta` (P2, salvedad):** `turno` se deduce del grupo (`2CM1` → M). Guardado normal tendría
  anomalía de actualización. Es una **columna generada**: el gestor la calcula y no deja escribirla
  (ver 1.3).
- **`cupo` (P4, salvedad):** se cruza con `oferta` por `(periodo, grupo, materia)`, que **no es llave de
  `oferta`**, porque en TT varios asesores comparten grupo y materia. No salen tuplas espurias porque
  sí es la llave de `cupo`. Pero no lleva llave foránea a `oferta`: hay 53 cupos sin oferta (grupos X
  de TT y otros) y 5 ofertas sin cupo.
- **`usuario` (P1 y P3):**
  - P1: la columna `alias_cambios` **quedó sin uso** desde la migración del 2026-11-22. Ahora manda la
    tabla `alias_cambio`, y una columna muerta confunde. Hay que quitarla con una migración (pendiente).
  - P3: `suspendido_hasta` e `ingreso` son `NULL` en casi todas las cuentas.
- **`materia` (P3):** columnas casi siempre vacías.
  - `nombre_en` vacío en 181 de 209 (solo lo tienen las optativas de ISC);
  - `descripcion_fuente` vacío en 168 (solo se llena en las descripciones "orientativas");
  - `horas_t` vacío en 82.

  Son atributos opcionales de pocas materias. Separarlos en otra tabla no quita ninguna anomalía.
- **`evento_calendario` (P1 y P3):** el `NULL` tiene significado:
  - `periodo NULL` = "fuera de periodo" (21 de 48);
  - `fin NULL` = "un solo día" (25 de 48).

  La pauta pide evitar nulos con significado; aquí está documentado en el esquema.
- **`avance` (P3):** `calif` y `resultado` se excluyen (número o "aprobada sin número"), así que una de
  las dos siempre es `NULL`. Lo controlan los `CHECK` (`avance_resultado_sin_calif`).
- **`comentario` (P3):** `anonimo` y `editado` casi siempre son `NULL`.
- **`bitacora` (P3):** según la acción, el objetivo es una cuenta, un comentario o nada (respaldo,
  probar correo).

---

## Ejercicio 1.2 · Las dependencias funcionales

### 1.2.1 El conjunto F, desde las reglas del negocio

Las dependencias salen de **reglas de ESCOM, SAES y la app**, no de mirar filas.

**F de `horario_plano`** (la relación que se normaliza):

```
horario_plano(periodo, periodo_inicio, periodo_fin, grupo, turno, clave, materia, tipo, semestre,
              creditos, ua, requisitos, carrera, carrera_nombre, letra, carga_min_ua, carga_media_ua,
              carga_max_ua, profesor, mp_calidad, mp_recomiendan, mp_dificultad, edificio, salon,
              dia, bloque, hora_ini, hora_fin, cupo, inscritos, disponibles)
```

| # | Dependencia | Regla que la justifica |
|---|---|---|
| DF1 | `clave → materia, tipo, semestre, creditos, ua, carrera` | La clave oficial (C203) identifica a la unidad de aprendizaje en el plan de estudios |
| DF2 | `carrera → carrera_nombre, letra, carga_min_ua, carga_media_ua, carga_max_ua` | La carga mínima, media y máxima es de la carrera (Procedimiento de Reinscripción 27/1) |
| DF3 | `letra → carrera` | Cada carrera tiene su letra: C = ISC, B = IA, A = LCD |
| DF4 | `clave → letra` | La clave empieza con la letra de su carrera (C203 es de ISC) |
| DF5 | `periodo → periodo_inicio, periodo_fin` | El calendario del IPN fija las fechas de cada periodo |
| DF6 | `grupo → turno` | El turno es la 3.ª letra del grupo: 2C**M**1 es matutino |
| DF7 | `bloque → hora_ini, hora_fin` | La rejilla de ESCOM es fija: el bloque 1 siempre es 07:00–08:30 |
| DF8 | `profesor → mp_calidad, mp_recomiendan, mp_dificultad` | Las métricas de MisProfesores son del profesor, no de una clase |
| DF9 | `periodo, grupo, clave → cupo, inscritos` | **SAES da el cupo por grupo + materia en cada periodo** |
| DF10 | `periodo, grupo, clave, profesor → edificio, salon, cupo, inscritos` | Así lo registraba iscweb: el salón y el cupo pegados a cada clase |
| DF11 | `cupo, inscritos → disponibles` | disponibles = cupo − inscritos |

Además hay una **dependencia multivaluada**, `clave ↠ requisitos`: una materia tiene varios
requisitos, independientes de todo lo demás. Se trata en el paso a 1FN.

**Las que NO se cumplen**, aunque en muchos datos parezca:
- **`periodo, grupo, clave → profesor` es falsa.** En Trabajo Terminal varios asesores comparten
  grupo y materia: en 27/1, `8BM1` B801 tiene 3 asesores y `8BM2` tiene 2. Por eso el profesor está en
  la llave de la clase y el cupo no puede quedarse ahí.
- **`grupo → semestre` también es falsa.** Un grupo de 1.º puede ser de recurse, y un grupo puede
  llevar optativas de otro semestre.

**F del resto del esquema de Gestorix**, tabla por tabla (las que no aparecen solo tienen la de su
llave):

| Tabla | Dependencias no triviales | Regla |
|---|---|---|
| `carrera` | `codigo → todo`; `letra → codigo` | La letra es única por carrera |
| `materia` | `clave → todo`; `carrera, semestre, nombre_saes → clave` | SAES no repite un nombre dentro del semestre de una carrera. En IA y LCD **sí** lo repite entre 6.º y 7.º (las dos claves de cada optativa): por eso el semestre está en el determinante |
| `seriacion` | `materia, requisito → oficial` | El par es oficial (mapa de ISC) o propuesto (IA y LCD) |
| `ruta_optativa` | `id → todo`; `carrera, nombre → id` | No hay dos rutas con el mismo nombre en una carrera |
| `periodo` | `codigo → inicio, fin` | Calendario del IPN |
| `profesor` | `id → todo`; `nombre_norm → id` | Los profesores se identifican por el nombre sin acentos en mayúsculas |
| `cedula` | `numero → profesor, nivel` | **Una cédula de la SEP es de una sola persona y de un solo nivel** |
| `oferta` | `id → todo`; `periodo, grupo, materia, profesor → id`; `grupo → turno` | Una clase por grupo + materia + profesor en cada periodo; el turno está en el grupo |
| `bloque` | `numero → inicio, fin`; `inicio → numero`; `fin → numero` | La rejilla no repite horas |
| `cupo` | `periodo, grupo, materia → cupo, inscritos` | SAES |
| `usuario` | `id → todo`; `correo → id`; `lower(alias) → id` | Una cuenta por correo; alias único sin importar mayúsculas |
| `token` | `hash → usuario, tipo, expira` | Cada enlace es al azar y de un solo uso |
| `correo_borrado` | `hash → hasta` | — |
| `avance` | `usuario, materia → veces, calif, calif_ets, resultado, resultado_ets, periodo_reprobada` | Una fila por alumno y materia |
| `rubrica` | `comentario, concepto → porcentaje` | Un concepto no se repite en una reseña |
| `alias_cambio`, `recordatorio`, `comentario`, `reporte`, `bitacora`, `evento_calendario` | `id → todo` | Son hechos con su propio número; no hay otra combinación que los identifique |
| `sesion`, `horario`, `ruta_materia`, `equivalencia`, `moderador_carrera` | ninguna no trivial | Todas sus columnas son la llave |

### 1.2.2 Claves candidatas con el cierre de atributos

**`horario_plano`.** Primero, un atajo que vale para cualquier esquema: **un atributo que no aparece del
lado derecho de ninguna dependencia tiene que estar en toda clave**, porque nada lo determina. En F
esos atributos son `periodo`, `grupo`, `clave`, `profesor`, `dia` y `bloque`. Calculamos el cierre de
`K = {periodo, grupo, clave, profesor, dia, bloque}`. Antes se quita `requisitos`, que es una lista (ver
1FN en el 1.3).

| Paso | Dependencia que se usa | Se agrega |
|---|---|---|
| 0 | — | `periodo, grupo, clave, profesor, dia, bloque` |
| 1 | DF1 (`clave ⊆ K⁺`) | `materia, tipo, semestre, creditos, ua, carrera` |
| 2 | DF2 (`carrera ⊆ K⁺`) | `carrera_nombre, letra, carga_min_ua, carga_media_ua, carga_max_ua` |
| 3 | DF5 | `periodo_inicio, periodo_fin` |
| 4 | DF6 | `turno` |
| 5 | DF7 | `hora_ini, hora_fin` |
| 6 | DF8 | `mp_calidad, mp_recomiendan, mp_dificultad` |
| 7 | DF9 | `cupo, inscritos` |
| 8 | DF10 | `edificio, salon` |
| 9 | DF11 | `disponibles` |

`K⁺` tiene los 30 atributos, así que **`K` es superclave**. Como sus seis atributos no salen de ninguna
dependencia, toda clave tiene que contenerlos: **`K` es la única clave candidata**.

**El resto del esquema.** Las claves de una sola columna se ven directo: `id⁺` o `codigo⁺` es toda la
tabla por la primera dependencia. Las que tienen más de una clave candidata, o una clave compuesta:

| Tabla | Cierre | Claves candidatas |
|---|---|---|
| `carrera` | `{letra}⁺ = {letra, codigo} ∪ codigo⁺ = todo` | `codigo` y `letra` |
| `materia` | `{carrera, semestre, nombre_saes}⁺ = {…, clave} ∪ clave⁺ = todo`. Ningún subconjunto de 2 alcanza `clave`: el nombre se repite entre semestres y entre carreras | `clave` y `(carrera, semestre, nombre_saes)` |
| `bloque` | `{inicio}⁺ = {inicio, numero, fin}`; `{fin}⁺ = {fin, numero, inicio}` | `numero`, `inicio` y `fin` |
| `profesor` | `{nombre_norm}⁺ = {nombre_norm, id} ∪ id⁺ = todo` | `id` y `nombre_norm` |
| `usuario` | `{correo}⁺ = todo`; `{lower(alias)}⁺ = todo` | `id`, `correo` y el alias (sin mayúsculas) |
| `oferta` | `{periodo, grupo, materia, profesor}⁺ = {…, id} ∪ id⁺ = todo`. Sin `profesor` no se alcanza `id` (TT) | `id` y `(periodo, grupo, materia, profesor)` |
| `cupo` | `{periodo, grupo, materia}⁺ = todo` | `(periodo, grupo, materia)` |
| `avance` | `{usuario, materia}⁺ = todo` | `(usuario, materia)` |
| `rubrica` | `{comentario, concepto}⁺ = todo` | `(comentario, concepto)` |
| **`cedula`** | `{numero}⁺ = {numero, profesor, nivel} = todo` | **solo `numero`** |

**Hallazgo en `cedula`:** la llave declarada es `PRIMARY KEY (profesor, numero)`, pero `{numero}⁺` ya
es toda la tabla. La llave **no es mínima**: `profesor` sobra. Las 110 cédulas cargadas tienen 110
números distintos, y ninguno está en dos profesores. La tabla sigue en FNBC, porque el determinante
`numero` es clave, pero falta declarar `UNIQUE (numero)` para que la base lo haga cumplir. Se anota
como migración pendiente.

### 1.2.3 Recubrimiento mínimo de F (`horario_plano`)

**Paso 1 · Lados derechos simples.** Se parte cada dependencia en una por atributo. Por ejemplo, DF1
da `clave → materia`, `clave → tipo`, …, `clave → carrera`. Salen **28 dependencias**:

| Origen | Cuántas |
|---|---|
| DF1 | 6 |
| DF2 | 5 |
| DF3 | 1 |
| DF4 | 1 |
| DF5 | 2 |
| DF6 | 1 |
| DF7 | 2 |
| DF8 | 3 |
| DF9 | 2 |
| DF10 | 4 |
| DF11 | 1 |

**Paso 2 · Sin atributos sobrantes del lado izquierdo.** Solo se revisan las que tienen más de un
atributo a la izquierda. Un atributo `B` de `X → A` sobra si `(X − B)⁺` ya contiene `A`.

| Dependencia | Se prueba quitar | Cierre sin ese atributo | ¿Sobra? |
|---|---|---|---|
| `periodo, grupo, clave → cupo` | `periodo` | `{grupo, clave}⁺ = {grupo, clave, turno, materia, tipo, semestre, creditos, ua, carrera, carrera_nombre, letra, cargas}`: no tiene `cupo` | No (el cupo cambia cada periodo) |
| | `grupo` | `{periodo, clave}⁺`: no tiene `cupo` | No |
| | `clave` | `{periodo, grupo}⁺ = {periodo, grupo, periodo_inicio, periodo_fin, turno}`: no tiene `cupo` | No |
| `periodo, grupo, clave, profesor → cupo` | **`profesor`** | `{periodo, grupo, clave}⁺` **sí tiene `cupo`** (por DF9) | **Sí** |
| `periodo, grupo, clave, profesor → inscritos` | **`profesor`** | igual, por DF9 | **Sí** |
| `periodo, grupo, clave, profesor → edificio` | `profesor` | `{periodo, grupo, clave}⁺`: tiene `cupo`, pero no `edificio` | No (cada clase tiene su salón) |
| | `periodo`, `grupo` o `clave` | ningún cierre de 3 de ellos llega a `edificio` | No |
| `… → salon` | lo mismo | lo mismo | No |
| `cupo, inscritos → disponibles` | `cupo` | `{inscritos}⁺ = {inscritos}` | No |
| | `inscritos` | `{cupo}⁺ = {cupo}` | No |

Al quitar `profesor`, las dos dependencias de cupo de DF10 quedan **iguales** a las de DF9, así que se
eliminan por repetidas: quedan **26**. **Esta es la decisión de normalización de Gestorix**: el cupo
dependía de menos atributos que la clase.

**Paso 3 · Sin dependencias redundantes.** `X → A` sobra si, sin ella, `X⁺` todavía contiene `A`.

| Dependencia | `X⁺` calculado SIN ella | ¿Redundante? |
|---|---|---|
| **`clave → letra`** (DF4) | `{clave}⁺ = {clave, materia, tipo, semestre, creditos, ua, carrera}`, y con `carrera → letra` agrega **`letra`** | **Sí: se elimina** |
| `clave → carrera` | (ya sin DF4) `{clave}⁺ = {clave, materia, tipo, semestre, creditos, ua}`: no tiene `carrera` | No |
| `letra → carrera` | `{letra}⁺ = {letra}` | No |
| `carrera → letra` | `{carrera}⁺ = {carrera, carrera_nombre, cargas}` | No |
| las demás de `clave`, `carrera`, `periodo`, `grupo`, `bloque` y `profesor` | sin ella, su lado izquierdo no tiene otro camino para llegar a ese atributo: es la única dependencia que lo trae | No |
| `periodo, grupo, clave → cupo` / `inscritos` | `{periodo, grupo, clave}⁺` ya no tiene `cupo` (la de DF10 se fue en el paso 2) | No |
| `periodo, grupo, clave, profesor → edificio` / `salon` | ninguna otra trae `edificio` ni `salon` | No |
| `cupo, inscritos → disponibles` | ninguna otra trae `disponibles` | No |

> El recubrimiento mínimo **no es único**. Si en el paso 3 se revisara primero `clave → carrera`, saldría
> redundante (`clave → letra → carrera`) y se quedaría `clave → letra`. Elegimos el orden que deja la
> regla tal como la escribe el plan de estudios: la materia es de una carrera.

**F mínimo (25 dependencias, agrupadas por lado izquierdo):**

```
1  clave                            → materia, tipo, semestre, creditos, ua, carrera
2  carrera                          → carrera_nombre, letra, carga_min_ua, carga_media_ua, carga_max_ua
3  letra                            → carrera
4  periodo                          → periodo_inicio, periodo_fin
5  grupo                            → turno
6  bloque                           → hora_ini, hora_fin
7  profesor                         → mp_calidad, mp_recomiendan, mp_dificultad
8  periodo, grupo, clave            → cupo, inscritos
9  periodo, grupo, clave, profesor  → edificio, salon
10 cupo, inscritos                  → disponibles
```

### 1.2.4 Equivalencia con el F de otro equipo

**Pendiente.** Hay que intercambiar F con un equipo que conozca el dominio, por ejemplo otro equipo de
ESCOM que modele horarios o SAES. Cómo se demuestra:

1. Para cada dependencia `X → A` de **su** F, calcular `X⁺` con **nuestro** F. Si siempre contiene `A`,
   su F ⊆ nuestro F⁺.
2. Al revés: cada dependencia nuestra, con el cierre en su F.
3. Si las dos se cumplen, F y G son equivalentes (F⁺ = G⁺). Si alguna falla, esa dependencia es la
   diferencia y hay que discutir qué regla del negocio la justifica.

| Dependencia | Viene de | `X⁺` con el otro conjunto | ¿Se deduce? |
|---|---|---|---|
| *(llenar con el otro equipo)* | | | |

---

## Ejercicio 1.3 · Las formas normales

### 1.3.1 Forma normal de cada tabla del esquema actual

| Tabla | Forma normal | Por qué |
|---|---|---|
| `carrera`, `materia`, `profesor`, `bloque`, `usuario` | FNBC | Cada determinante (`codigo` y `letra`; `clave` y el trío de SAES; `id` y `nombre_norm`; `numero`, `inicio` y `fin`; `id`, `correo` y alias) es clave candidata |
| `periodo`, `cupo`, `token`, `correo_borrado`, `avance`, `rubrica`, `seriacion` | FNBC | Su única dependencia no trivial sale de la llave |
| `ruta_optativa`, `evento_calendario`, `alias_cambio`, `recordatorio`, `comentario`, `reporte`, `bitacora` | FNBC | Solo `id → todo` (y `carrera, nombre → id` en rutas, que también es clave) |
| `sesion`, `horario`, `ruta_materia`, `equivalencia`, `moderador_carrera` | FNBC | Todas sus columnas son la llave: no hay dependencias no triviales |
| `cedula` | FNBC | `numero → todo` y `numero` es clave. La llave declarada no es mínima (1.2.2) |
| **`oferta`** | FNBC **si `turno` se toma como calculado**; si no, ni 2FN | `grupo → turno` y `grupo` es parte de la clave `(periodo, grupo, materia, profesor)`: es una dependencia **parcial** |
| **`horario_plano`** | **Ni 1FN** | `requisitos` es una lista |

**La excepción de `oferta.turno`, justificada.** Se quedó en `oferta` como **columna generada**:

```sql
turno CHAR(1) GENERATED ALWAYS AS (substr(grupo, 3, 1)) STORED
```

Postgres no deja escribir en ella: un `INSERT` o `UPDATE` que le ponga valor truena, así que **no puede
contradecir al grupo** y no hay anomalía de actualización. La alternativa estricta, una tabla
`grupo(codigo, turno)`, cuesta 142 filas más que cargar y un `JOIN` en cada consulta de horarios, para
un dato que se saca con `substr`. **No se pierde ninguna dependencia:** `grupo → turno` la hace cumplir
la expresión de la columna.

**Conclusión:** el esquema de Gestorix ya está en 3FN y en FNBC, con la excepción consciente de
`turno`. Como pide la práctica, se normaliza en su lugar la tabla desnormalizada a propósito,
`horario_plano`, con 90 filas reales.

### 1.3.2 `horario_plano` hasta 3FN, y la comprobación de FNBC

Ejemplo real de cómo se ve: Cálculo aplicado en `2CM1` (27/1) se da tres veces por semana, así que ocupa
tres filas que repiten todo lo demás.

| periodo | grupo | clave | materia | profesor | salon | dia | bloque | cupo | inscritos | disponibles |
|---|---|---|---|---|---|---|---|---|---|---|
| 27/1 | 2CM1 | C203 | Cálculo aplicado | VIVEROS VELA KARINA | 007 | 1 | 2 | 36 | 36 | 0 |
| 27/1 | 2CM1 | C203 | Cálculo aplicado | VIVEROS VELA KARINA | 007 | 3 | 2 | 36 | 36 | 0 |
| 27/1 | 2CM1 | C203 | Cálculo aplicado | VIVEROS VELA KARINA | 007 | 4 | 2 | 36 | 36 | 0 |

**A 1FN · se elimina el grupo repetitivo `requisitos`.** `"C101,C104"` no es atómico. Por la dependencia
multivaluada `clave ↠ requisitos`, la lista sale a su propia tabla, una fila por requisito:

```
seriacion(materia, requisito)          ← de la lista "requisitos"
R1 = horario_plano − requisitos        ← clave: K
```

**A 2FN · se eliminan las dependencias parciales.** En R1, todas las de F mínimo salvo las transitivas
(2, 3 y 10) tienen como determinante una **parte** de K. Cada una sale con su determinante como llave:

| Dependencia que se elimina de R1 | Tabla nueva |
|---|---|
| 1 `clave → …` | `materia(clave, materia, tipo, semestre, creditos, ua, carrera, carrera_nombre, letra, cargas)` |
| 4 `periodo → …` | `periodo(periodo, inicio, fin)` |
| 5 `grupo → turno` | queda como columna generada de `oferta` (ver 1.3.1) |
| 6 `bloque → …` | `bloque(numero, inicio, fin)` |
| 7 `profesor → …` | `profesor(nombre, mp_calidad, mp_recomiendan, mp_dificultad)` |
| 8 `periodo, grupo, clave → …` | **`cupo(periodo, grupo, clave, cupo, inscritos, disponibles)`** |
| 9 `periodo, grupo, clave, profesor → …` | `oferta(periodo, grupo, clave, profesor, edificio, salon)` |
| (lo que queda: la llave K) | `sesion(periodo, grupo, clave, profesor, dia, bloque)` |

**A 3FN · se eliminan las dependencias transitivas.** Quedan dos:

| Tabla | Transitiva que se elimina | Qué se hace |
|---|---|---|
| `materia` | `clave → carrera → carrera_nombre, letra, cargas` (2 y 3) | Sale `carrera(codigo, letra, nombre, carga_min_ua, carga_media_ua, carga_max_ua)`; `materia.carrera` es llave foránea |
| `cupo` | `periodo, grupo, clave → cupo, inscritos → disponibles` (10) | **`disponibles` no se guarda**: es una resta y se calcula al consultar (`cupo − inscritos`) |

Detalles de implementación:
- `profesor` lleva un `id` sustituto (`SERIAL`), así `oferta` apunta a un número y no a un nombre
  largo. El nombre queda `UNIQUE`: sigue siendo clave candidata.
- `oferta` lleva `id` sustituto, y `sesion` apunta a él en vez de a cuatro columnas:
  `sesion(oferta, dia, bloque)`.

**Comprobación de FNBC.** El determinante de toda dependencia no trivial tiene que ser superclave:

| Tabla final | Dependencias no triviales | ¿Su determinante es clave? |
|---|---|---|
| `carrera` | `codigo → todo`, `letra → codigo` | Sí: `codigo` (PK) y `letra` (UNIQUE) |
| `periodo` | `codigo → inicio, fin` | Sí |
| `materia` | `clave → todo` | Sí |
| `seriacion` | ninguna | — |
| `profesor` | `id → todo`, `nombre → id` | Sí: `id` (PK) y `nombre` (UNIQUE) |
| `bloque` | `numero → inicio, fin`, `inicio → numero`, `fin → numero` | Sí: las tres columnas son únicas |
| `oferta` | `id → todo`, `periodo, grupo, materia, profesor → id` (y `grupo → turno`, calculada) | Sí |
| `sesion` | ninguna | — |
| `cupo` | `periodo, grupo, materia → cupo, inscritos` | Sí: es la PK |

**Todas quedan en FNBC.** No hizo falta quedarse en 3FN: ninguna dependencia se pierde (1.3.3).

### 1.3.3 Reunión sin pérdida y preservación de dependencias

**Prueba de los atributos comunes** (Heath): al partir `R` en `R1` y `R2`, la reunión no pierde
información si los atributos comunes `R1 ∩ R2` son clave de alguno de los dos lados (`R1 ∩ R2 → R1`
o `R1 ∩ R2 → R2`). Cada corte que se hizo:

| Corte | Atributos comunes | ¿Son clave de un lado? | Sin pérdida |
|---|---|---|---|
| horario_plano → `seriacion` + R1 | `clave` | Por `clave ↠ requisitos`: la condición para dependencias multivaluadas | ✅ |
| R1 → `materia`(con carrera) + resto | `clave` | Sí, de `materia` | ✅ |
| `materia` → `materia` + `carrera` | `carrera` | Sí, de `carrera` | ✅ |
| resto → `periodo` + resto | `periodo` | Sí, de `periodo` | ✅ |
| resto → `bloque` + resto | `bloque` | Sí, de `bloque` | ✅ |
| resto → `profesor` + resto | `profesor` | Sí, de `profesor` | ✅ |
| resto → `cupo` + resto | `periodo, grupo, clave` | Sí, de `cupo` | ✅ |
| resto → `oferta` + `sesion` | `periodo, grupo, clave, profesor` | Sí, de `oferta` | ✅ |

**Y se comprueba con los datos.** La migración reúne las tablas nuevas y compara con `horario_plano` en
los dos sentidos (`EXCEPT`):
- si falta una fila, hay pérdida;
- si sobra una, hay tuplas espurias.

Al levantar el contenedor imprime:

```
NOTICE:  Sin pérdida: las 90 filas de horario_plano salen igual al reunir las tablas nuevas (faltan 0, sobran 0).
```

**Preservación de dependencias:** cada dependencia de F mínimo queda **entera dentro de una tabla**, así
que se puede hacer cumplir sin reunir nada:

| Dependencia | Tabla donde vive | Cómo la hace cumplir el gestor |
|---|---|---|
| 1 `clave → …` | `materia` | `PRIMARY KEY (clave)` |
| 2 `carrera → …` y 3 `letra → carrera` | `carrera` | `PRIMARY KEY (codigo)` y `UNIQUE (letra)` |
| 4 `periodo → …` | `periodo` | `PRIMARY KEY` |
| 5 `grupo → turno` | `oferta` | columna `GENERATED ALWAYS` |
| 6 `bloque → …` | `bloque` | `PRIMARY KEY` |
| 7 `profesor → …` | `profesor` | `UNIQUE (nombre)` |
| 8 `periodo, grupo, clave → cupo, inscritos` | `cupo` | `PRIMARY KEY` |
| 9 `periodo, grupo, clave, profesor → edificio, salon` | `oferta` | `UNIQUE (periodo, grupo, materia, profesor)` |
| 10 `cupo, inscritos → disponibles` | (no se guarda) | se calcula: no se puede contradecir |

**Se preservan todas.**

### 1.3.4 La migración sobre la base poblada

[`migraciones/001-normalizar-horario-plano.sql`](migraciones/001-normalizar-horario-plano.sql), en una sola
transacción:

1. Crea cada tabla del esquema final con sus llaves, llaves foráneas y `CHECK`.
2. **Mueve los renglones** con `INSERT … SELECT DISTINCT` desde `horario_plano`. No vuelve a cargar
   nada a mano. La lista `requisitos` se parte con `unnest(string_to_array(…))`.
3. **Comprueba F sobre los datos sin escribir una consulta aparte.** Si una dependencia no se
   cumpliera, por ejemplo dos calidades distintas para el mismo profesor, el `DISTINCT` daría dos
   filas con la misma llave y la llave primaria haría fallar la migración.
4. Reúne todo y compara con `horario_plano` (1.3.3). Si no cuadra, `RAISE EXCEPTION` y no queda nada a
   medias.
5. No borra `horario_plano`: la mueve al esquema `antes`, para poder compararla.

El contenedor la aplica solo, en orden, con [`init/02-aplicar-migraciones.sh`](init/02-aplicar-migraciones.sh).
Las siguientes migraciones serán `002-…`, `003-…`.

**Migraciones pendientes que salieron de este análisis** (en Gestorix, no en el contenedor):
- `cedula`: agregar `UNIQUE (numero)` (1.2.2);
- `usuario`: quitar la columna sin uso `alias_cambios` (1.1).
