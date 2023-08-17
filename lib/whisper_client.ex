defmodule CajuWhats.WhisperClient do
  use HTTPoison.Base

  @whisper_url "https://api.openai.com/v1/audio/transcriptions"

  defp api_key do
    Application.fetch_env!(:caju_whats, :openai_key)
  end

  defp headers do
    [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> api_key()}
    ]
  end

  def transcribe(audio_path) do
    multipart = [
      {:file, audio_path, [{"content-type", "audio/mp3"}]},
      {"language", "pt"},
      {"model", "whisper-1"},
      {"response_format", "text"}
    ]

    case HTTPoison.post("#{@whisper_url}", {:multipart, multipart}, headers()) do
      {:ok, %HTTPoison.Response{status_code: 200, body: transcription}} ->
        {:ok, transcription}
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "Received unexpected status code #{status_code}"}
      {:error, reason} ->
        {:error, reason}
    end
  end
end
