defmodule App1.TestCase do
  use ExUnit.CaseTemplate

  using opts do
    quote do
      use Playwright.Case, unquote(opts)

      import App1.Helpers
      import Hologram.Test.FeatureHelpers

      # Fails the test on an uncaught error in any of its pages.
      setup %{context: context}, do: track_js_errors(context)
    end
  end
end
