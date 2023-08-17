defmodule CajuWhats.TwilioClient do
  use HTTPoison.Base

  @twilio_url "https://api.twilio.com/2010-04-01/Accounts/AC23bf52cbca125a4c92d7268e3f28d82f/Messages.json"

  defp key do
    Application.fetch_env!(:caju_whats, :openai_key)
  end

  defp auth_token do
    "Basic " <> Base.encode64("AC23bf52cbca125a4c92d7268e3f28d82f:" <> Application.fetch_env!(:caju_whats, :twilio_auth_token))
  end

  defp headers do
    [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", auth_token()}
    ]
  end

  def send_message(to, from, body) do
    payload = [
      {"To", to},
      {"From", from},
      {"Body", body}
    ]
    payload_encoded = URI.encode_query(payload)

    post(@twilio_url, payload_encoded, headers())
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
