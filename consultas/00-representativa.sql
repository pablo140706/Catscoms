-- 00 · Consulta representativa (selección, proyección y dos reuniones theta)
-- Pregunta: ¿qué profesores con calidad de 8 o más dan materias de 2.º semestre en 27/1, y en qué grupo?
-- Álgebra:
--   π profesor.nombre, materia.nombre, oferta.grupo (
--     σ mp_calidad >= 8 (profesor)
--     ⨝ profesor.id = oferta.profesor (
--       σ periodo = '27/1' (oferta) ⨝ oferta.materia = materia.clave σ semestre = 2 (materia)
--     )
--   )
SELECT p.nombre AS profesor, m.nombre AS materia, o.grupo
FROM profesor p
JOIN oferta o  ON p.id = o.profesor
JOIN materia m ON o.materia = m.clave
WHERE p.mp_calidad >= 8 AND o.periodo = '27/1' AND m.semestre = 2
ORDER BY 1;
