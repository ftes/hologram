import Config

# Every app instance in the cluster runs from this same build, so the port comes from an
# env var - the orchestrator assigns each peer its own before starting the app there.
#
# `server: false` because this config belongs to the ORCHESTRATOR - the node running
# ExUnit, the browser and the proxy, which serves no app traffic itself. Peers get the env
# copied with `server: true` and their own port before the app starts there.
config :hologram_cluster_tests, HologramClusterTestsWeb.Endpoint,
  http: [
    ip: {127, 0, 0, 1},
    port: String.to_integer(System.get_env("HOLOGRAM_CLUSTER_TESTS_PORT") || "4003")
  ],
  secret_key_base: "wK5c8mQnJ2vRfTz9BxYhE3aGdN7pLsU4C6jViObM0WqXtZrAeD1kFyHgPnSuIlo0",
  server: false

# The one origin the browser ever sees. Browser traffic distributes across the peers
# exactly as the proxy's routing policy decides.
config :hologram_cluster_tests, :proxy_port, 4005

config :logger, level: :warning

config :playwright, :test,
  # The proxy, the one origin the browser ever sees (:proxy_port above).
  base_url: "http://localhost:4005",
  action_timeout: 30_000,
  expect: [timeout: 30_000],
  navigation_timeout: 30_000,
  screenshot: :only_on_failure,
  trace: :retain_on_failure
