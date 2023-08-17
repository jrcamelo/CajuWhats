defmodule CajuWhats do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting application...")

    children = [
      {Plug.Cowboy, scheme: :http, plug: CajuWhats.Router, options: [port: 4000]},
      CajuWhats.ChatHistory
    ]

    Logger.info("Starting supervisor...")
    opts = [strategy: :one_for_one, name: CajuWhats.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
