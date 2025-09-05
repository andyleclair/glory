defmodule Glory.Window do
  alias Glory.Camera
  alias Glory.Cube
  alias Glory.Input
  alias Glory.Math
  alias Glory.Shader
  alias Glory.Texture
  alias Graphmath.Mat44

  import WxRecords
  import Bitwise
  require Logger

  @behaviour :wx_object

  def start_link(_) do
    :wx_object.start_link({:local, __MODULE__}, __MODULE__, [], [])
    {:ok, self()}
  end

  @container_path Path.join([__DIR__, "..", "..", "container.jpg"])
  @awesome_path Path.join([__DIR__, "..", "..", "awesomeface.png"])

  @vertex_path Path.join([__DIR__, "shaders", "vertex.glsl"])
  @fragment_path Path.join([__DIR__, "shaders", "fragment.glsl"])

  @width 1200
  @height 800
  @aspect @width / @height * 1.0

  @impl :wx_object
  def init(_) do
    opts = [size: {@width, @height}]
    wx = :wx.new()
    frame = :wxFrame.new(wx, :wx_const.wx_id_any(), ~c"Hello", opts)

    :wxWindow.connect(frame, :close_window)
    :wxFrame.show(frame)

    gl_attrib = [
      attribList: [
        :wx_const.wx_gl_core_profile(),
        :wx_const.wx_gl_major_version(),
        4,
        :wx_const.wx_gl_minor_version(),
        2,
        :wx_const.wx_gl_doublebuffer(),
        :wx_const.wx_gl_depth_size(),
        16
      ]
    ]

    canvas = :wxGLCanvas.new(frame, opts ++ gl_attrib)
    ctx = :wxGLContext.new(canvas)
    :wxGLCanvas.setCurrent(canvas, ctx)

    :wxGLCanvas.connect(canvas, :key_down, callback: &Input.handler/2)
    :wxGLCanvas.connect(canvas, :key_up, callback: &Input.handler/2)
    :wxGLCanvas.connect(canvas, :motion, callback: &Input.handler/2)
    Input.init()

    max_attribs = :gl.getIntegerv(:gl_const.gl_max_vertex_attribs()) |> inspect()

    Logger.debug("OpenGL max vertex attribs: " <> max_attribs)

    # Initialize shaders
    shader_program = Shader.init(@vertex_path, @fragment_path)

    Logger.debug("Created Shader program")
    frame_counter = :counters.new(2, [:atomics])
    cube_vao = Cube.bind()
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
       texture2: texture2,
       cubes: Cube.positions(),
       keys: MapSet.new(),
       camera: Camera.new(),
       projection: Glory.Math.perspective(45.0, @aspect, 0.1, 100.0)
     }}
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
    send(self(), :update)
    # Process.send_after(self(), :update, 10)
    state = render(state)

    {:noreply, state}
  end

  @impl :wx_object
  def handle_cast({:key_down, key_code}, %{keys: keys} = state) do
    keys = MapSet.put(keys, key_code)
    state = Map.put(state, :keys, keys)
    {:noreply, state}
  end

  @impl :wx_object
  def handle_cast({:key_up, key_code}, %{keys: keys} = state) do
    keys = MapSet.delete(keys, key_code)
    state = Map.put(state, :keys, keys)
    {:noreply, state}
  end

  @impl :wx_object
  def handle_cast(request, state) do
    IO.inspect(request, label: "casted")
    {:noreply, state}
  end

  defp render(%{canvas: canvas} = state) do
    state =
      state
      |> update_frame_counter()
      |> handle_input()
      |> draw()

    Logger.debug("Frame time #{now() - state.last_frame_time}ms")

    :wxGLCanvas.swapBuffers(canvas)

    state
  end

  defp handle_input(%{camera: camera, keys: keys} = state) do
    camera = Camera.handle_input(camera, keys)
    %{state | camera: camera}
  end

  defp draw(
         %{
           frame: frame,
           shader_program: shader_program,
           cubes: cubes,
           camera: camera,
           projection: projection,
           cube_vao: cube_vao
         } = state
       ) do
    :gl.enable(:gl_const.gl_depth_test())
    :gl.depthFunc(:gl_const.gl_less())

    :gl.clearColor(0.2, 0.3, 0.3, 1.0)
    :gl.clear(:gl_const.gl_color_buffer_bit() ||| :gl_const.gl_depth_buffer_bit())

    :gl.activeTexture(:gl_const.gl_texture0())
    :gl.bindTexture(:gl_const.gl_texture_2d(), state.texture1)
    :gl.activeTexture(:gl_const.gl_texture1())
    :gl.bindTexture(:gl_const.gl_texture_2d(), state.texture2)

    view = Camera.view(camera)

    shader_program
    |> Shader.set(~c"view", view)
    |> Shader.set(~c"projection", projection)

    cubes
    |> Enum.with_index()
    |> Enum.each(fn {{x, y, z}, i} ->
      degrees = (state.start_time - now()) * 0.01 * (i + 1)
      rads = Math.radians(degrees)

      model =
        Mat44.make_translate(x, y, z)
        |> Mat44.multiply(Mat44.make_rotate_x(rads))
        |> Mat44.multiply(Mat44.make_rotate_z(rads))

      Shader.set(shader_program, ~c"model", model)

      :gl.bindVertexArray(cube_vao)
      :gl.drawArrays(:gl_const.gl_triangles(), 0, 36)
    end)

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
      %{state | fps: fps, last_sample_time: now, last_frame_time: now}
    else
      :counters.add(frame_counter, 1, 1)
      %{state | last_frame_time: now}
    end
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :permanent
    }
  end

  defp now do
    System.monotonic_time(:millisecond)
  end
end
