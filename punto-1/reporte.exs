defmodule Reporte do
  @moduledoc "Calcula las estadísticas por ciudad y construye el texto del reporte."

  @doc "Genera el texto completo del reporte a partir de los datos leídos."
  def generar(ciudades, movimientos, rechazados_ciudades, rechazados_movimientos) do
    {validos, sin_ciudad} = separar_por_ciudad(ciudades, movimientos)
    secciones = Enum.map(ciudades, fn ciudad -> seccion_ciudad(ciudad, validos) end)
    rechazos = seccion_rechazos(rechazados_ciudades, rechazados_movimientos + length(sin_ciudad))

    Enum.join([encabezado()] ++ secciones ++ [rechazos], "\n\n")
  end

  @doc "Construye el texto de una ciudad con sus movimientos y estadísticas."
  def seccion_ciudad(ciudad, movimientos) do
    propios = Enum.filter(movimientos, fn m -> m.id_ciudad == ciudad.id end)
    estadisticas = estadisticas(propios)

    (["Ciudad: #{ciudad.nombre}", "Habitantes: #{ciudad.habitantes}"] ++
       lineas_movimientos(propios) ++
       [
         "Total de movimientos: #{estadisticas.cantidad}",
         "Movimiento de mayor magnitud: #{texto_mayor(estadisticas.mayor)}",
         "Profundidad promedio: #{texto_promedio(estadisticas.promedio)}"
       ])
    |> Enum.join("\n")
  end

  @doc "Calcula en un solo recorrido la cantidad, el de mayor magnitud y el promedio de profundidad."
  def estadisticas(movimientos) do
    {cantidad, mayor, suma} = recorrer(movimientos, 0, nil, 0.0)
    promedio = if cantidad > 0, do: suma / cantidad, else: nil
    %{cantidad: cantidad, mayor: mayor, promedio: promedio}
  end

  defp recorrer([], cantidad, mayor, suma), do: {cantidad, mayor, suma}

  defp recorrer([movimiento | resto], cantidad, mayor, suma) do
    recorrer(resto, cantidad + 1, mas_fuerte(mayor, movimiento), suma + movimiento.profundidad)
  end

  defp mas_fuerte(nil, movimiento), do: movimiento

  defp mas_fuerte(%Movimiento{magnitud: actual}, %Movimiento{magnitud: nueva} = movimiento)
       when nueva > actual,
       do: movimiento

  defp mas_fuerte(mayor, _movimiento), do: mayor

  defp separar_por_ciudad(ciudades, movimientos) do
    ids = MapSet.new(ciudades, fn ciudad -> ciudad.id end)
    Enum.split_with(movimientos, fn m -> MapSet.member?(ids, m.id_ciudad) end)
  end

  defp encabezado do
    "REPORTE DE MOVIMIENTOS SÍSMICOS POR CIUDAD"
  end

  defp lineas_movimientos([]), do: ["Movimientos: Sin movimientos registrados"]

  defp lineas_movimientos(movimientos) do
    ["Movimientos:" | Enum.map(movimientos, &linea_movimiento/1)]
  end

  defp linea_movimiento(m) do
    "  - #{m.codigo} | Inicio: #{Time.to_string(m.hora_inicio)} | Fin: #{Time.to_string(m.hora_final)}" <>
      " | Magnitud: #{Float.to_string(m.magnitud)} | Profundidad: #{Float.to_string(m.profundidad)} km"
  end

  defp texto_mayor(nil), do: "No aplica"
  defp texto_mayor(m), do: "#{m.codigo} · #{Float.to_string(m.magnitud)}"

  defp texto_promedio(nil), do: "No aplica"
  defp texto_promedio(promedio), do: "#{Util.formatear(promedio, 2)} km"

  defp seccion_rechazos(rechazados_ciudades, rechazados_movimientos) do
    "Registros rechazados\n" <>
      "  ciudades.txt: #{rechazados_ciudades}\n" <>
      "  movimientos.txt: #{rechazados_movimientos}"
  end
end
