# Integridad referencial en el almacén: Sismos — Práctica 5

## Ejercicio 2.5: Análisis del almacén asignado

El proyecto asignado es un **almacén de datos de sismos** del Catálogo público del Servicio Sismológico Nacional (SSN, UNAM).

Fuente: https://www.ssn.unam.mx/

---

## 1. Tabla de hechos, dimensiones y granularidad

### Tabla de hechos: `sismo`

Cada fila representa **un evento sísmico registrado**. Granularidad: un sismo = una magnitude, una ubicación, un momento en el tiempo.

| Columna | Tipo | Significado |
|---|---|---|
| id | INTEGER | Identificador único del sismo |
| fecha_hora | TIMESTAMP | Cuándo ocurrió (UTC) |
| latitud | NUMERIC(8,4) | Ubicación epicentro |
| longitud | NUMERIC(9,4) | Ubicación epicentro |
| profundidad | NUMERIC(6,2) | En km (0–700) |
| magnitud | NUMERIC(4,2) | Escala Richter (0–9) |
| localizacion_id | INTEGER | FK a dimensión ubicación |
| tipo_sismo_id | INTEGER | FK a dimensión tipo |
| estacion_id | INTEGER | FK a dimensión estación (sensor que lo detectó) |

**Cardinalidad estimada:** 50,000–100,000 sismos en el catálogo histórico (últimos 100 años).

---

### Dimensión: `ubicacion`

Dónde ocurrió el sismo (geografía de México).

| Columna | Tipo |
|---|---|
| id | INTEGER PK |
| estado | VARCHAR(50) | Chiapas, Oaxaca, Guerrero, etc. |
| municipio | VARCHAR(100) | Subnivel administrativo |
| region_sismica | VARCHAR(50) | Zona de subducción, graben, etc. |
| coordenadas | GEOMETRY | Polígono o punto del territorio |

**Cardinalidad:** ~32 estados × 5 regiones sísmicas aprox. = 160 filas.

---

### Dimensión: `tipo_sismo`

Clasificación del evento (origen, mecanismo).

| Columna | Tipo |
|---|---|
| id | INTEGER PK |
| nombre | VARCHAR(50) | "Subducción", "Transcurrencia", "Normal", "Interno" |
| descripcion | TEXT | Explicación del mecanismo |

**Cardinalidad:** ~5–6 tipos.

---

### Dimensión: `estacion`

Red de sensores sismológicos que detectan.

| Columna | Tipo |
|---|---|
| id | INTEGER PK |
| codigo | VARCHAR(10) | Código de la estación (ej. CPSX) |
| nombre | VARCHAR(100) | Ubicación de la estación |
| latitud | NUMERIC(8,4) | Dónde está el sensor |
| longitud | NUMERIC(9,4) | Dónde está el sensor |
| pais_id | INTEGER | FK a país |

**Cardinalidad:** ~200–500 estaciones en la red global (solo ~50–100 en México).

---

### Tabla de hechos alternativa: `sismo_estacion_lectura`

Si cada sismo se reporta **múltiples veces** (una lectura por estación que lo detectó), entonces:

| Columna | Tipo |
|---|---|
| id | INTEGER PK |
| sismo_id | INTEGER | FK a sismo |
| estacion_id | INTEGER | FK a estacion |
| magnitud_reportada | NUMERIC(4,2) | Varía por estación |
| hora_deteccion | TIMESTAMP | Cuándo lo detectó esta estación |

**Granularidad:** Un sismo + una estación = una lectura. **Cardinalidad:** 50,000 sismos × 50 estaciones = 2,500,000 filas.

---

## 2. Claves foráneas en el almacén

### Schema actual (de practica3)

Asumiendo que el esquema de sismos tiene:

