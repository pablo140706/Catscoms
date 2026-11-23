-- 12 · Agrupación γ con avg sobre una reunión (resumen por grupo)
-- Pregunta: ¿qué calidad promedio tienen los profesores de cada grupo en 27/1?
-- Álgebra:
--   γ grupo; avg(mp_calidad)→calidad_promedio, count(mp_calidad)→con_dato (
--     σ periodo = '27/1' (oferta) ⨝ oferta.profesor = profesor.id profesor
--   )
SELECT o.grupo, round(avg(p.mp_calidad), 2) AS calidad_promedio, count(p.mp_calidad) AS con_dato
FROM oferta o JOIN profesor p ON o.profesor = p.id
WHERE o.periodo = '27/1'
GROUP BY o.grupo
ORDER BY o.grupo;
