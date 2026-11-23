# Análisis del Manuscrito y Propuestas de Mejora

## 1. Referencia en APA 7
Villa Vargas, J. M., & Hurtado Avilés, G. (2026). *A browser-based seismic data observatory for detecting and comparing earthquake sequences across North American catalogues* [Manuscrito en revisión, *Computers & Geosciences*]. Repositorio GitHub: https://github.com/gabrielhuav/Seismic_Data_Geosciences/tree/main | Archivo de datos y código en Zenodo: https://doi.org/10.5281/zenodo.24361244

- **Manuscrito (Word):** https://github.com/gabrielhuav/Seismic_Data_Geosciences/blob/main/paper/manuscript/out/Seismic_CG_manuscript_R3.docx
- **Manuscrito (PDF):** https://github.com/gabrielhuav/Seismic_Data_Geosciences/blob/main/paper/manuscript/out/Seismic_CG_manuscript_R3.pdf
- **Reporte iThenticate:** https://github.com/gabrielhuav/Seismic_Data_Geosciences/blob/main/paper/manuscript/out/ITHENTICATE_R3_05.pdf

## 2. Resumen del manuscrito
- **Problema:** Cuando dos agencias sismológicas reportan lo que parece ser el mismo sismo, los algoritmos de detección de secuencias (familias de sismos y réplicas) pueden asignarles distintos eventos "padre" o roles operativos (*aislado*, *representante*, *asociado*) debido a diferencias en magnitud, ubicación, cobertura o peso asignado a la magnitud. Además, la búsqueda exhaustiva de vecinos más cercanos en catálogos grandes resulta computacionalmente costosa.
- **Datos y método:** Se construyó un observatorio sísmico en navegador con **287,936 registros preservados** de cuatro catálogos de Norteamérica (USGS Norteamérica, USGS México, NRCan Canadá y SSN/UNAM México). Se implementó una búsqueda espacial exacta con **árbol KD (*KD-tree*)** y *octree* sobre la esfera unitaria para el método de vecinos más cercanos (Zaliapin y Ben-Zion), validándola contra búsqueda exhaustiva, el método Gardner-Knopoff (GK) y 60 catálogos sintéticos ETAS con genealogía conocida.
- **Resultado principal:**
  - En 170,880 registros del SSN ($M \ge 3.5$), el índice *KD-tree* devolvió exactamente los mismos resultados que la búsqueda exhaustiva, reduciendo la mediana de tiempo de **524.04 s a 5.92 s** (aceleración de **88.46×**). En el navegador (Chrome Web Worker) completó el catálogo en ~12.88 s, mientras que la búsqueda exhaustiva superó el límite de 120 s.
  - En México ($M \ge 4.5$, peso $w=1$), 772 de 889 pares candidatos (86.84%) coincidieron en su rol entre SSN y ComCat, pero la coincidencia de eventos representantes (índice de Jaccard) fue de **0.41**. Al usar pesos ajustados por catálogo (valor $b$ aparente), la coincidencia en 2021–2025 cayó a **37.17%**.
- **Avance respecto al primer parcial:**
  - **Arquitectura:** Pasó de un sistema dependiente de **Docker, PostgreSQL y Python** (*Seismic-Data-Visualization-System*, artículo *AZCATL*) a una aplicación **100% estática en el navegador** con `sql.js` (SQLite en WebAssembly), *Web Workers* y verificación SHA-256.
  - **Cobertura y alcance:** Pasó de visualizar únicamente datos de México (SSN + INEGI) a comparar **4 catálogos de Norteamérica** e incorporar algoritmos científicos reproducibles de detección de secuencias sísmicas.

## 3. Propuestas de mejora

### Mejora 1: Paginación interactiva y telemetría de memoria en el entorno SQL y Web Worker
- **Limitación observada:** El manuscrito reporta que el pico de memoria del *Web Worker* en el navegador es desconocido (*"Peak Worker memory is unknown"*) y el explorador SQL trunca los resultados en un límite fijo de 5,000 filas sin navegación por páginas.
- **Qué se cambiaría:** Agregar controles de paginación (`LIMIT` / `OFFSET` automáticos en la interfaz) en el *Advanced SQL editor* para recorrer resultados mayores a 5,000 filas sin truncamiento, junto con un indicador ligero de tiempo de ejecución y estimación de memoria del *Worker*.
- **Cómo se comprobaría si funciona:** Ejecutar una consulta sobre `records` con más de 5,000 filas (por ejemplo, todos los sismos del SSN con $M \ge 4.0$), verificar que el conteo total coincida con `SELECT COUNT(*)` al navegar las páginas y confirmar que la interfaz no se congela y reporta tiempos consistentes en milisegundos.

### Mejora 2: Alerta visual de discrepancia de magnitud y tipo no reportado en comparaciones
- **Limitación observada:** El catálogo del SSN no reporta el tipo de magnitud (`mag_type IS NULL`) y en 1,112 de los 2,989 pares candidatos entre SSN y ComCat existe una diferencia de magnitud $|\Delta M| \ge 0.3$ (media SSN–ComCat de $+0.13034$), lo cual altera la asignación de roles sin advertencia visual directa en las tablas.
- **Qué se cambiaría:** Incorporar una etiqueta de advertencia en las vistas *Compare* y *SQL explorer* que resalte los registros con `mag_type IS NULL` y los pares con $|\Delta M| \ge 0.3$, con un filtro rápido para inspeccionar los eventos con mayor discrepancia entre agencias.
- **Cómo se comprobaría si funciona:** Aplicar el filtro sobre la cohorte de México ($M \ge 3.5$) y comprobar mediante una consulta SQL de control que el número de pares resaltados coincida exactamente con los 1,112 pares reportados en el manuscrito.