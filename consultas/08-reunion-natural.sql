-- 08 · Reunión natural ⨝
-- Pregunta: ¿qué cupo le toca a cada asesor de Trabajo Terminal II?
-- Álgebra:
--   π grupo, materia, profesor, cupo, inscritos (σ materia = 'B801' (oferta ⨝ cupo))
SELECT grupo, materia, profesor, cupo, inscritos
FROM oferta NATURAL JOIN cupo
WHERE materia = 'B801'
ORDER BY grupo, profesor;
