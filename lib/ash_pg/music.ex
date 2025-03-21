defmodule AshPg.Music do
  use Ash.Domain,
    otp_app: :ash_pg,
    extensions: [AshPaperTrail.Domain, AshAi]

  paper_trail do
    include_versions? true
  end

  tools do
    tool :list_artists, AshPg.Music.Artist, :list
    tool :create_artist, AshPg.Music.Artist, :create
  end

  resources do
    resource AshPg.Music.Artist do
      define :list_artists, action: :list
      define :delete_artist, action: :delete
    end

    resource AshPg.Music.Album
    resource AshPg.Music.ArtistAlbum
  end
end
