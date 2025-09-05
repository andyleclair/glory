defmodule Glory.Cube do
  @vertices [
              [-0.5, -0.5, -0.5, 0.0, 0.0],
              [0.5, -0.5, -0.5, 1.0, 0.0],
              [0.5, 0.5, -0.5, 1.0, 1.0],
              [0.5, 0.5, -0.5, 1.0, 1.0],
              [-0.5, 0.5, -0.5, 0.0, 1.0],
              [-0.5, -0.5, -0.5, 0.0, 0.0],
              [-0.5, -0.5, 0.5, 0.0, 0.0],
              [0.5, -0.5, 0.5, 1.0, 0.0],
              [0.5, 0.5, 0.5, 1.0, 1.0],
              [0.5, 0.5, 0.5, 1.0, 1.0],
              [-0.5, 0.5, 0.5, 0.0, 1.0],
              [-0.5, -0.5, 0.5, 0.0, 0.0],
              [-0.5, 0.5, 0.5, 1.0, 0.0],
              [-0.5, 0.5, -0.5, 1.0, 1.0],
              [-0.5, -0.5, -0.5, 0.0, 1.0],
              [-0.5, -0.5, -0.5, 0.0, 1.0],
              [-0.5, -0.5, 0.5, 0.0, 0.0],
              [-0.5, 0.5, 0.5, 1.0, 0.0],
              [0.5, 0.5, 0.5, 1.0, 0.0],
              [0.5, 0.5, -0.5, 1.0, 1.0],
              [0.5, -0.5, -0.5, 0.0, 1.0],
              [0.5, -0.5, -0.5, 0.0, 1.0],
              [0.5, -0.5, 0.5, 0.0, 0.0],
              [0.5, 0.5, 0.5, 1.0, 0.0],
              [-0.5, -0.5, -0.5, 0.0, 1.0],
              [0.5, -0.5, -0.5, 1.0, 1.0],
              [0.5, -0.5, 0.5, 1.0, 0.0],
              [0.5, -0.5, 0.5, 1.0, 0.0],
              [-0.5, -0.5, 0.5, 0.0, 0.0],
              [-0.5, -0.5, -0.5, 0.0, 1.0],
              [-0.5, 0.5, -0.5, 0.0, 1.0],
              [0.5, 0.5, -0.5, 1.0, 1.0],
              [0.5, 0.5, 0.5, 1.0, 0.0],
              [0.5, 0.5, 0.5, 1.0, 0.0],
              [-0.5, 0.5, 0.5, 0.0, 0.0],
              [-0.5, 0.5, -0.5, 0.0, 1.0]
            ]
            |> List.flatten()
            |> Enum.reduce(<<>>, fn el, acc -> <<acc::binary, el::float-native-size(32)>> end)

  def vertices do
    @vertices
  end

  def positions do
    [
      {0.0, 0.0, 0.0},
      {2.0, 5.0, -15.0},
      {-1.5, -2.2, -2.5},
      {-3.8, -2.0, -12.3},
      {2.4, -0.4, -3.5},
      {-1.7, 3.0, -7.5},
      {1.3, -2.0, -2.5},
      {1.5, 2.0, -2.5},
      {1.5, 0.2, -1.5},
      {-1.3, 1.0, -1.5}
    ]
  end

  def bind() do
    [vertex_array] = :gl.genVertexArrays(1)
    [vertex_buffer] = :gl.genBuffers(1)

    :gl.bindVertexArray(vertex_array)

    :gl.bindBuffer(:gl_const.gl_array_buffer(), vertex_buffer)

    :gl.bufferData(
      :gl_const.gl_array_buffer(),
      byte_size(vertices()),
      vertices(),
      :gl_const.gl_static_draw()
    )

    :gl.vertexAttribPointer(
      0,
      3,
      :gl_const.gl_float(),
      :gl_const.gl_false(),
      5 * byte_size(<<0.0::float-native-size(32)>>),
      0
    )

    :gl.enableVertexAttribArray(0)

    :gl.vertexAttribPointer(
      1,
      2,
      :gl_const.gl_float(),
      :gl_const.gl_false(),
      5 * byte_size(<<0.0::float-native-size(32)>>),
      3 * byte_size(<<0.0::float-native-size(32)>>)
    )

    :gl.enableVertexAttribArray(1)

    vertex_array
  end
end
