# Practices 6, 7 and 8 · Gestorix (own project)

**Run everything with one command** (Docker Desktop or Docker Engine with Compose v2):

```bash
docker compose up --exit-code-from consultas
```

**What you should see:**
- PostgreSQL 17 starts, loads the flat table `horario_plano` (90 real class sessions) and applies the
  numbered migration that normalizes it. Its log says
  `Sin pérdida: las 90 filas … (faltan 0, sobran 0)`.
- The `consultas` service prints, in order, every query of Part 2: its question, its relational-algebra
  expression and its result.
- It regenerates `relax/grupo.txt` from the database and ends with `Todo terminó sin errores.`
- The command returns exit code 0.

The whole output is also saved to `evidencias/salida-del-contenedor.txt`. It needs no input:
the test credentials are in `.env.example` (they are not real). Data survives restarts in the
`datos` volume. Run the same command again to repeat the queries; `docker compose down -v` deletes the
volume and starts from scratch.

---

## What is here

Gestorix is an academic manager for ESCOM students (progress, timetable, teachers, reviews), published at
<https://thwarting-earthling-evasive.ngrok-free.dev> (repository:
[`pablo140706/Gestorix`](https://github.com/pablo140706/Gestorix)). Its schema was already in 3NF/BCNF,
so, as the assignment allows, we normalize a **purposely denormalized table built with real data**: the
flat timetable record that iscweb (Gestorix before it had a database) used.

| Path | Content |
|---|---|
| [`normalizacion.md`](normalizacion.md) | Part 1, exercises 1.1–1.3: design guidelines per table, functional dependencies from business rules, attribute closures, minimal cover, normal forms, lossless join and dependency preservation |
| [`algebra.md`](algebra.md) | Part 2, exercises 2.1–2.2: 14 queries covering every operator, with algebra, RelaX screenshot, SQL and the result returned by the database |
| `almacen-y-formas-normales.md` | Exercise 1.4 (assigned project's data warehouse): by Emiliano |
| [`init/`](init/) | Runs by itself on the first start: `00` creates the flat table, `01` loads its 90 rows, `02` applies the migrations in order |
| [`migraciones/`](migraciones/) | Numbered schema migrations. `001` normalizes `horario_plano` by **moving its rows** into the new tables and checks that joining them gives back exactly the original rows |
| [`consultas/`](consultas/) | One `.sql` file per query (`00-…` to `13-…`); `correr.sh` runs them |
| [`relax/`](relax/) | `exportar-grupo.sql` (export script) and `grupo.txt` (the RelaX group, regenerated on every run) |
| [`integrantes/`](integrantes/) | Individual work, one signed file per member, with their own queries (also run by the container) |
| [`evidencias/`](evidencias/) | RelaX screenshots and the container's output |
| [`fuente/`](fuente/) | The script that extracted the sample from the Gestorix database (run once; not part of the container) |
| `compose.yaml`, `.env.example` | The `db` service (PostgreSQL 17 with a volume) and the `consultas` service (runs the queries) |

## Test on a clean machine

Another member cloned the repository into a new folder, ran the command and recorded the result:

| Who | Date | Commit | Result |
|---|---|---|---|
| *(to fill in)* | | | |

## Use of generative AI

Claude (Anthropic), through Claude Code, was used to draft and review the documents, queries, migration
and container setup. The team chose the approach, checked every dependency against the business rules,
ran everything and is responsible for what is delivered.
