# Evidencia: registro desde la web y verificación en la base

Lo que pide la 1.ª parte del segundo parcial: capturar un registro desde un formulario de la app,
encontrarlo en el gestor con un `SELECT` y comprobar que los datos coinciden. En Gestorix hay dos
registros que se pueden enseñar: **crear una cuenta** (tabla `usuario`) y **guardar tu avance**
(tabla `avance`, con su vista `avance_status`).

> Las capturas van en [`screenshots/`](screenshots/) con los nombres de abajo.

---

## 1. Crear una cuenta

### En la app (<https://thwarting-earthling-evasive.ngrok-free.dev>, o `http://localhost:8080` en la PC)

1. **Entrar** (arriba a la derecha) → **Crear cuenta**.
2. Correo de prueba, por ejemplo `Prueba.Parcial2@example.com` (con mayúsculas a propósito),
   contraseña de 8 o más caracteres y carrera **ISC**.
3. **Crear cuenta**. La app dice que te mandó un correo.

📸 `screenshots/registro-1-formulario.png`: el formulario lleno, antes de enviar.

### En pgAdmin (`http://localhost:5051`)

```sql
SELECT id, correo, alias, carrera, rol, verificado, creado, left(hash, 7) AS hash
FROM usuario
WHERE correo = 'prueba.parcial2@example.com';
```

📸 `screenshots/registro-2-select.png`: la fila.

**Qué enseñar en la fila:**

| Columna | Qué se ve | Qué regla lo hace |
|---|---|---|
| `correo` | En minúsculas, aunque se escribió con mayúsculas | `CHECK (correo = lower(correo))` y `validarCorreo()` en PHP |
| `alias` | Uno al azar ("Puma Sereno 66"): no se pide nombre real | `aliasAlAzar()` + índice único sobre `lower(alias)` |
| `carrera` | `ISC` | Llave foránea a `carrera`: no acepta una carrera que no exista |
| `rol` | `alumno` | `DEFAULT 'alumno'` + `CHECK (rol IN (...))` |
| `verificado` | `false` | No se puede entrar hasta abrir el enlace del correo |
| `hash` | Empieza con `$2y$10$`: es bcrypt, **la contraseña no se guarda** | `password_hash()` de PHP |

### Activar la cuenta

Llega un correo de Gestorix (por Gmail; **puede caer en spam**) con el enlace de activación, que
apunta a la dirección pública. Ábrelo (te regresa a la app con "¡Tu cuenta está activa!"), vuelve a
correr el `SELECT` y `verificado` ya dice `true`.

Si el correo no llega, el enlace también queda en el log del servidor:

```bash
docker compose logs web | grep -o "https://[^ ]*/api/cuenta/verificar.php?t=[0-9a-f]*" | tail -1
```

Probado el 2026-11-20 con tres cuentas creadas desde celulares fuera de la red de la PC: llegó el
correo, se activaron y aparecieron en pgAdmin. El enlace sirve una sola vez: en la base solo se
guarda su sha256 (tabla `token`) y se borra al usarlo.

📸 `screenshots/registro-3-verificado.png`.

**Prueba de la regla "una cuenta por correo":** registrarse otra vez con el mismo correo no crea
otra fila (el `SELECT` sigue regresando una). La app contesta lo mismo exista o no el correo,
para que nadie pueda averiguar quién tiene cuenta.

---

## 2. Guardar avance (opcional, si sobra tiempo)

Con la sesión iniciada, en **Mi avance** captura una calificación: por ejemplo **Cálculo** aprobada
con **8** y **Fundamentos de programación** reprobada con **5**. Se guarda sola en la cuenta
(abajo dice "Guardado en tu cuenta").

```sql
SELECT s.materia, m.nombre, s.veces, s.calif, s.calif_ets, s.status, s.calif_final
FROM avance_status s
JOIN materia m ON m.clave = s.materia
JOIN usuario u ON u.id = s.usuario
WHERE u.correo = 'prueba.parcial2@example.com';
```

📸 `screenshots/registro-4-avance.png`.

El `status` (aprobada, reprobada…) **no se guarda**: lo calcula la vista a partir de `veces`,
`calif` y `calif_ets`. Una calificación de 11 se rechaza dos veces: primero en PHP
(`mis-datos.php` contesta "Las calificaciones son enteros de 0 a 10.") y, si llegara a la base,
en el `CHECK (calif BETWEEN 0 AND 10)`. Lo mismo con un ETS de una materia aprobada.

Resultado de la prueba (2026-11-19):

| materia | nombre | veces | calif | calif_ets | status | calif_final |
|---|---|---|---|---|---|---|
| C103 | Cálculo | 1 | 8 | | aprobada | 8 |
| C101 | Fundamentos de programación | 1 | 5 | | reprobada | |

La reprobada no tiene `calif_final` (es la calificación con que se aprobó). El promedio de la app, en cambio,
se saca como el del Kárdex de SAES: con la última calificación de cada materia, aprobada o reprobada.

---

## 3. Cómo viajan los datos del formulario a la base

```
Navegador                          Servidor (contenedor web)                   Base (contenedor db)
─────────                          ─────────────────────────                   ────────────────────
cuenta.js                          api/cuenta/registro.php
  fetch POST, cuerpo JSON  ──────▶   leerJson(): solo POST + JSON + mismo sitio
  { correo, contrasena,              validarCorreo(), validarContrasena()
    carrera }                        password_hash()
                                     lib/db.php: PDO con getenv('DB_*')  ──────▶  INSERT INTO usuario …
                                                                                  RETURNING id
  ◀──────  { ok, mensaje }  ◀──────  responder() en JSON
```

- **Las credenciales están del lado del servidor:** `lib/db.php` lee `DB_HOST`, `DB_USER` y
  `DB_PASSWORD` de variables de entorno que `docker-compose.yml` toma del archivo `.env`. El `.env`
  no va a git y el navegador nunca ve la contraseña de la base.
- **La app no entra como administrador:** usa `gestorix_app` (`sql/99-rol-app.sh`), que solo puede
  `SELECT`, `INSERT`, `UPDATE` y `DELETE`. No puede crear ni borrar tablas.
- **Consultas preparadas** (`$pdo->prepare(...)->execute([...])`): lo que escribe el usuario nunca
  se pega dentro del SQL, así que no hay inyección de SQL.
- **Protección CSRF:** `leerJson()` rechaza los POST que no son JSON o que vienen de otro sitio
  (cabecera `Origin`).
- **Límite de intentos:** 5 registros por hora por IP y 8 contraseñas fallidas por correo cada
  15 min (`lib/limite.php`); de ahí en adelante contesta 429 "Demasiados intentos".
- **Contra HTML o JavaScript inyectado:** el front escapa lo que escribe el usuario (`esc()`) y
  Apache manda una política CSP que solo deja correr JavaScript de los archivos del sitio
  (`apache/seguridad.conf`).
- **Por dónde entra la petición:** desde internet llega por el túnel de ngrok (HTTPS) a
  `localhost:8080` de la PC. Postgres no publica ningún puerto: solo la web habla con él.
- **Transacción:** guardar el avance (`api/mis-datos.php`) borra y vuelve a insertar todo el avance
  y el horario dentro de un `beginTransaction()` / `commit()`: si algo falla a la mitad, no queda
  nada a medias.

## 4. Al terminar

Para dejar la base limpia, en la app: **Tu cuenta → Borrar mi cuenta**. Las llaves foráneas con
`ON DELETE CASCADE` se llevan su avance, su horario y sus enlaces. Se puede comprobar con el mismo
`SELECT`: ya no regresa filas.
