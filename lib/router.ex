defmodule CajuWhats.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  post "/webhook" do
    conn
    |> CajuWhats.WebhookController.receive_message()
  end

  get "/" do
    conn
    |> send_resp(200, "App is running")
  end

  # Ignore favicon.ico requests
  match _ do
    conn
    |> send_resp(404, "Not Found")
  end
end
