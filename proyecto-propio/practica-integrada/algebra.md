# Álgebra relacional sobre la base de Gestorix

Práctica integrada 6, 7 y 8 · Bases de Datos · ESCOM · Gestorix

Los ejercicios cubren selección, proyección, conjuntos (unión, intersección y diferencia),
producto, reuniones (natural, theta y externa), agrupación y división. Cada uno trae la
pregunta, la expresión en la sintaxis de [RelaX](https://dbis-uibk.github.io/relax/), su SQL
equivalente y el resultado. **Los dos resultados se compararon y son iguales en los 13
ejercicios** (2026-11-19).

## Los datos

RelaX trabaja en el navegador con datos chicos, así que usamos un **subconjunto real** de la
base (40 ofertas, 27 profesores y 12 materias). Son los grupos `1CM1`, `1CM2`, `1CM8` y `2CM1`
de ISC en 26/2 y 27/1, más Trabajo Terminal II (B801) de IA en `8BM1` y `8BM2`, donde varios
asesores comparten un cupo.

| Archivo | Qué hace |
|---|---|
| [`relax/subconjunto.sql`](relax/subconjunto.sql) | Copia ese subconjunto de la base al esquema `relax`, con sus llaves |
| [`relax/exportar.sql`](relax/exportar.sql) | Escribe el grupo de RelaX a partir del esquema `relax` |
| [`relax/gestorix.txt`](relax/gestorix.txt) | **El grupo de RelaX**, ya generado |

Relaciones del grupo (son las tablas de la base, con menos columnas):

```
carrera   (codigo, letra, nombre, carga_min_ua, carga_media_ua, carga_max_ua)
materia   (clave, carrera, nombre, tipo, semestre, creditos, ua)
seriacion (materia, requisito)
profesor  (id, nombre, mp_calidad, mp_recomiendan, mp_dificultad)
oferta    (id, periodo, grupo, materia, profesor, turno, edificio, salon)
cupo      (periodo, grupo, materia, cupo, inscritos)
```

**Cargar el grupo en RelaX:** abre <https://dbis-uibk.github.io/relax/calc/local/uibk/local/0>,
entra a **Editor de Grupo**, pega todo `gestorix.txt`, pulsa **vista previa** y luego
**utilizar Grupo en editor**. Las consultas se escriben en la pestaña **Álgebra Relacional**.

**Correr el SQL sobre los mismos datos** (en pgAdmin o en la terminal):

```bash
docker compose exec -T db psql -U gestorix_admin -d gestorix < docs/relax/subconjunto.sql
```

y antes de cada consulta, `SET search_path = relax;`. Sin esa línea, el mismo SQL corre sobre la
base completa (`public`): da más filas, pero significa lo mismo.

---

## Consulta representativa

**Pregunta:** ¿qué profesores con calidad de 8 o más en MisProfesores dan materias de 2.º
semestre en 27/1, y en qué grupo?

Es la que le sirve a un alumno para elegir con quién inscribirse, y junta selección,
proyección y dos reuniones theta.

**Álgebra (RelaX):**

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

**Árbol de operadores** (RelaX también lo dibuja al ejecutar):

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

Las selecciones van **pegadas a las hojas**: primero se filtran los profes, las ofertas y las
materias, y luego se reúnen relaciones ya chicas. Es la misma optimización que hace el gestor
("empujar la selección hacia abajo").

**SQL:**

```sql
SELECT p.nombre AS profesor, m.nombre AS materia, o.grupo
FROM profesor p
JOIN oferta o  ON p.id = o.profesor
JOIN materia m ON o.materia = m.clave
WHERE p.mp_calidad >= 8 AND o.periodo = '27/1' AND m.semestre = 2
ORDER BY 1;
```

**Resultado (igual en RelaX y en SQL):**

| profesor | materia | grupo |
|---|---|---|
| CASTILLO MARRUFO JUAN ANTONIO | Fundamentos económicos | 2CM1 |
| VIVEROS VELA KARINA | Cálculo aplicado | 2CM1 |

**Cómo corresponden:** `σ` es el `WHERE` (cada condición se reparte a su relación), `⨝ … = …`
son los `JOIN … ON` y la `π` de la raíz es la lista del `SELECT`. En 2CM1 hay 6 profesores; los
otros 4 quedan fuera por calidad (7.2, 7.9 y 6.6) o porque no tienen dato (`null`: la
comparación `null >= 8` no es verdadera ni en RelaX ni en SQL).

---

## Ejercicios

### 1. Selección: materias de 1.er semestre

```
σ semestre = 1 (materia)
```

```sql
SELECT * FROM materia WHERE semestre = 1 ORDER BY clave;
```

| clave | carrera | nombre | tipo | semestre | creditos | ua |
|---|---|---|---|---|---|---|
| C101 | ISC | Fundamentos de programación | OBL | 1 | 7.5 | 1 |
| C102 | ISC | Matemáticas discretas | OBL | 1 | 10.5 | 1 |
| C103 | ISC | Cálculo | OBL | 1 | 7.5 | 1 |
| C104 | ISC | Análisis vectorial | OBL | 1 | 7.5 | 1 |
| C105 | ISC | Comunicación oral y escrita | OBL | 1 | 7.5 | 1 |

### 2. Proyección: qué grupos hay y en qué turno

```
π grupo, turno (oferta)
```

```sql
SELECT DISTINCT grupo, turno FROM oferta ORDER BY grupo;
```

6 filas a partir de 40 ofertas: `1CM1`, `1CM2`, `1CM8`, `2CM1`, `8BM1` y `8BM2`, todos en turno
`M`. **La proyección quita duplicados** (el álgebra trabaja con conjuntos); en SQL hay que
pedirlo con `DISTINCT`.

### 3. Selección y proyección: los profesores mejor calificados

```
π nombre, mp_calidad (σ mp_calidad >= 9 (profesor))
```

```sql
SELECT nombre, mp_calidad FROM profesor WHERE mp_calidad >= 9;
```

| nombre | mp_calidad |
|---|---|
| FLORES FUENTES NARIA ADRIANA | 9.2 |
| SANCHEZ MORENO ADRIANA DE LA P | 9.4 |

### 4. Unión: quién dio clase en `1CM1` en 26/2 o en 27/1

```
π nombre (
  ρ id←profesor (
    π profesor (σ grupo = '1CM1' ∧ periodo = '26/2' (oferta))
    ∪
    π profesor (σ grupo = '1CM1' ∧ periodo = '27/1' (oferta))
  ) ⨝ profesor
)
```

```sql
SELECT p.nombre
FROM profesor p
JOIN (SELECT profesor FROM oferta WHERE grupo = '1CM1' AND periodo = '26/2'
      UNION
      SELECT profesor FROM oferta WHERE grupo = '1CM1' AND periodo = '27/1') x
  ON x.profesor = p.id
ORDER BY 1;
```

8 profesores: los 5 de cada periodo, menos 2 que repiten (RESENDIZ MUÑOZ y SANCHEZ MORENO), que
la unión cuenta una sola vez. `ρ id←profesor` renombra el atributo para que la reunión natural
con `profesor` sea por `id`.

### 5. Intersección: profesores que dieron clase en los dos periodos

```
π nombre (
  ρ id←profesor (
    π profesor (σ periodo = '26/2' (oferta)) ∩ π profesor (σ periodo = '27/1' (oferta))
  ) ⨝ profesor
)
```

```sql
SELECT p.nombre
FROM profesor p
JOIN (SELECT profesor FROM oferta WHERE periodo = '26/2'
      INTERSECT
      SELECT profesor FROM oferta WHERE periodo = '27/1') x
  ON x.profesor = p.id
ORDER BY 1;
```

10 profesores: ARREDONDO SANCHEZ, CASTILLO MARRUFO, GUZMAN AGUILAR, PAREDES CADENA, RESENDIZ
MUÑOZ, SALINAS HERNANDEZ, SANCHEZ MORENO, SANCHEZ VARGAS, TECLA PARRA y VIVEROS VELA.

### 6. Diferencia: profesores de 26/2 que ya no dan clase en 27/1

```
π nombre (
  ρ id←profesor (
    π profesor (σ periodo = '26/2' (oferta)) - π profesor (σ periodo = '27/1' (oferta))
  ) ⨝ profesor
)
```

```sql
SELECT p.nombre
FROM profesor p
JOIN (SELECT profesor FROM oferta WHERE periodo = '26/2'
      EXCEPT
      SELECT profesor FROM oferta WHERE periodo = '27/1') x
  ON x.profesor = p.id
ORDER BY 1;
```

7 profesores: DIAZ SANCHEZ, DORANTES VILLA, HERRERA YAÑEZ, LEAL PACHECO, MIGUEL PILAR, REYES
BERMEJO y SERRANO ROMERO. Es lo mismo que pinta en rojo ("ya no la imparte") la ficha del
maestro en la app. La diferencia **no es conmutativa**: al revés saldrían los profes nuevos de
27/1.

### 7. Producto cartesiano: materia × carrera

```
materia ⨯ carrera
```

```sql
SELECT count(*) FROM materia CROSS JOIN carrera;    -- 36
```

12 materias × 3 carreras = **36 tuplas**, casi todas sin sentido (Cálculo con Ciencia de Datos).
El producto solo sirve si después se filtra:

```
π materia.clave, carrera.nombre (σ materia.carrera = carrera.codigo ∧ semestre = 8 (materia ⨯ carrera))
```

```sql
SELECT m.clave, c.nombre
FROM materia m CROSS JOIN carrera c
WHERE m.carrera = c.codigo AND m.semestre = 8;
```

| clave | nombre |
|---|---|
| B801 | Ingeniería en Inteligencia Artificial |

`σ` sobre `⨯` es exactamente una reunión theta: `materia ⨝ materia.carrera = carrera.codigo carrera`.

### 8. Reunión natural: el cupo de cada asesor de Trabajo Terminal

```
π grupo, materia, profesor, cupo, inscritos (σ materia = 'B801' (oferta ⨝ cupo))
```

```sql
SELECT grupo, materia, profesor, cupo, inscritos
FROM oferta NATURAL JOIN cupo
WHERE materia = 'B801'
ORDER BY grupo, profesor;
```

| grupo | materia | profesor | cupo | inscritos |
|---|---|---|---|---|
| 8BM1 | B801 | 56 | 36 | 29 |
| 8BM1 | B801 | 153 | 36 | 29 |
| 8BM1 | B801 | 213 | 36 | 29 |
| 8BM2 | B801 | 8 | 36 | 13 |
| 8BM2 | B801 | 15 | 36 | 13 |

La reunión natural usa los atributos con el mismo nombre: `periodo`, `grupo` y `materia`. Aquí
se ve la decisión de [`normalizacion.md`](normalizacion.md): el cupo se guarda **una vez** por
grupo y la reunión lo repite para cada asesor. Como `(periodo, grupo, materia)` es la llave de
`cupo`, la descomposición no pierde información.

### 9. Reunión theta: el horario de `2CM1` con el nombre del profesor

```
π oferta.materia, profesor.nombre, profesor.mp_calidad (
  σ grupo = '2CM1' ∧ periodo = '27/1' (oferta) ⨝ oferta.profesor = profesor.id profesor
)
```

```sql
SELECT o.materia, p.nombre, p.mp_calidad
FROM oferta o JOIN profesor p ON o.profesor = p.id
WHERE o.grupo = '2CM1' AND o.periodo = '27/1'
ORDER BY o.materia;
```

| materia | nombre | mp_calidad |
|---|---|---|
| C201 | TECLA PARRA ROBERTO | 7.2 |
| C202 | GUZMAN AGUILAR FLORENCIO | 7.9 |
| C203 | VIVEROS VELA KARINA | 8.3 |
| C204 | SALINAS HERNANDEZ ENCARNACION | 6.6 |
| C205 | ARREDONDO SANCHEZ ANA LAURA | null |
| C206 | CASTILLO MARRUFO JUAN ANTONIO | 8.2 |

Aquí no sirve la reunión natural: el atributo se llama `profesor` en `oferta` e `id` en
`profesor`, así que la condición se escribe (`oferta.profesor = profesor.id`).

### 10. Reunión externa izquierda: materias de 2.º y su requisito, si tienen

```
π materia.clave, materia.nombre, seriacion.requisito (
  σ semestre = 2 (materia) ⟕ materia.clave = seriacion.materia seriacion
)
```

```sql
SELECT m.clave, m.nombre, s.requisito
FROM materia m LEFT JOIN seriacion s ON m.clave = s.materia
WHERE m.semestre = 2;
```

| clave | nombre | requisito |
|---|---|---|
| C201 | Algoritmos y estructura de datos | C101 |
| C202 | Álgebra lineal | C104 |
| C203 | Cálculo aplicado | C103 |
| C204 | Mecánica y electromagnetismo | null |
| C205 | Ingeniería, ética y sociedad | null |
| C206 | Fundamentos económicos | null |

Con una reunión normal (`⨝`) desaparecerían las 3 materias sin requisito. La externa las
conserva y llena con `null`.

### 11. Agrupación

**a) Cuántas materias ofrece cada grupo en cada periodo**

