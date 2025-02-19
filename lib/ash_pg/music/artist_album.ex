defmodule AshPg.Music.ArtistAlbum do
  use Ash.Resource,
    otp_app: :ash_pg,
    domain: AshPg.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource]

  postgres do
    table "artist_albums"
    repo AshPg.Repo
    base_filter_sql "(archived_at IS NULL)"
  end

  resource do
    base_filter expr(is_nil(archived_at))
  end

  actions do
    read :list do
      primary? true
    end

    destroy :delete do
      primary? true
    end
  end

  relationships do
    belongs_to :artist, AshPg.Music.Artist, primary_key?: true, allow_nil?: false
    belongs_to :album, AshPg.Music.Album, primary_key?: true, allow_nil?: false
  end
end
