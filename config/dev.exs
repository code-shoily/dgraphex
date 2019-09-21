use Mix.Config

config :dgraphex, Configuration,
  hostname: 'localhost',
  port: 9080,
  pool_size: 5,
  max_overflow: 1
