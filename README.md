# Catscoms

Equipo del curso de Bases de Datos, ESCOM-IPN, ISC 2020.

Práctica 2: *Modelo Entidad-Relación Extendido: proyecto propio y proyecto asignado*.

## Integrantes

- Estrada Sánchez Emiliano
- Mora Acosta Pablo
- Espinosa Gómez David Enrique

## Proyecto propio

**Gestor académico ESCOM** — sistema multiusuario de apoyo a la reinscripción para las tres carreras de la Escuela (ISC, IIA, LCD), a partir de `iscweb`. Detalles en [`proyecto-propio/requisitos-ampliados.pdf`](proyecto-propio/requisitos-ampliados.pdf).

- Modelo EER en notación Chen: [`proyecto-propio/eer-chen.png`](proyecto-propio/eer-chen.png)
- Modelo EER en notación Crow's Feet: [`proyecto-propio/eer-crows-feet.png`](proyecto-propio/eer-crows-feet.png)

## Proyecto asignado

**Sismos** — Sistema de visualización de datos sísmicos de México

- Repositorio original: https://github.com/gabrielhuav/Seismic-Data-Visualization-System
- Fork del equipo: https://github.com/pablo140706/Seismic-Data-Visualization-System
- Commit que lo puso en funcionamiento: [`8569667`](https://github.com/pablo140706/Seismic-Data-Visualization-System/commit/8569667cf4f46fab640dba3f82a7b324ca7efaf7)
- Artículo de referencia: Villa Vargas, J. M., Hurtado Avilés, G., y Climent Hernández, J. A. (2026). Cuando México tiembla: la historia contada por los datos. *AZCATL Revista de Divulgación en Ciencias, Ingeniería e Innovación, 4*(6), 28-33. https://doi.org/10.24275/AZC2026E1004
- Documentación del levantamiento: [`proyecto-asignado/levantamiento.md`](proyecto-asignado/levantamiento.md)
- Modelo EER del proyecto asignado (notación Chen): [`proyecto-asignado/eer.png`](proyecto-asignado/eer.png)
- Correspondencia con el esquema publicado: [`proyecto-asignado/correspondencia-con-el-esquema.pdf`](proyecto-asignado/correspondencia-con-el-esquema.pdf)
- Evidencias (terminal, aplicación en funcionamiento y consulta): carpeta [`proyecto-asignado/evidencias/`](proyecto-asignado/evidencias/)

## Resúmenes de artículos (Ejercicio 3)

Resúmenes de los tres artículos de referencia (datos sísmicos, consumo de agua en la CDMX y obra pública municipal): [`articulos/resumenes.pdf`](articulos/resumenes.pdf).

## Propuestas de mejora (Ejercicio 6)

Registradas como issues, asignadas a su autor. Los issues están en el fork del proyecto asignado: [ver issues cerrados](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues?q=is%3Aissue+state%3Aclosed).

| # | Autor | Propuesta | Issue |
|---|---|---|---|
| 2 | Estrada Sánchez Emiliano | Despliegue reproducible del entorno que funcione con un solo comando | [#1](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/1) |
| 3 | Estrada Sánchez Emiliano | Normalizar la tabla de hechos y sus dimensiones | [#5](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/5) |
| 6 | Estrada Sánchez Emiliano | Guardar y compartir reportes analíticos personalizados | [#6](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/6) |
| 1 | Mora Acosta Pablo | Bitácora de carga y auditoría de registros descartados | [#2](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/2) |
| 4 | Mora Acosta Pablo | Selección dinámica de cortes censales para el impacto | [#3](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/3) |
| 8 | Mora Acosta Pablo | Cálculo del impacto territorial por municipio | [#4](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/4) |
| 5 | Espinosa Gómez David Enrique | Documentación y versionado del cálculo de riesgo | [#7](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/7) |
| 7 | Espinosa Gómez David Enrique | Detección de réplicas y secuencias sísmicas | [#8](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/8) |
| 9 | Espinosa Gómez David Enrique | Clasificación por placa tectónica o zona sismogénica | [#9](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/9) |

PDF con el detalle de las 9 propuestas: [`propuestas/propuestas-de-mejora.pdf`](propuestas/propuestas-de-mejora.pdf)

## Exposición

Presentación en PDF: [`exposicion/presentacion.pdf`](exposicion/presentacion.pdf)

## Repositorio y sistema gestor

El archivo [`compose.yaml`](compose.yaml) de la Práctica 1 se conserva para levantar el sistema gestor de bases de datos; se usará en la Práctica 3 con el esquema del proyecto propio. El trabajo de la práctica se hizo en la rama `practica2` y se cerró con un Pull Request revisado por otro integrante.

## Bibliografía

Villa Vargas, J. M., Hurtado Avilés, G., y Climent Hernández, J. A. (2026). Cuando México tiembla: la historia contada por los datos. *AZCATL Revista de Divulgación en Ciencias, Ingeniería e Innovación, 4*(6), 28-33. https://doi.org/10.24275/AZC2026E1004

Velázquez Arrieta, E. U., Pulido Morales, O. F., García López, E., Hernández Martínez, C. A., y Hurtado Avilés, G. (en prensa). Territorial information retrieval from heterogeneous open data through the construction of a data warehouse for water management in Mexico City. En *Advances in Computer Science Applications and Research*. Springer.

González Casiano, U., Maldonado Mejía, M. T., y Hurtado Avilés, G. (en prensa). A dimensional data warehouse for geospatial monitoring of municipal public works, with an evolution path toward a lakehouse architecture. En *Advances in Computer Science Applications and Research*. Springer.

## Declaración sobre el uso de inteligencia artificial generativa

Se usó Claude (Anthropic) como asistente para localizar y leer los artículos del Ejercicio 3, redactar los borradores de los resúmenes y apoyar la elaboración del modelo EER y del documento del proyecto asignado. El contenido fue revisado, corregido y aprobado por el equipo, y cada integrante es responsable de sus propuestas de mejora.
