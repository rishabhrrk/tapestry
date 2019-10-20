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
    {:reply, :ok, state}
  end

  # get state of every node
  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

end
