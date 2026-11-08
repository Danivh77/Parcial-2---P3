defmodule Ciudad do
  @moduledoc "Representa una ciudad del catálogo."
  @enforce_keys [:id, :nombre, :habitantes]
  defstruct [:id, :nombre, :habitantes]
end

defmodule Movimiento do
  @moduledoc "Representa un movimiento sísmico registrado."
  @enforce_keys [:codigo, :id_ciudad, :hora_inicio, :hora_final, :magnitud, :profundidad]
  defstruct [:codigo, :id_ciudad, :hora_inicio, :hora_final, :magnitud, :profundidad]
end
