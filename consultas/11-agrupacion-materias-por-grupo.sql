-- 11 · Agrupación γ con count
-- Pregunta: ¿cuántas ofertas tiene cada grupo en cada periodo?
-- Álgebra:
--   γ periodo, grupo; count(*)→ofertas (oferta)
SELECT periodo, grupo, count(*) AS ofertas
FROM oferta
GROUP BY periodo, grupo
ORDER BY periodo, grupo;
