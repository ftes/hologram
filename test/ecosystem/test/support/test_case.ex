defmodule HologramEcosystemTests.TestCase do
  use ExUnit.CaseTemplate

  using opts do
    quote do
      use Playwright.Case, unquote(opts)

      # visit/2 comes from Hologram.Test.FeatureHelpers, which takes a page module
      # rather than a path.
      import Hologram.Test.FeatureHelpers
      import HologramEcosystemTests.Helpers

      # Fails the test on an uncaught error in any of its pages.
      setup %{context: context}, do: track_js_errors(context)
    end
  end
end
