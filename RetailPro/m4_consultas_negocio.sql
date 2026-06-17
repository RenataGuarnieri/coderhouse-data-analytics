-- ══════════════════════════════════════════
-- RetailPro — M4: Consultas SQL de Negocio
-- Base de datos: Ventas_Tech_DB (creada en M3)
-- Autor: Renata Guarnieri
-- Fecha: 17/06/2026
-- ══════════════════════════════════════════

-- NOTA SOBRE EL ESQUEMA: la tabla "clientes" creada en M3 tiene el campo "ciudad",
-- no "región". Como no existe una tabla de territorios/regiones en el esquema actual,
-- se usa "ciudad" como la dimensión geográfica para resolver las consultas 1 y 4.

-- ── Consulta 1: Resumen ejecutivo mensual ───────────────
-- Total de ventas, cantidad de pedidos y ticket promedio, agrupados por mes y ciudad (región)

SELECT
    EXTRACT(YEAR FROM v.fecha_venta)  AS anio,
    EXTRACT(MONTH FROM v.fecha_venta) AS mes,
    c.ciudad                          AS region,
    COUNT(v.id_venta)                 AS cantidad_pedidos,
    SUM(v.cantidad * v.precio_unitario) AS total_ventas,
    AVG(v.cantidad * v.precio_unitario) AS ticket_promedio
FROM ventas v
JOIN clientes c ON v.id_cliente = c.id_cliente
GROUP BY EXTRACT(YEAR FROM v.fecha_venta), EXTRACT(MONTH FROM v.fecha_venta), c.ciudad
ORDER BY anio, mes, region;

-- Nota de compatibilidad: EXTRACT(YEAR/MONTH FROM fecha) es estándar ANSI y funciona en
-- PostgreSQL nativamente. En versiones de SQL Server previas a 2022, reemplazar por:
-- DATEPART(YEAR, v.fecha_venta) y DATEPART(MONTH, v.fecha_venta).


-- ── Consulta 2: Ranking de productos (Top 5) ────────────
-- Top 5 productos por total de ventas: nombre, categoría, unidades vendidas y total generado

SELECT
    p.nombre_producto   AS producto,
    cat.nombre_categoria AS categoria,
    SUM(v.cantidad)      AS unidades_vendidas,
    SUM(v.cantidad * v.precio_unitario) AS total_generado
FROM ventas v
JOIN productos p   ON v.id_producto = p.id_producto
JOIN categorias cat ON p.id_categoria = cat.id_categoria
GROUP BY p.nombre_producto, cat.nombre_categoria
ORDER BY total_generado DESC
LIMIT 5;

-- Nota de compatibilidad: LIMIT 5 es sintaxis de PostgreSQL. En SQL Server, reemplazar
-- "SELECT" por "SELECT TOP 5" al inicio de la consulta y quitar el LIMIT del final.


-- ── Consulta 3: Clientes activos ────────────────────────
-- Clientes con más de una compra: nombre, cantidad de pedidos y total gastado

SELECT
    c.nombre AS cliente,
    COUNT(v.id_venta) AS cantidad_pedidos,
    SUM(v.cantidad * v.precio_unitario) AS total_gastado
FROM ventas v
JOIN clientes c ON v.id_cliente = c.id_cliente
GROUP BY c.nombre
HAVING COUNT(v.id_venta) > 1
ORDER BY total_gastado DESC;


-- ── Consulta 4: Performance regional ────────────────────
-- Total de ventas por región (ciudad) comparado contra el promedio general

WITH ventas_por_region AS (
    SELECT
        c.ciudad AS region,
        SUM(v.cantidad * v.precio_unitario) AS total_ventas
    FROM ventas v
    JOIN clientes c ON v.id_cliente = c.id_cliente
    GROUP BY c.ciudad
)
SELECT
    region,
    total_ventas,
    (SELECT AVG(total_ventas) FROM ventas_por_region) AS promedio_general,
    CASE
        WHEN total_ventas > (SELECT AVG(total_ventas) FROM ventas_por_region) THEN 'Por encima'
        ELSE 'Por debajo'
    END AS comparacion
FROM ventas_por_region
ORDER BY total_ventas DESC;


-- ══════════════════════════════════════════
-- Hallazgos
-- ══════════════════════════════════════════
-- 1. Buenos Aires y Tucumán concentran el 73% de los ingresos totales (USD 4.740 de
--    USD 6.444), mientras que Córdoba, Rosario y Mendoza generan apenas el 27% combinado,
--    a pesar de tener la misma cantidad de pedidos (2 cada una). Esto sugiere que el
--    ticket promedio, no el volumen de pedidos, es lo que está marcando la diferencia
--    entre regiones.
--
-- 2. La Laptop Pro 15 genera el mayor ingreso total (USD 3.600) con solo 3 unidades
--    vendidas, mientras que el Mouse Inalámbrico vende más unidades (13) pero genera
--    apenas USD 364, quedando último en el ranking. Esto confirma que el volumen de
--    unidades vendidas no es un buen proxy del impacto económico real de un producto.
--
-- 3. El 100% de los clientes registrados (5 de 5) realizó más de una compra, por lo
--    que todos califican como "clientes activos" según el criterio de la Consulta 3.
--    Es una base de clientes chica pero con buena tasa de recompra; conviene seguir
--    monitoreando esta métrica a medida que la base crezca.
