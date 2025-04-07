defmodule AshPg.Domain.Accounts.Org do
  use Ash.Resource,
    otp_app: :ash_pg,
    domain: AshPg.Domain.Accounts,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_v7_primary_key :id

    attribute :name, :string, allow_nil?: false

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :staffs, AshPg.Domain.Accounts.Staff
  end

  actions do
    read :list do
      primary? true
    end
  end

  aggregates do
    sum :salary1, [:staffs], :salary1
    sum :salary2, [:staffs], :salary2

    sum :total_staff_salary, [:staffs], :salary do
      public? true
      filterable? true
    end
  end
end
