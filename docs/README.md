# ESCOM Academic Manager — Catscoms

A web system that gathers into a single relational database everything an ESCOM
student needs in order to plan a re-enrollment: the curriculum, the groups
opened each term, the personal schedule, community teacher reviews and the
official IPN calendar.

**Academic program / curriculum:** Computer Systems Engineering / 2020 ·
**Course:** Databases · **School:** ESCOM, IPN · **Team:** Catscoms

## Addresses

| What | Address |
|---|---|
| **Site (GitHub Pages)** | **https://pablo140706.github.io/Catscoms/** |
| Mirror — Netlify | `TODO: paste the URL from Exercise 5` |
| Mirror — Vercel | `TODO: paste the URL from Exercise 5` |
| Mirror — Cloudflare Pages | `TODO: paste the URL from Exercise 5` |
| Team repository | https://github.com/pablo140706/Catscoms |
| Fork of the assigned project | https://github.com/pablo140706/Seismic-Data-Visualization-System |

The three deployments publish the exact same static site from this repository,
so any of them shows the same content; the GitHub Pages address is the canonical
one. A side-by-side comparison of the three hosting services is in
[`comparacion.md`](comparacion.md).

## The problem

Students at ESCOM — in all three programs: Computer Systems Engineering (ISC),
Artificial Intelligence Engineering (IIA) and the Data Science degree (LCD) —
plan every re-enrollment by hand, cross-checking information that lives in
unrelated places: the *kardex* to know which courses they failed, their student
status to know how many course units they are allowed to take, the SAES schedule
module to see which groups are opened, and external websites to decide which
teacher to retake a course with. None of those sources talks to the others, and
none of them shows the whole picture.

This project centralizes that information in one relational database: the course
catalog per program, the groups opened each term with their teacher and seat
count, each student's personal schedule, teacher reviews written by the students
who actually took the group, the official IPN calendar and a personal agenda.
The data model behind it is the EER model of Practice 2 and the relational
diagram of Practice 3, both published on the site.

## Team