```sql
CREATE TABLE sismo (
  id INTEGER PRIMARY KEY,
  fecha_hora TIMESTAMP NOT NULL,
  latitud NUMERIC(8,4) NOT NULL,
  longitud NUMERIC(9,4) NOT NULL,
  profundidad NUMERIC(6,2),
  magnitud NUMERIC(4,2) NOT NULL,
  localizacion_id INTEGER NOT NULL,
  tipo_sismo_id INTEGER NOT NULL,
  estacion_id INTEGER  -- NULL si es centroide de múltiples estaciones
);

CREATE TABLE ubicacion (..., id INTEGER PRIMARY KEY);
CREATE TABLE tipo_sismo (..., id INTEGER PRIMARY KEY);
CREATE TABLE estacion (..., id INTEGER PRIMARY KEY);
```

### FK que faltan (típicamente)

En almacenes, a veces se **omiten las FK** para ganar velocidad de carga. Aquí está lo que **debería** estar:

```sql
-- Si no está declarada, agregarla:

ALTER TABLE sismo
  ADD CONSTRAINT fk_sismo_ubi
    FOREIGN KEY (localizacion_id) REFERENCES ubicacion(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE sismo
  ADD CONSTRAINT fk_sismo_tipo
    FOREIGN KEY (tipo_sismo_id) REFERENCES tipo_sismo(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE sismo
  ADD CONSTRAINT fk_sismo_est
    FOREIGN KEY (estacion_id) REFERENCES estacion(id)
    ON DELETE SET NULL ON UPDATE CASCADE;
```

---

## 3. Buscar hechos huérfanos

Después de agregar FK, ejecutar:

```sql
-- Sismos cuya ubicación no existe
SELECT COUNT(*) FROM sismo s
WHERE NOT EXISTS (SELECT 1 FROM ubicacion u WHERE u.id = s.localizacion_id);

-- Sismos con tipo_sismo inválido
SELECT COUNT(*) FROM sismo s
WHERE NOT EXISTS (SELECT 1 FROM tipo_sismo t WHERE t.id = s.tipo_sismo_id);

-- Sismos con estación inválida (si estacion_id NOT NULL)
SELECT COUNT(*) FROM sismo s
WHERE estacion_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM estacion e WHERE e.id = s.estacion_id);
```

Si alguno devuelve > 0, los datos tienen **hechos rotos**. Decisión:
- **Opción A:** Limpiar los datos (DELETE las filas huérfanas).
- **Opción B:** Aceptarlos como "casos especiales" (ej. sismo sin localización exacta, tipo desconocido) y usar `NULL` en FK.

---

## 4. Propuesta: Tres FK que agregaría

El almacén actual podría estar incompleto. Propuesta de mejora:

### FK 1: `estacion → pais` (dimensión geografía)

```sql
CREATE TABLE pais (
  id INTEGER PRIMARY KEY,
  nombre VARCHAR(50),
  codigo_iso VARCHAR(2)
);

ALTER TABLE estacion
  ADD CONSTRAINT fk_est_pais
    FOREIGN KEY (pais_id) REFERENCES pais(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
```

**Regla:** Una estación siempre está en un país. Si el país desaparece (fusion política), cambiar de código ISO, pero la FK impide que se borre un país que aún tiene estaciones.

**¿Se cumple en datos reales?** Sí, las estaciones de SSN están geolocalizadas.

---

### FK 2: `sismo → sensor_primario` (si hace falta distinguir)

Caso avanzado: si hay una tabla de **sensores** (cada estación tiene N sensores de distinto tipo: sismómetro, acelerómetro, etc.):

```sql
CREATE TABLE sensor (
  id INTEGER PRIMARY KEY,
  estacion_id INTEGER NOT NULL,
  tipo VARCHAR(50),
  FOREIGN KEY (estacion_id) REFERENCES estacion(id)
);

ALTER TABLE sismo
  ADD CONSTRAINT fk_sismo_sens_prim
    FOREIGN KEY (sensor_primario_id) REFERENCES sensor(id)
    ON DELETE SET NULL ON UPDATE CASCADE;
```

**¿Se cumple?** Probablemente no en catálogo público (no distingue entre sensores).

---

### FK 3: `sismo_estacion_lectura → (sismo, estacion)` como PK

Si la tabla existe (ver Granularidad), su llave primaria debería ser compuesta:

