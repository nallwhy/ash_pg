defmodule AshPg.Domain.Music.Label do
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
      description: "The name of the label"
  end

  relationships do
    has_many :artists, AshPg.Domain.Music.Artist
  end

  resource do
    base_filter expr(is_nil(archived_at))
  end

  postgres do
    table "labels"
    repo AshPg.Repo
    base_filter_sql "(archived_at IS NULL)"
  end

  archive do
    archive_related []
  end

  paper_trail do
    primary_key_type :uuid_v7
    change_tracking_mode :snapshot
    store_action_name? true
    ignore_attributes [:created_at, :updated_at]
  end
end
