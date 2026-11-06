# Fuente de datos — Proyecto propio (Gestor académico ESCOM)

## Ejercicio 1.3: Referencia y metadatos

### Referencia APA

ESCOM-IPN. (2020). *Plan de estudios y catálogo de materias: Ingeniería en Sistemas Computacionales*. Disponible en: https://www.escom.ipn.mx/

**Licencia:** Datos públicos de una institución gubernamental (IPN). Uso permitido: educativo, no comercial, con atribución.

---

## Formato original y tamaño

| Aspecto | Valor |
|---|---|
| **Formato** | PDF (mapa curricular) + portal SAESPEED (acceso restringido) + CSV manual transcrito |
| **Tamaño** | ~500 KB (mapa), ~50 MB (base si se puebla completa) |
| **Registros esperados** | Ver tabla más abajo |
| **Período cubierto** | 2020/1 (plan vigente) y períodos 2025/2, 2026/1 en adelante |

### Tablas y registros esperados

| Tabla | Registros | Fuente |
|---|---|---|
| carrera | 3 | Catálogo: ISC, IA, LCD |
| periodo | 8–10 | Histórico: 26/2, 27/1, 27/2, 28/1, … |
| profesor | 200–250 | SAESPEED (directorio público por materia) |
| materia | 150–180 | Mapa curricular (46 ISC + 41 IA + 40 LCD obligatorias, ~40 optativas c/u) |
| grupo | 450–550 | Horarios ISC (SAESPEED matutino + vespertino), IA, LCD (2026/1) |
| estudiante | 2000–6000 | SAESPEED (rol docente acceso limitado) o fuente externa (si ESCOM compartiera) |
| cursa (inscripciones) | 15000–50000 | SAESPEED período vigente |
| sesion_horario | 800–1200 | Desglose de cada grupo (3–5 sesiones × semana) |
| rama (optativas ISC) | 14 | Mapa de optativas |

---

## Tabla de correspondencia: campos fuente → esquema

### `carrera`

| Campo fuente | Tabla | Columna | Tipo | Notas |
|---|---|---|---|---|
| Nombre (Ing. en Sistemas Computacionales) | carrera | nombre | VARCHAR(80) | Traducción: "ISC", "IA", "LCD" |
| Plan 2020 | carrera | plan_version | CHAR(4) | "2020" |
| Carga mínima del plan | carrera | carga_minima | SMALLINT | 4 UA (estándar ESCOM) |
| Carga media del plan | carrera | carga_media | SMALLINT | 7 UA (ISC) |

### `materia` y `materia_obligatoria`

| Campo fuente | Tabla | Columna | Tipo | Notas |
|---|---|---|---|---|
| Clave | materia | clave | VARCHAR(10) | "C101", "B640", "A720" (oficial SAES) |
| Nombre | materia | nombre | VARCHAR(120) | Tal como aparece en el mapa |
| Créditos | materia | creditos | SMALLINT | Siempre 7–9 |
| Semestre | materia | semestre_sugerido | SMALLINT | 1–8 (de la tabla del mapa) |
| Horas teoría | materia | horas_teoria | SMALLINT | Del mapa |
| Horas práctica | materia | horas_practica | SMALLINT | Del mapa |
| Tipo (Obligatoria) | materia_obligatoria | materia_id | FK | Si tipo='OBL' en mapa |

### `grupo` y `sesion_horario`

| Campo fuente | Tabla | Columna | Tipo | Notas |
|---|---|---|---|---|
| Grupo (ej. 1CM1) | grupo | codigo | VARCHAR(10) | Codificación: [semestre][carrera][turno][num] |
| Asignatura | grupo | materia_id | FK | Buscar por clave en materia |
| Profesor | grupo | profesor_id | FK | Normalizar nombre con `UPPER()` y buscar en profesor |
| Turno (M/V) | grupo | turno | CHAR(1) | Extraído del código del grupo o de SAESPEED |
| Período | grupo | periodo_id | FK | Del período vigente o histórico |
| Cupo | grupo | cupo | SMALLINT | Si está disponible en SAESPEED |
| Lun–Sáb, hora, aula | sesion_horario | [varios] | — | Una fila por sesión; agregar edificio si se tiene |

### `profesor`

| Campo fuente | Tabla | Columna | Tipo | Notas |
|---|---|---|---|---|
| Nombre (de SAESPEED) | profesor | nombre | VARCHAR(150) | Normalizado a UPPER(); algunos tienen acentos |
| Email | profesor | email | VARCHAR(100) | Si está disponible (SAESPEED no lo trae) |
| Teléfono | profesor | telefono | VARCHAR(20) | Si ESCOM lo compartiera |
| Activo en período | profesor | activo | BOOLEAN | 1 si enseña en 2026/1; 0 si no |

### `estudiante`

| Campo fuente | Tabla | Columna | Tipo | Notas |
|---|---|---|---|---|
| Matrícula | estudiante | matricula | VARCHAR(20) | Único por estudiante |
| Nombre | estudiante | nombre | VARCHAR(150) | Normalizado |
| Carrera | estudiante | carrera_id | FK | ISC, IA o LCD |
| Semestre actual | estudiante | semestre_actual | SMALLINT | 1–8 |
| Promedio acumulado | estudiante | promedio | NUMERIC(5,2) | Calculado o descargado de SAESPEED |
| Fecha ingreso | estudiante | fecha_ingreso | DATE | Año de ingreso convertido a 2020-09-01 |

