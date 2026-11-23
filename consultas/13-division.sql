-- 13 · División ÷ (una pregunta con «todas»)
-- Pregunta: ¿qué grupos ofrecen en 27/1 TODAS las materias de 1.er semestre?
-- Álgebra:
--   π grupo, materia (σ periodo = '27/1' (oferta))
--   ÷
--   ρ materia←clave (π clave (σ semestre = 1 (materia)))
-- SQL no tiene división: "no existe una materia de 1.º que el grupo no ofrezca" (doble NOT EXISTS).
SELECT DISTINCT o.grupo
FROM oferta o
WHERE o.periodo = '27/1'
  AND NOT EXISTS (
        SELECT 1 FROM materia m
        WHERE m.semestre = 1
          AND NOT EXISTS (
                SELECT 1 FROM oferta x
                WHERE x.periodo = '27/1' AND x.grupo = o.grupo AND x.materia = m.clave))
ORDER BY o.grupo;
