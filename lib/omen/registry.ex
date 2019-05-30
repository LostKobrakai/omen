defmodule Omen.Registry do
  @moduledoc false
  @opaque uuid :: binary

  @doc false
  @spec child_spec(term) :: Supervisor.child_spec()
  def child_spec(arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [arg]}
    }
  end

  @doc "Start the registry"
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(args) do
    args =
      args
      |> Keyword.put(:keys, :unique)
      |> Keyword.put_new(:name, __MODULE__)

    Registry.start_link(args)
  end

  @doc """
  Register a task in the registry and return a key for later identification

  The key must be easily storable in a jsonb encoded db column.
  """
  @spec register_task() :: uuid
  @spec register_task(pid | Registry.registry()) :: uuid
  def register_task(registry \\ __MODULE__) do
    key = Ecto.UUID.generate()
    Registry.register(registry, key, true)
    key
  end

  @doc """
  Try to send a message to a task in the registry registered by the given uuid.

  If the task is no longer registered in the registry this returns `:error`.
  """
  @spec send_message(uuid, term) :: :ok | :error
  @spec send_message(pid | Registry.registry(), uuid, term) :: :ok | :error
  def send_message(registry \\ __MODULE__, uuid, message) do
    case Registry.lookup(registry, uuid) do
      [{task, _}] ->
        send(task, message)
        :ok

      [] ->
        :error
    end
  end
end
