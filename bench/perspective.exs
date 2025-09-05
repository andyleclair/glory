aspect = 1200.0 / 800.0

Benchee.run(
  %{
    "elixir" => fn ->
      Glory.Math.perspective(45.0, aspect, 0.1, 100.0)
    end
  },
  time: 10,
  memory_time: 2
)
