defmodule AshPg.Music.ArtistBio do
  use Ash.Resource, otp_app: :ash_pg, domain: AshPg.Music, data_layer: :embedded

  attributes do
    attribute :birth, :date, allow_nil?: true, public?: true
    attribute :nationality, :string, allow_nil?: true, public?: true
  end
end
