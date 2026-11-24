defmodule HologramFeatureTests.DynamicReflectionTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.CallGraph.DynamicReflectionPage

  describe "__struct__ on a module read from state" do
    test "through struct/2", %{page: page} do
      page
      |> visit(DynamicReflectionPage)
      |> click_button("Build with struct/2")
      |> assert_text("#result", inspect({"default", 0}))
    end

    test "through struct!/2", %{page: page} do
      page
      |> visit(DynamicReflectionPage)
      |> click_button("Build with struct!/2")
      |> assert_text("#result", inspect({"custom", 42}))
    end

    test "through a dot", %{page: page} do
      page
      |> visit(DynamicReflectionPage)
      |> click_button("Build with a dot")
      |> assert_text("#result", inspect({"default", 0}))
    end
  end

  describe "schema reflection on a module read from state" do
    test "__changeset__/0", %{page: page} do
      page
      |> visit(DynamicReflectionPage)
      |> click_button("Read __changeset__/0")
      |> assert_text("#result", inspect(%{name: :string}))
    end

    test "__schema__/1", %{page: page} do
      page
      |> visit(DynamicReflectionPage)
      |> click_button("Read __schema__/1")
      |> assert_text("#result", inspect([:name]))
    end
  end
end
