# Guion de la expo: proyecto propio (6 minutos)

Lo que pide el PDF del 2.º parcial, en orden. Practícalo con cronómetro: cada minuto extra resta un
punto.

## Antes de empezar (10 minutos antes)

- [ ] PC o laptop conectada al cargador, sin suspenderse.
- [ ] Docker Desktop prendido y `docker compose up -d`.
- [ ] La ventana de ngrok abierta: `ngrok http --url=thwarting-earthling-evasive.ngrok-free.dev 8080`.
- [ ] El link abre desde tu celular con datos móviles.
- [ ] pgAdmin abierto (`localhost:5051`) con la **Query Tool** sobre `gestorix` y las consultas de
      abajo pegadas.
- [ ] RelaX abierto con el grupo de `docs/relax/gestorix.txt` cargado.
- [ ] El video de respaldo a la mano por si falla la red.
- [ ] Respaldo de la base sacado ([respaldo.md](https://github.com/pablo140706/Gestorix/blob/main/docs/respaldo.md)).

## 0:00 – 1:30 · Registro desde la web y SELECT

1. "Gestorix es un gestor académico para alumnos de ESCOM: avance, horario, maestros y comentarios."
2. Pásale el link al profe (o regístrate tú desde el celular): **Entrar → Crear cuenta**.
3. "Le llega un correo de activación (puede caer en spam)." Ábrelo y activa.
4. Sale la **bienvenida**: elige "nuevo ingreso" y un grupo, o "importar de SAES".
5. En pgAdmin:

```sql
SELECT id, correo, alias, carrera, verificado, ingreso, creado
FROM usuario WHERE correo = 'correo-del-profe';
```

6. "El correo está en minúsculas, el alias es al azar, la contraseña no se guarda: solo su hash."

## 1:30 – 2:30 · Cómo viajan los datos (backend)

- "El formulario manda JSON por `fetch` a `api/cuenta/registro.php`. PHP valida, hace
  `password_hash` e inserta con **consultas preparadas**, entrando a Postgres con un **usuario de
  mínimo privilegio**. Las credenciales están en `.env`, del lado del servidor."
- "La PC es el servidor: Docker corre la base y ngrok saca solo la web a internet. Postgres no
  publica ningún puerto."
- **Seguridad**, con la tabla del README: inyección SQL, XSS (CSP y `esc()`), límite de intentos
  (5 fallidos y 15 minutos de espera, 429), CSRF, contraseñas con bcrypt, groserías bloqueadas.
- **Entrada falsa desde la consola** (lo que pidió el profe; con una cuenta de alumno, F12 →
  Consola). "Esconder un botón no protege nada: cada petición se revisa en el servidor."

```js
fetch('api/admin/usuarios.php').then(r => r.json())
// {error: "Solo el administrador."}  → no se ven los usuarios ni sus correos
fetch('api/moderacion/accion.php', { method: 'POST', headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ accion: 'banear', usuario: 1, motivo: 'hackeo' }) }).then(r => r.json())
// {error: "Solo moderadores y administradores."}
```

- **Pestaña Admin** (con tu cuenta): tablero, reportes, bitácora y usuarios. Ver correos pide tu
  contraseña otra vez y queda en la bitácora; cada moderador solo ve su carrera.

## 2:30 – 4:00 · Esquema e integridad

- Muestra `docs/diagrama-er.md`: tablas `usuario`, `avance`, `token`.
- Claves y restricciones: `CHECK (calif BETWEEN 0 AND 10)`, una sola cuenta por correo, alias único
  sin importar mayúsculas, "solo hay ETS si reprobaste".
- Acciones referenciales: al borrar una cuenta, `CASCADE` en avance, horario y comentarios.
- **Migraciones**: `migraciones/` (resultado sin calificación, periodo reprobado). "Con usuarios
  reales ya no se vuelve a sembrar: cada cambio es un archivo."
- Si da tiempo, demuestra un CHECK en pgAdmin:

```sql
INSERT INTO avance (usuario, materia, calif) VALUES (11, 'C101', 11);
-- ERROR: viola la restricción avance_calif_check (la calificación es de 0 a 10)
```

## 4:00 – 6:00 · Práctica integrada 6–8

1. **Normalización** (`docs/normalizacion.md`): el caso del cupo separado de la oferta.
   Dependencias funcionales, claves candidatas, 3FN y FNBC.
2. **Álgebra relacional** (`docs/algebra.md`): una consulta en RelaX y su SQL en pgAdmin, y que los
   resultados coinciden.
3. "En el repo quedan los 13 ejercicios: selección, proyección, conjuntos, producto, reuniones,
   agrupación y división."

## Si falla la red

Pon el video de respaldo y sigue explicando sobre él. Tus docs y pgAdmin funcionan sin internet.
