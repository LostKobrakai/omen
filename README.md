# Omen

Omen is a companion library for [Oban](https://hex.pm/packages/oban), which returns a `Task` when inserting a job into the database, which can be `await`ed or `yield`ed like any other `Task`, but with the benefit that the job will execute no matter the state of the `Task`'s process. 

## Usage

Create a worker using `Omen.Worker`. It's basically just a small wrapper around `Oban.Worker`, which handles sending the `Task` a message with the return value of `action/1` and calling `on_task_gone/2` if it's defined and the task is no longer alive.

```elixir
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
```

Adding a new job using an `Omen.Worker` works similar to `Oban`. 

```elixir
{:ok, task} = 
  # Create the worker job
  %{...data}
  |> MyApp.Worker.new()
  # Insert into the db and spawn the task to listen for the return value
  |> Omen.async(Repo)
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `omen` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:omen, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/omen](https://hexdocs.pm/omen).

