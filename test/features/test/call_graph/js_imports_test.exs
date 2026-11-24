defmodule HologramFeatureTests.JsImportsTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.CallGraph.JsImportsPage

  test "js_import of a runtime-bundled component resolves", %{page: page} do
    page
    |> visit(JsImportsPage)
    |> assert_text("#js_call_result", "not called yet")
    |> click_button("Call JS")
    |> assert_text("#js_call_result", "IT WORKS")
  end

  # The page calls the component's suffix/0, so the component's MFAs are split between the runtime
  # bundle and the page bundle. The runtime bundle owns the component's JS bindings, so the page
  # bundle must not import a second copy of the JavaScript module they come from.
  test "the JS module of a split module is loaded once", %{page: page} do
    page
    |> visit(JsImportsPage)
    |> assert_text("#suffix", "!")
    |> click_button("Count loads")
    |> assert_text("#js_call_result", "1")
  end
end
