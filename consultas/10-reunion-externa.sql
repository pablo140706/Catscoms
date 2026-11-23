-- 10 · Reunión externa izquierda ⟕
-- Pregunta: ¿qué requisito tiene cada materia de 2.º semestre, si tiene?
-- Álgebra:
--   π materia.clave, materia.nombre, seriacion.requisito (
--     σ semestre = 2 (materia) ⟕ materia.clave = seriacion.materia seriacion
--   )
SELECT m.clave, m.nombre, s.requisito
FROM materia m LEFT JOIN seriacion s ON m.clave = s.materia
WHERE m.semestre = 2
ORDER BY m.clave;
