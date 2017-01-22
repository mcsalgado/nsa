defmodule Nsa.PageController do
  use Nsa.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
