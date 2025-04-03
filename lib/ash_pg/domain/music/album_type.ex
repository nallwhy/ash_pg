defmodule AshPg.Music.AlbumType do
  use Ash.Type.Enum,
    values: [
      :studio,
      :ep,
      :single,
      :compilation,
      :live,
      :etc
    ]
end
