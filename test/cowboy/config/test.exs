import Config

config :hologram_cowboy_tests, HologramCowboyTestsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "kYpR2mWvT8xQz5NbGf3JhE7aDs9LcU4C6jViObM0WqXtZrAeD1kFyHgPnSuIlo0z",
  server: true

config :logger, level: :warning

config :playwright, :test,
  base_url: "http://localhost:4002",
  action_timeout: 30_000,
  expect: [timeout: 30_000],
  navigation_timeout: 30_000,
  screenshot: :only_on_failure,
  trace: :retain_on_failure
