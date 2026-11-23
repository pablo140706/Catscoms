# Catscoms

Equipo del curso de Bases de Datos · ESCOM-IPN · Ingeniería en Sistemas Computacionales, plan 2020

| Integrante | Usuario de GitHub |
|---|---|
| Estrada Sánchez Emiliano | `Ayddoous10` |
| Mora Acosta Pablo | `pablo140706` |
| Espinosa Gómez David Enrique | `daenesgo` |

## Segundo parcial: enlaces y archivos

### 1. Proyecto propio: Gestorix

El *Gestor académico ESCOM* de las prácticas anteriores ahora se llama **Gestorix** y vive en su propio repositorio.

| Entregable | Dónde |
|---|---|
| Aplicación web | **<https://thwarting-earthling-evasive.ngrok-free.dev>**. La PC del autor es el servidor: la base vive en su Docker y ngrok la saca a internet. Funciona mientras esa PC esté prendida |
| Repositorio e instrucciones para ejecutarla | [`pablo140706/Gestorix`](https://github.com/pablo140706/Gestorix) (sección *Cómo levantarlo*) |
| Esquema (creación) | [`sql/00-tablas.sql`](https://github.com/pablo140706/Gestorix/blob/main/sql/00-tablas.sql) |
| Modelo relacional actualizado, claves, restricciones y acciones referenciales | [`proyecto-propio/practica-integrada/diagrama-er.md`](proyecto-propio/practica-integrada/diagrama-er.md) |
| Scripts de carga y migración | [`sql/`](https://github.com/pablo140706/Gestorix/tree/main/sql) (carga inicial), [`importador/`](https://github.com/pablo140706/Gestorix/tree/main/importador) (HTML de SAES → base) y [`migraciones/`](https://github.com/pablo140706/Gestorix/tree/main/migraciones) (cambios con la base en uso) |
| Evidencia del registro | [`proyecto-propio/evidencia-registro.md`](proyecto-propio/evidencia-registro.md): formulario → `SELECT` en pgAdmin, con capturas en [`proyecto-propio/screenshots/`](proyecto-propio/screenshots/) |
| Seguridad (registro, permisos y pestaña de administración) | Tabla en el [README de Gestorix](https://github.com/pablo140706/Gestorix#publicación-la-pc-como-servidor) |
| Práctica integrada 6–8: normalización | [`proyecto-propio/practica-integrada/normalizacion.md`](proyecto-propio/practica-integrada/normalizacion.md) |
| Práctica integrada 6–8: álgebra relacional y SQL | [`proyecto-propio/practica-integrada/algebra.md`](proyecto-propio/practica-integrada/algebra.md): 13 ejercicios (selección, proyección, conjuntos, producto, reuniones, agrupación y división) comparados en RelaX |
| Grupo de RelaX | [`proyecto-propio/practica-integrada/relax/gestorix.txt`](proyecto-propio/practica-integrada/relax/gestorix.txt) (se pega en el *Editor de Grupo* de [RelaX](https://dbis-uibk.github.io/relax/calc/local/uibk/local/0)) y los scripts que lo generan |
| Guion de la exposición (6 min) | [`proyecto-propio/guion-expo.md`](proyecto-propio/guion-expo.md) |
