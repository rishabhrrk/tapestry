defmodule Tapestry.Node do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @doc """
  Sets routing table for q node in its state
  """
  @impl true
  def handle_call({:set_routing, routing}, _from, state) do
    # update map of routing table in the state
    state = Map.put(state, :routing_table, routing)
    # IO.inspect(state)
    {:reply, state, state}
  end

  # get state of every node
  @impl true
  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end

  # cast function for hopping
  @impl true
  def handle_call({:destination, destination_hash}, _from, state) do
    counter = Enum.at(Enum.map(:ets.lookup(:hops, "counter"), fn {_, count} -> count end),0)
    # counter = 0
    # IO.inspect counter
    if counter < 10 do
      # updating the counter
      :ets.insert(:hops, {"counter",counter+1})

      #find hash of source
      source = :ets.lookup(:pid_to_node, self())
      [{_,source_hash}] = source
      # IO.puts("source")
      # IO.inspect source_hash

      #find how many characters are common between source and destination
      common_length = String.length(Tapestry.Modules.matching(source_hash, destination_hash))
      routing_table = state[:routing_table]
      value_at_index = routing_table[{common_length, String.at(destination_hash,common_length)}]
      # IO.puts("value")
      # IO.inspect value_at_index
      # IO.puts("dest")
      # IO.inspect destination_hash
      if value_at_index == destination_hash do
        # IO.puts "done"
        :ets.insert(:hops, {"counter",counter+2})
        # IO.inspect :ets.lookup(:hops, "counter")
        {:reply, state, state}
      else
        pid = Enum.map(:ets.lookup(:node_to_pid, value_at_index), fn {_, pid} -> pid end)
        GenServer.call(Enum.at(pid, 0), {:destination, destination_hash})
      end
      # IO.inspect(value_at_index)
    end
    {:reply, state, state}
  end

end
