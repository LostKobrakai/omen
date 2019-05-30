defmodule Omen.PingWorker do
  use Omen.Worker

  @impl Omen.Worker
  def action(%{"pid" => test} = args) do
    test = :erlang.list_to_pid(test)
    send(test, {:pong, args})
    {:result, args}
  end
end
