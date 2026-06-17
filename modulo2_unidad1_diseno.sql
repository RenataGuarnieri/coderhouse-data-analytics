-- =========================================================
-- Módulo 2 - Unidad 1: Diseño de Esquema y Tipos de Datos
-- Ejercicio: Creación de tablas Clientes y Productos
-- =========================================================

-- ---------------------------------------------------------
-- TABLA: clientes
-- ---------------------------------------------------------
CREATE TABLE clientes (
    id_cliente INT,            -- INT: identificador entero único. No se realizan operaciones
                                -- matemáticas con él, pero al ser secuencial y numérico,
                                -- INT es el estándar para una clave/ID.

    nombre VARCHAR(100),       -- VARCHAR(100): texto de longitud variable. 100 caracteres
                                -- es más que suficiente para un nombre completo y evita
                                -- desperdiciar espacio reservando memoria de más.

    perfil_bio TEXT,           -- TEXT: se usa para bloques de texto largos y de longitud
                                -- impredecible, como una biografía o notas. A diferencia de
                                -- VARCHAR(n), no requiere definir un límite máximo fijo.

    fecha_registro DATE        -- DATE: solo necesitamos el día en que se registró el cliente
                                -- (Año-Mes-Día), sin hora exacta. Guardarlo como DATE (y no
                                -- como texto) permite luego hacer reportes por mes/año en
                                -- Power BI o SQL sin problemas.
);

-- ---------------------------------------------------------
-- TABLA: productos
-- ---------------------------------------------------------
CREATE TABLE productos (
    id_producto INT,           -- INT: identificador entero único del producto.

    descripcion VARCHAR(255),  -- VARCHAR(255): es el tamaño estándar para descripciones
                                -- cortas de producto. Suficiente para un nombre/detalle
                                -- breve sin ocupar espacio innecesario.

    precio DECIMAL(10, 2),     -- DECIMAL(10,2): nunca se usa FLOAT para dinero porque puede
                                -- generar errores de redondeo. DECIMAL(10,2) permite hasta
                                -- 10 dígitos en total, 2 de ellos decimales (ej: 99999999.99),
                                -- que cubre cualquier precio de un producto de tecnología.

    esta_activo INT             -- INT (0 = inactivo, 1 = activo): se usa un número pequeño
                                -- en lugar de texto ("si"/"no") porque es más eficiente de
                                -- almacenar y de filtrar (WHERE esta_activo = 1). 
                                -- Nota: en PostgreSQL también se podría usar el tipo
                                -- BOOLEAN, pero se eligió INT para mantener compatibilidad
                                -- tanto con PostgreSQL como con SQL Server.
);
