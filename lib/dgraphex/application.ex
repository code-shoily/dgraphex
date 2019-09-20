defmodule Dgraphex.Application do
  @moduledoc false

  use Application

  def start(_, start_args) do
    Dgraphex.start_link(start_args)
  end

  def stop(_state) do
    :ok
  end
end
