defmodule Omen.TaskSupervisor do
  @moduledoc false

  @doc false
  @spec child_spec(term) :: Supervisor.child_spec()
  def child_spec(arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [arg]}
    }
  end

  @doc "Start the task supervisor"
  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(args) do
    args = Keyword.put_new(args, :name, __MODULE__)
    Task.Supervisor.start_link(args)
  end

  @doc """
  Start an new empty Task, which is meant to be the receiver for the result of an job execution.

  After spawing the task this waits for `opts[:timeout]` or `200`ms to get the uuid identification
  send back from the task.
  """
  @spec start_receiver_task(keyword()) ::
          {:ok, uuid :: binary, Task.t()} | :timeout
  @spec start_receiver_task(Supervisor.supervisor(), keyword()) ::
          {:ok, Omen.Registry.uuid(), Task.t()} | :timeout
  def start_receiver_task(supervisor \\ __MODULE__, opts) do
    timeout = Keyword.get(opts, :timeout, 200)
    task = Task.Supervisor.async(supervisor, __MODULE__, :receive_results, [self()], opts)

    receive do
      {:omen_uuid, uuid} -> {:ok, uuid, task}
    after
      timeout ->
        Task.shutdown(task, :brutal_kill)
        :timeout
    end
  end

  @doc """
  Callback of spawned tasks.

  It registers itself in a registry and get's back a key.
  The key is immediatelly sent back to the caller, which spawned the task.
  """
  @spec receive_results(Process.dest()) :: term
  def receive_results(caller) do
    send(caller, {:omen_uuid, Omen.Worker.register_receiver()})

    receive do
      {:omen_response, response} -> response
    end
  end
end
