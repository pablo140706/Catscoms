-- 09 · Reunión theta ⨝θ
-- Pregunta: ¿quién da cada materia de 2CM1 en 27/1, y qué calidad tiene?
-- Álgebra:
--   π oferta.materia, profesor.nombre, profesor.mp_calidad (
--     σ grupo = '2CM1' ∧ periodo = '27/1' (oferta) ⨝ oferta.profesor = profesor.id profesor
--   )
SELECT o.materia, p.nombre, p.mp_calidad
FROM oferta o JOIN profesor p ON o.profesor = p.id
WHERE o.grupo = '2CM1' AND o.periodo = '27/1'
ORDER BY o.materia;
