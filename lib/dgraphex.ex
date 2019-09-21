defmodule Dgraphex do
  @moduledoc false
  use Supervisor

  alias Dgraphex.ConfigStore
  alias Dgraphex.Utils

  @type payload :: atom() | {atom(), any()}

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    children = [
      {ConfigStore, Utils.default_config(opts)},
      :poolboy.child_spec(:worker, poolboy_config())
    ]

    Supervisor.init(children, strategy: :one_for_one, name: Dgraphex.Supervisor)
  end

  def stop(_state) do
    :ok
  end

  # ---------------------------------------------------------
  # PUBLIC API
  # ---------------------------------------------------------
  @spec config :: Keyword.t()
  def config, do: ConfigStore.get_config()

  @doc false
  @spec config(atom()) :: any()
  def config(key), do: Keyword.get(config(), key)

  @doc false
  @spec config(atom(), any()) :: any()
  def config(key, default) do
    Keyword.get(config(), key, default)
  rescue
    _ -> default
  end

  def get_channel, do: transact(:channel)

  def reconnect, do: transact(:reconnect)

  def alter(statement), do: transact({:alter, statement})

  def query(statement), do: transact({:query, statement})

  def mutate_nquads(statement) when is_list(statement), do:
    transact({:mutate_nquads_many, statement})

  def mutate_nquads(statement) when is_binary(statement), do:
    transact({:mutate_nquads, statement})

  def mutate_json(statement) when is_list(statement), do:
    transact({:mutate_json_many, statement})

  def mutate_json(statement), do: transact({:mutate_json, statement})

  # ---------------------------------------------------------
  # PRIVATE API
  # ---------------------------------------------------------
  @spec transact(payload()) :: any()
  defp transact(payload) do
    :poolboy.transaction(
      :worker,
      fn pid -> GenServer.call(pid, payload) end,
      config(:timeout)
    )
  end

  @spec poolboy_config :: Keyword.t()
  defp poolboy_config do
    Application.get_env(:dgraphex, Configuration)
    |> Keyword.put_new(:name, {:local, :worker})
    |> Keyword.put_new(:worker_module, Dgraphex.ApiWrapper)
  end
end
