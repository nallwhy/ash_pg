defmodule AshPg.Music.Album do
  use Ash.Resource,
    otp_app: :ash_pg,
    domain: AshPg.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource, AshPaperTrail.Resource]

  postgres do
    table "albums"
    repo AshPg.Repo
    base_filter_sql "(archived_at IS NULL)"
  end

  archive do
    archive_related [:artist_albums]
  end

  paper_trail do
    primary_key_type :uuid_v7
    change_tracking_mode :snapshot
    store_action_name? true
    ignore_attributes [:created_at, :updated_at]
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

    read :list_for_ai do
      prepare build(load: [:artists])
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :title, :string,
      allow_nil?: false,
      public?: true,
      description: "The title of the album"

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    many_to_many :artists, AshPg.Music.Artist, through: AshPg.Music.ArtistAlbum, public?: true
    has_many :artist_albums, AshPg.Music.ArtistAlbum
  end
end
