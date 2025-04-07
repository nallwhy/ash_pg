defmodule AshPg.Code do
  def weird_filtering() do
    AshPg.Domain.Accounts.Org
    |> Ash.Query.filter_input(%{total_staff_salary: %{greater_than: 0}})
    |> Ash.read!()
  end
end
