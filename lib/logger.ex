defmodule CloudLogger do
  @moduledoc """
  A backend for the Elixir `Logger` that logs message as structured logs compatible with
  Google Cloud Logging.

    See https://cloud.google.com/logging/docs/structured-logging#special-payload-fields

  Error-level logs will be added the `ReportedErrorEvent` type to expose the error in Google Error
  Reporting.

    See https://cloud.google.com/error-reporting/docs/formatting-error-messages#@type

  > Heavily inspired by the [Ink](https://github.com/ivx/ink)
  > and [logger_json](https://github.com/Nebo15/logger_json) projects.
  """
  import Jason.Helpers, only: [json_map: 1]
  require Timex

  @behaviour :gen_event

  @googleErrorType "type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent"

  @severity_levels %{
    :debug => "DEBUG",
    :info => "INFO",
    :warn => "WARNING",
    :error => "ERROR"
  }

  def init(__MODULE__) do
    {:ok, configure(Application.get_env(:logger, CloudLogger, []), default_options())}
  end

  def handle_call({:configure, options}, state) do
    {:ok, :ok, configure(options, state)}
  end

  def handle_event({_level, gl, {Logger, _, _, _}}, state)
      when node(gl) != node() do
    {:ok, state}
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  def handle_event({level, _, {Logger, message, timestamp, metadata}}, state) do
    %{level: log_level} = state

    case meet_level?(level, log_level) do
      true -> {:ok, log_message(message, level, timestamp, metadata, state)}
      false -> {:ok, state}
    end
  end

  def handle_info(_msg, state) do
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  def code_change(_old, state, _extra) do
    {:ok, state}
  end

  defp configure(options, state) do
    state
    |> Map.merge(Enum.into(options, %{}))
  end

  defp default_options do
    %{
      io_device: :stdio,
      level: :debug,
      name: "bidder",
      version: "unknown"
    }
  end

  defp meet_level?(_lvl, nil), do: true
  defp meet_level?(lvl, min), do: Logger.compare_levels(lvl, min) != :lt

  defp log_message(message, level, timestamp, metadata, config) do
    structured_log = format_event(message, level, timestamp, metadata, config)
    IO.puts(config.io_device, structured_log)
    config
  end

  defp format_event(message, level, timestamp, metadata, config) do
    # Formats the event as a "structured log" for GKE.
    # See https://cloud.google.com/logging/docs/structured-logging
    {:ok, time} =
      timestamp
      |> Timex.to_datetime()
      |> Timex.format("{RFC3339}")

    %{
      severity: Map.get(@severity_levels, level, "DEFAULT"),
      message: IO.chardata_to_string(message),
      time: time,
      context: Keyword.get(metadata, :bidder, %{})
    }
    |> Map.put(:"logging.googleapis.com/labels", %{
      name: config.name,
      version: config.version
    })
    |> Map.put(:"logging.googleapis.com/sourceLocation", format_source_location(metadata))
    |> maybe_put_error_type(level)
    |> Jason.encode_to_iodata!()
  end

  defp format_source_location(metadata) do
    file = Keyword.get(metadata, :file)
    line = Keyword.get(metadata, :line, 0)
    function = Keyword.get(metadata, :function)
    module = Keyword.get(metadata, :module)

    json_map(
      file: file,
      line: line,
      function: format_function(module, function)
    )
  end

  defp format_function(nil, function), do: function
  defp format_function(module, function), do: "#{module}.#{function}"

  defp maybe_put_error_type(map, :error), do: Map.put(map, "@type", @googleErrorType)
  defp maybe_put_error_type(map, _level), do: map
end
