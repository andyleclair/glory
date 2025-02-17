defmodule Gltest.Math do
  def radians(degrees) when is_float(degrees) or is_integer(degrees) do
    degrees * :math.pi() / 180.0
  end

  @spec perspective(fov :: float(), aspect :: float(), near :: float(), far :: float()) ::
          Graphmath.Mat44.mat44()
  def perspective(fov, aspect, near, far)
      when is_float(fov) and is_float(aspect) and is_float(near) and is_float(far) do
    fov_rad = radians(fov / 2.0)
    tan_half_fovy = :math.tan(fov_rad)
    range = far - near

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
      -((far + near) / range),
      -(2.0 * far * near / range),
      0.0,
      0.0,
      -1.0,
      0.0
    }
  end

  def ortho(left, right, bottom, top, near, far) do
    {
      2.0 / (right - left),
      0.0,
      0.0,
      -(right + left) / (right - left),
      0.0,
      2.0 / (top - bottom),
      0.0,
      -(top + bottom) / (top - bottom),
      0.0,
      0.0,
      -2.0 / (far - near),
      -(far + near) / (far - near),
      0.0,
      0.0,
      0.0,
      1.0
    }
  end

  def transpose({a1, a2, a3, a4, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, d4}) do
    {a1, b1, c1, d1, a2, b2, c2, d2, a3, b3, c3, d3, a4, b4, c4, d4}
  end
end
