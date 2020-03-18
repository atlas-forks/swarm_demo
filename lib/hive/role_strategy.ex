defmodule Hive.Distribution.LabledRing do
   @moduledoc """
  A quorum is the minimum number of nodes that a distributed cluster has to
  obtain in order to be allowed to perform an operation. This can be used to
  enforce consistent operation in a distributed system.
  ## Quorum size
  You must configure this distribution strategy and specify its minimum quorum
  size:
      config :swarm,
        distribution_strategy: Swarm.Distribution.StaticQuorumRing,
        static_quorum_size: 5
  It defines the minimum number of nodes that must be connected in the cluster
  to allow process registration and distribution.
  If there are fewer nodes currently available than the quorum size, any calls
  to `Swarm.register_name/5` will return `{:error, :no_node_available}` until
  enough nodes have started.
  You can configure the `:kernel` application to wait for cluster formation
  before starting your application during node start up. The
  `sync_nodes_optional` configuration specifies which nodes to attempt to
  connect to within the `sync_nodes_timeout` window, defined in milliseconds,
  before continuing with startup. There is also a `sync_nodes_mandatory` setting
  which can be used to enforce all nodes are connected within the timeout window
  or else the node terminates.
      config :kernel,
        sync_nodes_optional: [:"node1@192.168.1.1", :"node2@192.168.1.2"],
        sync_nodes_timeout: 60_000
  The `sync_nodes_timeout` can be configured as `:infinity` to wait indefinitely
  for all nodes to connect. All involved nodes must have the same value for
  `sync_nodes_timeout`.
  ### Example
  In a 9 node cluster you would configure the `:static_quorum_size` as 5. During
  a network split of 4 and 5 nodes, processes on the side with 5 nodes
  will continue running, whereas processes on the other 4 nodes will be stopped.
  Be aware that in the running 5 node cluster, no more failures can be handled
  because the remaining cluster size would be less than the required 5 node
  minimum. All running processes would be stopped in the case of another single
  node failure.
  """

  use Swarm.Distribution.Strategy

  alias Hive.Distribution.LabledRing

  defstruct [:nodes]

  def create do
    IO.inspect("create")
    %LabledRing{
      nodes: []
    }
  end

  def add_node(quorum, node) do
    IO.inspect("add_node/2 #1")
    role = :rpc.call(node, System, :get_env, ["ROLE"])
    info = %{node: node, role: role}

    IO.inspect(quorum, label: "quorum")
    IO.inspect(node, label: "node")

    %LabledRing{
      nodes: [info | quorum.nodes]
    }
  end

  def add_node(quorum, _node, _weight) do
    IO.inspect("add_node/2 #2")

    %LabledRing{
      nodes: quorum.nodes
    }
  end

  def add_nodes(quorum, nodes) do
    IO.inspect("add_nodes/2")

    IO.inspect(quorum, label: "quorum")
    IO.inspect(nodes, label: "nodes")

    %LabledRing{
      nodes: quorum.nodes
    }
  end

  def remove_node(quorum, node) do
    IO.inspect("remove_node/2")
    IO.inspect(node, label: "remove_node")

    %LabledRing{
      nodes: Enum.filter(quorum.nodes, & &1.node == node)
    }
  end

  @doc """
  Maps a key to a specific node via the current distribution strategy.
  If the available nodes in the cluster are fewer than the minimum node count it returns `:undefined`.
  """
  def key_to_node(%LabledRing{nodes: nodes}, map_key) do
    # case length(ring.nodes) do
    #   node_count when node_count < static_quorum_size -> :undefined
    #   _ -> HashRing.key_to_node(ring, key)
    # end

    avail_nodes =
      nodes
      |> Enum.filter(& &1.role == map_key.role)

    IO.inspect("key_to_node/2")
    IO.inspect(nodes, label: "nodes")
    IO.inspect(map_key)
    IO.inspect(avail_nodes)

    case Enum.count(avail_nodes) > 0 do
      false -> :undefined
      true ->
        %{node: node} = Enum.at(avail_nodes, 0)
        node
    end
  end

  # defp static_quorum_size() do
  #   Application.get_env(:swarm, :static_quorum_size, 2)
  #   |> static_quorum_size()
  # end

  # defp static_quorum_size(nil), do: static_quorum_size(2)

  # defp static_quorum_size(binary) when is_binary(binary) do
  #   binary
  #   |> Integer.parse()
  #   |> convert_to_integer()
  #   |> static_quorum_size()
  # end

  # defp static_quorum_size(size) when is_integer(size) and size > 0, do: size

  # defp static_quorum_size(_size),
  #   do: raise("config :static_quorum_size should be a positive integer")

  # defp convert_to_integer({integer, _}) when is_integer(integer), do: integer
  # defp convert_to_integer(other), do: other
end
