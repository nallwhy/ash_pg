# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     AshPg.Repo.insert!(%AshPg.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias AshPg.Music

Ash.DataLayer.transaction([Music.Artist], fn ->
  artists =
    1..100
    |> Enum.map(fn i ->
      Ash.Seed.seed!(Music.Artist, %{
        name: "artist-#{i}",
        bio: Ash.Seed.seed!(Music.ArtistBio, %{
          birth: Date.range(~D[2000-01-01], ~D[2010-01-01]) |> Enum.random(),
          nationality: ["US", "UK", "KO", "JP"] |> Enum.random()
        })
      })
    end)

  albums =
    1..100
    |> Enum.map(fn i ->
      Ash.Seed.seed!(Music.Album, %{
        title: "album-#{i}"
      })
    end)

  [artists, albums]
  |> Enum.zip_with(fn [artist, album] ->
    Ash.Seed.seed!(Music.ArtistAlbum, %{
      artist_id: artist.id,
      album_id: album.id
    })
  end)
end)
