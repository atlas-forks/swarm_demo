defmodule Hive do
  use Application

  @pg2_group :hive_workers
  @workers Application.fetch_env!(:hive, :workers)

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false


    # Define workers and child supervisors to be supervised
    children = [
      worker(Hive.Registry, [])
      # worker(Hive.Chaos, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hive.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def pg2_group, do: @pg2_group
  def random_worker, do: :"worker_#{:rand.uniform(@workers)}"

  def connect_nodes do
    ["a", "b", "c"]
    |> Enum.map(& Node.connect(:"#{&1}@127.0.0.1"))
  end
end

#####

# Task.async(fn ->
#   Node.spawn(:"b@127.0.0.1", fn -> System.get_env("ROLE") end)
# end) |> Task.await()

# Node.spawn_link(:"b@127.0.0.1", fn ->
#   receive do
#     {:ping, client} ->
#       role = System.get_env("ROLE")
#       send client, role
#   end
# end)
