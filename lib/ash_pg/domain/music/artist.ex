defmodule AshPg.Domain.Music.Artist do
  use Ash.Resource,
    otp_app: :ash_pg,
    domain: AshPg.Domain.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource, AshPaperTrail.Resource]

  attributes do
    uuid_v7_primary_key :id

    attribute :name, :string,
      allow_nil?: false,
      public?: true,
      description: "The name of the artist"

    attribute :bio, AshPg.Domain.Music.ArtistBio, allow_nil?: true, public?: true

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :label, AshPg.Domain.Music.Label, public?: true

    many_to_many :albums, AshPg.Domain.Music.Album,
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
      accept [:name, :bio]
      argument :albums, {:array, :map}

      change manage_relationship(:albums, type: :create)
    end

    update :update do
      primary? true
      accept [:name, :bio]
    end

    destroy :delete do
      primary? true
    end
  end

  aggregates do
    sum :studio_copies_sold, [:albums], :copies_sold do
      filter expr(type == :studio)
    end
  end

  resource do
    base_filter expr(is_nil(archived_at))
  end

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
end
