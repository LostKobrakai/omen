use Mix.Config

config :logger, level: :warn

config :omen, ecto_repos: [Omen.Repo]

config :omen, Omen.Repo,
  database: "omen_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
