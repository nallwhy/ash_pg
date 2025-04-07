defmodule AshPg.Domain.Music do
  use Ash.Domain,
    otp_app: :ash_pg,
    extensions: [AshPaperTrail.Domain, AshAi]

  paper_trail do
    include_versions? true
  end

  tools do
    tool :list_artists, AshPg.Domain.Music.Artist, :list
    tool :create_artist, AshPg.Domain.Music.Artist, :create
    tool :update_artist, AshPg.Domain.Music.Artist, :update
    tool :delete_artist, AshPg.Domain.Music.Artist, :delete
    tool :list_albums, AshPg.Domain.Music.Album, :list_for_ai
  end

  resources do
    resource AshPg.Domain.Music.Label

    resource AshPg.Domain.Music.Artist do
      define :list_artists, action: :list
      define :create_artist, action: :create
      define :delete_artist, action: :delete
    end

    resource AshPg.Domain.Music.Album
    resource AshPg.Domain.Music.ArtistAlbum
  end
end
