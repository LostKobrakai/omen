defmodule OmenTest do
  use Omen.DataCase

  describe "async/2" do
    setup :setup_queue

    test "ping", %{module: module, name: name} do
      pid_list = :erlang.pid_to_list(self())

      {:ok, task} =
        %{pid: pid_list}
        |> Omen.PingWorker.new(queue: module)
        |> Omen.async(Repo)

      assert {:result, args_result} = Task.await(task)

      assert_received {:pong, args_sent}

      assert args_result == args_sent
      assert %{"pid" => ^pid_list} = args_result

      stop_supervised(name)
    end

    test "sleep", %{module: module, name: name} do
      {:ok, task} =
        %{sleep: 120}
        |> Omen.SleepWorker.new(queue: module)
        |> Omen.async(Repo)

      assert nil == Task.yield(task, 40)
      assert nil == Task.yield(task, 40)
      assert nil == Task.yield(task, 40)
      assert {:ok, :ok} = Task.yield(task)

      stop_supervised(name)
    end

    test "task gone", %{module: module, name: name} do
      pid_list = :erlang.pid_to_list(self())

      spawn(fn ->
        pid_list_2 = :erlang.pid_to_list(self())

        {:ok, task} =
          %{pid: pid_list, pid2: pid_list_2}
          |> Omen.TaskGoneWorker.new(queue: module)
          |> Omen.async(Repo)

        nil = Task.shutdown(task, :brutal_kill)
      end)

      assert_receive {:action, %{"pid" => ^pid_list}}, 500
      assert_receive {:on_task_gone, %{"pid" => ^pid_list}, :ok}, 500

      stop_supervised(name)
    end
  end
end
