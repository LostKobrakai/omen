defmodule Omen.Repo do
  use Ecto.Repo,
    otp_app: :omen,
    adapter: Ecto.Adapters.Postgres
end
