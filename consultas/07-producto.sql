-- 07 · Producto cartesiano ×
-- Pregunta: ¿de qué carrera es cada materia de 8.º semestre? (el producto solo sirve si se filtra después)
-- Álgebra:
--   materia ⨯ carrera                                   (todas las combinaciones: se cuentan)
--   π materia.clave, carrera.nombre (σ materia.carrera = carrera.codigo ∧ semestre = 8 (materia ⨯ carrera))
SELECT count(*) AS tuplas_del_producto FROM materia CROSS JOIN carrera;
SELECT m.clave, c.nombre
FROM materia m CROSS JOIN carrera c
WHERE m.carrera = c.codigo AND m.semestre = 8;
