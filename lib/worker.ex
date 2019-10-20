defmodule Tapestry.Node do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

end
