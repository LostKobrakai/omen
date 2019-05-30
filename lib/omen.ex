defmodule Omen do
  @moduledoc """
  Omen is a companion library for [Oban](https://hex.pm/packages/oban), which returns a `Task` when inserting a job into the database, which can be `await`ed or `yield`ed like any other `Task`, but with the benefit that the job will execute no matter the state of the `Task`'s process.

  ## Usage

  Create a worker using `Omen.Worker`. It's basically just a small wrapper around `Oban.Worker`, which handles sending the `Task` a message with the return value of `action/1` and calling `on_task_gone/2` if it's defined and the task is no longer alive.

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

  Adding a new job using an `Omen.Worker` works similar to `Oban`.

      {:ok, task} =
        # Create the worker job
        %{...data}
        |> MyApp.Worker.new()
        # Insert into the db and spawn the task to listen for the return value
        |> Omen.async(Repo)
  """

  @doc """
  Enqueues the job and return a `Task` to receive the result in an async fashion.

  ## Usage

      {:ok, task} =
        # Create the worker job
        %{...data}
        |> MyApp.Worker.new()
        # Insert into the db and spawn the task to listen for the return value
        |> Omen.async(Repo)

  ## Options

  * `:timeout` - Timeout for the Task to respond with a UUID after being spawned. Default: 200
  """
  @spec async(Ecto.Changeset.t(Oban.Job.t()), Ecto.Repo.t(), keyword()) ::
          {:ok, Task.t()} | {:error, :term}
  def async(%Ecto.Changeset{} = job, repo, opts \\ []) do
    with {:ok, uuid, task} <- Omen.TaskSupervisor.start_receiver_task(opts),
         job = Omen.Worker.add_uuid_to_args(job, uuid),
         {:ok, _} <- repo.insert(job) do
      {:ok, task}
    else
      :timeout -> {:error, :timeout}
      err -> err
    end
  end
end
