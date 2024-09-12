defmodule GlTest.Window do
  import WxRecords

  @behaviour :wx_object

  def start_link(_) do
    :wx_object.start_link(__MODULE__, [], [])
    {:ok, self()}
  end

  @impl :wx_object
  def init(_) do
    opts = [size: {800, 600}]
    wx = :wx.new()
    frame = :wxFrame.new(wx, :wx_const.wx_id_any(), ~c"Hello", opts)

    :wxWindow.connect(frame, :close_window)
    :wxFrame.show(frame)

    gl_attrib = [
      attribList: [
        :wx_const.wx_gl_core_profile(),
        :wx_const.wx_gl_major_version(),
        3,
        :wx_const.wx_gl_minor_version(),
        3,
        :wx_const.wx_gl_doublebuffer(),
        0
      ]
    ]

    canvas = :wxGLCanvas.new(frame, opts ++ gl_attrib)
    ctx = :wxGLContext.new(canvas)
    :wxGLCanvas.setCurrent(canvas, ctx)
    max_attribs = :gl.getIntegerv(:gl_const.gl_max_vertex_attribs()) |> inspect()

    IO.puts("OpenGL max vertex attribs: " <> max_attribs)
    {shader_program, vao1, vao2, rect_vao} = init_opengl()
    frame_counter = :counters.new(1, [:atomics])

    send(self(), :update)
    now = System.monotonic_time(:millisecond)

    {frame,
     %{
       last_time: now,
       frame: frame,
       frame_counter: frame_counter,
       canvas: canvas,
       shader_program: shader_program,
       fps: 0,
       vao1: vao1,
       vao2: vao2,
       rect_vao: rect_vao
     }}
  end

  @vertex_path Path.join([__DIR__, "shaders", "vertex.glsl"])
  @external_resource @vertex_path
  @vertex_source @vertex_path
                 |> File.read!()
                 |> String.to_charlist()

  @fragment_path Path.join([__DIR__, "shaders", "fragment.glsl"])
  @external_resource @fragment_path
  @fragment_source @fragment_path
                   |> File.read!()
                   |> String.to_charlist()

  def init_opengl() do
    vertex_shader = :gl.createShader(:gl_const.gl_vertex_shader())
    :gl.shaderSource(vertex_shader, [@vertex_source])
    :gl.compileShader(vertex_shader)

    fragment_shader = :gl.createShader(:gl_const.gl_fragment_shader())
    :gl.shaderSource(fragment_shader, [@fragment_source])
    :gl.compileShader(fragment_shader)

    shader_program = :gl.createProgram()
    :gl.attachShader(shader_program, vertex_shader)
    :gl.attachShader(shader_program, fragment_shader)
    :gl.linkProgram(shader_program)

    :gl.deleteShader(vertex_shader)
    :gl.deleteShader(fragment_shader)

    vertices = triangle_vertices()
    vertices_2 = triangle_vertices_2()

    [vao1, vao2, rect_vao] = :gl.genVertexArrays(3)
    [vbo1, vbo2, rect_vbo, ebo] = :gl.genBuffers(4)

    for {vertex_array, vertex_buffer, vertices} <- [
          {vao1, vbo1, vertices},
          {vao2, vbo2, vertices_2}
        ] do
      :gl.bindVertexArray(vertex_array)

      :gl.bindBuffer(:gl_const.gl_array_buffer(), vertex_buffer)

      :gl.bufferData(
        :gl_const.gl_array_buffer(),
        byte_size(vertices),
        vertices,
        :gl_const.gl_static_draw()
      )

      :gl.vertexAttribPointer(
        0,
        3,
        :gl_const.gl_float(),
        :gl_const.gl_false(),
        3 * byte_size(<<0.0::float-size(32)>>),
        0
      )

      :gl.enableVertexAttribArray(0)

      :gl.bindBuffer(:gl_const.gl_array_buffer(), 0)

      :gl.bindVertexArray(0)
    end

    rect_vertices = rectangle_vertices()
    rect_indices = rectangle_indices()

    :gl.bindVertexArray(rect_vao)
    :gl.bindBuffer(:gl_const.gl_array_buffer(), rect_vbo)

    :gl.bufferData(
      :gl_const.gl_array_buffer(),
      byte_size(rect_vertices),
      rect_vertices,
      :gl_const.gl_static_draw()
    )

    :gl.bindBuffer(:gl_const.gl_element_array_buffer(), ebo)

    :gl.bufferData(
      :gl_const.gl_element_array_buffer(),
      byte_size(rect_indices),
      rect_indices,
      :gl_const.gl_static_draw()
    )

    :gl.vertexAttribPointer(
      0,
      3,
      :gl_const.gl_float(),
      :gl_const.gl_false(),
      3 * byte_size(<<0.0::float-size(32)>>),
      0
    )

    :gl.enableVertexAttribArray(0)
    {shader_program, vao1, vao2, rect_vao}
  end

  @triangle_vertices [
                       [0.0, 1.0, 0.0],
                       [1.0, 0.0, 0.0],
                       [1.0, 1.0, 0.0]
                     ]
                     |> List.flatten()
                     |> Enum.reduce(<<>>, fn el, acc -> acc <> <<el::float-native-size(32)>> end)
  def triangle_vertices do
    @triangle_vertices
  end

  @triangle_vertices_2 [
                         [-0.5, -0.5, 0.0],
                         [0.5, -0.5, 0.0],
                         [0.0, 0.5, 0.0]
                       ]
                       |> List.flatten()
                       |> Enum.reduce(<<>>, fn el, acc -> acc <> <<el::float-native-size(32)>> end)
  def triangle_vertices_2 do
    @triangle_vertices_2
  end

  @rectangle_vertices [
                        [0.5, 0.5, 0.0],
                        [0.5, -0.5, 0.0],
                        [-0.5, -0.5, 0.0],
                        [-0.5, 0.5, 0.0]
                      ]
                      |> List.flatten()
                      |> Enum.reduce(<<>>, fn el, acc -> acc <> <<el::float-native-size(32)>> end)

  def rectangle_vertices do
    @rectangle_vertices
  end

  @rectangle_indices [[0, 1, 3], [1, 2, 3]]
                     |> List.flatten()
                     |> Enum.reduce(<<>>, fn el, acc -> acc <> <<el::native-size(32)>> end)
  def rectangle_indices do
    @rectangle_indices
  end

  @impl :wx_object
  def handle_event(wx(event: wxClose()), state) do
    {:stop, :normal, state}
  end

  @impl :wx_object
  def handle_info(:stop, %{canvas: canvas, fps_counter_label: fps_counter_label} = state) do
    :wxGLCanvas.destroy(canvas)
    :wxStaticText.destroy(fps_counter_label)

    {:stop, :normal, state}
  end

  @impl :wx_object
  def handle_info(:update, state) do
    state = render(state)

    {:noreply, state}
  end

  defp render(%{canvas: canvas} = state) do
    state =
      state
      |> update_frame_counter()
      |> draw()

    :wxGLCanvas.swapBuffers(canvas)
    send(self(), :update)

    state
  end

  defp draw(%{frame: frame} = state) do
    :gl.clearColor(0.2, 0.1, 0.3, 1.0)
    :gl.clear(:gl_const.gl_color_buffer_bit())

    now = System.monotonic_time(:millisecond)
    green = :math.sin(now) / 2 + 0.5

    location = :gl.getUniformLocation(state.shader_program, ~c"vertexColor")
    :gl.useProgram(state.shader_program)
    :gl.uniform4f(location, 0.0, green, 0.0, 1.0)

    :gl.bindVertexArray(state.vao1)
    :gl.drawArrays(:gl_const.gl_triangles(), 0, 3)

    :gl.bindVertexArray(state.vao2)
    :gl.drawArrays(:gl_const.gl_triangles(), 0, 3)

    :gl.polygonMode(:gl_const.gl_front_and_back(), :gl_const.gl_line())
    :gl.bindVertexArray(state.rect_vao)
    :gl.drawElements(:gl_const.gl_triangles(), 6, :gl_const.gl_unsigned_int(), 0)
    :gl.polygonMode(:gl_const.gl_front_and_back(), :gl_const.gl_fill())

    :wxWindow.setLabel(frame, ~c"FPS: #{state.fps}")

    state
  end

  def update_frame_counter(%{last_time: last_time, frame_counter: frame_counter} = state) do
    now = System.monotonic_time(:millisecond)
    elapsed = now - last_time

    if elapsed > 100 do
      frames = :counters.get(frame_counter, 1)
      fps = (frames / elapsed * 1000) |> round()
      :counters.put(frame_counter, 1, 0)
      Map.merge(state, %{fps: fps, last_time: now})
    else
      :counters.add(frame_counter, 1, 1)
      state
    end
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :permanent
    }
  end
end
