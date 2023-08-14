import Config

config :caju_whats, CajuWhats,
  port: 4000

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger, level: :info
