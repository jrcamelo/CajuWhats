import Config
import Dotenvy
source!(".env")

config :caju_whats,
  openai_key: env!("OPENAI_KEY", :string),
  twilio_auth_token: env!("TWILIO_AUTH_TOKEN", :string)
