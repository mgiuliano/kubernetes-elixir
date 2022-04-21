import Config

config :logger,
  backends: [CloudLogger]

config :logger, CloudLogger,
  name: "hello",
  level: :info,
  version: Mix.Project.config()[:version]

config :libcluster,
  topologies: [
    default: [
      strategy: Cluster.Strategy.Kubernetes.DNS,
      config: [
        service: "hello-nodes",
        application_name: "hello"
      ]
    ]
  ]
