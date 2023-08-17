defmodule CajuWhats.GPTClient do
  use HTTPoison.Base
  require Logger

  @chatgpt_url "https://api.openai.com/v1/chat/completions"

  defp api_key do
    Application.fetch_env!(:caju_whats, :openai_key)
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

    response = HTTPoison.post(@chatgpt_url, Jason.encode!(payload), headers(), recv_timeout: 20_000)
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
      Logger.info("Received response: #{inspect(response_body)}")
        {:ok, extract_content(Jason.decode!(response_body))}
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        Logger.error("Error on GPT response: #{inspect(response)}")
        {:error, "Houve um erro: #{status_code}"}
      {:error, reason} ->
        Logger.error("Error on GPT response: #{inspect(response)}")
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
