defmodule HologramClusterTests.TestCase do
  use ExUnit.CaseTemplate

  using opts do
    quote do
      use Playwright.Case, unquote(opts)

      import Hologram.Test.FeatureHelpers, only: [track_js_errors: 1, visit: 2]
      import HologramClusterTests.BrowserHelpers
      import HologramClusterTests.Cluster

      alias HologramClusterTests.Proxy

      # Fails the test on an uncaught error in any of its pages.
      setup %{context: context}, do: track_js_errors(context)
    end
  end
end
