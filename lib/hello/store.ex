defmodule Hello.EventStore do
  use GenServer
  require Logger

  defmodule Event do
    defstruct [
      :id,
      :name,
      caretaker_id: nil
    ]

    def decode({__MODULE__, id, name, caretaker_id}) do
      %__MODULE__{
        id: id,
        name: name,
        caretaker_id: caretaker_id
      }
    end

    def encode(%__MODULE__{
      id: id,
      name: name,
      caretaker_id: caretaker_id
    }) do
      {__MODULE__, id, name, caretaker_id}
    end
  end

  @impl true
  def init(state) do
    :net_kernel.monitor_nodes(true)
    IO.inspect(connect_mnesia_to_cluster())
    {:ok, state}
  end

  @impl true
  def handle_info({:nodeup, node}, state) do
    Logger.info("Node connected: #{inspect node}")
    :ok = connect_mnesia_to_cluster()
    {:noreply, state}
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    Logger.info("Node disconnected: #{inspect node}")
    update_mnesia_nodes()
    {:noreply, state}
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def list() do
    {:atomic, list} = :mnesia.transaction(fn ->
      :mnesia.match_object({Event, :_, :_, :_})
    end)

    list |> Enum.map(fn x -> Event.decode(x) end)
  end

  def create(%Event{id: id} = state) when is_integer(id) do
    IO.puts("Inserting #{inspect state}")

    {:atomic, reason} = :mnesia.transaction(fn ->
      case :mnesia.read(Event, id, :write) do
        [] ->
          Event.encode(state) |> :mnesia.write()
        _ ->
          :record_exists
      end
    end)

    reason
  end

  defp connect_mnesia_to_cluster() do
    :ok = ensure_schema_exists()
    :ok = :mnesia.start()
    :ok = ensure_table_exists()

    Logger.debug("Nodes in cluster: #{Node.list()}")
    #{:ok, nodes} = :mnesia.change_config(:extra_db_nodes, Node.list())
    #Logger.debug("Added extra nodes: #{ inspect nodes }")

    :mnesia.change_table_copy_type(:schema, node(), :disc_copies)
    #:ok = ensure_table_copy_exists()

    IO.puts("Successfully connected Mnesia to the cluster!")

    :ok
  end

  defp update_mnesia_nodes do
    nodes = Node.list()
    IO.puts("Updating Mnesia nodes with #{inspect nodes}")
    :mnesia.change_config(:extra_db_nodes, nodes)
  end

  defp ensure_schema_exists() do
    case :mnesia.create_schema([node()]) do
      {:error, {_node, {:already_exists, __node}}} ->
        :ok

      :ok -> :ok
    end
  end

  defp ensure_table_exists() do
    :mnesia.create_table(
      Event,
      [
        attributes: [
          :id,
          :name,
          :caretaker_id
        ],
        disc_copies: [node()]
      ]
    )
    |> case do
      {:atomic, :ok} ->
        :ok
      {:aborted, {:already_exists, Event}} ->
        :ok
    end

    :ok = :mnesia.wait_for_tables([Event], 5_000)
  end

  defp ensure_table_copy_exists() do
    case :mnesia.add_table_copy(Event, node(), :disc_copies) do
      {:atomic, :ok} -> :ok
      {:aborted, {:already_exists, Event, _node}} -> :ok
    end
  end

end
