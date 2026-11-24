import Config

config :hologram_feature_tests, HologramFeatureTestsWeb.Endpoint,
  secret_key_base: "+c4nzKpOujvWTRjsuvgfREOT8nnWvr/ZL0t+CR5AeWkiJQl36INDkV7uAvyGgnBa",
  server: true

# HOLOGRAM_FEATURE_TESTS_HTTPS serves the same app over TLS, where Chrome negotiates
# HTTP/2 - Bandit offers it over TLS by default. Tests touching the SSE stream then run
# against Bandit's other protocol, whose stream lifecycle is unlike HTTP/1.1's.
# The Playwright base URL below follows the listener, so nothing else changes.
#
# The cert is a test-only self-signed pair made with OpenSSL, not `mix phx.gen.cert`:
#
#   openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 3650 \
#     -subj "/O=Hologram feature tests/CN=localhost" \
#     -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" \
#     -keyout priv/cert/selfsigned_key.pem -out priv/cert/selfsigned.pem
#
# phx.gen.cert leaves out the NULL parameters of the public key's rsaEncryption algorithm
# identifier, which RFC 3279 requires. OpenSSL and curl accept that, Chrome's BoringSSL
# does not: it rejects the key with a fatal decode error and every page load fails.
if System.get_env("HOLOGRAM_FEATURE_TESTS_HTTPS") do
  config :hologram_feature_tests, HologramFeatureTestsWeb.Endpoint,
    https: [
      certfile: Path.expand("../priv/cert/selfsigned.pem", __DIR__),
      ip: {127, 0, 0, 1},
      keyfile: Path.expand("../priv/cert/selfsigned_key.pem", __DIR__),
      port: 4002
    ]
else
  config :hologram_feature_tests, HologramFeatureTestsWeb.Endpoint,
    http: [ip: {127, 0, 0, 1}, port: 4002]
end

config :logger, level: :warning

# Lets a feature test drive the SSE stream's test seams via cookies: hold the attach open,
# so a boot-time command can reach the server before the connection exists, and shorten
# the heartbeat, so a silent stream's reconnect fits the wait budget. Never enabled
# outside the test env.
config :hologram, :__sse_test_seams_enabled__, true

config :playwright, :test,
  base_url: "http://localhost:4002",
  action_timeout: 30_000,
  expect: [timeout: 30_000],
  navigation_timeout: 30_000,
  screenshot: :only_on_failure,
  trace: :retain_on_failure,
  # The window size the suite was written against.
  viewport: %{width: 1280, height: 800}

if System.get_env("HOLOGRAM_FEATURE_TESTS_HTTPS") do
  config :playwright, :test,
    base_url: "https://localhost:4002",
    launch_options: [
      args: [
        # Trusts the self-signed cert of the HTTPS listener above, by the SHA-256 of its
        # public key. Ignoring the cert error instead (ignore_https_errors) keeps every page
        # out of Chrome's HTTP cache, and Playwright's Chrome has no back/forward cache, so
        # Back would load a page afresh rather than restore it. Made with:
        #
        #   openssl x509 -in priv/cert/selfsigned.pem -pubkey -noout |
        #     openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
        "--ignore-certificate-errors-spki-list=qg6CVLnxX7fFhxDpY37sTG3B7B1uLbNB6gczT/cLFz0="
      ]
    ]
end
