defmodule ExStatsD do
  @moduledoc """
  Settings are taken from the `ex_statsd` application configuration.
  See `ExStatsD.Config` for all the options.
  """

  use GenServer

  @timing_stub 1.234

  # CLIENT

  @doc """
  Start the server.
  """
  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, ExStatsD.Config.generate, [name: __MODULE__] ++ options)
  end

  @doc """
  Stop the server.
  """
  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  @doc """
  Ensure the metrics are sent.
  """
  @spec flush :: :ok
  def flush do
    GenServer.call(__MODULE__, :flush)
  end


  # API

  @doc """
  Record a counter metric.

  * `sample_rate`: Limit how often the metric is collected
  * `tags`: Add tags to entry (DogStatsD-only)

  It returns the amount given as its first argument, making it suitable
  for pipelining.
  """
  def counter(amount, metric, options \\ [sample_rate: 1, tags: []]) do
    sampling options, fn(decision) ->
      case decision do
        {:sample, rate} ->
          {metric, amount, :c} |> transmit(options, rate)
          amount
        _ ->
          amount
      end
    end
  end

  @doc """
  Record the Enum.count/1 of an enumerable.

  * `sample_rate`: Limit how often the metric is collected
  * `tags`: Add tags to entry (DogStatsD-only)

  It returns the collection given as its first argument, making it suitable for
  pipelining.
  """
  def count(collection, metric, options \\ [sample_rate: 1, tags: []]) do
    value = collection |> Enum.count
    sampling options, fn(decision) ->
      case decision do
        {:sample, rate} ->
          {metric, value, :c} |> transmit(options, rate)
          collection
        _ ->
          collection
      end
    end
  end

  @doc """
  Record an increment to a counter metric.

  * `sample_rate`: Limit how often the metric is collected
  * `tags`: Add tags to entry (DogStatsD-only)

  Returns `nil`.
  """
  def increment(metric, options \\ [sample_rate: 1, tags: []]) do
    1 |> counter(metric, options)
    nil
  end

  @doc """
  Record a decrement to a counter metric.

  * `sample_rate`: Limit how often the metric is collected
  * `tags`: Add tags to entry (DogStatsD-only)

  Returns `nil`.
  """
  def decrement(metric, options \\ [sample_rate: 1, tags: []]) do
    -1 |> counter(metric, options)
    nil
  end

  @doc """
  Record a gauge entry.

  * `tags`: Add tags to entry (DogStatsD-only)

  It returns the amount given as its first argument, making it suitable
  for pipelining.
  """
  def gauge(amount, metric, options \\ [tags: []]) do
    {metric, amount, :g} |> transmit(options)
    amount
  end

  @doc """
  Record a set metric.

  * `tags`: Add tags to entry (DogStatsD-only)

  It returns the value given as its first argument, making it suitable
  for pipelining.
  """
  def set(member, metric, options \\ [tags: []]) do
    {metric, member, :s} |> transmit(options)
    member
  end

  @doc """
  Record a timer metric.

  * `sample_rate`: Limit how often the metric is collected
  * `tags`: Add tags to entry (DogStatsD-only)

  It returns the value given as its first argument, making it suitable
  for pipelining.
  """
  def timer(amount, metric, options \\ [sample_rate: 1, tags: []]) do
    sampling options, fn(decision) ->
      case decision do
        {:sample, rate} ->
          {metric, amount, :ms} |> transmit(options, rate)
          amount
        _ ->
          amount
      end
    end
  end

  @doc """
  Measure a function call.

  * `sample_rate`: Limit how often the metric is collected
  * `tags`: Add tags to entry (DogStatsD-only)

  It returns the result of the function call, making it suitable
  for pipelining.
  """
  def timing(metric, fun, options \\ [sample_rate: 1, tags: []]) do
    sampling options, fn(decision) ->
      case decision do
        {:sample, rate} ->
          {time, value} = :timer.tc(fun)
          amount = time / 1000.0
          # We should hard code the amount when we are in test mode.
          amount = if Application.get_env(:ex_statsd, :test_mode, false), do: @timing_stub, else: amount
          {metric, amount, :ms} |> transmit(options, rate)
          value
        _ ->
          fun.()
      end
    end
  end

  @doc """
  Record a histogram value (DogStatsD-only).

  * `sample_rate`: Limit how often the metric is collected
  * `tags`: Add tags to entry (DogStatsD-only)

  It returns the value given as the first argument, making it suitable for
  pipelining.
  """
  def histogram(amount, metric, options \\ [sample_rate: 1, tags: []]) do
    sampling options, fn(decision) ->
      case decision do
        {:sample, rate} ->
          {metric, amount, :h} |> transmit(options, rate)
          amount
        _ ->
          amount
      end
    end
  end

  @doc """
  Time a function using a histogram metric (DogStatsD-only).

  * `sample_rate`: Limit how often the metric is collected
  * `tags`: Add tags to entry (DogStatsD-only)

  It returns the result of the function call, making it suitable
  for pipelining.
  """
  def histogram_timing(metric, fun, options \\ [sample_rate: 1, tags: []]) do
    sampling options, fn(decision) ->
      case decision do
        {:sample, rate} ->
          {time, value} = :timer.tc(fun)
          amount = time / 1000.0
          # We should hard code the amount when we are in test mode.
          amount = if Application.get_env(:ex_statsd, :test_mode, false), do: @timing_stub, else: amount
          {metric, amount, :h} |> transmit(options, rate)
          value
        _ ->
          fun.()
      end
    end
  end

  @doc """
  Emit event.

  `text` supports line breaks, only first 4KB will be transmitted.

  Available options:
  * `tags`: Add tags to entry (DogStatsD-only)
  * `priority`: Can be *normal* or *low*, default *normal*
  * `alert_type`: Can be *error*, *warning*, *info* or *success*, default *info*
  * `aggregation_key`: Assign an aggregation key to the event, to group it with some others
  * `hostname`: Assign a hostname to the event
  * `source_type_name`: Assign a source type to the event
  * `date_happened`: Assign a timestamp to the event, default current time

  It returns the title of the event, making it suitable for pipelining.
  """
  def event(title, text \\ "", options \\ [tags: []]) do
    {:event, title, text, options} |> transmit(options)
    title
  end

  defp sampling(options, fun) when is_list(options) do
    case Keyword.get(options, :sample_rate, 1) do
      1 -> fun.({:sample, 1})
      sample_rate -> sample(sample_rate, fun)
    end
  end
  defp sample(sample_rate, fun) do
    case :random.uniform <= sample_rate do
      true -> fun.({:sample, sample_rate})
      _ -> fun.(:no_sample)
    end
  end

  defp transmit(message, options), do: transmit(message, options, 1)
  defp transmit(message, options, sample_rate) do
    GenServer.cast(__MODULE__, {:transmit, message, options, sample_rate})
  end

  defp packet({key, value, type}, namespace, tags, sample_rate) do
    [key |> stat_name(namespace),
     ":#{value}|#{type}",
     sample_rate |> sample_rate_suffix,
     tags |> tags_suffix
    ]
  end

  defp packet({:event, title, text, opts}, _namespace, tags, _sample_rate) do
    text = text |> String.replace("\n","\\n") |> String.slice(0, 4096)
    [
      "_e",
      "{#{title |> byte_size},#{text |> byte_size}}",
      ":#{title}|#{text}",
      opts[:priority]         && "|p:#{opts[:priority]}" || "",
      opts[:alert_type]       && "|t:#{opts[:alert_type]}" || "",
      opts[:source_type_name] && "|s:#{opts[:source_type_name]}" || "",
      opts[:aggregation_key]  && "|k:#{opts[:aggregation_key]}" || "",
      opts[:hostname]         && "|h:#{opts[:hostname]}" || "",
      opts[:date_happened]    && "|d:#{opts[:date_happened]}" || "",
      tags |> tags_suffix
    ]
  end

  defp sample_rate_suffix(1), do: ""
  defp sample_rate_suffix(sample_rate) do
    ["|@", :io_lib.format('~.2f', [sample_rate])]
  end

  defp tags_suffix([]), do: ""
  defp tags_suffix(tags) do
    ["|#", tags |> Enum.join(",")]
  end

  defp stat_name(key, nil), do: key
  defp stat_name(key, namespace), do: "#{namespace}.#{key}"

  # SERVER

  @doc false
  def handle_cast({:transmit, message, options, sample_rate}, %{sink: sink} = state) when is_list(sink) do
    tags = Keyword.get(options, :tags, [])
    pkt = message |> packet(state.namespace, state.tags ++ tags, sample_rate) |> IO.iodata_to_binary
    {:noreply, %{state | sink: [pkt | sink]}}
  end

  @doc false
  def handle_cast({:transmit, message, options, sample_rate}, state) do
    tags = Keyword.get(options, :tags, [])
    pkt = message |> packet(state.namespace, state.tags ++ tags, sample_rate)
    {:ok, socket} = :gen_udp.open(0, [:binary])
    :gen_udp.send(socket, state.host, state.port, pkt)
    :gen_udp.close(socket)
    {:noreply, state}
  end

  @doc false
  def handle_call(:flush, _from, state) do
    {:reply, :ok, state}
  end
end
