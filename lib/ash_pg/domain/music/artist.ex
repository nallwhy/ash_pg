defmodule AshPg.Music.Artist do
  use Ash.Resource,
    otp_app: :ash_pg,
    domain: AshPg.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource, AshPaperTrail.Resource]

  postgres do
    table "artists"
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

    create :create do
      primary? true
      accept [:name, :bio]
    end

    update :update do
      primary? true
      accept [:name, :bio]
    end

    destroy :delete do
      primary? true
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :name, :string,
      allow_nil?: false,
      public?: true,
      description: "The name of the artist"

    attribute :bio, AshPg.Music.ArtistBio, allow_nil?: true, public?: true

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    many_to_many :albums, AshPg.Music.Album, through: AshPg.Music.ArtistAlbum, public?: true
    has_many :artist_albums, AshPg.Music.ArtistAlbum
  end
end
