# Normalización: por qué el cupo vive aparte de la oferta

Práctica integrada 6, 7 y 8 · Bases de Datos · ESCOM · Gestorix

La decisión de normalización que explicamos es real y está en el esquema
([`sql/00-tablas.sql`](https://github.com/pablo140706/Gestorix/blob/main/sql/00-tablas.sql)): **el cupo de SAES no es de una oferta, sino de
grupo + materia**, así que tiene su propia tabla `cupo`. Partimos del registro plano que usaba
iscweb (la versión anterior de Gestorix, sin base de datos), sacamos sus dependencias
funcionales, lo llevamos hasta 3FN y revisamos FNBC tabla por tabla. Todas las cifras salen de
la base cargada con los datos de SAES de 27/1.

---

## 1. De dónde partimos

En iscweb cada clase era un objeto de JavaScript (`schedule.js`) con su lista de sesiones, y
los cupos venían en otro archivo (`cupos.js`) que se cruzaba por grupo + nombre de la materia.
Si juntamos todo en una sola tabla, una fila por cada bloque de clase, queda la **relación
universal**:

```
R(periodo, grupo, turno, clave, materia, semestre, creditos, carrera, carga_media,
  profesor, mp_calidad, edificio, salon, dia, bloque, hora_ini, hora_fin,
  cupo, inscritos, disponibles)
```

Ejemplo real: Cálculo aplicado en `2CM1` (27/1) se da lunes, miércoles y jueves a las 8:30,
así que ocupa tres filas que repiten todo lo demás:

| periodo | grupo | turno | clave | materia | profesor | edificio | salon | dia | bloque | hora_ini | cupo | inscritos | disponibles |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 27/1 | 2CM1 | M | C203 | Cálculo aplicado | VIVEROS VELA KARINA | 1 | 007 | 1 | 2 | 08:30 | 36 | 36 | 0 |
| 27/1 | 2CM1 | M | C203 | Cálculo aplicado | VIVEROS VELA KARINA | 1 | 007 | 3 | 2 | 08:30 | 36 | 36 | 0 |
| 27/1 | 2CM1 | M | C203 | Cálculo aplicado | VIVEROS VELA KARINA | 1 | 007 | 4 | 2 | 08:30 | 36 | 36 | 0 |

**No está en 1FN:** en iscweb `sesiones` era una lista dentro de cada clase (un grupo
repetitivo). Para llegar a 1FN cada sesión pasa a ser su propia fila, con `dia` y `bloque`
atómicos, que es justo como está escrita R.

## 2. Dependencias funcionales

| # | Dependencia | Por qué se cumple |
|---|---|---|
| DF1 | `clave → materia, semestre, creditos, carrera` | La clave oficial (C203) identifica a la materia |
| DF2 | `carrera → carga_media` | La carga media es de la carrera (7 UA en ISC, 6 en IA y LCD) |
| DF3 | `bloque → hora_ini, hora_fin` | La rejilla es fija: el bloque 1 siempre es 07:00–08:30 |
| DF4 | `grupo → turno` | El turno es la 3.ª letra del grupo: 2C**M**1 es matutino |
| DF5 | `profesor → mp_calidad` | Las métricas de MisProfesores son del profesor, no de la clase |
| DF6 | `periodo, grupo, clave → cupo, inscritos` | **SAES da el cupo por grupo + materia** |
| DF7 | `cupo, inscritos → disponibles` | disponibles = cupo − inscritos |
| DF8 | `periodo, grupo, clave, profesor → edificio, salon` | Cada clase (oferta) tiene su salón |

**Lo que no se cumple, y por qué importa:** `periodo, grupo, clave → profesor` **es falsa**. En
Trabajo Terminal varios asesores comparten el mismo grupo y la misma materia. En 27/1, `8BM1`
Trabajo Terminal II (B801) tiene **3 asesores** y `8BM2` tiene **2**:

```sql
SELECT periodo, grupo, materia, count(*) AS asesores
FROM oferta GROUP BY periodo, grupo, materia HAVING count(*) > 1;
--  27/1 | 8BM2 | B801 | 2
--  27/1 | 8BM1 | B801 | 3
```

Por eso el profesor tiene que estar en la llave de la oferta, y el cupo no puede quedarse ahí.

## 3. Clave candidata de R

Calculamos el cierre de `K = {periodo, grupo, clave, profesor, dia, bloque}`:

1. Con DF1: + materia, semestre, creditos, carrera. Con DF2: + carga_media.
2. Con DF3: + hora_ini, hora_fin. Con DF4: + turno. Con DF5: + mp_calidad.
3. Con DF6: + cupo, inscritos. Con DF7: + disponibles. Con DF8: + edificio, salon.

`K⁺` = todos los atributos, así que `K` es superclave. Además es **mínima**: si quitas `dia` o
`bloque` ya no distingues las sesiones de una clase, si quitas `profesor` no distingues a los
asesores de TT, y `periodo`, `grupo` y `clave` no salen de ninguna otra dependencia. Ningún
atributo de afuera determina a los de `K`, así que **`K` es la única clave candidata**.

## 4. Las anomalías, con datos reales

| Anomalía | Qué pasa en R |
|---|---|
| **Redundancia** | R tendría 2,021 filas solo en 27/1 (3.1 sesiones por oferta). "Matemáticas discretas" y sus créditos se repetirían 79 veces. El cupo 36 de `8BM1` B801 se repetiría una vez por asesor |
| **Actualización** | Si SAES cambia el cupo de `8BM1` B801, hay que cambiarlo en las filas de los 3 asesores. Si se te pasa una, la base dice dos cupos distintos para el mismo grupo |
| **Inserción** | Los grupos X de Trabajo Terminal (`7CX1`, `8BX1`…) **tienen cupo en SAES pero no tienen oferta ni horario**. En R no se pueden guardar: les faltaría profesor, día y bloque, que son parte de la llave |
| **Borrado** | Si se borra la única oferta de una materia, se pierden su nombre, sus créditos y su semestre |

## 5. Paso a 2FN: quitar las dependencias parciales

Todas menos la llave completa son **parciales**: dependen de una parte de `K`. Cada una se
vuelve su propia tabla, con su determinante como llave:

| Dependencia parcial | Parte de K | Tabla nueva |
|---|---|---|
| DF1 | `clave` | `materia(clave, nombre, semestre, creditos, carrera, carga_media)` |
| DF3 | `bloque` | `bloque(numero, inicio, fin)` |
| DF4 | `grupo` | ver el §8 (la excepción `turno`) |
| DF5 | `profesor` | `profesor(id, nombre, mp_calidad, …)` |
| DF6 | `periodo, grupo, clave` | **`cupo(periodo, grupo, materia, cupo, inscritos, disponibles)`** |
| DF8 | `periodo, grupo, clave, profesor` | `oferta(id, periodo, grupo, materia, profesor, edificio, salon)` |
| (la llave) | `K` completa | `sesion(oferta, dia, bloque)` |

En la base, `oferta` lleva un `id` sustituto (`SERIAL`), así `sesion` y `horario` apuntan a un
solo número en vez de a cuatro columnas. La llave natural se conserva como
`UNIQUE NULLS NOT DISTINCT (periodo, grupo, materia, profesor)`: `NULLS NOT DISTINCT` hace que
dos ofertas "sin profesor" del mismo grupo y materia también cuenten como repetidas.

## 6. Paso a 3FN: quitar las dependencias transitivas

Quedan dos dependencias entre atributos que no son llave:

| Tabla | Transitiva | Solución |
|---|---|---|
| `cupo` | `(periodo, grupo, materia) → cupo, inscritos → disponibles` | **No se guarda `disponibles`**: lo calcula `api/cupos.php` (`'disp' => cupo − inscritos`) |
| `materia` | `clave → carrera → carga_media` | La carga va en **`carrera(codigo, letra, nombre, plan, carga_min_ua, carga_media_ua, carga_max_ua)`** y `materia.carrera` es llave foránea |

## 7. Comprobación de FNBC

En FNBC, el determinante de toda dependencia no trivial tiene que ser superclave. Las
tablas finales:

| Tabla | Dependencias no triviales | Determinantes | ¿FNBC? |
|---|---|---|---|
| `carrera` | `codigo → todo`, `letra → todo` | Las dos son claves candidatas (`PRIMARY KEY` y `UNIQUE`) | ✅ |
| `materia` | `clave → todo`, `(carrera, semestre, nombre_saes) → clave` | Las dos son claves candidatas (`PRIMARY KEY` y `UNIQUE`). El nombre se repite entre las claves de 6.º y 7.º de IA y LCD, por eso lleva el semestre | ✅ |
| `bloque` | `numero → inicio, fin`, `inicio → …`, `fin → …` | Las tres columnas son `UNIQUE`: tres claves candidatas | ✅ |
| `profesor` | `id → todo`, `nombre_norm → todo` | `PRIMARY KEY` y `UNIQUE` | ✅ |
| `cupo` | `(periodo, grupo, materia) → cupo, inscritos` | Es la `PRIMARY KEY` | ✅ |
| `sesion` | ninguna (las tres columnas son la llave) | — | ✅ |
| `oferta` | `id → todo`, `(periodo, grupo, materia, profesor) → id` | `PRIMARY KEY` y `UNIQUE` | ✅ salvo `turno` (§8) |

## 8. La excepción consciente: `oferta.turno`

`grupo → turno` (DF4) sigue dentro de `oferta`, y `grupo` no es superclave. En sentido
estricto eso es una **dependencia parcial**: la tabla no estaría ni en 2FN. La decisión fue
dejarla, pero como **columna generada**:

```sql
turno CHAR(1) GENERATED ALWAYS AS (substr(grupo, 3, 1)) STORED   -- M, V o X (TT)
```

- **No hay anomalía de actualización:** Postgres no deja escribir en una columna generada (un
  `INSERT` o `UPDATE` que le ponga valor truena), así que `turno` no puede contradecir al
  grupo. La redundancia existe, pero la mantiene el gestor, no las personas.
- **La alternativa estricta** sería una tabla `grupo(codigo PK, turno)` con llave foránea desde
  `oferta`: 142 grupos más que cargar y un `JOIN` más en cada consulta del horario, para un
  dato que se saca con `substr`.
- Por eso la carrera (`2C` → ISC) y el semestre (`2C` → 2.º) del grupo **ni siquiera se
  guardan**: se deducen cuando hacen falta.

Si se toma `turno` como un atributo calculado y no como un dato independiente, `oferta` queda
en FNBC.

## 9. ¿Por qué `cupo` no tiene llave foránea hacia `oferta`?

Porque no se puede: `cupo` y `oferta` se cruzan por `(periodo, grupo, materia)`, y eso **no es
llave de `oferta`** (TT repite grupo + materia con varios asesores). Además hay cupos sin
oferta (los 7 grupos X de TT, con cupo 250/255 = sin límite) y ofertas sin cupo (las 5 extra que
no vienen en SAES). `cupo` solo tiene llaves foráneas a `periodo` y `materia`.

## 10. La descomposición no pierde información

`oferta` y `cupo` comparten `(periodo, grupo, materia)`, que es la llave de `cupo`. Por el
teorema de Heath, la reunión natural `oferta ⨝ cupo` reconstruye exactamente las filas
originales, sin tuplas de más. Se comprueba en RelaX con el ejercicio 8 de
[`algebra.md`](algebra.md): los 5 asesores de TT II salen cada uno con el cupo de su grupo.

## 11. Comprobación en los datos

Las dependencias que usamos se cumplen en la base cargada. Cada consulta busca violaciones y
regresa 0:

```sql
SELECT 'grupo -> turno' AS df, count(*) AS violaciones
FROM (SELECT grupo FROM oferta GROUP BY grupo HAVING count(DISTINCT turno) > 1) x
UNION ALL
SELECT '(carrera, semestre, nombre_saes) -> clave', count(*)
FROM (SELECT carrera, semestre, nombre_saes FROM materia GROUP BY 1, 2, 3
      HAVING count(DISTINCT clave) > 1) x
UNION ALL
SELECT 'letra -> codigo', count(*)
FROM (SELECT letra FROM carrera GROUP BY letra HAVING count(DISTINCT codigo) > 1) x;
```

| df | violaciones |
|---|---|
| grupo -> turno | 0 |
| (carrera, semestre, nombre_saes) -> clave | 0 |
| letra -> codigo | 0 |

Y la que **no** se cumple, que justifica toda la decisión:
`periodo, grupo, materia → profesor` falla en `8BM1` y `8BM2` (§2).
