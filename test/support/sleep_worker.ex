defmodule Omen.SleepWorker do
  use Omen.Worker

  @impl Omen.Worker
  def action(%{"sleep" => timeout}) do
    Process.sleep(timeout)
    :ok
  end
end
