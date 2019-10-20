defmodule Tapestry.Modules do
    def encrypt_multiple(node_ids) do
        all_hash_list = []
        Enum.map(node_ids, fn node_id ->
            encryted_value = encrypt_single(inspect(node_id))
            :ets.insert(:pid_to_node,{node_id, encryted_value})
            :ets.insert(:node_to_pid,{encryted_value, node_id})
        end)
    end

    def encrypt_single(key) do
        :crypto.hash(:sha,key) |> Base.encode16
    end

    def build_routing(all_hash_list) do
        for hash_value <- all_hash_list do
            neighbours =
            for node <- all_hash_list, hash_value != node do
                    common_length = String.length(matching(hash_value,node))
                    {{common_length, String.at(node,common_length)}, node}
            end
            neighbours = Enum.into(neighbours,%{})
            {hash_value, neighbours}
        end
    end

    def matching(word1, word2) do
        min = word1
        max = word2
        index = Enum.find_index(0..String.length(min), fn x -> String.at(min,x) != String.at(max,x) end)
        if index, do: String.slice(min, 0, index), else: min
    end

end
