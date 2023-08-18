defmodule CajuWhats.TwilioClient do
  use HTTPoison.Base
  require Logger

  @twilio_url "https://api.twilio.com/2010-04-01/Accounts/AC23bf52cbca125a4c92d7268e3f28d82f/Messages.json"

  defp auth_token do
    "Basic " <> Base.encode64("AC23bf52cbca125a4c92d7268e3f28d82f:" <> Application.fetch_env!(:caju_whats, :twilio_auth_token))
  end

  defp headers do
    [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", auth_token()}
    ]
  end

  def send_message(to, from, message_body, retry_count \\ 0) do
    max_retries = 2

    payload = [
      {"To", to},
      {"From", from},
      {"Body", message_body}
    ]
    payload_encoded = URI.encode_query(payload)

    case post(@twilio_url, payload_encoded, headers()) do
      {:ok, %HTTPoison.Response{status_code: code}} when code in 200..399 ->
        Logger.info("Message sent successfully to #{to}")
        :ok
      {:ok, %HTTPoison.Response{status_code: 429}} when retry_count < max_retries ->
        Logger.warn("Got a 429 when talking to #{to}, waiting 3 seconds + #{retry_count * 3} seconds")
        :timer.sleep(3000 + (3000 * retry_count))
        send_message(to, from, message_body, retry_count + 1)
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Failed to send message to #{to}: Status code #{status_code}, Body: #{body}")
        {:error, status_code}
      {:error, reason} ->
        Logger.error("Failed to send message to #{to}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def download_from_url(url) do
    requestHeaders = [
      {"Authorization", auth_token()}
    ]
    response = HTTPoison.get(url, requestHeaders, follow_redirect: true)
    case response do
      {:ok, %HTTPoison.Response{status_code: code, body: body, headers: headers}} when code in 200..399 ->
        {:ok, body, headers}
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "Received unexpected status code #{status_code}"}
      {:error, reason} ->
        {:error, reason}
    end
  end
end
