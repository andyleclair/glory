defmodule GlTest.Window do
  import WxRecords

  @behaviour :wx_object

  def start_link(_) do
    :wx_object.start_link(__MODULE__, [], [])
    {:ok, self()}
  end

  @container_path Path.join([__DIR__, "..", "..", "container.jpg"])
  @awesome_path Path.join([__DIR__, "..", "..", "awesomeface.png"])

  @vertex_path Path.join([__DIR__, "shaders", "vertex.glsl"])
  @fragment_path Path.join([__DIR__, "shaders", "fragment.glsl"])

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
    # Initialize shaders
    shader_program = GlTest.Shader.init(@vertex_path, @fragment_path)

    IO.puts("Created Shader program")
    # colored_triangle_vao = bind_shape(colored_triangle_vertices())
    frame_counter = :counters.new(1, [:atomics])
    rect_vao = bind_rectangle()
    IO.puts("Bound shape")
    texture1 = GlTest.Texture.load_texture(@container_path)
    texture2 = GlTest.Texture.load_texture(@awesome_path)
    IO.puts("Loaded textures")

    :gl.useProgram(shader_program)
    GlTest.Shader.set(shader_program, ~c"texture1", 0)
    GlTest.Shader.set(shader_program, ~c"texture2", 1)

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
       rect_vao: rect_vao,
       texture1: texture1,
       texture2: texture2
     }}
  end

  def bind_shape(vertices) do
    [vertex_array] = :gl.genVertexArrays(1)
    [vertex_buffer] = :gl.genBuffers(1)

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
      6 * byte_size(<<0.0::float-size(32)>>),
      0
    )

    :gl.enableVertexAttribArray(0)

    :gl.vertexAttribPointer(
      1,
      3,
      :gl_const.gl_float(),
      :gl_const.gl_false(),
      6 * byte_size(<<0.0::float-size(32)>>),
      3 * byte_size(<<0.0::float-size(32)>>)
    )

    :gl.enableVertexAttribArray(2)

    vertex_array
  end

  def bind_rectangle do
    [rect_vao] = :gl.genVertexArrays(1)
    [rect_vbo, ebo] = :gl.genBuffers(2)

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
      8 * byte_size(<<0.0::float-size(32)>>),
      0
    )

    :gl.enableVertexAttribArray(0)

    :gl.vertexAttribPointer(
      1,
      3,
      :gl_const.gl_float(),
      :gl_const.gl_false(),
      8 * byte_size(<<0.0::float-size(32)>>),
      3 * byte_size(<<0.0::float-size(32)>>)
    )

    :gl.enableVertexAttribArray(1)

    :gl.vertexAttribPointer(
      2,
      2,
      :gl_const.gl_float(),
      :gl_const.gl_false(),
      8 * byte_size(<<0.0::float-size(32)>>),
      6 * byte_size(<<0.0::float-size(32)>>)
    )

    :gl.enableVertexAttribArray(2)

    rect_vao
  end

  def bind_texture do
  end

  @colored_triangle_vertices [
                               # Positions          # Colors
                               [0.5, -0.5, 0.0, 1.0, 0.0, 0.0],
                               [-0.5, -0.5, 0.0, 0.0, 1.0, 0.0],
                               [0.0, 0.5, 0.0, 0.0, 0.0, 1.0]
                             ]
                             |> List.flatten()
                             |> Enum.reduce(<<>>, fn el, acc ->
                               acc <> <<el::float-native-size(32)>>
                             end)
  def colored_triangle_vertices do
    @colored_triangle_vertices
  end

  @rectangle_vertices [
                        [[0.5, 0.5, 0.0], [1.0, 0.0, 0.0], [1.0, 1.0]],
                        [[0.5, -0.5, 0.0], [0.0, 1.0, 0.0], [1.0, 0.0]],
                        [[-0.5, -0.5, 0.0], [0.0, 0.0, 1.0], [0.0, 0.0]],
                        [[-0.5, 0.5, 0.0], [1.0, 1.0, 0.0], [0.0, 1.0]]
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
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(:gl_const.gl_color_buffer_bit())

    :gl.activeTexture(:gl_const.gl_texture0())
    :gl.bindTexture(:gl_const.gl_texture_2d(), state.texture1)
    :gl.activeTexture(:gl_const.gl_texture1())
    :gl.bindTexture(:gl_const.gl_texture_2d(), state.texture2)
    :gl.bindVertexArray(state.rect_vao)
    :gl.drawElements(:gl_const.gl_triangles(), 6, :gl_const.gl_unsigned_int(), 0)

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
