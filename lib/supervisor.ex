defmodule Tapestry.Supervisor do
    use Supervisor

    @default_node_state %{
        counter: 0
    }

    def start_link(opts) do
        Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
    end

    @impl true
    def init(num_nodes) do
        nodes = Enum.map(1..num_nodes, fn i ->
            Supervisor.child_spec({Tapestry.Node,@default_node_state}, id: i)
        end)
        Supervisor.init(nodes, strategy: :one_for_one)
    end
end
