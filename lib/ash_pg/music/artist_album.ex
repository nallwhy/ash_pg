defmodule AshPg.Music.ArtistAlbum do
  use Ash.Resource, otp_app: :ash_pg, domain: AshPg.Music, data_layer: AshPostgres.DataLayer

  postgres do
    table "artist_albums"
    repo AshPg.Repo
  end

  actions do
    read :list do
      primary? true
    end
  end

  relationships do
    belongs_to :artist, AshPg.Music.Artist, primary_key?: true, allow_nil?: false
    belongs_to :album, AshPg.Music.Album, primary_key?: true, allow_nil?: false
  end
end
