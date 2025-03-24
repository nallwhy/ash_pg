defmodule AshPg.Utils.UUID do
  def v4() do
    Ash.UUID.generate()
  end

  def v7() do
    Ash.UUIDv7.generate()
  end
end
