defmodule AshPg.Domain.Music.ArtistAlbum do
  use Ash.Resource,
    otp_app: :ash_pg,
    domain: AshPg.Domain.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource, AshPaperTrail.Resource]

  attributes do
    uuid_v7_primary_key :id
  end

  relationships do
    belongs_to :artist, AshPg.Domain.Music.Artist, allow_nil?: false
    belongs_to :album, AshPg.Domain.Music.Album, allow_nil?: false
  end

  actions do
    read :list do
      primary? true
    end

    create :create do
      primary? true
      accept [:artist_id, :album_id]
    end

    destroy :delete do
      primary? true
    end
  end

  identities do
    identity :artist_album, [:artist_id, :album_id]
  end

  resource do
    base_filter expr(is_nil(archived_at))
  end

  postgres do
    table "artist_albums"
    repo AshPg.Repo
    base_filter_sql "(archived_at IS NULL)"
  end

  paper_trail do
    primary_key_type :uuid_v7
    change_tracking_mode :snapshot
    store_action_name? true
    ignore_attributes [:created_at, :updated_at]
  end
end
