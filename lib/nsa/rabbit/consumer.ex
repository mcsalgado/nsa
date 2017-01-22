defmodule Nsa.Rabbit.Consumer do
  use GenServer
  use AMQP

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: :rabbit_consumer])
  end

  @queue "nsa"

  def init(_opts) do
    rabbitmq_connect()
  end

  defp rabbitmq_connect do
    rabbit_url = Application.get_env(:nsa, :rabbit_url)
    rabbit_amqp_port = Application.get_env(:nsa, :rabbit_amqp_port)
    case Connection.open("amqp://#{rabbit_url}:#{rabbit_amqp_port}") do
      {:ok, conn} ->
        Process.monitor(conn.pid)

        {:ok, chan} = Channel.open(conn)
        Basic.qos(chan, prefetch_count: 10)

        Queue.declare(chan, @queue, durable: true,
                                    arguments: [])

        Nsa.Rabbit.Api.get_exchanges
        |> Enum.map(fn(exchange) -> Queue.bind(chan, @queue, exchange, routing_key: "#") end)

        {:ok, _consumer_tag} = Basic.consume(chan, @queue)
        {:ok, chan}
      {:error, _} ->
        # Reconnection loop
        :timer.sleep(10000)
        rabbitmq_connect
    end
end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, chan) do
    {:noreply, chan}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, chan) do
    {:stop, :normal, chan}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info({:basic_deliver, payload, meta = %{delivery_tag: tag, redelivered: redelivered}}, chan) do
    spawn fn -> consume(chan, tag, redelivered, payload, meta) end
    {:noreply, chan}
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, _) do
    {:ok, chan} = rabbitmq_connect
    {:noreply, chan}
  end

  def handle_cast({:ack_message, tag, channel}, state) do
    Basic.ack channel, tag
    {:noreply, channel}
  end

  def ack_message(tag, channel) do
    GenServer.cast(:rabbit_consumer, {:ack_message, tag, channel})
  end

  defp consume(channel, tag, redelivered, payload, meta) do
     try do
      Nsa.Endpoint.broadcast("messages", "new_message", %{
                                                          "exchange" => meta[:exchange],
                                                          "routing_key" => meta[:routing_key],
                                                          "message" => payload
                                                        })

      Basic.ack channel, tag
    rescue
      exception ->
        # Requeue unless it's a redelivered message.
        # This means we will retry consuming a message once in case of exception
        # before we give up and have it moved to the error queue
        Basic.reject channel, tag, requeue: not redelivered
        IO.puts "Error converting #{payload} to integer"
    end
  end
end
