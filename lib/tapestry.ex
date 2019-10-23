defmodule Tapestry.CLI do
  @doc """
  Starter function called when run through mix run
  """
  def main do
    args = System.argv()
    main(args)
  end

  @doc """
  Starter function called when run through escript
  """
  def main(args) do
    if length(args) != 2 do
      print_help_msg()
      exit :shutdown
    end

    num_nodes = Enum.at(args, 0) |> String.to_integer
    num_requests = Enum.at(args, 1) |> String.to_integer

    # Start all nodes
    Tapestry.Supervisor.start_link(num_nodes)

    # Get all nodes' pids
    node_pids = Supervisor.which_children(Tapestry.Supervisor)
      |> Enum.map(fn {_, pid, :worker, [Tapestry.Node]} -> pid end)

    # Create a global ets for pid to node_id mapping
    :ets.new(:pid_to_hash, [:set, :public, :named_table])

    # Create a global ets for node_id to pid mapping
    :ets.new(:hash_to_pid, [:set, :public, :named_table])

    # Create a global ets for maintaining the number of hops
    :ets.new(:hops, [:set, :public, :named_table])
    :ets.insert(:hops, {"counter",0})

    # Populate the global ets' :pid_to_hash and :hash_to_pid
    Tapestry.Modules.encode_multiple(node_pids)

    # Construct a list of all the hashed pids
    all_hash_list = Enum.map(node_pids, fn pid ->
      [{_pid, hash}] = :ets.lookup(:pid_to_hash, pid)
      hash
    end)

    # Construct the routing tables from the hash list
    routing_tables = Tapestry.Modules.build_routing(all_hash_list)

    # Set the routing table in the state of each node
    Enum.each(routing_tables, fn {node, routing_table} ->
      [{_node, pid}] = :ets.lookup(:hash_to_pid, node)
      GenServer.call(pid, {:set_routing_table, routing_table})
    end)

    # Make each node make `num_requests` requests and store
    # the hops required in the :ets table :hops

    counters = Enum.reduce(node_pids, [], fn pid, counters ->
      
      counters_to_append = Enum.map(1..num_requests, fn _ ->
        :ets.insert(:hops, {"counter", 0})

        # Choose a random destination to make a request to
        destination = node_pids
          |> Enum.reject(&(&1 == pid))
          |> Enum.random

        [{_, destination_hash}] = :ets.lookup(:pid_to_hash, destination)

        GenServer.call(pid, {:destination, destination_hash})

        [{_, counter_value}] = :ets.lookup(:hops, "counter")
        counter_value
      end)

      counters_to_append ++ counters
    end)

    # Print the maximum hops a request took
    IO.puts "Max hops: #{Enum.max(counters)}"
  end

  defp print_help_msg do
    IO.puts "Usage: mix run application.exs num_nodes num_requests"
  end
end
