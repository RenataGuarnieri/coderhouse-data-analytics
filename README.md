# Lenguaje M en el Editor Avanzado — TechStore

## 1. ¿Qué hace exactamente el bloque `let...in`? ¿Por qué cada paso puede referenciar al anterior?

El bloque `let` define una lista de pasos nombrados, donde cada uno es una expresión M que se evalúa una sola vez. El bloque `in` indica cuál de esas variables es el resultado final que la consulta devuelve hacia Power BI. Cada paso puede referenciar a cualquier paso definido antes que él porque M no ejecuta el código línea por línea como un script tradicional: arma internamente un grafo de dependencias, evalúa cada variable solo cuando es necesaria, y resuelve el orden según qué pasos usa cada expresión. En la práctica, esto significa que `LimpiarEspacios` puede usar `Origen` porque `Origen` ya existe como variable en el mismo bloque, pero no podría usar `TiparColumnas`, que se define después: la cadena de dependencias solo mira "hacia atrás".

## 2. ¿Por qué M es Case Sensitive y qué consecuencia práctica tiene? Ejemplo.

M distingue mayúsculas de minúsculas tanto en nombres de funciones como en comparaciones de texto dentro del código. Esto tiene dos consecuencias prácticas distintas:

- **En funciones:** `Table.SelectRows` funciona, pero `table.selectrows` no existe para M y tira error de inmediato, deteniendo toda la consulta.
- **En comparaciones de datos:** si yo hubiera escrito el filtro `[categoria] <> "Prueba"` **antes** de estandarizar la columna con `Text.Proper`, cualquier fila con "PRUEBA" en mayúsculas o "prueba" en minúsculas no habría sido detectada como igual a `"Prueba"`, porque para M son tres strings distintos. El resultado habría sido una tabla con registros de prueba que deberían haberse eliminado y no se eliminaron — un error silencioso, sin mensaje de fallo, mucho más peligroso que un error de sintaxis porque pasa desapercibido.

## 3. ¿Cuál es la diferencia entre `Text.Trim` y `Text.Clean`?

`Text.Trim` elimina únicamente los espacios en blanco que están al principio y al final de un texto, dejando intacto todo lo que hay en el medio (por ejemplo, `" Laptop Pro 15 "` → `"Laptop Pro 15"`). `Text.Clean`, en cambio, elimina caracteres no imprimibles o de control que pueden estar en cualquier parte del string — saltos de línea, tabulaciones, o caracteres invisibles que a veces vienen de exportaciones de sistemas legacy — pero no toca los espacios normales. En este ejercicio usé `Text.Trim` porque el problema descrito es específicamente espacios sobrantes al inicio y al final; si el dataset tuviera, por ejemplo, un salto de línea pegado en medio del nombre de un producto por un error de exportación, ahí sí correspondería usar `Text.Clean` (o ambas combinadas).

## 4. ¿Por qué filtré los registros "PRUEBA" después de estandarizar la categoría y no antes?

Porque el filtro compara el valor de `categoria` con el string exacto `"Prueba"`, y esa comparación es case-sensitive. Si filtrara antes de aplicar `Text.Proper`, solo se eliminarían las filas donde el valor original coincidiera carácter por carácter con `"Prueba"` — cualquier variante como `"PRUEBA"` en mayúsculas quedaría en la tabla final, porque para M no es el mismo valor. Al estandarizar primero con `Text.Proper`, garantizo que todas las variantes de mayúsculas/minúsculas queden normalizadas a un único formato, y recién ahí la comparación exacta del filtro es confiable y cubre todos los casos reales.
