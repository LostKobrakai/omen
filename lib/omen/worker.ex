defmodule Omen.Worker do
  @moduledoc """
  Worker implementation for `Omen`.

  Workers are created using `Omen.Worker`. It's basically just a small wrapper around `Oban.Worker`, which handles sending the `Task` a message with the return value of `action/1` and calling `on_task_gone/2` if it's defined and the task is no longer alive.

      defmodule MyApp.Worker do
        use Omen.Worker

        @impl Omen.Worker
        def action(args) do
          # Do whatever you need to do
        end

        @impl Omen.Worker
        def on_task_gone(args, result) do
          # This is an optional
          #
          # Use this to handle cases, where you need to
          # respond to someone, when a synchronous response
          # via the task is no longer possible.
        end
      end
  """
  @type result :: term

  @callback action(args :: map) :: result
  @callback on_task_gone(args :: map, result) :: term
  @optional_callbacks on_task_gone: 2

  defmacro __using__(args) do
    quote do
      use Oban.Worker, unquote(args)
      @behaviour unquote(__MODULE__)
      alias unquote(__MODULE__), as: OmenWorker

      @impl Oban.Worker
      def perform(args) do
        {uuid, args} = Map.pop(args, "uuid")

        unless is_binary(uuid) do
          raise "Tried to use #{inspect(OmenWorker)} by directly intersting it in the database."
        end

        result = OmenWorker.run_action(__MODULE__, args)
        OmenWorker.handle_action_result(__MODULE__, uuid, args, result)
      end
    end
  end

  @doc false
  # Run the action on the worker
  @spec run_action(module(), map) :: result
  def run_action(worker, args) do
    worker.action(args)
  end

  @doc false
  # Handle the results of the action call on worker.
  # If the task-uuid is no longer reachable this tries to
  # execute `on_task_gone/2` on the worker module.
  @spec handle_action_result(module(), Omen.Registry.uuid(), map, result) :: term
  def handle_action_result(worker, uuid, args, result) do
    with :error <- Omen.Registry.send_message(uuid, {:omen_response, result}),
         true <- function_exported?(worker, :on_task_gone, 2) do
      worker.on_task_gone(args, result)
    end
  end

  @doc false
  # Register the current process as receiver for worker results
  @spec register_receiver() :: Omen.Registry.uuid()
  def register_receiver do
    Omen.Registry.register_task()
  end

  @doc false
  # Add a task-uuid to the job's changeset
  @spec add_uuid_to_args(Ecto.Changeset.t(Oban.Job.t()), Omen.Registry.uuid()) ::
          Ecto.Changeset.t(Oban.Job.t())
  def add_uuid_to_args(%Ecto.Changeset{} = job, uuid) do
    Ecto.Changeset.update_change(job, :args, fn args ->
      Map.put(args, :uuid, uuid)
    end)
  end
end
