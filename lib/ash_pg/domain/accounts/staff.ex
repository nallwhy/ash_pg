defmodule AshPg.Domain.Accounts.Staff do
  use Ash.Resource,
    otp_app: :ash_pg,
    domain: AshPg.Domain.Accounts,
    data_layer: Ash.DataLayer.Ets

  attributes do
    integer_primary_key :id

    attribute :name, :string, allow_nil?: false
    attribute :salary1, :decimal, allow_nil?: false
    attribute :salary2, :decimal, allow_nil?: false

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :org, AshPg.Domain.Accounts.Org, attribute_type: :integer
  end

  actions do
    read :list do
      primary? true
    end
  end

  calculations do
    calculate :salary, :decimal, expr(salary1 + salary2)
  end
end
