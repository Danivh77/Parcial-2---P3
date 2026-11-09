Code.require_file("util.ex", __DIR__)

defmodule NodoCliente do
  @moduledoc "Nodo cliente que envía consultas al servidor y muestra las respuestas."

  @nombre_servicio :servicio_respuesta
  @nodo_servidor :"nodoservidor@localhost"
  @servicio_remoto {:servicio_sismos, @nodo_servidor}

  @solicitudes [
    {:reporte_ciudad, "C01"},
    {:reporte_ciudad, "C03"},
    {:reporte_ciudad, "C99"},
    :reporte_general,
    :fin
  ]

  @doc "Registra :servicio_respuesta, se conecta al servidor y realiza las consultas."
  def main() do
    Process.register(self(), @nombre_servicio)

    Util.mostrar_mensaje("Cliente iniciado en #{Node.self()}.")

    @nodo_servidor
    |> Node.connect()
    |> iniciar_consultas()
  end

  defp iniciar_consultas(true) do
    enviar_solicitudes()
    recibir_respuestas()
  end

  defp iniciar_consultas(_resultado) do
    Util.mostrar_error("No se pudo conectar con el nodo servidor.")
  end

  defp enviar_solicitudes() do
    Enum.each(@solicitudes, &enviar_solicitud/1)
  end

  defp enviar_solicitud(solicitud) do
    destino_respuesta = {@nombre_servicio, Node.self()}

    send(@servicio_remoto, {destino_respuesta, solicitud})
  end

    defp recibir_respuestas() do
    receive do
      :fin ->
        Util.mostrar_mensaje("\nSe recibieron todas las respuestas.")
        :ok

      respuesta ->
        Util.mostrar_mensaje("\n========================================")
        Util.mostrar_mensaje(respuesta)

        recibir_respuestas()
    after
      10_000 ->
        Util.mostrar_error("El servidor no respondió a tiempo.")
    end
  end
end

NodoCliente.main()
