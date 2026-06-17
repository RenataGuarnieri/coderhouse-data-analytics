-- ══════════════════════════════════════════
-- BodegaTech — Script de Inventario
-- Autor: Renata Guarnieri
-- Fecha: 17/06/2026
-- ══════════════════════════════════════════

-- ── SECCIÓN DDL ──────────────────────────

-- Eliminamos la tabla si ya existe para poder re-ejecutar el script sin errores
DROP TABLE IF EXISTS inventario;

CREATE TABLE inventario (
    id_producto INT PRIMARY KEY,         -- INT como clave primaria: es un identificador
                                          -- entero único y secuencial, ideal para PK.

    nombre_producto VARCHAR(100),
    categoria VARCHAR(50),

    precio_unitario DECIMAL(10, 2),      -- DECIMAL(10,2) y no FLOAT: para valores monetarios
                                          -- necesitamos precisión exacta en los decimales,
                                          -- FLOAT puede generar errores de redondeo.

    stock_actual INT,
    stock_minimo INT,

    fecha_ingreso DATE,                  -- DATE: solo necesitamos el día de ingreso al
                                          -- inventario, sin hora. Permite filtrar y agrupar
                                          -- por fecha fácilmente en reportes.

    activo SMALLINT                      -- SMALLINT (1 = disponible, 0 = descontinuado):
                                          -- se usó SMALLINT en lugar de TINYINT(1) (que es
                                          -- sintaxis específica de MySQL) para garantizar
                                          -- compatibilidad tanto con PostgreSQL como con
                                          -- SQL Server, cumpliendo la misma función de flag.
);

-- ── SECCIÓN DML ──────────────────────────

-- INSERT INTO: carga de los 10 productos iniciales
INSERT INTO inventario (id_producto, nombre_producto, categoria, precio_unitario, stock_actual, stock_minimo, fecha_ingreso, activo)
VALUES
(1,  'Laptop Pro 15',        'Computación',     1200.00, 15, 3,  '2024-01-10', 1),
(2,  'Mouse Inalámbrico',    'Accesorios',      28.00,   80, 10, '2024-01-10', 1),
(3,  'Monitor 4K 27"',       'Computación',     450.00,  12, 2,  '2024-01-15', 1),
(4,  'Teclado Mecánico',     'Accesorios',      95.00,   40, 5,  '2024-01-15', 1),
(5,  'Laptop Basic 14',      'Computación',     650.00,  20, 3,  '2024-02-01', 1),
(6,  'Auriculares BT Pro',   'Audio',           120.00,  35, 5,  '2024-02-01', 1),
(7,  'Hub USB-C 7 puertos',  'Accesorios',      45.00,   60, 10, '2024-02-10', 1),
(8,  'Webcam HD 1080p',      'Accesorios',      85.00,   25, 5,  '2024-02-10', 1),
(9,  'SSD Externo 1TB',      'Almacenamiento',  130.00,  18, 3,  '2024-03-01', 1),
(10, 'Parlante Bluetooth',   'Audio',           60.00,   45, 8,  '2024-03-01', 1);

-- UPDATE ventas del día: descontamos del stock_actual las unidades vendidas
UPDATE inventario SET stock_actual = stock_actual - 3  WHERE id_producto = 1;  -- Laptop Pro 15: 15 -> 12
UPDATE inventario SET stock_actual = stock_actual - 12 WHERE id_producto = 2;  -- Mouse Inalámbrico: 80 -> 68
UPDATE inventario SET stock_actual = stock_actual - 5  WHERE id_producto = 6;  -- Auriculares BT Pro: 35 -> 30

-- UPDATE producto descontinuado: la Webcam HD 1080p ya no se vende
UPDATE inventario SET activo = 0 WHERE id_producto = 8;

-- SELECT validaciones

-- Ver inventario completo ordenado por categoria
SELECT * FROM inventario
ORDER BY categoria, nombre_producto;

-- Ver productos con stock por debajo del mínimo
SELECT id_producto, nombre_producto, stock_actual, stock_minimo
FROM inventario
WHERE stock_actual <= stock_minimo AND activo = 1;

-- Ver valor total del inventario activo por categoria
SELECT
    categoria,
    COUNT(*) AS cantidad_productos,
    SUM(stock_actual * precio_unitario) AS valor_total_stock
FROM inventario
WHERE activo = 1
GROUP BY categoria
ORDER BY valor_total_stock DESC;
