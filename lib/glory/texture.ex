defmodule Glory.Texture do
  alias Vix.Vips.Image

  def load_texture(image_path) do
    dbg("Loading texture: #{image_path}")

    if File.exists?(image_path) do
      IO.puts("File exists")
    else
      IO.puts("File does not exist")
    end

    [texture] = :gl.genTextures(1)
    :gl.bindTexture(:gl_const.gl_texture_2d(), texture)

    :gl.texParameteri(
      :gl_const.gl_texture_2d(),
      :gl_const.gl_texture_wrap_s(),
      :gl_const.gl_repeat()
    )

    :gl.texParameteri(
      :gl_const.gl_texture_2d(),
      :gl_const.gl_texture_wrap_t(),
      :gl_const.gl_repeat()
    )

    :gl.texParameteri(
      :gl_const.gl_texture_2d(),
      :gl_const.gl_texture_min_filter(),
      :gl_const.gl_linear_mipmap_linear()
    )

    :gl.texParameteri(
      :gl_const.gl_texture_2d(),
      :gl_const.gl_texture_mag_filter(),
      :gl_const.gl_linear()
    )

    {:ok, img} = Image.new_from_file(image_path)
    {:ok, img} = Vix.Vips.Operation.flip(img, :VIPS_DIRECTION_VERTICAL)
    height = Image.height(img)
    width = Image.width(img)

    data =
      case Image.write_to_binary(img) do
        {:ok, bin} when is_binary(bin) ->
          bin

        err ->
          IO.puts("error!")
          IO.inspect(err)
      end

    if String.contains?(image_path, ".png") do
      :gl.texImage2D(
        :gl_const.gl_texture_2d(),
        0,
        :gl_const.gl_rgba(),
        width,
        height,
        0,
        :gl_const.gl_rgba(),
        :gl_const.gl_unsigned_byte(),
        data
      )
    else
      :gl.texImage2D(
        :gl_const.gl_texture_2d(),
        0,
        :gl_const.gl_rgb(),
        width,
        height,
        0,
        :gl_const.gl_rgb(),
        :gl_const.gl_unsigned_byte(),
        data
      )
    end

    :gl.generateMipmap(:gl_const.gl_texture_2d())
    texture
  end
end