```
γ periodo, grupo; count(*)→materias (oferta)
```

```sql
SELECT periodo, grupo, count(*) AS materias FROM oferta GROUP BY periodo, grupo ORDER BY periodo, grupo;
```

| periodo | grupo | materias |
|---|---|---|
| 26/2 | 1CM1 | 5 |
| 26/2 | 1CM2 | 5 |
| 26/2 | 1CM8 | 2 |
| 26/2 | 2CM1 | 6 |
| 27/1 | 1CM1 | 5 |
| 27/1 | 1CM2 | 5 |
| 27/1 | 1CM8 | 1 |
| 27/1 | 2CM1 | 6 |
| 27/1 | 8BM1 | 3 |
| 27/1 | 8BM2 | 2 |

`8BM1` tiene 3 ofertas de una sola materia: son los 3 asesores de TT II. `1CM8` es un grupo de
recurse (número ≥ 6), por eso trae solo algunas materias.

**b) Calidad promedio de los profesores de cada grupo en 27/1**

```
γ grupo; avg(mp_calidad)→calidad_promedio, count(mp_calidad)→con_dato (
  σ periodo = '27/1' (oferta) ⨝ oferta.profesor = profesor.id profesor
)
```

```sql
SELECT o.grupo, round(avg(p.mp_calidad), 2) AS calidad_promedio, count(p.mp_calidad) AS con_dato
FROM oferta o JOIN profesor p ON o.profesor = p.id
WHERE o.periodo = '27/1'
GROUP BY o.grupo
ORDER BY o.grupo;
```

