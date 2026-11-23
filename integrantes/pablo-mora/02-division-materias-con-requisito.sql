-- Pablo · 02 · División
-- Pregunta: ¿qué grupos ofrecen en 27/1 TODAS las materias que piden un requisito?
-- Álgebra:
--   π grupo, materia (σ periodo = '27/1' (oferta))
--   ÷
--   π materia (seriacion)
SELECT DISTINCT o.grupo
FROM oferta o
WHERE o.periodo = '27/1'
  AND NOT EXISTS (
        SELECT 1 FROM seriacion s
        WHERE NOT EXISTS (
                SELECT 1 FROM oferta x
                WHERE x.periodo = '27/1' AND x.grupo = o.grupo AND x.materia = s.materia))
ORDER BY o.grupo;
