defmodule VapiServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @env Application.compile_env(:vapi_server, :env)
  @dev_children if @env == :dev, do: [VapiServer.VapiConnection], else: []

  @impl true
  def start(_type, _args) do
    children =
      [
        VapiServerWeb.Telemetry,
        VapiServer.Repo,
        {DNSCluster, query: Application.get_env(:vapi_server, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: VapiServer.PubSub},
        # Start the Finch HTTP client for sending emails
        {Finch, name: VapiServer.Finch},
        # Start a worker by calling: VapiServer.Worker.start_link(arg)
        # {VapiServer.Worker, arg},
        # Start to serve requests, typically the last entry
        VapiServerWeb.Endpoint
      ]
      |> Enum.concat(@dev_children)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: VapiServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    VapiServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
