# Parte 2 · Álgebra relacional

Prácticas 6, 7 y 8 · Bases de Datos · ESCOM · proyecto propio: **Gestorix**

Consultas sobre la base **ya normalizada** (la que deja la migración 001), con datos reales de SAES.
Cada una trae:
- la pregunta;
- la expresión en álgebra, en la sintaxis de [RelaX](https://dbis-uibk.github.io/relax/);
- la captura de RelaX con el árbol y el resultado;
- su SQL;
- el resultado que devolvió la base.

**Los resultados de abajo son los que imprimió el contenedor** (`evidencias/salida-del-contenedor.txt`).
Hay que comprobar que RelaX da las mismas filas.

| Operador | Pide | Hay | Consultas |
|---|---|---|---|
| Selección σ y proyección π | 3 | 4 | 00, 01, 02, 03 |
| Unión, intersección y diferencia | 3 | 3 | 04, 05, 06 |
| Producto cartesiano × | 1 | 1 | 07 |
| Reunión natural, theta y externa | 3 | 4 | 08, 09, 10 (y 00 y 12 usan theta) |
| Agregación y agrupación γ | 2 | 2 | 11, 12 |
| División ÷ | 1 | 1 | 13 |

## Ejercicio 2.1 · Los datos en RelaX

| Archivo | Qué hace |
|---|---|
| [`relax/exportar-grupo.sql`](relax/exportar-grupo.sql) | Lee la base normalizada y escribe el grupo en formato de RelaX |
| [`relax/grupo.txt`](relax/grupo.txt) | **El grupo**, ya generado. El contenedor lo regenera en cada corrida: nadie lo escribe a mano |

La muestra son los grupos `1CM1`, `1CM8` (de recurse) y `2CM1` de ISC en 26/2 y 27/1, más Trabajo
Terminal II (B801) de IA en `8BM1` y `8BM2`, donde varios asesores comparten un cupo. Respeta la
integridad referencial: cada oferta trae su materia, su profesor y su cupo.

| Relación | Filas | Nota |
|---|---|---|
| `carrera` | 2 | Solo hay las carreras de la muestra (ISC e IA) |
| `materia` | 12 | |
| `seriacion` | 3 | Los únicos requisitos entre materias de la muestra |
| `profesor` | 19 | |
| `oferta` | 30 | |
| `cupo` | 27 | |

`sesion` (90 filas), `bloque` y `periodo` no van al grupo: ninguna consulta los usa, y `sesion` pasa de 30.

```
carrera   (codigo, letra, nombre, carga_min_ua, carga_media_ua, carga_max_ua)
materia   (clave, carrera, nombre, tipo, semestre, creditos, ua)
seriacion (materia, requisito)
profesor  (id, nombre, mp_calidad, mp_recomiendan, mp_dificultad)
oferta    (id, periodo, grupo, materia, profesor, turno, edificio, salon)
cupo      (periodo, grupo, materia, cupo, inscritos)
```

**Cargarlo en RelaX:**
1. Abre <https://dbis-uibk.github.io/relax/calc/local/uibk/local/0>.
2. Entra a **Editor de Grupo** y pega todo `relax/grupo.txt`.
3. Pulsa **vista previa** y luego **utilizar Grupo en editor**.
4. Las consultas se escriben en la pestaña **Álgebra Relacional**.

---

## Ejercicio 2.2 · Las consultas

### 00 · Consulta representativa

**Pregunta:** ¿qué profesores con calidad de 8 o más dan materias de 2.º semestre en 27/1, y en qué grupo?

```
π profesor.nombre, materia.nombre, oferta.grupo (
  σ mp_calidad >= 8 (profesor)
  ⨝ profesor.id = oferta.profesor (
    σ periodo = '27/1' (oferta)
    ⨝ oferta.materia = materia.clave
    σ semestre = 2 (materia)
  )
)
```

**Árbol:**

```
π profesor.nombre, materia.nombre, oferta.grupo        ← operador principal (la raíz)
└── ⨝ profesor.id = oferta.profesor
    ├── σ mp_calidad ≥ 8
    │   └── profesor
    └── ⨝ oferta.materia = materia.clave
        ├── σ periodo = '27/1'
        │   └── oferta
        └── σ semestre = 2
            └── materia
```

Las selecciones van pegadas a las hojas: primero se filtran las tres relaciones y luego se reúnen
relaciones ya chicas. Es lo mismo que hace el gestor ("empujar la selección hacia abajo").

📸 Captura de RelaX: `evidencias/relax-00.png` · SQL: [`consultas/00-representativa.sql`](consultas/00-representativa.sql)

| profesor | materia | grupo |
|---|---|---|
| CASTILLO MARRUFO JUAN ANTONIO | Fundamentos económicos | 2CM1 |
| VIVEROS VELA KARINA | Cálculo aplicado | 2CM1 |

Cómo se corresponden:
- `σ` es el `WHERE`;
- cada `⨝ … = …` es un `JOIN … ON`;
- la `π` de la raíz es la lista del `SELECT`.

Los otros 4 profes de 2CM1 quedan fuera por calidad (7.2, 7.9 y 6.6) o por no tener dato (`null >= 8`
no es verdadero ni en RelaX ni en SQL).

### 01 · Selección

**Pregunta:** ¿qué materias son de 1.er semestre?

```
σ semestre = 1 (materia)
```

📸 `evidencias/relax-01.png` · SQL: [`consultas/01-seleccion.sql`](consultas/01-seleccion.sql)

| clave | carrera | nombre | tipo | semestre | creditos | ua |
|---|---|---|---|---|---|---|
| C101 | ISC | Fundamentos de programación | OBL | 1 | 7.5 | 1 |
| C102 | ISC | Matemáticas discretas | OBL | 1 | 10.5 | 1 |
| C103 | ISC | Cálculo | OBL | 1 | 7.5 | 1 |
| C104 | ISC | Análisis vectorial | OBL | 1 | 7.5 | 1 |
| C105 | ISC | Comunicación oral y escrita | OBL | 1 | 7.5 | 1 |

La selección filtra **filas**: quedan todas las columnas.

### 02 · Proyección

**Pregunta:** ¿qué grupos hay y en qué turno?

```
π grupo, turno (oferta)
```

📸 `evidencias/relax-02.png` · SQL: [`consultas/02-proyeccion.sql`](consultas/02-proyeccion.sql)

| grupo | turno |
|---|---|
| 1CM1 | M |
| 1CM8 | M |
| 2CM1 | M |
| 8BM1 | M |
| 8BM2 | M |

De 30 ofertas salen 5 filas: **la proyección quita duplicados**, porque el álgebra trabaja con conjuntos.
En SQL hay que pedirlo con `DISTINCT`.

### 03 · Selección y proyección compuestas

**Pregunta:** ¿qué profesores tienen calidad de 9 o más en MisProfesores?

```
π nombre, mp_calidad (σ mp_calidad >= 9 (profesor))
```

📸 `evidencias/relax-03.png` · SQL: [`consultas/03-seleccion-y-proyeccion.sql`](consultas/03-seleccion-y-proyeccion.sql)

| nombre | mp_calidad |
|---|---|
| FLORES FUENTES NARIA ADRIANA | 9.2 |
| SANCHEZ MORENO ADRIANA DE LA P | 9.4 |

Primero `σ` (filas) y luego `π` (columnas). Al revés no se puede: si se proyecta primero sin
`mp_calidad`, la selección ya no tiene con qué comparar.

### 04 · Unión

**Pregunta:** ¿quién dio clase en 1CM1 en 26/2 o en 27/1?

```
π nombre (
  ρ id←profesor (
    π profesor (σ grupo = '1CM1' ∧ periodo = '26/2' (oferta))
    ∪
    π profesor (σ grupo = '1CM1' ∧ periodo = '27/1' (oferta))
  ) ⨝ profesor
)
```

📸 `evidencias/relax-04.png` · SQL: [`consultas/04-union.sql`](consultas/04-union.sql)

| nombre |
|---|
| DORANTES VILLA CLAUDIA JISELA |
| FLORES FUENTES NARIA ADRIANA |
| GUZMAN AGUILAR FLORENCIO |
| HERRERA YAÑEZ CRISPIN |
| RESENDIZ MUÑOZ ROCIO |
| RODRIGUEZ VILLARREAL JOSE GREGORIO |
| SANCHEZ MORENO ADRIANA DE LA P |
| VAZQUEZ GONZALEZ LEONOR |

Son 8: 5 profes por periodo, y 2 que repiten (RESENDIZ MUÑOZ y SANCHEZ MORENO) se cuentan una vez.

- **Compatibilidad de unión:** los dos lados son `π profesor (…)` sobre la misma relación, así que
  tienen el mismo número de atributos y del mismo dominio.
- `ρ id←profesor` renombra para que la reunión natural con `profesor` sea por `id`.

### 05 · Intersección

**Pregunta:** ¿qué profesores dieron clase en los dos periodos?

```
π nombre (
  ρ id←profesor (
    π profesor (σ periodo = '26/2' (oferta)) ∩ π profesor (σ periodo = '27/1' (oferta))
  ) ⨝ profesor
)
```

📸 `evidencias/relax-05.png` · SQL: [`consultas/05-interseccion.sql`](consultas/05-interseccion.sql)

| nombre |
|---|
| ARREDONDO SANCHEZ ANA LAURA |
| CASTILLO MARRUFO JUAN ANTONIO |
| GUZMAN AGUILAR FLORENCIO |
| RESENDIZ MUÑOZ ROCIO |
| SALINAS HERNANDEZ ENCARNACION |
| SANCHEZ MORENO ADRIANA DE LA P |
| TECLA PARRA ROBERTO |
| VIVEROS VELA KARINA |

### 06 · Diferencia

**Pregunta:** ¿qué profesores dieron clase en 26/2 y ya no en 27/1?

```
π nombre (
  ρ id←profesor (
    π profesor (σ periodo = '26/2' (oferta)) - π profesor (σ periodo = '27/1' (oferta))
  ) ⨝ profesor
)
```

📸 `evidencias/relax-06.png` · SQL: [`consultas/06-diferencia.sql`](consultas/06-diferencia.sql)

| nombre |
|---|
| DORANTES VILLA CLAUDIA JISELA |
| HERRERA YAÑEZ CRISPIN |
| LEAL PACHECO CHRISTIAN RENE |
| REYES BERMEJO TLATOANI DE JESUS |

Es lo que la ficha del maestro pinta en rojo en la app ("ya no la imparte"). La diferencia **no es
conmutativa**: al revés salen los profes nuevos de 27/1.

### 07 · Producto cartesiano

**Pregunta:** ¿de qué carrera es cada materia de 8.º semestre?

```
materia ⨯ carrera
π materia.clave, carrera.nombre (σ materia.carrera = carrera.codigo ∧ semestre = 8 (materia ⨯ carrera))
```

📸 `evidencias/relax-07.png` · SQL: [`consultas/07-producto.sql`](consultas/07-producto.sql)

El producto solo da **24 tuplas** (12 materias × 2 carreras), casi todas sin sentido, como Cálculo con
IA. Con la selección:

| clave | nombre |
|---|---|
| B801 | Ingeniería en Inteligencia Artificial |

**Por qué casi nunca se usa solo:** combina todo con todo. `σ` sobre `⨯` es exactamente una reunión
theta, `materia ⨝ materia.carrera = carrera.codigo carrera`, y el gestor la hace sin armar el producto
completo.

### 08 · Reunión natural

**Pregunta:** ¿qué cupo le toca a cada asesor de Trabajo Terminal II?

```
π grupo, materia, profesor, cupo, inscritos (σ materia = 'B801' (oferta ⨝ cupo))
```

📸 `evidencias/relax-08.png` · SQL: [`consultas/08-reunion-natural.sql`](consultas/08-reunion-natural.sql)

| grupo | materia | profesor | cupo | inscritos |
|---|---|---|---|---|
| 8BM1 | B801 | 6 | 36 | 29 |
| 8BM1 | B801 | 7 | 36 | 29 |
| 8BM1 | B801 | 12 | 36 | 29 |
| 8BM2 | B801 | 1 | 36 | 13 |
| 8BM2 | B801 | 3 | 36 | 13 |

La reunión natural usa los atributos con el mismo nombre: `periodo`, `grupo` y `materia`.
- **Qué se conserva:** cada asesor sale con el cupo de su grupo. El cupo se guarda **una vez** y la
  reunión lo repite: es la decisión de [`normalizacion.md`](normalizacion.md).
- **Qué se pierde:** las ofertas sin cupo y los cupos sin oferta (en la muestra no hay).

### 09 · Reunión theta

**Pregunta:** ¿quién da cada materia de 2CM1 en 27/1, y qué calidad tiene?

```
π oferta.materia, profesor.nombre, profesor.mp_calidad (
  σ grupo = '2CM1' ∧ periodo = '27/1' (oferta) ⨝ oferta.profesor = profesor.id profesor
)
```

📸 `evidencias/relax-09.png` · SQL: [`consultas/09-reunion-theta.sql`](consultas/09-reunion-theta.sql)

| materia | nombre | mp_calidad |
|---|---|---|
| C201 | TECLA PARRA ROBERTO | 7.2 |
| C202 | GUZMAN AGUILAR FLORENCIO | 7.9 |
| C203 | VIVEROS VELA KARINA | 8.3 |
| C204 | SALINAS HERNANDEZ ENCARNACION | 6.6 |
| C205 | ARREDONDO SANCHEZ ANA LAURA | null |
| C206 | CASTILLO MARRUFO JUAN ANTONIO | 8.2 |

Aquí no sirve la natural: el atributo se llama `profesor` en `oferta` e `id` en `profesor`, así que la
condición se escribe.

### 10 · Reunión externa izquierda

**Pregunta:** ¿qué requisito tiene cada materia de 2.º semestre, si tiene?

```
π materia.clave, materia.nombre, seriacion.requisito (
  σ semestre = 2 (materia) ⟕ materia.clave = seriacion.materia seriacion
)
```

📸 `evidencias/relax-10.png` · SQL: [`consultas/10-reunion-externa.sql`](consultas/10-reunion-externa.sql)

| clave | nombre | requisito |
|---|---|---|
| C201 | Algoritmos y estructura de datos | C101 |
| C202 | Álgebra lineal | C104 |
| C203 | Cálculo aplicado | C103 |
| C204 | Mecánica y electromagnetismo | null |
| C205 | Ingeniería, ética y sociedad | null |
| C206 | Fundamentos económicos | null |

Con `⨝` normal **se perderían** las 3 materias sin requisito. La externa las **conserva** y llena con
`null`.

### 11 · Agrupación con count

**Pregunta:** ¿cuántas ofertas tiene cada grupo en cada periodo?

```
γ periodo, grupo; count(*)→ofertas (oferta)
```

📸 `evidencias/relax-11.png` · SQL: [`consultas/11-agrupacion-materias-por-grupo.sql`](consultas/11-agrupacion-materias-por-grupo.sql)

| periodo | grupo | ofertas |
|---|---|---|
| 26/2 | 1CM1 | 5 |
| 26/2 | 1CM8 | 2 |
| 26/2 | 2CM1 | 6 |
| 27/1 | 1CM1 | 5 |
| 27/1 | 1CM8 | 1 |
| 27/1 | 2CM1 | 6 |
| 27/1 | 8BM1 | 3 |
| 27/1 | 8BM2 | 2 |

`8BM1` tiene 3 ofertas de **una sola** materia: son los 3 asesores de TT II. `1CM8` es grupo de recurse,
por eso trae solo algunas materias.

### 12 · Agrupación con avg (resumen por grupo)

**Pregunta:** ¿qué calidad promedio tienen los profesores de cada grupo en 27/1?

```
γ grupo; avg(mp_calidad)→calidad_promedio, count(mp_calidad)→con_dato (
  σ periodo = '27/1' (oferta) ⨝ oferta.profesor = profesor.id profesor
)
```

📸 `evidencias/relax-12.png` · SQL: [`consultas/12-agrupacion-calidad.sql`](consultas/12-agrupacion-calidad.sql)

| grupo | calidad_promedio | con_dato |
|---|---|---|
| 1CM1 | 8.04 | 5 |
| 1CM8 | 9.20 | 1 |
| 2CM1 | 7.64 | 5 |
| 8BM1 | 6.40 | 3 |
| 8BM2 | 6.00 | 2 |

`avg` y `count(atributo)` **ignoran los `null`**: `2CM1` tiene 6 profes pero solo 5 con calidad.
RelaX no redondea, así que puede mostrar más decimales (`7.640000000000001`); SQL redondea con
`round(…, 2)`.

### 13 · División (una pregunta con «todas»)

**Pregunta:** ¿qué grupos ofrecen en 27/1 **todas** las materias de 1.er semestre?

```
π grupo, materia (σ periodo = '27/1' (oferta))
÷
ρ materia←clave (π clave (σ semestre = 1 (materia)))
```

**Árbol:**

```
÷                                              ← operador principal
├── π grupo, materia
│   └── σ periodo = '27/1'
│       └── oferta
└── ρ materia←clave
    └── π clave
        └── σ semestre = 1
            └── materia
```

📸 `evidencias/relax-13.png` · SQL: [`consultas/13-division.sql`](consultas/13-division.sql)

| grupo |
|---|
| 1CM1 |

`1CM8` queda fuera porque en 27/1 solo ofrece Cálculo; `2CM1`, `8BM1` y `8BM2` no tienen ninguna de 1.º.
SQL no tiene operador de división. Se escribe con dos `NOT EXISTS` anidados, que se leen "no existe una
materia de 1.º que el grupo no ofrezca", o sea, "para todas". El `ρ materia←clave` da al divisor el
mismo nombre de atributo que el dividendo.

---

## Ejercicio 2.3 · El álgebra del proyecto asignado

Es del proyecto asignado (Sismos): lo hizo **Emiliano**. Va en el archivo que él preparó.
