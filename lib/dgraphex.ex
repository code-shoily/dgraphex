defmodule Dgraphex do
  @moduledoc false
  use Supervisor

  alias Dgraphex.ConfigStore

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    children = [
      {ConfigStore, default_config(opts)},
      :poolboy.child_spec(:worker, poolboy_config())
    ]

    Supervisor.init(children, strategy: :one_for_one, name: Dgraphex.Supervisor)
  end

  def stop(_state) do
    :ok
  end

  def config, do: ConfigStore.get_config()

  @doc false
  def config(key), do: Keyword.get(config(), key)

  @doc false
  def config(key, default) do
    Keyword.get(config(), key, default)
  rescue
    _ -> default
  end

  # ---------------------------------------------------------
  # PUBLIC API
  # ---------------------------------------------------------
  def alter(command), do: :implement_me
  def query(command, vars), do: :implement_me
  def mutate(command, vars), do: :implement_me
  def delete(command, vars), do: :implement_me
  def login(command, vars), do: :implement_me
  # ---------------------------------------------------------
  # PRIVATE API
  # ---------------------------------------------------------
  defp poolboy_config do
    Application.get_env(:dgraphex, Dgraphex)
    |> Keyword.put_new(:name, {:local, :worker})
    |> Keyword.put_new(:worker_module, Dgraphex.APIWrapper)
  end

  @spec default_config(Keyword.t()) :: Keyword.t()
  def default_config(config) do
    config
    |> Keyword.put_new(:hostname, System.get_env("DGRAPH_HOST") || 'localhost')
    |> Keyword.put_new(:port, System.get_env("DGRAPH_PORT") || 9080)
    |> Keyword.put_new(:timeout, 15_000)
    |> Keyword.put_new(:ssl, false)
    |> Keyword.put_new(:tls_client_auth, false)
    |> Keyword.put_new(:certfile, nil)
    |> Keyword.put_new(:keyfile, nil)
    |> Keyword.put_new(:cacertfile, nil)
    |> Keyword.put_new(:enforce_struct_schema, false)
    |> Keyword.put_new(:keepalive, :infinity)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
  end
end
