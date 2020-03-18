defmodule Hive.Worker do
  use GenServer
  require Logger

  # Hive.
  # Hive.Registry.register(%{name: :worker_1, role: "b_role"})
  # Hive.Registry.register(%{name: :worker_2, role: "b_role"})
  # Hive.Registry.register(%{name: {:global, :worker_3}, role: "b_role"})

  def get_name(pid) do
    GenServer.call(pid, {:name})
  end

  def raise(pid, msg) do
    GenServer.cast(pid, {:raise, msg})
  end

  def register(initial_state) do
    start_link(initial_state)
  end

  def start_link(%{name: name} = initial_state) do
    GenServer.start_link(__MODULE__, [initial_state], name: name)
  end

  def init([%{name: name} = initial_state]) do
    Hive.Registry.monitor(self(), name)
    {:ok, initial_state}
  end

  def handle_cast({:raise, msg}, _name) do
    raise msg
  end

  def handle_cast({:swarm, :end_handoff}, initial_state) do
    Logger.info("[Worker] begin_handoff: #{inspect(initial_state)}")
    {:noreply, initial_state}
  end

  def handle_cast({:swarm, :resolve_conflict}, initial_state) do
    Logger.info("[Worker] resolve_conflict: #{inspect(initial_state)}")
    {:noreply, initial_state}
  end

  def handle_call({:name}, _from, initial_state) do
    {:reply, initial_state, initial_state}
  end

  def handle_call({:swarm, :begin_handoff}, _from, initial_state) do
    Logger.info("[Worker] begin_handoff: #{inspect(initial_state)}")
    {:reply, :resume, initial_state}
  end

  def handle_info({:swarm, :die}, initial_state) do
    Logger.info("[Worker] swarm stopping worker: #{initial_state}")
    {:stop, :normal, initial_state}
  end
end
