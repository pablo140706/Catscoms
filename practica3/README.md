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

**Gestor académico ESCOM** — sistema multiusuario de apoyo a la reinscripción para las tres carreras de la Escuela (ISC, IIA, LCD). El modelo EER de partida es el del Ejercicio 4 de la Práctica 2: [`proyecto-propio/requisitos-ampliados.pdf`](../proyecto-propio/requisitos-ampliados.pdf).

## Proyecto asignado

**Sismos** — Sistema de visualización de datos sísmicos de México.

- Repositorio original: https://github.com/gabrielhuav/Seismic-Data-Visualization-System
- Fork del equipo: https://github.com/pablo140706/Seismic-Data-Visualization-System
- Modelo EER reconstruido en la Práctica 2: [`proyecto-asignado/Ejercicio-5.pdf`](../proyecto-asignado/Ejercicio-5.pdf)

## Sistema gestor utilizado

**PostgreSQL 16**, en contenedor, levantado con el [`compose.yaml`](../compose.yaml) de la Práctica 1.

| | Proyecto propio | Proyecto asignado |
|---|---|---|
| Contenedor | `pg-practica1` | `seismic-data-visualization-system-db-1` |
| Puerto en el host | 5432 | 5433 |
| Base de datos | `catscoms_p3` | `datawarehouse` |

```bash
docker compose up -d
docker exec -it pg-practica1 psql -U postgres -c "CREATE DATABASE catscoms_p3;"
docker exec -it pg-practica1 psql -U postgres -d catscoms_p3 -f /ruta/esquema.sql
```

## Correcciones al modelo EER de la Práctica 2

> El Ejercicio 2 pide corregir el modelo antes de transformarlo y anotar aquí qué cambió y por qué.

| Qué cambió | Por qué |
|---|---|
| *(pendiente)* | |

## Cambio de esquema por integrante (Ejercicio 8)

| Integrante | Propuesta que lleva al esquema | Issue | Archivo |
|---|---|---|---|
| Estrada Sánchez Emiliano | *(pendiente: una de sus 3)* | | `cambios/cambio-Ayddoous10.sql` |
| Mora Acosta Pablo | *(pendiente: una de sus 3)* | | `cambios/cambio-pablo140706.sql` |
| Espinosa Gómez David Enrique | *(pendiente: una de sus 3)* | | `cambios/cambio-daenesgo.sql` |

Las nueve propuestas registradas en la Práctica 2 están en el [README de la raíz](../README.md).

## Contenido

```
practica3/
  README.md
  proyecto-propio/
    inventario-eer.pdf
    transformacion.pdf
    diccionario-de-datos.pdf
    diagrama-relacional.png
    sql/
      esquema.sql
      pruebas-de-restricciones.sql
  proyecto-asignado/
    analisis-del-esquema.pdf
    comparacion-eer-relacional.pdf
  cambios/
    cambio-<usuario>.sql
    cambio-<usuario>.pdf
  evidencias/
```

## Bibliografía

*(pendiente — formato APA séptima edición)*

## Declaración sobre el uso de inteligencia artificial generativa

*(pendiente)*
