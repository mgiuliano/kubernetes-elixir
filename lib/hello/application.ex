defmodule Hello.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      case Application.get_env(:libcluster, :topologies) do
        nil -> []
        topologies ->
          [
            {Cluster.Supervisor, [topologies, [name: Hello.ClusterSupervisor]]},
          ]
      end

    port = get_free_port(8080)
    IO.puts("Running on port #{port}")
    children =
      children ++ [
        {Hello.EventStore, []},
        {Plug.Cowboy, scheme: :http, plug: Hello.Server, options: [port: port]}
      ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hello.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp get_free_port(start) do
    case :gen_tcp.listen(start, [:binary]) do
      {:ok, socket} ->
        :ok = :gen_tcp.close(socket)
        start

      {:error, :eaddrinuse} ->
        get_free_port(start + 1)
    end
  end
end
