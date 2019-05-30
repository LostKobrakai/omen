ExUnit.start()
Supervisor.start_child(Omen.Supervisor, Omen.Repo)
Ecto.Adapters.SQL.Sandbox.mode(Omen.Repo, :manual)

Supervisor.start_child(
  Omen.Supervisor,
  {Oban, [repo: Omen.Repo, prune: :disabled, queues: false]}
)
