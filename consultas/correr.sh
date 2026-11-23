#!/bin/bash
# =====================================================================
#  Corre cada consulta de la Parte 2 y regenera el grupo de RelaX
# =====================================================================
#  Lo ejecuta el servicio "consultas" del compose.yaml, cuando la base ya
#  está lista (esquema normalizado y datos migrados). Para cada archivo
#  consultas/NN-*.sql, y luego integrantes/<nombre>/NN-*.sql, en orden:
#    1. imprime su encabezado: la pregunta y la expresión en álgebra;
#    2. ejecuta su SQL y muestra el resultado.
#  Al final escribe relax/grupo.txt desde la base. Todo lo que imprime se
#  guarda también en evidencias/salida-del-contenedor.txt.
#  No pide nada: usuario y contraseña de prueba vienen de .env.example.
# =====================================================================
# pipefail: si una consulta falla, el script termina con error aunque la
# salida pase por tee.
set -eo pipefail
SALIDA=/evidencias/salida-del-contenedor.txt

{
  echo "Gestorix · práctica 6, 7 y 8 · $(date -u '+%Y-%m-%d %H:%M UTC')"
  echo
  echo "Tablas después de la migración (filas):"
  psql -X -v ON_ERROR_STOP=1 -At -F ' : ' -c "
    SELECT 'carrera', count(*) FROM carrera UNION ALL SELECT 'periodo', count(*) FROM periodo
    UNION ALL SELECT 'materia', count(*) FROM materia UNION ALL SELECT 'seriacion', count(*) FROM seriacion
    UNION ALL SELECT 'profesor', count(*) FROM profesor UNION ALL SELECT 'bloque', count(*) FROM bloque
    UNION ALL SELECT 'oferta', count(*) FROM oferta UNION ALL SELECT 'sesion', count(*) FROM sesion
    UNION ALL SELECT 'cupo', count(*) FROM cupo
    UNION ALL SELECT 'antes.horario_plano (la tabla original)', count(*) FROM antes.horario_plano"

  for f in /consultas/[0-9][0-9]-*.sql; do
    echo
    echo "======================================================================"
    # El encabezado: las líneas "-- " del principio, sin el "-- ".
    sed -n '/^--/!q; s/^-- \{0,1\}//p' "$f"
    echo "----------------------------------------------------------------------"
    psql -X -v ON_ERROR_STOP=1 -P null=null -P footer=on -q -f "$f"
  done

  # Las consultas propias de cada integrante (integrantes/<nombre>/NN-*.sql).
  for f in /integrantes/*/[0-9][0-9]-*.sql; do
    [ -e "$f" ] || continue
    echo
    echo "======================================================================"
    sed -n '/^--/!q; s/^-- \{0,1\}//p' "$f"
    echo "----------------------------------------------------------------------"
    psql -X -v ON_ERROR_STOP=1 -P null=null -P footer=on -q -f "$f"
  done

  echo
  echo "======================================================================"
  echo "Regenerando relax/grupo.txt desde la base…"
  psql -X -v ON_ERROR_STOP=1 -At -q -f /relax/exportar-grupo.sql > /relax/grupo.txt
  echo "Listo: relax/grupo.txt ($(grep -c '= {' /relax/grupo.txt) relaciones, $(wc -l < /relax/grupo.txt) líneas)."
  echo "Todo terminó sin errores."
} 2>&1 | tee "$SALIDA"
