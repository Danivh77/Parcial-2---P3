defmodule Coordinador do
  @moduledoc "Coordina la lectura concurrente de los archivos y la generación del reporte."

  @recursos Path.join(__DIR__, "resources")

  @doc "Genera el reporte, lo muestra en consola y lo guarda en resources/reporte_sismos.txt."
  def ejecutar do
    case obtener_reporte() do
      {:ok, reporte} ->
        Util.mostrar_mensaje(reporte)
        guardar(reporte)

      {:error, mensaje} ->
        Util.mostrar_error(mensaje)
        Util.mostrar_error("Se conserva el reporte anterior.")
    end
  end

  @doc "Lee ambos archivos en procesos separados. Retorna {:ok, reporte} o {:error, mensaje}."
  def obtener_reporte do
    referencia = make_ref()
    iniciar_trabajador(referencia, :ciudades, &Lector.leer_ciudades/1)
    iniciar_trabajador(referencia, :movimientos, &Lector.leer_movimientos/1)

    referencia
    |> esperar_resultados(%{})
    |> combinar()
  end

  defp iniciar_trabajador(referencia, tipo, leer) do
    coordinador = self()
    ruta = Path.join(@recursos, nombre_archivo(tipo))
    spawn(fn -> send(coordinador, {referencia, tipo, leer.(ruta)}) end)
  end

  defp esperar_resultados(_referencia, resultados) when map_size(resultados) == 2, do: resultados

  defp esperar_resultados(referencia, resultados) do
    receive do
      {^referencia, tipo, resultado} ->
        esperar_resultados(referencia, Map.put(resultados, tipo, resultado))
    end
  end

  defp combinar(%{ciudades: {:ok, ciudades, rc}, movimientos: {:ok, movimientos, rm}}) do
    {:ok, Reporte.generar(ciudades, movimientos, rc, rm)}
  end

  defp combinar(resultados) do
    errores =
      for {tipo, {:error, razon}} <- resultados do
        "No se pudo leer #{nombre_archivo(tipo)}: #{:file.format_error(razon)}"
      end

    {:error, Enum.join(errores, "\n")}
  end

  defp guardar(reporte) do
    ruta = Path.join(@recursos, "reporte_sismos.txt")

    case File.write(ruta, reporte <> "\n") do
      :ok ->
        Util.mostrar_mensaje("\nReporte guardado en resources/reporte_sismos.txt")

      {:error, razon} ->
        Util.mostrar_error("No se pudo guardar el reporte: #{:file.format_error(razon)}")
    end
  end

  defp nombre_archivo(:ciudades), do: "ciudades.txt"
  defp nombre_archivo(:movimientos), do: "movimientos.txt"
end
