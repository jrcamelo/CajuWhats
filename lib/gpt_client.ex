defmodule GPTClient do
  use HTTPoison.Base

  @chatgpt_url "https://api.openai.com/v1/chat/completions"

  defp api_key do
    Application.fetch_env!(:your_app, :openai_key)
  end

  defp headers do
    [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> api_key()}
    ]
  end

  def chat(user_message, history_messages \\ [], opts \\ []) do
    default_messages = [
      %{"role" => "system", "content" => "Responda usando português brasileiro; Seja claro e objetivo, o usuário pode ser iniciante ou ter dificuldades de compreensão."},
      %{"role" => "user", "content" => user_message}
    ]

    messages = history_messages ++ default_messages

    payload = %{
      "model" => opts[:model] || "gpt-3.5-turbo",
      "messages" => messages,
      "temperature" => opts[:temperature] || 0.7,
      "max_tokens" => 1200
    }

    case HTTPoison.post(@chatgpt_url, Jason.encode!(payload), headers()) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        {:ok, extract_content(Jason.decode!(response_body))}
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "Houve um erro: #{status_code}"}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_content(response) do
    response["choices"]
    |> Enum.at(0)
    |> Map.get("message")
    |> Map.get("content")
  end
end
