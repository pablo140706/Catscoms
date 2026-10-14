# Práctica 3 — Transformación del modelo EER al modelo relacional

Equipo **Catscoms** · Bases de Datos · ESCOM-IPN · Ingeniería en Sistemas Computacionales, plan 2020

Fecha de entrega: miércoles 14 de octubre de 2026

## Integrantes

| Integrante | Usuario de GitHub |
|---|---|
| Estrada Sánchez Emiliano | `Ayddoous10` |
| Mora Acosta Pablo | `pablo140706` |
| Espinosa Gómez David Enrique | `daenesgo` |

## Proyecto propio

**Gestor académico ESCOM** — sistema multiusuario de apoyo a la reinscripción para las tres carreras de la Escuela (ISC, IIA, LCD). El modelo EER de partida es el del Ejercicio 4 de la [Práctica 2](https://github.com/pablo140706/Catscoms/blob/main/proyecto-propio/requisitos-ampliados.pdf).

El esquema resultante tiene **18 tablas**, 89 columnas, 22 claves foráneas y 28 restricciones `CHECK`, más dos vistas para los atributos derivados y tres disparadores para las reglas de negocio que no caben en una restricción declarativa.

## Proyecto asignado

**Sismos** — Sistema de visualización de datos sísmicos de México.

- Repositorio original: https://github.com/gabrielhuav/Seismic-Data-Visualization-System
- Fork del equipo: https://github.com/pablo140706/Seismic-Data-Visualization-System
- Modelo EER reconstruido en la [Práctica 2](https://github.com/pablo140706/Catscoms/blob/main/proyecto-asignado/Ejercicio-5.pdf)

## Sistema gestor utilizado

**PostgreSQL 16** para el proyecto propio y **PostgreSQL 17** para el asignado, los dos en contenedor.

| | Proyecto propio | Proyecto asignado |
|---|---|---|
| Contenedor | `pg-practica1` | `seismic-data-visualization-system-db-1` |
| Puerto en el host | 5432 | 5433 |
| Base de datos | `catscoms_p3` | `datawarehouse` |

```bash
docker compose up -d
docker exec -it pg-practica1 psql -U postgres -c "CREATE DATABASE catscoms_p3;"
docker exec -i pg-practica1 psql -U postgres -d catscoms_p3 -v ON_ERROR_STOP=1 < proyecto-propio/sql/esquema.sql
```

Cada integrante trabaja el Ejercicio 8 sobre su propia copia de la base del proyecto asignado, para no pisar el trabajo de los demás: `dw_pablo140706`, `dw_ayddoous10` y `dw_daenesgo`.

## Correcciones al modelo EER de la Práctica 2

El Ejercicio 2 pide corregir el modelo antes de transformarlo. Al revisarlo contra las reglas de la notación aparecieron tres puntos que además impedían aplicar alguna regla de transformación.

| Qué cambió | Por qué |
|---|---|
| La cardinalidad de **Cursa** pasa de `(0, carga_media) : (0, cupo)` a `(0, N) : (0, N)` | El máximo de una cardinalidad debe ser una constante del modelo. Aquí dependía de `Carrera.carga_media` —7 en ISC y 6 en IIA y LCD— y de `Grupo.cupo`, distinto en cada grupo. Los dos topes pasaron a disparadores |
| Se añade el atributo multivaluado **`Estudiante.telefono`** | El modelo no tenía ninguno y la Regla 3 se quedaba sin nada que transformar. El procedimiento de reinscripción exige teléfono de casa y celular, así que el atributo estaba en el dominio aunque faltara en el diagrama |
| **MateriaOptativa** gana un segundo atributo propio, `semestre_sugerido` | Solo tenía `slot`: lo que se contaba como segundo atributo era `rama_id`, que es una clave foránea y no un atributo del subtipo |

## Decisiones de transformación que conviene justificar

- **Jerarquía `Materia`: estrategia A**, una tabla por supertipo y una por subtipo. Se descartó la C —tabla por subtipo sin supertipo— aunque la jerarquía sea total y disjunta, porque `grupo.materia_id` y las dos columnas de `prerrequisito` necesitan apuntar a una sola tabla.
- **La disyunción la impone el gestor**, no la aplicación: cada subtipo referencia la pareja `(id, tipo)` de `materia` y fija su propio `tipo` con un `CHECK`.
- **Los atributos derivados no se almacenan.** `promedio`, `carga_inscrita` y `adeudos_contabilizados` son vistas, para que nunca contradigan al historial del que salen.
- **`grupo` lleva clave subrogada** con la clave natural `(periodo_id, codigo)` declarada como `UNIQUE`, para no arrastrar dos columnas por cada nivel de dependencia.

## Cambio de esquema por integrante (Ejercicio 8)

| Integrante | Propuesta | Issue | Archivos |
|---|---|---|---|
| Estrada Sánchez Emiliano | Guardar y compartir reportes analíticos personalizados | [#6](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/6) | `cambios/cambio-Ayddoous10.sql` y `.pdf` |
| Mora Acosta Pablo | Bitácora de carga y auditoría de registros descartados | [#2](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/2) | `cambios/cambio-pablo140706.sql` y `.pdf` |
| Espinosa Gómez David Enrique | Detección de réplicas y secuencias sísmicas | [#8](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/8) | `cambios/cambio-daenesgo.sql` y `.pdf` |

## Contenido

```
proyecto-propio/
  inventario-eer.pdf              Ejercicio 2
  transformacion.pdf              Ejercicios 3, 4, 5, 6.1, 6.2 y 6.5
  diccionario-de-datos.pdf        Ejercicio 6.4
  diagrama-relacional.png         Ejercicio 6.3
  sql/
    esquema.sql
    pruebas-de-restricciones.sql
proyecto-asignado/
  analisis-del-esquema.pdf        Ejercicio 7.1 y 7.2
  comparacion-eer-relacional.pdf  Ejercicio 7.3
cambios/
  cambio-<usuario>.sql y .pdf     Ejercicio 8, uno por integrante
evidencias/
```

## Bibliografía

Elmasri, R., y Navathe, S. B. (2016). *Fundamentals of database systems* (7.ª ed.). Pearson.

Escuela Superior de Cómputo. (2026). *Procedimiento de reinscripción, periodo escolar 2027/1 (agosto 2026 – enero 2027)*. Instituto Politécnico Nacional.

Instituto Politécnico Nacional. (2011). *Reglamento General de Estudios*. https://www.ipn.mx/assets/files/normatividad/docs/reglamentos/rge-13-06-2011.pdf

Kimball, R., y Ross, M. (2013). *The data warehouse toolkit: The definitive guide to dimensional modeling* (3.ª ed.). Wiley.

The PostgreSQL Global Development Group. (2025). *PostgreSQL 16 documentation*. https://www.postgresql.org/docs/16/

Villa Vargas, J. M., Hurtado Avilés, G., y Climent Hernández, J. A. (2026). Cuando México tiembla: la historia contada por los datos. *AZCATL Revista de Divulgación de la Ciencia, la Ingeniería y la Innovación, 4*(6), 28–33. https://doi.org/10.24275/AZC2026E1004

## Declaración sobre el uso de inteligencia artificial generativa

Se utilizó **Claude** (Anthropic), a través de Claude Code, como apoyo en esta práctica.

**Para qué se usó.** Revisar el modelo EER de la Práctica 2 contra las reglas de la notación y detectar los tres puntos corregidos que se listan arriba; escribir el borrador del script de definición de datos y de las pruebas de restricciones; generar el diccionario de datos y el diagrama relacional a partir del catálogo del gestor; consultar la base del proyecto asignado para documentar su esquema con datos reales; y redactar los documentos.

**Qué puso el equipo.** El modelo conceptual, las entidades y las reglas de negocio provienen del trabajo previo de los integrantes y de las fuentes oficiales citadas. Las decisiones de transformación —la estrategia de la jerarquía, el uso de disparadores para los topes de carga y de cupo, y no almacenar los atributos derivados— se tomaron y se revisaron en equipo. Cada integrante ejecutó el esquema y su propio cambio del Ejercicio 8, conservó sus evidencias, y responde por el contenido que entrega.
