defmodule AshPg.Music.ArtistBio do
  use Ash.Resource, otp_app: :ash_pg, domain: AshPg.Music, data_layer: :embedded

  attributes do
    attribute :birth, :date,
      allow_nil?: true,
      public?: true,
      description: "birth date of the artist"

    attribute :nationality, :string,
      allow_nil?: true,
      public?: true,
      description: "nationality of the artist"
  end
end
