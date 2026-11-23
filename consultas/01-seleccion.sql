-- 01 · Selección σ
-- Pregunta: ¿qué materias son de 1.er semestre?
-- Álgebra:
--   σ semestre = 1 (materia)
SELECT * FROM materia WHERE semestre = 1 ORDER BY clave;
