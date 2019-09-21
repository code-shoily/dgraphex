defmodule Dgraphex do
  @moduledoc false
  use Supervisor

  alias Dgraphex.ConfigStore

  @timeout 5_000

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
  def get_channel do
    :poolboy.transaction(
      :worker,
      fn pid -> GenServer.call(pid, :channel) end,
      @timeout
    )
  end

  def reconnect do
    :poolboy.transaction(
      :worker,
      fn pid -> GenServer.call(pid, :reconnect) end,
      @timeout
    )
  end

  def alter(statement) do
    :poolboy.transaction(
      :worker,
      fn pid -> GenServer.call(pid, {:alter, statement}) end,
      @timeout
    )
  end
  def query(statement) do
    :poolboy.transaction(
      :worker,
      fn pid -> GenServer.call(pid, {:query, statement}) end,
      @timeout
    )
  end

  def mutate_nquads(statement) when is_list(statement) do
    :poolboy.transaction(
      :worker,
      fn pid -> GenServer.call(pid, {:mutate_nquads_many, statement}) end,
      @timeout
    )
  end

  def mutate_nquads(statement) when is_binary(statement) do
    :poolboy.transaction(
      :worker,
      fn pid -> GenServer.call(pid, {:mutate_nquads, statement}) end,
      @timeout
    )
  end

  def mutate_json(statement) when is_list(statement) do
    :poolboy.transaction(
      :worker,
      fn pid -> GenServer.call(pid, {:mutate_json_many, statement}) end,
      @timeout
    )
  end

  def mutate_json(statement) do
    :poolboy.transaction(
      :worker,
      fn pid -> GenServer.call(pid, {:mutate_json, statement}) end,
      @timeout
    )
  end
  # ---------------------------------------------------------
  # PRIVATE API
  # ---------------------------------------------------------
  defp poolboy_config do
    Application.get_env(:dgraphex, Dgraphex)
    |> Keyword.put_new(:name, {:local, :worker})
    |> Keyword.put_new(:worker_module, Dgraphex.ApiWrapper)
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
