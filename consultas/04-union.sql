-- 04 · Unión ∪
-- Pregunta: ¿quién dio clase en 1CM1 en 26/2 o en 27/1?
-- Álgebra:
--   π nombre (
--     ρ id←profesor (
--       π profesor (σ grupo = '1CM1' ∧ periodo = '26/2' (oferta))
--       ∪
--       π profesor (σ grupo = '1CM1' ∧ periodo = '27/1' (oferta))
--     ) ⨝ profesor
--   )
SELECT p.nombre
FROM profesor p
JOIN (SELECT profesor FROM oferta WHERE grupo = '1CM1' AND periodo = '26/2'
      UNION
      SELECT profesor FROM oferta WHERE grupo = '1CM1' AND periodo = '27/1') x
  ON x.profesor = p.id
ORDER BY 1;
