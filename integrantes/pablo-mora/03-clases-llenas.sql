-- Pablo · 03 · Selección entre dos atributos + reunión natural + reunión theta
-- Pregunta: ¿qué clases de 27/1 están llenas (inscritos ≥ cupo) y quién las da?
-- Álgebra:
--   π oferta.grupo, oferta.materia, profesor.nombre, cupo.cupo, cupo.inscritos (
--     (σ inscritos >= cupo ∧ periodo = '27/1' (cupo) ⨝ oferta) ⨝ oferta.profesor = profesor.id profesor
--   )
SELECT o.grupo, o.materia, p.nombre, c.cupo, c.inscritos
FROM cupo c
NATURAL JOIN oferta o
JOIN profesor p ON o.profesor = p.id
WHERE c.inscritos >= c.cupo AND c.periodo = '27/1'
ORDER BY o.grupo, o.materia;
