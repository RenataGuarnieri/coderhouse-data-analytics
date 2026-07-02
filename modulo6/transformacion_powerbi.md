# Transformación de Datos en Power BI — Production Dataset

**Autor:** Renata Guarnieri  
**Fecha:** 17/06/2026  
**Archivo fuente:** Production_resultado_en_sql.xlsx

---

## Descripción del dataset original

El archivo contiene 1.141 filas y 14 columnas exportadas desde un sistema legacy de gestión de producción. Cada producto aparece repetido en múltiples filas, una por cada ubicación de almacenamiento donde se encuentra (entre 1 y 6 ubicaciones por producto), lo que totaliza 504 productos únicos distribuidos en 14 ubicaciones distintas.

Los datos mezclan atributos del producto (nombre, precio, costo, categoría) con atributos de su ubicación física (ID y nombre de depósito), lo que dificulta el análisis y viola el principio de normalización. La columna de fechas viene como texto en formato SQL (`YYYY-MM-DD HH:MM:SS.000`) en lugar de tipo Date, y varios campos críticos tienen nombres técnicos en inglés y mayúsculas no descriptivos.

---

## Transformaciones realizadas en Power Query

### 1. Renombrado de columnas

Se reemplazaron los nombres técnicos del sistema por nombres descriptivos en español usando snake_case, para que cualquier usuario pueda interpretar el modelo sin conocer la base de datos original:

| Nombre original      | Nombre nuevo          |
|----------------------|-----------------------|
| ProductID            | id_producto           |
| NAME                 | nombre_producto       |
| Color                | color                 |
| STOCK_RECOMENDADO    | stock_recomendado     |
| PUNTO_REPOSICION     | punto_reposicion      |
| COSTO                | costo                 |
| PRECIO               | precio                |
| DIAS_FABRICACION     | dias_fabricacion      |
| FECHA_INICIO_VENTA   | fecha_inicio_venta    |
| FECHA_FIN_VENTA      | fecha_fin_venta       |
| SUBCATEGORIA         | subcategoria          |
| CATEGORIA            | categoria             |
| ID_UBICACION         | id_ubicacion          |
| UBICACION            | nombre_ubicacion      |

---

### 2. Corrección de tipos de datos

- **fecha_inicio_venta** y **fecha_fin_venta**: venían como texto (`object`) con formato `YYYY-MM-DD HH:MM:SS.000`. Se convirtieron a tipo `Date` eliminando el componente horario. Sin este paso, Power BI no puede usar filtros temporales ni calcular diferencias entre fechas.
- **id_producto**: se dejó como `Whole Number` (entero), ya que es un identificador y no se realizan operaciones matemáticas sobre él.
- **id_ubicacion**: se convirtió de `float64` (número con decimal `.0`) a `Whole Number`, ya que es también un identificador entero.
- **costo** y **precio**: se dejaron como `Decimal Number` para habilitar cálculos financieros (márgenes, totales). Se registra que el 60% de los productos tiene costo y precio en 0.0, lo que indica que son materias primas o componentes internos sin precio de venta al público — este hallazgo se documenta como un problema de calidad de datos a revisar con el área.
- **stock_recomendado**, **punto_reposicion**, **dias_fabricacion**: se dejaron como `Whole Number` por ser cantidades enteras.

---

### 3. Gestión de valores nulos

| Columna          | Nulos | Decisión                              | Justificación |
|------------------|-------|---------------------------------------|---------------|
| color            | 688   | Reemplazar por `"Sin color"`          | Son productos que no tienen variante de color (ej. componentes metálicos). Eliminar las filas haría perder 60% del dataset. |
| fecha_fin_venta  | 975   | Reemplazar por `"Sin fecha fin"`      | El 85% de los productos no tiene fecha de fin de venta, lo que significa que siguen activos. NULL aquí es información válida, no un error. |
| subcategoria     | 609   | Reemplazar por `"Sin clasificar"`     | Productos sin categoría asignada en el sistema legacy. Eliminarlos sesgaría el análisis por categoría. |
| categoria        | 609   | Reemplazar por `"Sin clasificar"`     | Mismo criterio que subcategoria (están correlacionados: cuando una es NULL la otra también). |
| id_ubicacion     | 72    | Reemplazar por `0`                    | 72 filas sin ubicación asignada. Se asigna ID 0 como "Ubicación desconocida" para no perder los datos del producto. |
| nombre_ubicacion | 72    | Reemplazar por `"Desconocida"`        | Consistente con el criterio de id_ubicacion. |

**Nota sobre duplicados:** El dataset no contiene filas completamente duplicadas (verificado). Las repeticiones de productos son intencionales (un producto × múltiples ubicaciones) y se gestionan con la separación en dos tablas.

---

### 4. Separación en dos tablas

El dataset original mezcla datos del producto con datos de su ubicación física. Se separó en dos tablas independientes:

**Tabla: dim_productos** (504 filas únicas por producto)  
Columnas: `id_producto`, `nombre_producto`, `color`, `stock_recomendado`, `punto_reposicion`, `costo`, `precio`, `dias_fabricacion`, `fecha_inicio_venta`, `fecha_fin_venta`, `subcategoria`, `categoria`

**Criterio:** Se agrupó por `id_producto` tomando el primer valor de cada atributo del producto, ya que estos atributos son constantes independientemente de la ubicación.

**Tabla: dim_ubicaciones_producto** (1.141 filas, relación producto-ubicación)  
Columnas: `id_producto`, `id_ubicacion`, `nombre_ubicacion`

**Criterio de separación:** `id_ubicacion` y `nombre_ubicacion` describen dónde está físicamente el producto en el depósito, no qué es el producto. Son datos de logística, no de catálogo. Separarlos permite construir un modelo estrella en Power BI donde `dim_productos` actúa como tabla de dimensión y `dim_ubicaciones_producto` como tabla de ubicación, ambas relacionadas por `id_producto`.

---

## Modelo resultante en Power BI

```
dim_productos (id_producto PK)
      │
      └──── dim_ubicaciones_producto (id_producto FK)
```

Esta estructura permite analizar distribución de stock por ubicación manteniendo los atributos del producto centralizados, sin redundancia de datos.
