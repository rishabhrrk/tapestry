defmodule Tapestry.Modules do
  def encode_multiple(pids) do
    all_hash_list = []
    Enum.each(pids, fn pid ->
      hash = encode_single(inspect(pid))
      :ets.insert(:pid_to_hash, {pid, hash})
      :ets.insert(:hash_to_pid, {hash, pid})
    end)
  end

  def encode_single(key) do
    :crypto.hash(:sha, key) |> Base.encode16
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
    index = Enum.find_index(0..String.length(word1), fn x ->
      String.at(word1, x) != String.at(word2, x)
    end)
    
    if index, do: String.slice(word1, 0, index), else: word1
  end

end
