-- ══════════════════════════════════════════
-- RetailPro — M5: Consultas con JOINs
-- Base de datos: Ventas_Tech_DB (creada en M3)
-- Autor: Renata Guarnieri
-- Fecha: 17/06/2026
-- ══════════════════════════════════════════

-- NOTA SOBRE EL ESQUEMA: la consigna de M5 menciona columnas y tablas que no
-- existen en el esquema creado en M3 (territorios, segmento, región, canal).
-- Las consultas se adaptan al esquema real disponible:
--   - "región" se reemplaza por "ciudad" (campo disponible en clientes)
--   - "segmento" no existe en el esquema; se omite con la aclaración correspondiente
--   - "canal" no existe en ventas; se agrega a continuación con ALTER TABLE
--   - "territorios" no existe como tabla; no se incluye en el JOIN

-- Agregamos la columna "canal" a la tabla ventas para soportar la Consulta 4.
-- En un entorno de producción, esto se haría una sola vez y formaría parte del DDL.
ALTER TABLE ventas ADD COLUMN canal VARCHAR(20) DEFAULT 'Online';

-- Asignamos canal 'Presencial' a algunas ventas para que la Consulta 4 sea significativa
UPDATE ventas SET canal = 'Presencial' WHERE id_venta IN (2, 5, 7, 9);
UPDATE ventas SET canal = 'Online'     WHERE id_venta IN (1, 3, 4, 6, 8, 10);


-- ── Consulta 1: Vista base del proyecto (INNER JOIN) ────
-- Combina ventas, clientes, productos y categorias en una sola fila.
-- Esta consulta es la fuente de datos principal para el dashboard en Power BI.
-- Incluye: fecha, nombre del cliente, ciudad (reemplaza a región, que no existe en el
-- esquema), nombre del producto, categoría, cantidad, precio unitario, total y canal.

SELECT
    v.fecha_venta                           AS fecha,
    c.nombre                                AS nombre_cliente,
    c.ciudad                                AS region,          -- no hay tabla territorios en M3;
                                                                 -- ciudad es la dimensión geográfica
                                                                 -- disponible
    p.nombre_producto                       AS producto,
    cat.nombre_categoria                    AS categoria,
    v.cantidad,
    v.precio_unitario,
    (v.cantidad * v.precio_unitario)        AS total_venta,
    v.canal
FROM ventas v
INNER JOIN clientes   c   ON v.id_cliente  = c.id_cliente
INNER JOIN productos  p   ON v.id_producto = p.id_producto
INNER JOIN categorias cat ON p.id_categoria = cat.id_categoria
ORDER BY v.fecha_venta DESC;


-- ── Consulta 2: Clientes sin ventas (LEFT JOIN) ─────────
-- Identifica clientes registrados que aún no realizaron ninguna compra.
-- El WHERE filtra solo las filas donde no hubo coincidencia en ventas (NULL).

SELECT
    c.nombre           AS nombre_cliente,
    c.email,
    c.fecha_registro
FROM clientes c
LEFT JOIN ventas v ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL
ORDER BY c.fecha_registro;

-- Nota: con los datos actuales de M3, todos los clientes tienen al menos una venta,
-- por lo que esta consulta devolverá 0 filas. La lógica es correcta y se verificaría
-- con datos reales donde existan clientes sin historial de compras.


-- ── Consulta 3: Productos sin ventas (LEFT JOIN) ────────
-- Identifica productos del catálogo que no tienen ninguna venta registrada.
-- El WHERE filtra solo los productos sin coincidencia en ventas (NULL).

SELECT
    p.nombre_producto  AS producto,
    cat.nombre_categoria AS categoria,
    p.precio
FROM productos p
LEFT JOIN ventas       v   ON p.id_producto  = v.id_producto
LEFT JOIN categorias   cat ON p.id_categoria = cat.id_categoria
WHERE v.id_venta IS NULL
ORDER BY cat.nombre_categoria, p.nombre_producto;

-- Nota: con los datos actuales de M3, todos los productos tienen al menos una venta,
-- por lo que esta consulta también devolverá 0 filas. La lógica es correcta para
-- un catálogo real donde existan productos sin movimiento.


-- ── Consulta 4: Consolidado por canal (UNION ALL) ───────
-- Combina en un único resultado las ventas Online y Presencial,
-- y al final calcula el total vendido por canal con GROUP BY.

-- Paso 1: vista combinada con UNION ALL (conserva todas las filas de ambos canales)
SELECT
    v.id_venta,
    c.nombre      AS nombre_cliente,
    p.nombre_producto,
    v.cantidad,
    v.precio_unitario,
    (v.cantidad * v.precio_unitario) AS total_venta,
    v.canal
FROM ventas v
INNER JOIN clientes  c ON v.id_cliente  = c.id_cliente
INNER JOIN productos p ON v.id_producto = p.id_producto
WHERE v.canal = 'Online'

UNION ALL

SELECT
    v.id_venta,
    c.nombre,
    p.nombre_producto,
    v.cantidad,
    v.precio_unitario,
    (v.cantidad * v.precio_unitario),
    v.canal
FROM ventas v
INNER JOIN clientes  c ON v.id_cliente  = c.id_cliente
INNER JOIN productos p ON v.id_producto = p.id_producto
WHERE v.canal = 'Presencial'

ORDER BY canal, id_venta;

-- Paso 2: total por canal con GROUP BY
SELECT
    canal,
    COUNT(id_venta)                          AS cantidad_ventas,
    SUM(cantidad * precio_unitario)          AS total_recaudado,
    AVG(cantidad * precio_unitario)          AS ticket_promedio
FROM ventas
GROUP BY canal
ORDER BY total_recaudado DESC;