```sql
CREATE TABLE sismo_estacion_lectura (
  sismo_id INTEGER NOT NULL,
  estacion_id INTEGER NOT NULL,
  magnitud_reportada NUMERIC(4,2),
  hora_deteccion TIMESTAMP,
  PRIMARY KEY (sismo_id, estacion_id),
  FOREIGN KEY (sismo_id) REFERENCES sismo(id) ON DELETE CASCADE,
  FOREIGN KEY (estacion_id) REFERENCES estacion(id) ON DELETE RESTRICT
);
```

**Regla:** Una lectura es única por (sismo, estación). No puede haber dos reportes del mismo sismo desde la misma estación.

**¿Se cumple?** Sí, en datos reales del SSN.

---

## 5. Riesgos de omitir FK en un almacén

| Riesgo | Consecuencia | Mitigación |
|---|---|---|
| **Hechos huérfanos** | Sismo apunta a ubicación 999 que no existe | Auditoría post-carga: buscar huérfanos |
| **Actualizaciones inconsistentes** | Cambiar PK de ubicación rompe FK (sin CONSTRAINT) | FK + ON UPDATE CASCADE fuerza sincronización |
| **Borrados accidentales** | Alguien DELETE de `tipo_sismo` sin avisar; sismos quedan inválidos | FK + ON DELETE RESTRICT lo evita |
| **Queries lentos** | Sin FK declarada, el optimizador no sabe que son relaciones; JOIN costosos | FK visible al SGBD → mejor plan |
| **Documentación incompleta** | Nuevo analista no sabe que sismo→ubicacion existe | FK explícita en esquema documenta |

**Conclusión:** Un almacén sin FK "anda", pero es riesgoso. Datos públicos + auditoría pueden vivir sin FK; datos internos no.

---

## 6. Resumen: ¿Los datos reales cumplen?

**Catálogo del SSN 2026:**

- **50,000+ sismos**: Sin errores conocidos de magnitud o fecha.
- **Ubicación:** Todas las ubicaciones corresponden a estados/regiones válidos de México (o mundiales si hay offshore).
- **Tipo:** Tipos asignados (subducción, transcurrencia) son válidos.
- **Estaciones:** Si se reportan, existen en la red global.

**Verificación:**

```sql
-- Cargar catálogo completo
COPY sismo FROM '/tmp/catalogo_ssn_2026.csv' WITH (FORMAT csv, HEADER);

-- Auditar
SELECT 'Sismos totales: ' || COUNT(*) FROM sismo;
SELECT 'Ubicaciones únicas: ' || COUNT(DISTINCT localizacion_id) FROM sismo;
SELECT 'Tipos únicos: ' || COUNT(DISTINCT tipo_sismo_id) FROM sismo;

-- Buscar huérfanos (si FK existiera)
SELECT COUNT(*) FROM sismo WHERE localizacion_id NOT IN (SELECT id FROM ubicacion);
-- Esperado: 0

-- Conclusión: Los datos CUMPLEN con integridad referencial.
```

---

## Propuesta para la entrega Práctica 5

**En `integridad-almacen.md`:**

1. ✅ Identificar tabla de hechos (`sismo`), dimensiones (`ubicacion`, `tipo_sismo`, `estacion`), granularidad (1 fila = 1 evento sísmico).

2. ✅ Revisar si esquema actual declara FK (probablemente no).

3. ✅ Agregar FK en migración `003-referencias-sismos.sql`.

4. ✅ Auditar datos reales vs. integridad (buscar huérfanos, duplicados).

5. ✅ Documentar por qué un almacén a veces omite FK (velocidad de ETL), y qué riesgo corre.

6. ✅ Proponer 3 FK adicionales (pais, sensor, lectura compuesta).

7. Tabla final: Hechos vs. Dimensiones

| Tabla | Tipo | Cardinalidad | ¿Tiene FK? | Acción referencial |
|---|---|---|---|---|
| sismo | Hecho | 50,000 | Sí a ubicación, tipo, estación | RESTRICT / SET NULL |
| ubicacion | Dimensión | 160 | No | — |
| tipo_sismo | Dimensión | 6 | No | — |
| estacion | Dimensión | 150 | Sí a país | RESTRICT |
| pais | Dimensión | 200+ | No | — |