| grupo | calidad_promedio | con_dato |
|---|---|---|
| 1CM1 | 8.05 | 4 |
| 1CM2 | 6.56 | 5 |
| 1CM8 | 9.20 | 1 |
| 2CM1 | 7.64 | 5 |
| 8BM1 | 6.10 | 2 |
| 8BM2 | 6.00 | 2 |

`avg` y `count(atributo)` **ignoran los `null`** en los dos lados: `1CM1` tiene 5 profes pero
solo 4 con calidad. RelaX muestra `7.640000000000001` en `2CM1` porque no redondea.

### 12. División: grupos que en 27/1 ofrecen todas las materias de 1.er semestre

```
π grupo, materia (σ periodo = '27/1' (oferta))
÷
ρ materia←clave (π clave (σ semestre = 1 (materia)))
```

```sql
-- "No existe una materia de 1.º que el grupo no ofrezca" (doble negación)
SELECT DISTINCT o.grupo
FROM oferta o
WHERE o.periodo = '27/1'
  AND NOT EXISTS (
        SELECT 1 FROM materia m
        WHERE m.semestre = 1
          AND NOT EXISTS (
                SELECT 1 FROM oferta x
                WHERE x.periodo = '27/1' AND x.grupo = o.grupo AND x.materia = m.clave))
ORDER BY o.grupo;
```

| grupo |
|---|
| 1CM1 |
| 1CM2 |

`1CM8` queda fuera porque en 27/1 solo ofrece Cálculo, y `2CM1`, `8BM1` y `8BM2` no tienen
ninguna de 1.º. SQL no tiene operador de división: se escribe con dos `NOT EXISTS`
anidados, que se leen "para todo". El `ρ materia←clave` es para que el divisor tenga el mismo
nombre de atributo que el dividendo.

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
