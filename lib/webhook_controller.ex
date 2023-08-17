defmodule CajuWhats.WebhookController do
  import Plug.Conn
  require Logger

  def receive_message(conn) do
    {:ok, body, conn} = read_body(conn)
    params = Plug.Conn.Query.decode(body)
    Logger.info("Received new message: \"#{params["Body"]}\" from #{params["From"]}")

    case params["MediaUrl0"] do
      nil -> handle_text_message(params, conn)
      url -> handle_audio_message(params, url, conn)
    end
  end

  defp handle_text_message(params, conn) do
    user_message = params["Body"]
    user_id = params["From"]

    history_messages = CajuWhats.ChatHistory.get_messages(user_id)

    case CajuWhats.GPTClient.chat(user_message, history_messages) do
      {:ok, response} ->
        CajuWhats.ChatHistory.add_message(user_id, "user", user_message)
        CajuWhats.ChatHistory.add_message(user_id, "assistant", response)
        CajuWhats.TwilioClient.send_message(params["From"], params["To"], response)
        conn |> send_resp(200, "Success")

      {:error, _reason} ->
        error_message = "Houve um erro ao receber ou processar sua mensagem, tente novamente ou contate o desenvolvedor."
        CajuWhats.TwilioClient.send_message(params["From"], params["To"], error_message)
        conn |> send_resp(500, "Internal Server Error")
    end
  end

  defp handle_audio_message(params, url, conn) do
    message_sid = params["MessageSid"]
    original_file_path = "downloads/#{message_sid}"
    converted_file_path = original_file_path <> ".mp3"

    processing_result =
      with {:ok, audio_path} <- download_and_save_audio(url, message_sid),
           {:ok, converted_audio_path} <- convert_audio(audio_path),
           {:ok, transcription} <- CajuWhats.WhisperClient.transcribe(converted_audio_path) do
        process_audio_success(params, transcription, conn)
      else
        {:error, reason} -> process_audio_error(reason, params, conn)
      end

    clean_up_files(original_file_path, converted_file_path)

    case processing_result do
      {:ok, response_conn} -> response_conn
      {:error, response_conn} -> response_conn
    end
  end

  defp process_audio_success(params, transcription, conn) do
    user_id = params["From"]
    CajuWhats.ChatHistory.add_message(user_id, "assistant", transcription)

    Logger.info("Audio processed successfully")
    CajuWhats.TwilioClient.send_message(params["From"], params["To"], transcription)
    {:ok, conn |> send_resp(200, "Success")}
  end

  defp process_audio_error(reason, params, conn) do
    Logger.error("Error processing audio: #{reason}")
    CajuWhats.TwilioClient.send_message(params["From"], params["To"], "Houve um erro ao receber ou processar seu áudio, tente novamente ou contate o desenvolvedor.")
    {:error, conn |> send_resp(500, "Internal Server Error")}
  end

  defp clean_up_files(original_file_path, converted_file_path) do
    File.rm(original_file_path)
    File.rm(converted_file_path)
  end

  defp download_and_save_audio(url, message_sid) do
    Logger.info("Downloading audio from #{url}")

    case CajuWhats.TwilioClient.download_from_url(url) do
      {:ok, body, headers} ->
        file_size = headers |> List.keyfind("Content-Length", 0) |> elem(1) |> String.to_integer()
        max_file_size = 10_000_000 # Example: 10MB

        if file_size < max_file_size do
          file_path = "downloads/#{message_sid}"
          Logger.info("Saving audio to #{file_path}")
          File.write!(file_path, body)
          {:ok, file_path}
        else
          {:error, "File size exceeds the limit"}
        end
      {:error, reason} ->
        Logger.error("Error downloading audio from #{url}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp convert_audio(file_path) do
    Logger.info("Converting audio at #{file_path}")
    output_path = file_path <> ".mp3" # Converting to MP3
    cmd = "ffmpeg"
    args = ["-i", file_path, "-acodec", "libmp3lame", output_path]

    case System.cmd(cmd, args) do
      {_, 0} -> {:ok, output_path}
      {_, _} -> {:error, "Conversion failed"}
    end
  end
end
