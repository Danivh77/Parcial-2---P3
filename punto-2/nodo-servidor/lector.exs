defmodule Lector do
  @moduledoc "Lee los archivos de entrada y convierte cada línea válida en un struct."

  @doc "Lee el archivo de ciudades. Retorna {:ok, ciudades, rechazados} o {:error, razon}."
  def leer_ciudades(ruta), do: leer(ruta, &parsear_ciudad/1)

  @doc "Lee el archivo de movimientos. Retorna {:ok, movimientos, rechazados} o {:error, razon}."
  def leer_movimientos(ruta), do: leer(ruta, &parsear_movimiento/1)

  @doc "Convierte una línea en una ciudad. Retorna {:ok, %Ciudad{}} o :error."
  def parsear_ciudad(linea) do
    with [id, nombre, habitantes] <- campos(linea),
         true <- sin_vacios?([id, nombre, habitantes]),
         {:ok, habitantes} <- entero_positivo(habitantes) do
      {:ok, %Ciudad{id: id, nombre: nombre, habitantes: habitantes}}
    else
      _ -> :error
    end
  end

  @doc "Convierte una línea en un movimiento. Retorna {:ok, %Movimiento{}} o :error."
  def parsear_movimiento(linea) do
    with [codigo, id_ciudad, inicio, final, magnitud, profundidad] <- campos(linea),
         true <- sin_vacios?([codigo, id_ciudad, inicio, final, magnitud, profundidad]),
         {:ok, inicio} <- Time.from_iso8601(inicio),
         {:ok, final} <- Time.from_iso8601(final),
         {:ok, magnitud} <- decimal(magnitud),
         {:ok, profundidad} <- decimal_no_negativo(profundidad) do
      {:ok,
       %Movimiento{
         codigo: codigo,
         id_ciudad: id_ciudad,
         hora_inicio: inicio,
         hora_final: final,
         magnitud: magnitud,
         profundidad: profundidad
       }}
    else
      _ -> :error
    end
  end

  defp leer(ruta, parsear) do
    case File.read(ruta) do
      {:ok, contenido} -> procesar(contenido, parsear)
      {:error, razon} -> {:error, razon}
    end
  end

  defp procesar(contenido, parsear) do
    {validos, rechazados} =
      contenido
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.reduce({[], 0}, fn linea, {validos, rechazados} ->
        case parsear.(linea) do
          {:ok, registro} -> {[registro | validos], rechazados}
          :error -> {validos, rechazados + 1}
        end
      end)

    {:ok, Enum.reverse(validos), rechazados}
  end

  defp campos(linea), do: linea |> String.split("@") |> Enum.map(&String.trim/1)

  defp sin_vacios?(campos), do: Enum.all?(campos, &(&1 != ""))

  defp entero_positivo(texto) do
    case Integer.parse(texto) do
      {numero, ""} when numero > 0 -> {:ok, numero}
      _ -> :error
    end
  end

  defp decimal(texto) do
    case Float.parse(texto) do
      {numero, ""} -> {:ok, numero}
      _ -> :error
    end
  end

  defp decimal_no_negativo(texto) do
    case decimal(texto) do
      {:ok, numero} when numero >= 0 -> {:ok, numero}
      _ -> :error
    end
  end
end
