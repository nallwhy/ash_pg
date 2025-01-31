defmodule AshPg.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AshPgWeb.Telemetry,
      AshPg.Repo,
      {DNSCluster, query: Application.get_env(:ash_pg, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AshPg.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: AshPg.Finch},
      # Start a worker by calling: AshPg.Worker.start_link(arg)
      # {AshPg.Worker, arg},
      # Start to serve requests, typically the last entry
      AshPgWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AshPg.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AshPgWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
