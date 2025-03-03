defmodule AshPg.Music do
  use Ash.Domain,
    otp_app: :ash_pg,
    extensions: [AshPaperTrail.Domain]

  paper_trail do
    include_versions? true
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