| Member | What they did |
|---|---|
| **Mora Acosta Pablo** | Repository and Docker Compose environment of Practice 1; fork and bring-up of the assigned project, with the error log in `levantamiento.md`; improvement proposals [#2](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/2), [#3](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/3) and [#4](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/4). Practice 3: `TODO` |
| **Estrada Sánchez Emiliano** | Extended requirements and EER model of our own project; improvement proposals [#1](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/1), [#5](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/5) and [#6](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/6). Practice 3: `TODO` |
| **Espinosa Gómez David Enrique** | Summaries of the three reference articles and the class presentation; improvement proposals [#7](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/7), [#8](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/8) and [#9](https://github.com/pablo140706/Seismic-Data-Visualization-System/issues/9). Practice 3: `TODO` |

> Replace each `TODO` with the Practice 3 work actually done by that member
> (site, `investigacion.md`, `identificacion.md`, `comparacion.md`, the
> deployments). Everything else in this table comes from the repository history
> and from the issues opened on the fork.

## How to see the site

Online, with nothing to install: open any of the addresses above. To see what a
visitor sees, open it in a private window, so your GitHub session and your
browser cache stay out of the way.

To run it on your own machine, clone the repository and serve the site folder
over HTTP:

```bash
git clone https://github.com/pablo140706/Catscoms.git
```

With Node.js:

```bash
npx serve docs
```

Or with Python, if you would rather not install anything:

```bash
python -m http.server 8000 --directory docs
```

Then open `http://localhost:8000/`, or the port that `serve` prints. The site is
plain HTML, CSS and JavaScript — no framework, no build step and no database
connection — so opening `docs/index.html` straight from the file system works
too. Every path inside the site is relative, because a GitHub Pages site hangs
off the repository name (`/Catscoms/`) and not off the domain root: a path that
starts with a slash works on your machine and breaks online.

## Index

### Practice 3 — Publishing, documentation and hosting

| File | What it holds |
|---|---|
| [`docs/`](docs/) | Source of the published site: project name, team, the problem, the EER and relational diagrams, and the links to the repository and the fork |
| [`investigacion.md`](investigacion.md) | Research: frontend, backend, APIs, hosting, domains, DNS and HTTPS, with references in APA 7th edition |
| [`identificacion.md`](identificacion.md) | Frontend and backend of the assigned project, pointed out file by file, with the exact place where it connects to the database |
| [`comparacion.md`](comparacion.md) | The three hosting services compared: steps, time taken, address granted, HTTPS, auto-deploy on commit and declared limits |

### Practice 2 — Own project and assigned project

| File | What it holds |
|---|---|
| [`proyecto-propio/ejercicio4-modelo-eer.md`](proyecto-propio/ejercicio4-modelo-eer.md) | EER model: cardinalities, weak entities, specialization hierarchy, aggregation and the justification of each decision |
| [`proyecto-propio/eer-chen.png`](proyecto-propio/eer-chen.png) · [`proyecto-propio/eer-crows-feet.png`](proyecto-propio/eer-crows-feet.png) | The same model in Peter Chen and Crow's Foot notation, generated with Graphviz |
| [`proyecto-propio/requisitos-ampliados.pdf`](proyecto-propio/requisitos-ampliados.pdf) | Extended requirements of the ESCOM Academic Manager |
| [`proyecto-asignado/levantamiento.md`](proyecto-asignado/levantamiento.md) | Bring-up of the assigned project: steps, errors found and how each one was solved |
| [`proyecto-asignado/err-sismos.jpeg`](proyecto-asignado/err-sismos.jpeg) · [`proyecto-asignado/correspondencia-con-el-esquema.pdf`](proyecto-asignado/correspondencia-con-el-esquema.pdf) | Reverse-engineered model of the assigned project and how it maps to its actual schema |
| [`propuestas/propuestas-de-mejora.pdf`](propuestas/propuestas-de-mejora.pdf) | The nine improvement proposals, each one filed as an issue on the fork |
| [`articulos/resumenes.pdf`](articulos/resumenes.pdf) | Summaries of the three reference articles |
| [`exposicion/presentacion.pdf`](exposicion/presentacion.pdf) | Slides presented in class |

### Practice 1 — Environment

| File | What it holds |
|---|---|
| [`compose.yaml`](compose.yaml) | PostgreSQL 16 container used for the first practice |

## Project status

### What exists today

- The **static site**, published on GitHub Pages and on two more hosting
  services. Hand-written HTML, CSS and JavaScript: no framework, no build step,
  no requests at runtime.
- The **data model**, complete: extended requirements, EER model in two
  notations, and the relational diagram derived from it.
- The **written documentation** of the three practices, in Markdown, inside this
  repository.
- A **PostgreSQL container** defined in `compose.yaml`, used locally only.

### What is missing

1. **The backend. There is none yet** — and it is the piece everything else
   waits on. The published site is static: it cannot open a connection to a
   database, because the code that renders it runs in the visitor's browser,
   where a database password would be readable by anyone. What is needed is a
   server-side application (PHP or Node.js) that keeps the credentials, runs the
   queries and answers over HTTP.
2. **A deployed database.** The relational schema exists as a diagram, not yet
   as `CREATE TABLE` statements running on a server reachable from the internet.
   GitHub Pages, Netlify and Vercel publish static files only, so this needs a
   different kind of hosting: a virtual private server, a managed Postgres
   service, or shared hosting with PHP and MySQL.
3. **An API.** Once the backend exists, the site has to stop carrying its data
   inside the page and start asking for it: endpoints for the course catalog, the
   groups of a term, the personal schedule and the teacher reviews.
4. **Authentication.** The system is multi-user by design — each student sees
   their own schedule and writes reviews under their own name — and none of that
   works without accounts and sessions, which only the backend can handle.
5. **A known bug in the assigned project**, documented and left unfixed: in
   `datos_sismicos.php` the database host is hard-coded as `localhost` instead of
   the `db` service name, so inside the container it can never connect. See
   [`proyecto-asignado/levantamiento.md`](proyecto-asignado/levantamiento.md).

## Statement on the use of generative AI

Claude (Anthropic) was used as an assistant to locate and read the reference
articles, to draft the summaries, and to support the writing of the EER model,
the documentation of the assigned project and this README. The content was
reviewed, corrected and approved by the team, and each member is responsible for
their own improvement proposals.
