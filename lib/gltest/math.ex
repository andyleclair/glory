defmodule Gltest.Math do
  def radians(degrees) when is_number(degrees) do
    degrees * (:math.pi() / 180.0)
  end

  @spec perspective(fov :: float(), aspect :: float(), near :: float(), far :: float()) ::
          Graphmath.Mat44.mat44()
  def perspective(fov, aspect, near, far)
      when is_float(fov) and is_float(aspect) and is_float(near) and is_float(far) do
    fov_rad = radians(fov * 0.5)
    tan_half_fovy = :math.tan(fov_rad)
    range = near - far

    # Written out like this so it's easier to think about
    # Remember, OpenGL matrices are column-major
    # col 0{ 1.0 / (aspect * tan_half_fovy), 0.0, 0.0, 0.0,
    # col 1  0.0, 1.0 / tan_half_fovy, 0.0, 0.0,
    # col 2  0.0, 0.0, -((far + near) / range), -1.0,
    # col 3  0.0, 0.0, -(2.0 * far * near / range), 0.0
    # }

    {
      1.0 / (aspect * tan_half_fovy),
      0.0,
      0.0,
      0.0,
      0.0,
      1.0 / tan_half_fovy,
      0.0,
      0.0,
      0.0,
      0.0,
      (far + near) / range,
      -1.0,
      0.0,
      0.0,
      2.0 * far * near / range,
      0.0
    }
  end

  # def perspective(fov, aspect, near, far) do
  #  f = 1.0 / :math.tan(fov / 2)
  #  nf = 1 / (near - far)

  #  {
  #    {f / aspect, 0.0, 0.0, 0.0},
  #    {0.0, f, 0.0, 0.0},
  #    {0.0, 0.0, (far + near) * nf, -1.0},
  #    {0.0, 0.0, 2 * far * near * nf, 0.0}
  #  }
  #  |> flatten()
  # end

  # def flatten({{a0, a1, a2, a3}, {b0, b1, b2, b3}, {c0, c1, c2, c3}, {d0, d1, d2, d3}}) do
  #  {a0, a1, a2, a3, b0, b1, b2, b3, c0, c1, c2, c3, d0, d1, d2, d3}
  # end

  def ortho(left, right, bottom, top, near, far) do
    {
      2.0 / (right - left),
      0.0,
      0.0,
      0.0,
      0.0,
      2.0 / (top - bottom),
      0.0,
      0.0,
      0.0,
      0.0,
      -2.0 / (far - near),
      0.0,
      -(right + left) / (right - left),
      -(top + bottom) / (top - bottom),
      -(far + near) / (far - near),
      1.0
    }
  end

  def transpose({a1, a2, a3, a4, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, d4}) do
    {a1, b1, c1, d1, a2, b2, c2, d2, a3, b3, c3, d3, a4, b4, c4, d4}
  end

  def identity do
    {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  end

  def rotation_x(angle) do
    c = :math.cos(angle)
    s = :math.sin(angle)
    {1.0, 0.0, 0.0, 0.0, 0.0, c, s, 0.0, 0.0, -s, c, 0.0, 0.0, 0.0, 0.0, 1.0}
  end

  def rotation_y(angle) do
    c = :math.cos(angle)
    s = :math.sin(angle)
    {c, 0, -s, 0, 0, 1, 0, 0, s, 0, c, 0, 0, 0, 0, 1}
  end

  def rotation_z(angle) do
    c = :math.cos(angle)
    s = :math.sin(angle)
    {c, s, 0, 0, -s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}
  end

  def translate(x, y, z) do
    {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, x, y, z, 1.0}
  end
end
