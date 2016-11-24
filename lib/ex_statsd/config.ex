defmodule ExStatsD.Config do
  @moduledoc """
  Configuration parsing for statsd gen server, available options are:

   * `host`: The hostname or IP address (default: 127.0.0.1)
   * `port`: The port number (default: 8125)
   * `namespace`: The namespace to prefix all the keys (default: nil)
   * `tags`: The tags to use in all requests - part of dogstatd extension (default: [])
             When storing in env var, divide by commas.
   * `sink` (default: nil)

  You can also use environment variables on runtime, just specify the name
  of variable in config like: `{:system, "ENV_VAR_NAME"}`. You can also pass
  in default value, i.e.: `{:system, "ENV_VAR_NAME", "some default"}`.
  """

  @defaults %{
    port: 8125,
    host: "127.0.0.1",
    namespace: nil,
    tags: [],
    sink: nil
  }

  @doc """
  Generates config map based on application configuration, environment variables and given options.
  """
  def merge(options) do
    %{
      port:      fetch(options, :port) |> parse_port,
      host:      fetch(options, :host) |> parse_host,
      tags:      fetch(options, :tags) |> parse_tags,
      namespace: fetch(options, :namespace),
      sink:      fetch(options, :sink),
      socket:    nil
    }
  end

  defp fetch(list, key) do
    Keyword.get(
      list,
      key,
      ConfigExt.get_env(:ex_statsd, key, @defaults[key])
    )
  end

  defp parse_port(port) when is_integer(port), do: port
  defp parse_port(port) when is_bitstring(port), do: port |> String.to_integer
  defp parse_port(_), do: @defaults[:port]

  defp parse_host(host) when is_binary(host) do
    case host |> to_char_list |> :inet.parse_address do
      {:error, _}    -> host |> String.to_atom
      {:ok, address} -> address
    end
  end

  defp parse_host(_), do: parse_host(@defaults[:host])

  defp parse_tags(nil), do: []
  defp parse_tags(""),  do: []
  defp parse_tags(tags) when is_binary(tags), do: tags |> String.split(",")
  defp parse_tags(tags), do: tags
end
