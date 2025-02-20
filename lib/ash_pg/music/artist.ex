defmodule AshPg.Music.Artist do
  use Ash.Resource,
    otp_app: :ash_pg,
    domain: AshPg.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource]

  postgres do
    table "artists"
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

  attributes do
    uuid_v7_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :bio, AshPg.Music.ArtistBio, allow_nil?: true

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    many_to_many :albums, AshPg.Music.Album, through: AshPg.Music.ArtistAlbum
    has_many :artist_albums, AshPg.Music.ArtistAlbum
  end

  archive do
    archive_related [:artist_albums]
  end
end
