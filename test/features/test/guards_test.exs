defmodule HologramFeatureTests.GuardsTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.GuardsPage

  describe "anonymous function" do
    test "single guard", %{page: page} do
      page
      |> visit(GuardsPage)
      |> click_button("Anonymous function - single guard")
      |> assert_text("#result", ":b")
    end

    test "multiple guards", %{page: page} do
      page
      |> visit(GuardsPage)
      |> click_button("Anonymous function - multiple guards")
      |> assert_text("#result", ":c")
    end
  end

  describe "case expression" do
    test "single guard", %{page: page} do
      page
      |> visit(GuardsPage)
      |> click_button("Case expression - single guard")
      |> assert_text("#result", ":b")
    end

    test "multiple guards", %{page: page} do
      page
      |> visit(GuardsPage)
      |> click_button("Case expression - multiple guards")
      |> assert_text("#result", ":c")
    end
  end

  describe "private function" do
    test "single guard", %{page: page} do
      page
      |> visit(GuardsPage)
      |> click_button("Private function - single guard")
      |> assert_text("#result", ":b")
    end

    test "multiple guards", %{page: page} do
      page
      |> visit(GuardsPage)
      |> click_button("Private function - multiple guards")
      |> assert_text("#result", ":c")
    end
  end

  describe "public function" do
    test "single guard", %{page: page} do
      page
      |> visit(GuardsPage)
      |> click_button("Public function - single guard")
      |> assert_text("#result", ":b")
    end

    test "multiple guards", %{page: page} do
      page
      |> visit(GuardsPage)
      |> click_button("Public function - multiple guards")
      |> assert_text("#result", ":c")
    end
  end
end
