-- 05 · Intersección ∩
-- Pregunta: ¿qué profesores dieron clase en los dos periodos?
-- Álgebra:
--   π nombre (
--     ρ id←profesor (
--       π profesor (σ periodo = '26/2' (oferta)) ∩ π profesor (σ periodo = '27/1' (oferta))
--     ) ⨝ profesor
--   )
SELECT p.nombre
FROM profesor p
JOIN (SELECT profesor FROM oferta WHERE periodo = '26/2'
      INTERSECT
      SELECT profesor FROM oferta WHERE periodo = '27/1') x
  ON x.profesor = p.id
ORDER BY 1;