### `cursa` (inscripciones)

| Campo fuente | Tabla | Columna | Tipo | Notas |
|---|---|---|---|---|
| Estudiante + grupo | cursa | estudiante_id, grupo_id | FK | Composite key (casi) |
| Calificación | cursa | calificacion | NUMERIC(4,2) | NULL si aún no hay o el período no termina |
| Tipo inscripción (regular/recurse) | cursa | tipo | VARCHAR(20) | Derivado de la 1.ª intención vs. reincorporación |
| Fecha inscripción | cursa | fecha_inscripcion | DATE | Período de reinscripción |
| Fecha término | cursa | fecha_termino | DATE | Fin de semestre (NULL en curso) |

---

## Problemas encontrados y decisiones

### 1. Nombres de profesores con acentos

**Problema:** SAESPEED a veces captura "GARCIA" (sin acento) y a veces "GARCÍA" (con acento). Al buscar por FK, esto causa duplicados.

**Decisión:** Almacenar con acentos respetando la fuente original. En búsquedas, normalizar con `LOWER(UNACCENT(nombre))` (si el SGBD lo permite) o en la aplicación.

### 2. Estudiantes sin promedio (primero de semestre)

**Problema:** Al inicio del período, los estudiantes no tienen calificaciones; `promedio` está vacío.

**Decisión:** `promedio` NULL es válido; se recalcula cada vez que termina un período. Alternativa: DEFAULT 0.0 si entra sin calificaciones.

### 3. Grupos sin cupo en SAESPEED

**Problema:** Algunos grupos no declaran cupo (especialmente Trabajo Terminal, tutoría, optativas especiales).

**Decisión:** `grupo.cupo` puede ser NULL. Si está NULL, la aplicación no impone límite de inscritos (o asume capacidad ilimitada del salón).

### 4. Materias sin horario fijo

**Problema:** Trabajo Terminal II, Estancia Profesional (8.º sem) no tienen sesión_horario (se coordinan aparte).

**Decisión:** Una fila en `grupo` con `codigo` (ej. "8CM_TT") y NINGUNA fila en `sesion_horario`. La aplicación interpreta grupo sin sesiones como "tutoría independiente".

### 5. Optativas sin rama definida en IA/LCD

**Problema:** ISC tiene 14 ramas (A1/B1/A2/B2 fijos). IA y LCD no. El esquema pide `slot IN ('A1','B1','A2','B2')` con `rama_id NOT NULL`.

**Decisión:** Para IA y LCD, `materia_optativa.slot = NULL` y `rama_id` también NULL. Una migración futura cambiará el constraint de `NOT NULL` a `NULL` condicional según carrera.

### 6. Período histórico vs. vigente

**Problema:** SAESPEED solo muestra 2026/1, pero queremos datos de períodos anteriores (26/2, 27/1, 27/2) para análisis.

**Decisión:** `periodo` tabla contiene todo el histórico. `grupo`, `cursa` se cargan para cada período en que hay datos. Las consultas pueden filtrar por período.

---

## Búsqueda realizada

**Términos:** "ESCOM horarios SAESPEED", "IPN plan de estudios 2020 CSV", "catálogo materias ESCOM", "datos públicos ESCOM".

**Fuentes consultadas:**
- ESCOM portal (https://www.escom.ipn.mx/) — acceso restringido a SAESPEED
- IPN repositorio institucional — solo PDFs de planes y mapa curricular
- Datos.gob.mx — no hay conjuntos ESCOM
- INEGI — educación superior agregada, no individual por institución

**Conclusión:** No existe un CSV público con la combinación completa (materias + grupos + profesores + estudiantes + calificaciones). Los datos provienen de:
- Mapa curricular PDF (públicos, necesita OCR)
- Captura manual de SAESPEED (rol docente/estudiante, acceso verificable)
- Censo de estudiantes inscritos (agregado, no granular)

**Decisión:** Usar datos **reales de ESCOM para 2026/1** (directorio de profesores público, horarios observables) y datos **sintéticos pero realistas** para estudiantes y calificaciones (respetar restricciones, variar según semestre, mantener promedios creíbles).

Todos los datos de estudiantes y calificaciones se marcarán como sintéticos en el README (generados para ejercicio educativo). No se subirán datos reales de personas.

---

## Línea de tiempo de carga

1. **Tablas base (dimensiones):** `carrera` → `periodo` → `profesor` → `rama`
2. **Catálogo académico:** `materia` → `materia_obligatoria` → `materia_optativa` → `prerrequisito`
3. **Oferta del período:** `grupo` → `sesion_horario`
4. **Estudiantes:** `estudiante` (se espera que ESCOM la compartiera; usaremos sintéticos)
5. **Inscripciones e historia:** `cursa` → `telefono_estudiante` (si aplica)
6. **Evaluación:** `resena` (comentarios de estudiantes sobre profesores)
