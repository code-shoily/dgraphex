defmodule Dgraphex.Error do
  @moduledoc """
  Dgraph or connection error are wrapped in Dgraphex.Error.
  """
  defexception [:code, :reason, :action, :message]

  @type t :: %Dgraphex.Error{}

  @impl true
  def message(%{action: action, reason: reason}) do
    "#{action} failed with #{inspect(reason)}"
  end
end
