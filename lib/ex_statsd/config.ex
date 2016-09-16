defmodule ExStatsD.Config do
  @moduledoc """
  Configuration parsing for statsd gen server, available options are:

   * `host`: The hostname or IP address (default: 127.0.0.1)
   * `port`: The port number (default: 8125)
   * `namespace`: The namespace to prefix all the keys (default: nil)
   * `sink` (default: nil)

  You can also use environment variables on runtime, just specify the name
  of variable in config like: `{:system, "ENV_VAR_NAME"}`. You can also pass
  in default value, i.e.: `{:system, "ENV_VAR_NAME", "some default"}`.
  """

  @default_port 8125
  @default_host "127.0.0.1"
  @default_namespace nil
  @default_sink nil

  @doc """
  Generates config map based on application configuration & environment variables.
  """
  def generate do
    %{
      port:      get(:port, @default_port),
      host:      get(:host, @default_host) |> parse_host,
      namespace: get(:namespace, @default_namespace),
      sink:      get(:sink, @default_sink),
      socket:    nil
    }
  end

  defp get(option, default) do
    Application.get_env(:ex_statsd, option, default)
    |> finalize
  end

  defp finalize({:system, var}) do
    System.get_env(var)
  end

  defp finalize({:system, var, default}) do
    case System.get_env(var) do
      nil -> default
      val -> val
    end
  end

  defp finalize(value) do
    value
  end

  defp parse_host(host) when is_binary(host) do
    case host |> to_char_list |> :inet.parse_address do
      {:error, _}    -> host |> String.to_atom
      {:ok, address} -> address
    end
  end
end