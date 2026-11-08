ruta_punto_1 = Path.expand("../../punto-1", __DIR__)

Code.require_file("util.ex", ruta_punto_1)
Code.require_file("structs.exs", ruta_punto_1)
Code.require_file("lector.exs", ruta_punto_1)
Code.require_file("reporte.exs", ruta_punto_1)

Code.require_file("servidor.exs", __DIR__)

Servidor.main()