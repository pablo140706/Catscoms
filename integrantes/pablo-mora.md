# Trabajo individual · Mora Acosta Pablo

Prácticas 6, 7 y 8 · Bases de Datos · ESCOM · usuario de GitHub: `pablo140706`

Tres consultas propias sobre la base normalizada de Gestorix, que no repiten las del equipo
([`algebra.md`](../algebra.md)): una con **reunión externa**, una con **división** y una con
selección entre dos atributos y dos reuniones. El contenedor las corre solas desde
[`pablo-mora/`](pablo-mora/), y los resultados de abajo son los que devolvió.

---

## Consulta 1 · Reunión externa + agrupación

**Pregunta:** ¿cuántas clases da cada profesor en 27/1, contando también a los que ya no dan ninguna?

```
γ profesor.nombre; count(oferta.id)→clases_27_1 (
  profesor ⟕ profesor.id = oferta.profesor σ periodo = '27/1' (oferta)
)
```

📸 Captura de RelaX: `../evidencias/pablo-1.png` · SQL: [`pablo-mora/01-externa-clases-por-profesor.sql`](pablo-mora/01-externa-clases-por-profesor.sql)

| nombre | clases_27_1 |
|---|---|
| FLORES FUENTES NARIA ADRIANA | 2 |
| RESENDIZ MUÑOZ ROCIO | 2 |
| *(13 profesores más)* | 1 |
| DORANTES VILLA CLAUDIA JISELA | 0 |
| HERRERA YAÑEZ CRISPIN | 0 |
| LEAL PACHECO CHRISTIAN RENE | 0 |
| REYES BERMEJO TLATOANI DE JESUS | 0 |

19 filas: todos los profesores de la muestra.

**Por qué externa:** con una reunión normal, los 4 profesores que solo dieron clase en 26/2 desaparecen.
Con la externa izquierda se quedan con `null` en las columnas de `oferta`, y `count(oferta.id)` cuenta
0 porque `count` no cuenta los `null`. Si contara `count(*)`, les pondría 1, que sería falso.

**Ojo con dónde va el filtro:** el `σ periodo = '27/1'` va **dentro**, sobre `oferta`, antes de la
reunión. Si se pone después, sobre el resultado, el `null` de los que no tienen clase no pasa la
condición y se pierden otra vez. En SQL por eso el filtro va en una subconsulta, no en el `WHERE`.

## Consulta 2 · División

**Pregunta:** ¿qué grupos ofrecen en 27/1 **todas** las materias que piden un requisito?

```
π grupo, materia (σ periodo = '27/1' (oferta))
÷
π materia (seriacion)
```

📸 `../evidencias/pablo-2.png` · SQL: [`pablo-mora/02-division-materias-con-requisito.sql`](pablo-mora/02-division-materias-con-requisito.sql)

| grupo |
|---|
| 2CM1 |

El divisor es `{C201, C202, C203}`: las tres materias con requisito. Solo `2CM1` tiene las tres. Ningún
grupo de 1.º las tiene, porque son de 2.º. Aquí el divisor sale de **otra** relación, `seriacion`, no
de un filtro sobre la misma (como en la 13 del equipo). Los dos lados tienen el atributo `materia`, así
que no hace falta renombrar.

## Consulta 3 · Selección entre dos atributos + reunión natural + reunión theta

**Pregunta:** ¿qué clases de 27/1 están llenas (inscritos ≥ cupo) y quién las da?

```
π oferta.grupo, oferta.materia, profesor.nombre, cupo.cupo, cupo.inscritos (
  (σ inscritos >= cupo ∧ periodo = '27/1' (cupo) ⨝ oferta) ⨝ oferta.profesor = profesor.id profesor
)
```

📸 `../evidencias/pablo-3.png` · SQL: [`pablo-mora/03-clases-llenas.sql`](pablo-mora/03-clases-llenas.sql)

| grupo | materia | nombre | cupo | inscritos |
|---|---|---|---|---|
| 1CM1 | C101 | RESENDIZ MUÑOZ ROCIO | 36 | 36 |
| 1CM1 | C102 | VAZQUEZ GONZALEZ LEONOR | 36 | 36 |
| 1CM1 | C103 | FLORES FUENTES NARIA ADRIANA | 38 | 38 |
| 1CM1 | C104 | RODRIGUEZ VILLARREAL JOSE GREGORIO | 35 | 35 |
| 1CM1 | C105 | SANCHEZ MORENO ADRIANA DE LA P | 38 | 38 |
| 1CM8 | C103 | FLORES FUENTES NARIA ADRIANA | 37 | 37 |
| 2CM1 | C201 | TECLA PARRA ROBERTO | 36 | 36 |
| 2CM1 | C202 | GUZMAN AGUILAR FLORENCIO | 36 | 39 |
| 2CM1 | C203 | VIVEROS VELA KARINA | 36 | 36 |
| 2CM1 | C205 | ARREDONDO SANCHEZ ANA LAURA | 36 | 37 |
| 2CM1 | C206 | CASTILLO MARRUFO JUAN ANTONIO | 36 | 37 |

La condición compara **dos atributos de la misma fila** (`inscritos >= cupo`), no un atributo con una
constante. Hay clases con más inscritos que cupo, como `2CM1` C202 (39 de 36): es el **sobrecupo** de
SAES, que llega a +4. De 2CM1 solo falta C204 (Mecánica y electromagnetismo), que todavía tiene lugar.

---

## Una descomposición, con mis palabras: por qué el cupo salió de la oferta

En iscweb, la versión de Gestorix sin base, cada clase traía pegado su cupo. Parecía lógico: "el grupo
2CM1 de Cálculo aplicado con la profesora Viveros tiene 36 lugares". Pero el cupo **no es de la clase,
es del grupo + materia**. SAES lo da así. Se nota en Trabajo Terminal: en `8BM1` de TT II hay 3
asesores y **un solo** cupo de 36, que comparten.

Con el cupo dentro de la clase, ese 36 se guarda 3 veces. Si SAES lo cambia y se me olvida una fila, la
base dice dos cupos distintos para el mismo grupo. Eso es una anomalía de actualización. Y los grupos X
de TT, que tienen cupo pero no tienen clase con horario, ni siquiera se podían guardar.

En dependencias: escribí primero `periodo, grupo, clave, profesor → cupo`, pero al sacar el cierre de
`{periodo, grupo, clave}` ya me daba `cupo` sin el profesor. O sea, **el profesor sobraba** en ese lado
izquierdo. Ese atributo sobrante es justo la señal de una dependencia parcial: el cupo depende de una
**parte** de la llave de la clase. Así que el cupo se va a su propia tabla:

```
cupo(periodo, grupo, materia, cupo, inscritos)          llave: (periodo, grupo, materia)
oferta(id, periodo, grupo, materia, profesor, …)        llave natural: (periodo, grupo, materia, profesor)
```

No se pierde nada, porque lo que comparten (`periodo, grupo, materia`) es la llave de `cupo`. Al
reunirlas, cada asesor recupera el cupo de su grupo: es la consulta 08 del equipo. Y `disponibles` ni
se guarda: es `cupo − inscritos`, una dependencia transitiva, y se calcula al consultar.
