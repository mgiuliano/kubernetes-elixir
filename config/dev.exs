import Config

config :logger, :console,
  format: "[$level] $message\n",
  level: :debug

config :libcluster,
  topologies: [
    default: [
      strategy: Cluster.Strategy.Epmd,
      config: [
        hosts: [:"a@localhost", :"b@localhost"]
      ]
    ]
  ]

