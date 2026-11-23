-- 06 · Diferencia −
-- Pregunta: ¿qué profesores dieron clase en 26/2 y ya no en 27/1?
-- Álgebra:
--   π nombre (
--     ρ id←profesor (
--       π profesor (σ periodo = '26/2' (oferta)) - π profesor (σ periodo = '27/1' (oferta))
--     ) ⨝ profesor
--   )
SELECT p.nombre
FROM profesor p
JOIN (SELECT profesor FROM oferta WHERE periodo = '26/2'
      EXCEPT
      SELECT profesor FROM oferta WHERE periodo = '27/1') x
  ON x.profesor = p.id
ORDER BY 1;
