#!/usr/bin/env bash
# Runs `mix test` with the given arguments and GitHub annotations, and reruns the failures
# once when tests failed (exit status 2): a crash or a compile error isn't retried. The rerun
# takes no arguments: the failures manifest holds only this run's failures (only this
# partition's, under --partitions, which would deal them out again).
#
# On Elixir 1.20 and earlier --failed can lose a failure, and a rerun that lost them all starts
# no ExUnit run and exits 0, so that rerun fails. ("There are no tests to run" won't do: an
# umbrella prints it for each app without failures.)
set -o pipefail

formatters=(
  --formatter ExUnit.CLIFormatter
  --formatter Playwright.Test.GitHubFormatter
  --formatter Playwright.Test.JSONFormatter
)
log="$RUNNER_TEMP/mix-test-retry.log"
export PLAYWRIGHT_JSON_OUTPUT_DIR="$PWD/${PLAYWRIGHT_JSON_OUTPUT_DIR:-test-results}"

PLAYWRIGHT_JSON_OUTPUT_NAME=report.json \
  mix test --warnings-as-errors "$@" "${formatters[@]}" && exit 0
status=$?
[ "$status" -eq 2 ] || exit "$status"

PLAYWRIGHT_JSON_OUTPUT_NAME=report-retry.json \
  mix test --warnings-as-errors --failed "${formatters[@]}" | tee "$log" &&
  grep -q '^Running ExUnit with seed' "$log"
