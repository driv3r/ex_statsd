defmodule TestSupport do
  def var, do: "5689bec05b9b4acba45ddc2a0a61d693_exstasd_test"

  def with_sys(value, func) do
    System.put_env(var, value)
    func.()
  after
    System.delete_env(var)
  end

  def with_app(name, func) do
    with_app name, Application.get_env(:ex_statsd, name), func
  end

  def with_app(name, old, func) do
    Application.put_env(:ex_statsd, name, {:system, var})
    func.()
  after
    Application.put_env(:ex_statsd, name, old)
  end
end

ExUnit.start()
