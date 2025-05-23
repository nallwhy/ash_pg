defmodule AshPg.Domain.Music.Album do
  use Ash.Resource,
    otp_app: :ash_pg,
    domain: AshPg.Domain.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource, AshPaperTrail.Resource]

  attributes do
    uuid_v7_primary_key :id

    attribute :title, :string,
      allow_nil?: false,
      public?: true,
      description: "The title of the album"

    attribute :type, AshPg.Domain.Music.AlbumType,
      allow_nil?: false,
      default: :studio,
      public?: true,
      description: "The type of the album"

    attribute :copies_sold, :integer,
      allow_nil?: false,
      default: 0,
      public?: true,
      description: "The number of copies sold"

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    many_to_many :artists, AshPg.Domain.Music.Artist,
      through: AshPg.Domain.Music.ArtistAlbum,
      public?: true

    has_many :artist_albums, AshPg.Domain.Music.ArtistAlbum
  end

  actions do
    read :list do
      primary? true
    end

    create :create do
      primary? true
      accept [:title, :type, :copies_sold]
    end

    destroy :delete do
      primary? true
    end

    read :list_for_ai do
      prepare build(load: [:artists])
    end
  end

  resource do
    base_filter expr(is_nil(archived_at))
  end

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
end
