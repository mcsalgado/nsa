defmodule Nsa.Rabbit.Api do
  def get_exchanges do
    rabbit_url = Application.get_env(:nsa, :rabbit_url)
    rabbit_api_port = Application.get_env(:nsa, :rabbit_api_port)

    result = HTTPotion.get "http://#{rabbit_url}:#{rabbit_api_port}/api/exchanges", [timeout: 60_000]

    map = Poison.Parser.parse!(result.body)
    |> Enum.filter(fn(exchange) -> exchange["type"] == "topic" end)
    |> Enum.map(fn(exchange) -> exchange["name"] end)
  end
end
