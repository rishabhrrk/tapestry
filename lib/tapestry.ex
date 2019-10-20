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

    numRequests = Enum.at(args, 1)

    # Start all nodes
    Tapestry.Supervisor.start_link(numNodes)

    # Get all nodes' pids
    node_pids = Supervisor.which_children(Tapestry.Supervisor)
        |> Enum.map(fn {_, pid, :worker, [Tapestry.Node]} -> pid end)

    # Create a global ets for pid to node_id mapping
    :ets.new(:pid_to_node, [:set, :public, :named_table])

    # Create a global ets for node_id to pid mapping
    :ets.new(:node_to_pid, [:set, :public, :named_table])

    # Call Brouting build function
    Tapestry.Modules.encrypt_multiple(node_pids)

    all_hash_list = Enum.reduce(node_pids,[], fn n, acc -> acc ++ [Enum.map(:ets.lookup(:pid_to_node, n), fn {no, hash} -> hash end)] end)
    all_hash_list = List.flatten(all_hash_list)
    neighbours = Tapestry.Modules.build_routing(all_hash_list)
    # IO.inspect neighbours
  end

  defp print_help_msg do
    IO.puts "Usage: mix run application.exs numNodes numRequests"

    # IO.puts "\nAvailable topologies:"
    # Enum.each @topologies, &(IO.puts("- #{&1}"))

    # IO.puts "\nAvailable algorithms:"
    # Enum.each @algorithms, &(IO.puts("- #{&1}"))
  end
end
