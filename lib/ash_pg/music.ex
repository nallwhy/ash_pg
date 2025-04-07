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
    tool :update_artist, AshPg.Music.Artist, :update
    tool :delete_artist, AshPg.Music.Artist, :delete
    tool :list_albums, AshPg.Music.Album, :list_for_ai
  end

  resources do
    resource AshPg.Music.Label

    resource AshPg.Music.Artist do
      define :list_artists, action: :list
      define :create_artist, action: :create
      define :delete_artist, action: :delete
    end

    resource AshPg.Music.Album
    resource AshPg.Music.ArtistAlbum
  end
end
