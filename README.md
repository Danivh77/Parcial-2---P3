# Parcial 2 – Elixir: Observatorio Sismológico

Aplicación en Elixir que genera reportes de movimientos sísmicos por ciudad, primero de forma local (punto 1) y luego consultándolos desde otro nodo (punto 2).

**Integrantes:** Laura Daniela Vega Herrera, Elizabeth Cuéllar Vélez

## Punto 1 – Reporte local

Desde la carpeta `punto-1/`:

```
elixir main.exs
```

- **Archivos de entrada:** `punto-1/resources/ciudades.txt` y `punto-1/resources/movimientos.txt`.
- **Reporte generado:** `punto-1/resources/reporte_sismos.txt`. Se reemplaza en cada ejecución exitosa. Si un archivo de entrada no se puede leer, se indica cuál y se conserva el reporte anterior.

## Punto 2 – Consulta entre nodos

Se necesitan dos terminales. Primero se inicia el servidor y después el cliente.

**Cookie:** ambos nodos usan la misma cookie, `sismos_cookie`, que se configura con la opción `--cookie` en cada comando. Si no coinciden, los nodos no se conectan.

**Ejecución nodo-servidor:**

- cd punto-2/nodo-servidor
- elixir --sname nodoservidor@localhost --cookie sismos_cookie nodo_servidor.exs

**Ejecución nodo-cliente:**

- cd punto-2/nodo-cliente
- elixir --sname nodocliente@localhost --cookie sismos_cookie nodo_cliente.exs