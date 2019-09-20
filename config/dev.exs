use Mix.Config

config :dgraphex, Dgraphex,
  hostname: 'localhost',
  port: 9080,
  pool_size: 5,
  max_overflow: 1
