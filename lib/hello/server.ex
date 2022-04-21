defmodule Hello.Server do
  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    self_node = inspect(node())
    nodes = inspect(Node.list())

    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, "nodes: #{nodes}, self: #{self_node}")
  end
end
