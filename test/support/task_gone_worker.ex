defmodule Omen.TaskGoneWorker do
  use Omen.Worker

  @impl Omen.Worker
  def action(%{"pid" => test, "pid2" => spawned_process} = args) do
    test = :erlang.list_to_pid(test)
    send(test, {:action, args})

    spawned_process = :erlang.list_to_pid(spawned_process)
    ref = Process.monitor(spawned_process)

    receive do
      {:DOWN, ^ref, :process, ^spawned_process, _reason} ->
        Process.sleep(100)
        {:ok, :ok}
    end
  end

  @impl Omen.Worker
  def on_task_gone(%{"pid" => test} = args, result) do
    test = :erlang.list_to_pid(test)
    send(test, {:on_task_gone, args, result})
    {:ok, result}
  end
end
