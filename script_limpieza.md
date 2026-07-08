# Script de limpieza — TechStore (ventas_raw)

Código completo del Editor Avanzado, escrito manualmente sin usar los botones de la interfaz.

```powerquery
let
    // Paso 1: Fuente de datos original (tabla cargada manualmente vía "Especificar datos")
    // No modificar este paso: lo genera Power BI automáticamente con Table.FromRows(...)
    Origen = Table.FromRows(...),

    // Paso 2: Eliminar espacios en blanco al inicio y al final de nombre_producto
    // usando Text.Trim, para que " Laptop Pro 15 " quede como "Laptop Pro 15"
    LimpiarEspacios = Table.TransformColumns(Origen, {{"nombre_producto", Text.Trim, type text}}),

    // Paso 3: Estandarizar la columna categoria a Title Case con Text.Proper,
    // para unificar "computación", "COMPUTACIÓN" y "Computación" en un único formato
    EstandarizarCategoria = Table.TransformColumns(LimpiarEspacios, {{"categoria", Text.Proper, type text}}),

    // Paso 4: Filtrar y eliminar registros de prueba
    // Se filtra DESPUÉS de estandarizar, porque una vez aplicado Text.Proper
    // cualquier variante ("PRUEBA", "prueba") ya quedó normalizada como "Prueba",
    // así que la comparación exacta con Table.SelectRows es confiable
    EliminarPruebas = Table.SelectRows(EstandarizarCategoria, each [categoria] <> "Prueba"),

    // Paso 5: Definir los tipos de datos correctos para cada columna
    // id_venta numérico entero, nombre_producto y categoria texto,
    // precio numérico decimal, fecha_venta como fecha.
    // Se especifica locale "en-US" para que el punto de "precio" se interprete
    // como separador decimal y no como separador de miles (configuración regional
    // en español de Power BI Desktop convertía 1200.00 en 120000 sin este ajuste)
    TiparColumnas = Table.TransformColumnTypes(EliminarPruebas, {
        {"id_venta", Int64.Type},
        {"nombre_producto", type text},
        {"categoria", type text},
        {"precio", type number},
        {"fecha_venta", type date}
    }, "en-US")
in
    TiparColumnas
```

## Resultado esperado

- La tabla final tiene **5 filas** (se eliminan los registros 3 y 6, de categoría "PRUEBA").
- `nombre_producto` sin espacios al inicio ni al final.
- `categoria` estandarizada en Title Case (ej. "Computación", "Accesorios", "Audio").
- Tipos de datos correctos: `id_venta` entero, `precio` numérico (1200, 28, 450, 120, 85), `fecha_venta` fecha, el resto texto.

## Nota sobre configuración regional

Al aplicar `Table.TransformColumnTypes` sin especificar el locale, Power BI Desktop (configurado en español) interpretó el punto decimal de la columna `precio` como separador de miles, convirtiendo `1200.00` en `120000`. Se corrigió agregando `"en-US"` como tercer parámetro de la función, forzando la interpretación correcta del punto como separador decimal.
