-- 03 · Selección y proyección compuestas
-- Pregunta: ¿qué profesores tienen calidad de 9 o más en MisProfesores?
-- Álgebra:
--   π nombre, mp_calidad (σ mp_calidad >= 9 (profesor))
SELECT nombre, mp_calidad FROM profesor WHERE mp_calidad >= 9 ORDER BY nombre;
