defmodule AshPg.Domain.Accounts do
  use Ash.Domain,
    otp_app: :ash_pg,
    extensions: []

  resources do
    resource AshPg.Domain.Accounts.Org
    resource AshPg.Domain.Accounts.Staff
  end
end
