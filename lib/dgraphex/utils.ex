defmodule Dgraphex.Utils do
  @spec default_config(Keyword.t()) :: Keyword.t()
  def default_config(config \\ Application.get_env(:dgraphex, Configuration)) do
    :dgraphex
    |> Application.get_env(Configuration)
    |> Keyword.merge(config)
    |> Keyword.put_new(:hostname, 'localhost')
    |> Keyword.put_new(:port, 9080)
    |> Keyword.put_new(:timeout, 15_000)
    |> Keyword.put_new(:ssl, false)
    |> Keyword.put_new(:tls_client_auth, false)
    |> Keyword.put_new(:certfile, nil)
    |> Keyword.put_new(:keyfile, nil)
    |> Keyword.put_new(:cacertfile, nil)
    |> Keyword.put_new(:keepalive, :infinity)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
  end
end
