defmodule AshPg.Music do
  use Ash.Domain,
    otp_app: :ash_pg

  resources do
    resource AshPg.Music.Artist
  end
end
