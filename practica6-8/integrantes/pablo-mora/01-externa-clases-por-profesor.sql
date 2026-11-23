-- Pablo · 01 · Reunión externa + agrupación
-- Pregunta: ¿cuántas clases da cada profesor en 27/1, contando también a los que ya no dan ninguna?
-- Álgebra:
--   γ profesor.nombre; count(oferta.id)→clases_27_1 (
--     profesor ⟕ profesor.id = oferta.profesor σ periodo = '27/1' (oferta)
--   )
SELECT p.nombre, count(o.id) AS clases_27_1
FROM profesor p
LEFT JOIN (SELECT * FROM oferta WHERE periodo = '27/1') o ON p.id = o.profesor
GROUP BY p.nombre
ORDER BY clases_27_1 DESC, p.nombre;
