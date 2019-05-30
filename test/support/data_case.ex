defmodule Omen.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Omen.Repo

      import Ecto
      import Ecto.Query
      import Omen.DataCase

      use Oban.Testing, repo: Omen.Repo

      alias Omen.Repo
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Omen.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Omen.Repo, {:shared, self()})
    end

    :ok
  end

  def setup_queue(%{module: module}) do
    conf = Agent.get(Oban.Config, fn conf -> conf end)
    name = Module.concat([conf.name, "Queue"] ++ Module.split(module))
    queue = inspect(module)
    options = [conf: conf, queue: queue, limit: 2, name: name]
    {:ok, _} = start_supervised({Oban.Queue.Supervisor, options}, id: name)
    {:ok, queue: queue, name: name}
  end
end
