defmodule Servidor do
    @moduledoc "Atiende consultas de reportes sísmicos y coordina la lectura concurrente de los archivos."

    @nombre_servicio :servicio_sismos
    @recursos Path.join(__DIR__, "resources")

    @doc "Registra el proceso como :servicio_sismos y comienza a recibir solicitudes."
    def main() do
        Process.register(self(), @nombre_servicio)

        Util.mostrar_mensaje(
        "Servidor iniciado en #{Node.self()}. Esperando solicitudes..."
        )

        procesar_mensajes()
    end
    
    defp procesar_mensajes() do
        receive do
        {destino_respuesta, solicitud} ->
            respuesta = procesar_solicitud(solicitud)
            send(destino_respuesta, respuesta)

            procesar_mensajes()
        end
    end

    defp procesar_solicitud(:fin), do: :fin

    defp procesar_solicitud(:reporte_general) do
        generar_respuesta(:reporte_general)
    end

    defp procesar_solicitud({:reporte_ciudad, id_ciudad}) do
        generar_respuesta({:reporte_ciudad, id_ciudad})
    end

    defp procesar_solicitud(_solicitud) do
        "Solicitud desconocida."
    end

    defp generar_respuesta(solicitud) do
        case leer_datos() do
        {:ok, ciudades, movimientos, rc, rm} ->
            construir_reporte(solicitud, ciudades, movimientos, rc, rm)

        {:error, mensaje} ->
            mensaje
        end
    end

    defp leer_datos() do
        referencia = make_ref()

        iniciar_trabajador(referencia, :ciudades, &Lector.leer_ciudades/1)
        iniciar_trabajador(referencia, :movimientos, &Lector.leer_movimientos/1)

        referencia
        |> esperar_resultados(%{})
        |> combinar_resultados()
    end

    defp iniciar_trabajador(referencia, tipo, funcion_lectura) do
        coordinador = self()
        ruta = Path.join(@recursos, nombre_archivo(tipo))

        spawn(fn ->
        resultado = funcion_lectura.(ruta)
        send(coordinador, {referencia, tipo, resultado})
        end)
    end

    defp esperar_resultados(_referencia, resultados)
        when map_size(resultados) == 2 do
        resultados
    end

    defp esperar_resultados(referencia, resultados) do
        receive do
        {^referencia, tipo, resultado} ->
            nuevos_resultados = Map.put(resultados, tipo, resultado)
            esperar_resultados(referencia, nuevos_resultados)
        end
    end

    defp combinar_resultados(%{
            ciudades: {:ok, ciudades, rc},
            movimientos: {:ok, movimientos, rm}
        }) do
        {:ok, ciudades, movimientos, rc, rm}
    end

    defp combinar_resultados(resultados) do
        errores =
        for {tipo, {:error, razon}} <- resultados do
            "No se pudo leer #{nombre_archivo(tipo)}: #{:file.format_error(razon)}"
        end

        {:error, Enum.join(errores, "\n")}
    end

    defp construir_reporte(:reporte_general, ciudades, movimientos, rc, rm) do
        Reporte.generar(ciudades, movimientos, rc, rm)
    end

    defp construir_reporte(
            {:reporte_ciudad, id_ciudad},
            ciudades,
            movimientos,
            _rc,
            _rm
        ) do
        case Enum.find(ciudades, fn ciudad -> ciudad.id == id_ciudad end) do
        nil ->
            "La ciudad no está registrada"

        ciudad ->
            Reporte.seccion_ciudad(ciudad, movimientos)
        end
    end

    defp nombre_archivo(:ciudades), do: "ciudades.txt"
    defp nombre_archivo(:movimientos), do: "movimientos.txt"
end