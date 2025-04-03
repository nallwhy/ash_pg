defmodule AshPg.Music.ArtistTest do
  use AshPg.DataCase, async: true
  alias AshPg.Music

  test "studio_copies_sold" do
    artist =
      Music.create_artist!(%{
        name: "250",
        albums: [
          %{title: "Rear Window", type: :single, copies_sold: 1000},
          %{title: "Bang Bus", type: :single, copies_sold: 2000},
          %{title: "뽕", type: :studio, copies_sold: 1_000_000}
        ]
      })

    %{studio_copies_sold: studio_copies_sold} = artist |> Ash.load!([:studio_copies_sold])

    # The sum of copies sold for studio albums should be 1_000_000
    assert studio_copies_sold == 1_000_000
  end
end
