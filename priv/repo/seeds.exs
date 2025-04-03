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
    1..10
    |> Enum.map(fn i ->
      Ash.Seed.seed!(Music.Artist, %{
        name: "artist-#{i}",
        bio:
          Ash.Seed.seed!(Music.ArtistBio, %{
            birth: Date.range(~D[2000-01-01], ~D[2010-01-01]) |> Enum.random(),
            nationality: ["US", "UK", "KO", "JP"] |> Enum.random()
          })
      })
    end)

  album_types = Music.AlbumType.values()
  album_types_count = album_types |> Enum.count()

  albums =
    1..10
    |> Enum.map(fn i ->
      Ash.Seed.seed!(Music.Album, %{
        title: "album-#{i}",
        type: album_types |> Enum.at(rem(i, album_types_count)),
        copies_sold: i * 100
      })
    end)

  albums
  |> Enum.reduce(Stream.cycle(artists), fn album, artist_stream ->
    artist_count = if album.type == :compilation, do: 2, else: 1

    artist_stream
    |> Stream.take(artist_count)
    |> Enum.map(fn artist ->
      Ash.Seed.seed!(Music.ArtistAlbum, %{
        artist_id: artist.id,
        album_id: album.id
      })
    end)

    Stream.drop(artist_stream, artist_count)
  end)
end)
