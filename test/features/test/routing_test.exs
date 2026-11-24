defmodule HologramFeatureTests.RoutingTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Routing.RouteWithoutParamsPage
  alias HologramFeatureTests.Routing.RouteWithParamsPage

  test "route without params", %{page: page} do
    page
    |> visit(RouteWithoutParamsPage)
    |> assert_text("Route Without Params Page")
    |> assert_text("#page_module", inspect(RouteWithoutParamsPage))
    |> assert_text("#page_params", inspect(%{}))
  end

  test "route with params", %{page: page} do
    expected = inspect(%{a: "abc", b: 123})

    page
    |> visit(RouteWithParamsPage, a: "abc", b: 123)
    |> assert_text("Route With Params Page")
    |> assert_text("#page_module", inspect(RouteWithParamsPage))
    |> assert_text("#page_params", expected)
  end

  # Use hardcoded path with percent-encoded params to test server-side decoding.
  # Non-hardcoded call: visit(RouteWithPercentEncodedParamsPage, a: "hello world", b: "foo/bar")
  # would test the same decoding, but with encoding done by the test framework.
  # Client-side encoding is tested in navigation_test.exs.
  test "route with percent-encoded params", %{page: page} do
    page
    |> visit("/routing/route-with-percent-encoded-params/hello%20world/foo%2Fbar")
    |> assert_text("Route With Percent Encoded Params Page")
    |> assert_text("#param_a", ~s'"hello world"')
    |> assert_text("#param_b", ~s'"foo/bar"')
  end
end
