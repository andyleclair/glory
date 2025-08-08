defmodule Glory.Camera do
  use TypedStruct
  alias Graphmath.Vec3
  alias Glory.Math

  typedstruct do
    field(:position, Vec3.t(), default: Vec3.create(0.0, 0.0, 3.0))
    field(:front, Vec3.t(), default: Vec3.create(0.0, 0.0, -1.0))
    field(:up, Vec3.t(), default: Vec3.create(0.0, 1.0, 0.0))
  end

  def view(%__MODULE__{position: position, front: front, up: up}) do
    Math.look_at(position, Vec3.add(position, front), up)
  end

  @speed 0.05
  def handle_input(%__MODULE__{position: position, front: front, up: up} = camera, keys) do
    new_position =
      Enum.reduce(keys, position, fn key, position ->
        case key do
          ?W ->
            magnitude = Vec3.scale(front, @speed)
            Vec3.add(position, magnitude)

          ?A ->
            magnitude = Vec3.cross(front, up) |> Vec3.normalize() |> Vec3.scale(@speed)
            Vec3.subtract(position, magnitude)

          ?D ->
            magnitude = Vec3.cross(front, up) |> Vec3.normalize() |> Vec3.scale(@speed)
            Vec3.add(position, magnitude)

          ?S ->
            magnitude = Vec3.scale(front, @speed)
            Vec3.subtract(position, magnitude)
        end
      end)

    %__MODULE__{camera | position: new_position}
  end

  def new() do
    struct(__MODULE__)
  end
end
