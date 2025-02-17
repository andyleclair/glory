defmodule GlTest.Window do
  alias GlTest.Input
  alias GlTest.Shader
  alias GlTest.Texture

  import WxRecords
  import Bitwise
  require Logger

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
    :wxGLCanvas.connect(canvas, :key_down, callback: &Input.handler/2)
    :wxGLCanvas.connect(canvas, :key_up, callback: &Input.handler/2)
    :wxGLCanvas.connect(canvas, :motion, callback: &Input.handler/2)

    max_attribs = :gl.getIntegerv(:gl_const.gl_max_vertex_attribs()) |> inspect()

    Logger.debug("OpenGL max vertex attribs: " <> max_attribs)

    # Initialize shaders
    shader_program = Shader.init(@vertex_path, @fragment_path)

    Logger.debug("Created Shader program")
    frame_counter = :counters.new(2, [:atomics])
    cube_vao = bind_shape(cube_vertices())
    Logger.debug("Bound shape")
    texture1 = Texture.load_texture(@container_path)
    texture2 = Texture.load_texture(@awesome_path)
    Logger.debug("Loaded textures")

    :gl.useProgram(shader_program)
    Shader.set(shader_program, ~c"texture1", 0)
    Shader.set(shader_program, ~c"texture2", 1)

    send(self(), :update)
    now = now()

    Logger.debug("Starting now: #{now}")

    {frame,
     %{
       start_time: now,
       last_frame_time: now,
       last_sample_time: now,
       frame: frame,
       frame_counter: frame_counter,
       canvas: canvas,
       shader_program: shader_program,
       fps: 0,
       cube_vao: cube_vao,
       texture1: texture1,
       texture2: texture2
     }}
  end

  defp now do
    System.monotonic_time(:millisecond)
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
      5 * byte_size(<<0.0::float-size(32)>>),
      0
    )

    :gl.enableVertexAttribArray(0)

    :gl.vertexAttribPointer(
      1,
      2,
      :gl_const.gl_float(),
      :gl_const.gl_false(),
      5 * byte_size(<<0.0::float-size(32)>>),
      3 * byte_size(<<0.0::float-size(32)>>)
    )

    :gl.enableVertexAttribArray(1)

    vertex_array
  end

  @cube_vertices [
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
                 |> Enum.reduce(<<>>, fn el, acc -> acc <> <<el::float-native-size(32)>> end)

  def cube_vertices do
    @cube_vertices
  end

  @impl :wx_object
  def handle_event(wx(event: wxClose()), state) do
    Logger.debug("Window closed")
    System.stop()
    Logger.debug("System stopped")
    {:stop, :normal, state}
  end

  @impl :wx_object
  def handle_info(:stop, %{canvas: canvas, fps_counter_label: fps_counter_label} = state) do
    Logger.debug("stop called")
    :wxGLCanvas.destroy(canvas)
    :wxStaticText.destroy(fps_counter_label)

    {:stop, :normal, state}
  end

  @impl :wx_object
  def handle_info(:update, state) do
    # send(self(), :update)
    Process.send_after(self(), :update, 10)
    state = render(state)

    {:noreply, state}
  end

  defp render(%{canvas: canvas} = state) do
    state =
      state
      |> update_frame_counter()
      |> draw()

    :wxGLCanvas.swapBuffers(canvas)

    state
  end

  defp draw(%{frame: frame, shader_program: shader_program} = state) do
    :gl.enable(:gl_const.gl_depth_test())
    :gl.depthFunc(:gl_const.gl_less())

    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(:gl_const.gl_color_buffer_bit() ||| :gl_const.gl_depth_buffer_bit())

    :gl.activeTexture(:gl_const.gl_texture0())
    :gl.bindTexture(:gl_const.gl_texture_2d(), state.texture1)
    :gl.activeTexture(:gl_const.gl_texture1())
    :gl.bindTexture(:gl_const.gl_texture_2d(), state.texture2)

    rads = :math.sin(Gltest.Math.radians((now() - state.start_time) / 1_000)) * 90

    model =
      Graphmath.Mat44.multiply(
        Graphmath.Mat44.make_rotate_x(rads),
        Graphmath.Mat44.make_rotate_y(rads)
      )

    view = Graphmath.Mat44.make_translate(0.0, 0.0, -2.0)

    # Gltest.Math.perspective(45.0, 800.0 / 600.0, 1.0, 1000.0)
    projection =
      Gltest.Math.ortho(-1.0, 1.0, -1.0, 1.0, 0.1, 100.0)

    shader_program
    |> Shader.set(~c"model", model)
    |> Shader.set(~c"view", view)
    |> Shader.set(~c"projection", projection)

    :gl.bindVertexArray(state.cube_vao)
    :gl.drawArrays(:gl_const.gl_triangles(), 0, 36)

    :wxWindow.setLabel(frame, ~c"FPS: #{state.fps}")

    state
  end

  def update_frame_counter(
        %{
          last_frame_time: last_frame_time,
          last_sample_time: last_sample_time,
          frame_counter: frame_counter
        } = state
      ) do
    now = now()
    since_last_sample = now - last_sample_time
    _since_last_frame = now - last_frame_time
    # Increment global frame counter, index 2
    :counters.add(frame_counter, 2, 1)

    if since_last_sample > 50 do
      frames = :counters.get(frame_counter, 1)
      fps = (frames / since_last_sample * 1_000) |> round()
      :counters.put(frame_counter, 1, 0)
      Map.merge(state, %{fps: fps, last_sample_time: now, last_frame_time: now})
    else
      :counters.add(frame_counter, 1, 1)
      Map.put(state, :last_frame_time, now)
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
