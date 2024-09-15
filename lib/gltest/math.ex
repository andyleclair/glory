defmodule Gltest.Math do
  def rotate_z(t, degrees) do
    rads = degrees * :math.pi() / 180
    Nx.multiply(t, rotation_matrix(rads))
  end

  def rotation_matrix(rads) do
    cos = [rads] |> Nx.tensor() |> Nx.cos()
    sin = [rads] |> Nx.tensor() |> Nx.sin()
    neg_sin = sin |> Nx.negate()

    Nx.stack([
      Nx.concatenate([cos, neg_sin, Nx.tensor([0.0, 0.0])]),
      Nx.concatenate([sin, cos, Nx.tensor([0.0, 0.0])]),
      Nx.tensor([0.0, 0.0, 1.0, 0.0]),
      Nx.tensor([0.0, 0.0, 0.0, 1.0])
    ])
  end
end
