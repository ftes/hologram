import Config

config :hologram_ecosystem_tests, HologramEcosystemTestsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Hn4xWc7PqZ2mTrV9sLbD6yKgE0uJfA3oNiX8eRtY1wMpS5dCzQvG7aBlUjOhIkF2",
  server: true

config :logger, level: :warning

config :playwright, :test,
  base_url: "http://localhost:4002",
  action_timeout: 30_000,
  expect: [timeout: 30_000],
  navigation_timeout: 30_000,
  screenshot: :only_on_failure,
  trace: :retain_on_failure
