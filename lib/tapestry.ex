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

    numNodes = args |> Enum.at(0) |> String.to_integer

    numRequests = Enum.at(args, 1) |> String.to_integer

    # Start all nodes
    Tapestry.Supervisor.start_link(numNodes)

    # Get all nodes' pids
    node_pids = Supervisor.which_children(Tapestry.Supervisor)
      |> Enum.map(fn {_, pid, :worker, [Tapestry.Node]} -> pid end)

    # Create a global ets for pid to node_id mapping
    :ets.new(:pid_to_node, [:set, :public, :named_table])

    # Create a global ets for node_id to pid mapping
    :ets.new(:node_to_pid, [:set, :public, :named_table])

    # Create a global ets for maintaining the number of hops
    :ets.new(:hops, [:set, :public, :named_table])
    :ets.insert(:hops, {"counter",0})

    # Populate the global ets' :pid_to_node and :node_to_pid
    Tapestry.Modules.encode_multiple(node_pids)

    # Construct a list of all the hashed pids
    all_hash_list = Enum.map(node_pids, fn pid ->
      [{_pid, hash}] = :ets.lookup(:pid_to_node, pid)
      hash
    end)

    # Construct the routing tables from the hash list
    routing_tables = Tapestry.Modules.build_routing(all_hash_list)

    # Set the routing table in the state of each node
    Enum.each(routing_tables, fn {node, routing_table} ->
      [{_node, pid}] = :ets.lookup(:node_to_pid, node)
      GenServer.call(pid, {:set_routing_table, routing_table})
    end)

    # Construct a list of all hops between all source and all destination
    counter_list = []
    counter_list = counter_list ++ List.flatten(
      # Select one node from list of nodes to start sending messages
      # this node will be source
      Enum.map(node_pids, fn pid ->
        # Construct a list of all hops between one source and one destination
          intermediate_list = []
          # Randomly select numRequests nodes from the list as destinations
          counter_each_request = Enum.map(1..numRequests, fn _n ->
            # Set the counter to be zero in the beginning,
                :ets.insert(:hops, {"counter", 0})
            # Select a destination randomly
                destination_list = node_pids
                  |> Enum.reject(&(&1 == pid))
                random_destination =
                  Enum.random(destination_list)
                destination = :ets.lookup(:pid_to_node,
                  random_destination)
                [{_, destination_hash}] = destination
            # Call worker node with a destination as message
                GenServer.call(pid, {:destination, destination_hash})
            # Lookup the counter to store in the intermediate list
                [Enum.at(Enum.map(:ets.lookup(:hops, "counter"),
                           fn {_, count} -> count end),0)]
                            end)
                intermediate_list = intermediate_list ++
                  List.flatten(counter_each_request)
                intermediate_list
      end))
    IO.puts "Max Hops: "
    IO.inspect Enum.max(counter_list)
  end

  defp print_help_msg do
    IO.puts "Usage: mix run application.exs numNodes numRequests"

    # IO.puts "\nAvailable topologies:"
    # Enum.each @topologies, &(IO.puts("- #{&1}"))

    # IO.puts "\nAvailable algorithms:"
    # Enum.each @algorithms, &(IO.puts("- #{&1}"))
  end
end
