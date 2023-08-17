defmodule ChatHistory do
  use GenServer

  @base_path "history"
  @max_length 10_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    File.mkdir_p!(@base_path)
    {:ok, %{}}
  end

  def add_message(user_id, role, content) do
    GenServer.call(__MODULE__, {:add_message, user_id, role, content})
  end

  def get_messages(user_id) do
    GenServer.call(__MODULE__, {:get_messages, user_id})
  end

  def handle_call({:add_message, user_id, role, content}, _from, state) do
    path = Path.join(@base_path, "#{user_id}.json")

    messages = case File.read(path) do
      {:ok, content} -> Jason.decode!(content)
      {:error, :enoent} -> []
    end

    new_messages = case messages do
      [%{"content" => last_content} | _] when last_content == content and role == "user" ->
        # Replace the last message with a new "user" role
        List.replace_at(messages, -1, %{"role" => role, "content" => content})
      _ ->
        trim_messages(messages ++ [%{"role" => role, "content" => content}])
    end

    File.write!(path, Jason.encode!(new_messages))

    {:reply, :ok, state}
  end

  def handle_call({:get_messages, user_id}, _from, state) do
    path = Path.join(@base_path, "#{user_id}.json")
    messages = case File.read(path) do
      {:ok, content} -> Jason.decode!(content)
      {:error, :enoent} -> []
    end

    {:reply, messages, state}
  end

  defp trim_messages(messages) do
    length_fun = fn msg, acc -> String.length(msg["content"]) + String.length(msg["role"]) + 34 + acc end
    total_length = Enum.reduce(messages, 0, length_fun)

    if total_length > @max_length do
      messages
      |> tl()
      |> trim_messages()
    else
      messages
    end
  end
end
