defmodule AshPg.Music.Album do
  use Ash.Resource, otp_app: :ash_pg, domain: AshPg.Music, data_layer: AshPostgres.DataLayer

  postgres do
    table "albums"
    repo AshPg.Repo
  end

  attributes do
    uuid_v7_primary_key :id
    attribute :title, :string, allow_nil?: false

    create_timestamp :created_at
    update_timestamp :updated_at
  end
end
