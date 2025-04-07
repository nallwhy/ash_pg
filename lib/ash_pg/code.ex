defmodule AshPg.Code do
  alias AshPg.Domain.Music

  def weird_query() do
    Music.Artist
    |> Ash.Query.for_read(:list)
    |> Ash.Query.load([:albums])
    |> Ash.read!()
  end
end
