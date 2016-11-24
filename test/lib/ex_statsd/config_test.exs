defmodule ExStatsD.ConfigTest do
  use ExUnit.Case

  test "merge: default values merged with ex_statsd app config" do
    assert ExStatsD.Config.merge([sink: "foo"]) === %{
      port: 8125,
      host: {127, 0, 0, 1},
      namespace: "test",
      sink: "foo",
      socket: nil,
      tags: []
    }
  end

  test "merge: when using system env vars" do
    with_sys "foo,bar,baz", fn ->
      with_app :tags, {:system, var}, fn ->
        config = ExStatsD.Config.merge([])
        assert config[:tags] === ~w(foo bar baz)
      end
    end
  end

  test "merge: when system var is empty" do
    with_app :tags, {:system, var}, fn ->
      config = ExStatsD.Config.merge([])
      assert config[:tags] === []
    end
  end

  test "merge: when system var and options were given, returns options" do
    with_sys "foo,bar,baz", fn ->
      with_app :tags, {:system, var}, fn ->
        config = ExStatsD.Config.merge([tags: ~w(db perf)])
        assert config[:tags] === ~w(db perf)
      end
    end
  end

  test "merge: parses host correctly" do
    with_sys "localhost", fn ->
      with_app :host, {:system, var}, fn ->
        config = ExStatsD.Config.merge([])
        assert config[:host] === :localhost
      end
    end

    assert ExStatsD.Config.merge(host: "statsd")[:host] === :statsd
    assert ExStatsD.Config.merge(host: "52.32.124.24")[:host] === {52, 32, 124, 24}
    assert ExStatsD.Config.merge(host: nil)[:host] === {127, 0, 0, 1}
  end

  test "merge: when host is empty, uses default host" do
    with_app :host, {:system, var}, fn ->
      config = ExStatsD.Config.merge([])
      assert config[:host] === {127, 0, 0, 1}
    end
  end

  defp var, do: "5689bec05b9b4acba45ddc2a0a61d693_exstasd_test"

  defp with_sys(value, func) do
    System.put_env(var, value)
    func.()
  after
    System.delete_env(var)
  end

  defp with_app(name, val, func) do
    with_app name, val, Application.get_env(:ex_statsd, name), func
  end

  defp with_app(name, val, old, func) do
    Application.put_env(:ex_statsd, name, val)
    func.()
  after
    Application.put_env(:ex_statsd, name, old)
  end
end
