defmodule HologramFeatureTests.ClientCreatedStructsTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.CallGraph.ClientCreatedStructsPage

  test "create with defaults", %{page: page} do
    page
    |> visit(ClientCreatedStructsPage)
    |> click_button("Create with defaults")
    |> assert_text("#result", inspect({"default", 0}))
  end

  test "create with custom values", %{page: page} do
    page
    |> visit(ClientCreatedStructsPage)
    |> click_button("Create with custom values")
    |> assert_text("#result", inspect({"custom", 42}))
  end
end
