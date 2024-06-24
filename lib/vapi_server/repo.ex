defmodule VapiServer.Repo do
  use Ecto.Repo,
    otp_app: :vapi_server,
    adapter: Ecto.Adapters.Postgres
end
