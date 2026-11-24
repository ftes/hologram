import Config

config :app_1, App1.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "cGXbx/UMm3qsyR8HYYVwO+/SWp1HAYxhFYHO/ugY6VaRenmQs4dCUoSzdxfMEMeS",
  server: true

config :logger, level: :warning

config :playwright, :test,
  base_url: "http://localhost:4002",
  action_timeout: 30_000,
  expect: [timeout: 30_000],
  navigation_timeout: 30_000,
  screenshot: :only_on_failure,
  trace: :retain_on_failure
