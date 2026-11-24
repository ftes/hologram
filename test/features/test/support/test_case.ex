defmodule HologramFeatureTests.TestCase do
  use ExUnit.CaseTemplate

  using opts do
    quote do
      use Playwright.Case, unquote(opts)

      # Hologram.Commons.KernelUtils.inspect/1 is used instead of Kernel.inspect/1
      import Kernel, except: [inspect: 1]

      import Hologram.Commons.KernelUtils, only: [inspect: 1]
      import Hologram.Commons.TestUtils
      import Hologram.Test.FeatureHelpers
      import HologramFeatureTests.Helpers

      # Fails the test on an uncaught error in any of its pages, unless the test
      # expects it with assert_js_error/3 or assert_client_error/4.
      setup %{context: context}, do: track_js_errors(context)
    end
  end
end
