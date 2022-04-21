import Config

# Configures Elixir's Logger
config :logger, :console, format: "$time $metadata[$level] $message\n"

#config :mnesia,
#  stores: [Hello.Store]
#  #schema_type: :disc_copies

import_config "#{config_env()}.exs"
