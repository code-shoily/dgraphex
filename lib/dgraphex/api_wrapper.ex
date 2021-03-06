defmodule Dgraphex.ApiWrapper do
  use GenServer

  alias Dgraphex.Error
  alias Dgraphex.Api.{Operation, Request, Mutation}
  alias Dgraphex.Api.Dgraph.Stub, as: ApiStub

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  @impl true
  def init(_) do
    case connect() do
      {:ok, channel} -> {:ok, %{channel: channel}}
      error -> error
    end
  end

  @impl true
  def handle_call({:alter, statement}, _from, %{channel: channel} = state) do
    case ApiStub.alter(channel, Operation.new(schema: statement)) do
      {:ok, result} -> {:reply, result, state}
      {:error, error} -> {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:query, statement}, _from, %{channel: channel} = state) do
    case ApiStub.query(channel, Request.new(query: statement)) do
      {:ok, result} -> {:reply, result, state}
      {:error, error} -> {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:mutate_nquads, statement}, _from, %{channel: channel} = state) do
    mutations = [Mutation.new(set_nquads: statement)]

    case ApiStub.query(
           channel,
           Request.new(mutations: mutations, commit_now: true)
         ) do
      {:ok, result} -> {:reply, result, state}
      {:error, error} -> {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:mutate_nquads_many, statements}, _from, %{channel: channel} = state) do
    mutations =
      statements
      |> Enum.map(fn statement ->
        Mutation.new(set_nquads: statement)
      end)

    case ApiStub.query(
           channel,
           Request.new(mutations: mutations, commit_now: true)
         ) do
      {:ok, result} -> {:reply, result, state}
      {:error, error} -> {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:mutate_json, statement}, _from, %{channel: channel} = state) do
    mutations = [Mutation.new(set_json: Jason.encode!(statement))]

    case ApiStub.query(
           channel,
           Request.new(mutations: mutations, commit_now: true)
         ) do
      {:ok, result} -> {:reply, result, state}
      {:error, error} -> {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:mutate_json_many, statements}, _from, %{channel: channel} = state) do
    mutations =
      statements
      |> Enum.map(fn statement ->
        Mutation.new(set_json: Jason.encode!(statement))
      end)

    case ApiStub.query(
           channel,
           Request.new(mutations: mutations, commit_now: true)
         ) do
      {:ok, _} -> {:reply, :ok, state}
      {:error, error} -> {:reply, error, state}
    end
  end

  @impl true
  def handle_call(:channel, _from, %{channel: channel} = state) do
    {:reply, channel, state}
  end

  @impl true
  def handle_call(:reconnect, _from, _state) do
    {:ok, channel} = connect()
    {:reply, channel, %{channel: channel}}
  end

  @impl true
  def terminate(reason, %{channel: channel}) do
    disconnect(reason, channel)
    :ok
  end

  def connect() do
    host = to_charlist(Dgraphex.config(:hostname))
    port = Dgraphex.config(:port)

    opts =
      []
      |> set_ssl_opts()
      |> Keyword.put(:adapter_opts, %{http2_opts: %{keepalive: Dgraphex.config(:keepalive)}})

    case GRPC.Stub.connect("#{host}:#{port}", opts) do
      {:ok, channel} ->
        {:ok, channel}

      {:error, reason} ->
        {:error, %Error{action: :connect, reason: reason}}
    end
  end

  def disconnect(_error, channel) do
    case GRPC.Stub.disconnect(channel) do
      {:ok, _} -> :ok
      {:error, _reason} -> :ok
    end
  end

  defp configure_ssl(ssl_opts \\ []) do
    case Dgraphex.config(:ssl) do
      true ->
        add_ssl_file(ssl_opts, :cacertfile)

      false ->
        ssl_opts
    end
  end

  defp configure_tls_auth(ssl_opts) do
    case Dgraphex.config(:tls_client_auth) do
      true ->
        ssl_opts
        |> add_ssl_file(:certfile)
        |> add_ssl_file(:keyfile)
        |> add_ssl_file(:certfile)

      false ->
        ssl_opts
    end
  end

  defp add_ssl_file(ssl_opts, type) do
    Keyword.put(ssl_opts, type, validate_tls_file(type, Dgraphex.config(type)))
  end

  defp validate_tls_file(type, path) do
    case File.exists?(path) do
      true ->
        path

      false ->
        raise Error,
          code: 2,
          message: "SSL configuration error. File #{type} '#{Dgraphex.config(type)}' not found"
    end
  end

  defp set_ssl_opts(opts) do
    if Dgraphex.config(:ssl) || Dgraphex.config(:tls_client_auth) do
      ssl_opts =
        configure_ssl()
        |> configure_tls_auth()

      Keyword.put(opts, :cred, GRPC.Credential.new(ssl: ssl_opts))
    else
      opts
    end
  end
end
