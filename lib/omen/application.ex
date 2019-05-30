defmodule Omen.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Omen.Registry,
      Omen.TaskSupervisor
    ]

    opts = [strategy: :one_for_one, name: Omen.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
